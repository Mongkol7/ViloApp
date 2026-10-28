import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../domain/entities/inbox_item.dart';

/// Centralized in-memory manager for direct message threads and active conversations.
///
/// Ensures real-time state synchronization between Cart inquiries, ChatDetailScreen,
/// and the InboxScreen MESSAGES list, with dual persistence:
/// 1. Local per-account SharedPreferences (works on Web, Windows, Android, iOS).
/// 2. Remote PostgreSQL database (/api/v1/chats) when authenticated.
class InboxMessageManager {
  InboxMessageManager._internal() {
    _threads = [];
    threadsNotifier = ValueNotifier<List<DirectMessageThread>>(_threads);
  }

  static final InboxMessageManager instance = InboxMessageManager._internal();

  late final List<DirectMessageThread> _threads;
  late final ValueNotifier<List<DirectMessageThread>> threadsNotifier;
  final Map<String, String> _drafts = {};
  int? _activeUserId;
  Future<void> _writeQueue = Future<void>.value();
  Future<void>? _loadFuture;

  List<DirectMessageThread> get threads =>
      List.unmodifiable(_threads.map(resolveThreadForActiveUser));

  static bool _isNotLegacyStaticThread(DirectMessageThread thread) {
    final id = thread.id.trim().toLowerCase();
    // Legacy mock thread IDs were t0, t1, t2, t3, t4
    if (id == 't0' || id == 't1' || id == 't2' || id == 't3' || id == 't4') {
      return false;
    }
    final username = thread.username.replaceAll('@', '').trim().toLowerCase();
    if (username == 'fashionhub' ||
        username == 'jinxmo_mo' ||
        username == 'udom-omdu' ||
        username == '22-october' ||
        username == '28-nove') {
      return false;
    }
    return true;
  }

  Future<void> loadForCurrentUser() async {
    final userId = ProfileSyncService.instance.cachedMyProfile?.id ?? await TokenStorage.instance.getUserId();
    if (userId == null) {
      // Fully reset in-memory state on logout so the previous account's
      // messages never appear under the guest or next-login session.
      _activeUserId = null;
      _loadFuture = null;
      _threads.clear();
      _drafts.clear();
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_legacyGuestStorageKey);
      await preferences.remove(_olderGuestStorageKey);
      final saved = preferences.getString(_guestStorageKey);
      if (saved != null) {
        try {
          final decoded = jsonDecode(saved) as Map<String, dynamic>;
          final savedThreads = (decoded['threads'] as List<dynamic>? ?? const [])
              .map((thread) => DirectMessageThread.fromJson(thread as Map<String, dynamic>))
              .where(_isNotLegacyStaticThread)
              .toList();
          final savedDrafts = decoded['drafts'] as Map<String, dynamic>? ?? const {};
          if (savedThreads.isNotEmpty) {
            _threads.addAll(savedThreads);
            _drafts.addAll(savedDrafts.map((k, v) => MapEntry(k, v as String)));
            _deduplicateAndSortThreads();
            threadsNotifier.value = _threads.map(resolveThreadForActiveUser).toList();
            return;
          }
        } catch (_) {}
      }
      threadsNotifier.value = [];
      return;
    }
    await loadForUser(userId);
  }

  Future<void> loadForUser(int userId) async {
    if (_activeUserId == userId && _threads.isNotEmpty) {
      await _syncFromRemoteDatabase();
      return;
    }
    // Clear in-memory state before switching users so threads from the
    // previous session never contaminate the incoming account's data.
    _threads.clear();
    _drafts.clear();
    _activeUserId = userId;
    _loadFuture = _loadUserData(userId);
    await _loadFuture;
    await _syncFromRemoteDatabase();
  }

  @visibleForTesting
  Future<void> reloadForUser(int userId) async {
    await _writeQueue;
    _activeUserId = null;
    _loadFuture = null;
    await loadForUser(userId);
  }

  Future<void> _loadUserData(int userId) async {
    final preferences = await SharedPreferences.getInstance();
    // Move away from older inbox namespaces so legacy mock/test messages
    // cannot reappear after a fresh login.
    await preferences.remove(_legacyStorageKey(userId));
    await preferences.remove('inbox_user_v2_$userId');
    final saved = preferences.getString(_storageKey(userId));
    _drafts.clear();
    // _threads is always empty here because loadForUser clears it before calling us,
    // so there is no risk of cross-account contamination from in-memory state.
    if (saved != null) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      final savedThreads = (decoded['threads'] as List<dynamic>? ?? const [])
          .map((thread) => DirectMessageThread.fromJson(thread as Map<String, dynamic>))
          .where(_isNotLegacyStaticThread)
          .toList();
      final savedDrafts = decoded['drafts'] as Map<String, dynamic>? ?? const {};
      _threads.addAll(savedThreads);
      _drafts.addAll(savedDrafts.map((key, value) => MapEntry(key, value as String)));
    }
    _deduplicateAndSortThreads();
    threadsNotifier.value = _threads.map(resolveThreadForActiveUser).toList();
  }

  String? getDraft(String threadId) => _drafts[threadId];

  Future<void> saveDraft(String threadId, String draft) async {
    if (_activeUserId == null) return;
    if (draft.isEmpty) {
      _drafts.remove(threadId);
    } else {
      _drafts[threadId] = draft;
    }
    await _persist();
  }

  /// Completely clears all chat and message data for the active account / guest.
  Future<void> clearAllMessages() async {
    _threads.clear();
    _drafts.clear();
    threadsNotifier.value = [];
    final effectiveUserId = _activeUserId ?? ProfileSyncService.instance.cachedMyProfile?.id ?? TokenStorage.instance.getUserModel()?.id;
    final key = effectiveUserId != null ? _storageKey(effectiveUserId) : _guestStorageKey;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  static const String _storageVersion = 'v3';
  static const String _guestStorageKey = 'inbox_guest_messages_v3';
  static const String _legacyGuestStorageKey = 'inbox_guest_messages_v2';
  static const String _olderGuestStorageKey = 'inbox_guest_messages';

  Future<void> _persist() {
    final effectiveUserId = _activeUserId ?? ProfileSyncService.instance.cachedMyProfile?.id ?? TokenStorage.instance.getUserModel()?.id;
    final key = effectiveUserId != null ? _storageKey(effectiveUserId) : _guestStorageKey;
    _deduplicateAndSortThreads();
    final payload = jsonEncode({
      'threads': _threads.map((thread) => thread.toJson()).toList(),
      'drafts': _drafts,
    });
    _writeQueue = _writeQueue.catchError((Object error) {
      debugPrint('[InboxMessageManager] Previous save failed: $error');
    }).then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(key, payload);
    });
    return _writeQueue;
  }

  void _persistInBackground() {
    _persist().catchError((Object error) {
      debugPrint('[InboxMessageManager] Could not save inbox data: $error');
    });
  }

  String _storageKey(int userId) => 'inbox_user_${_storageVersion}_$userId';

  String _legacyStorageKey(int userId) => 'inbox_user_$userId';

  /// Guarantees that there is AT MOST one thread per distinct peer user in the inbox list.
  /// If multiple threads exist for the same peer, their messages are merged without duplicates.
  void _deduplicateAndSortThreads() {
    final Map<String, DirectMessageThread> uniqueByPeer = {};
    for (final thread in _threads) {
      final peer = resolvePeerHandle(thread).replaceAll('@', '').trim().toLowerCase();
      final key = peer.isNotEmpty ? peer : thread.username.replaceAll('@', '').trim().toLowerCase();
      if (key.isEmpty) continue;

      if (!uniqueByPeer.containsKey(key)) {
        uniqueByPeer[key] = thread;
      } else {
        final existing = uniqueByPeer[key]!;
        final existingIds = existing.messages.map((m) => m.id).toSet();
        final mergedMessages = [
          ...existing.messages,
          ...thread.messages.where((m) => !existingIds.contains(m.id)),
        ];
        // Prefer canonical dm_handle1_handle2 id over legacy chat_handle
        final preferId = (existing.id.startsWith('dm_') || !thread.id.startsWith('dm_'))
            ? existing.id
            : thread.id;
        final hasNewerAvatar = thread.avatarUrl.isNotEmpty &&
            !thread.avatarUrl.contains('dicebear') &&
            (existing.avatarUrl.isEmpty || existing.avatarUrl.contains('dicebear'));
        uniqueByPeer[key] = existing.copyWith(
          id: preferId,
          messages: mergedMessages,
          lastMessage: thread.lastMessage.isNotEmpty ? thread.lastMessage : existing.lastMessage,
          avatarUrl: hasNewerAvatar ? thread.avatarUrl : existing.avatarUrl,
        );
      }
    }
    _threads.clear();
    _threads.addAll(uniqueByPeer.values);
  }

  static String buildThreadId(String handle1, String handle2) {
    final c1 = handle1.replaceAll('@', '').trim().toLowerCase();
    final c2 = handle2.replaceAll('@', '').trim().toLowerCase();
    if (c1.isEmpty) return 'chat_$c2';
    if (c2.isEmpty) return 'chat_$c1';
    final list = [c1, c2]..sort();
    return 'dm_${list[0]}_${list[1]}';
  }

  /// Ensures a thread is resolved from the perspective of the active user.
  /// If the thread's displayed title is the active user's own handle, it inverts
  /// to the other participant's handle and avatar.
  static DirectMessageThread resolveThreadForActiveUser(DirectMessageThread thread) {
    final activeProfile = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
    final rawUsername = activeProfile?.username ?? ProfileSyncService.instance.currentUsername;
    final cleanMy = rawUsername.replaceAll('@', '').trim().toLowerCase();
    if (cleanMy.isEmpty) return thread;

    final cleanThreadU = thread.username.replaceAll('@', '').trim().toLowerCase();
    final cleanSender = thread.senderHandle?.replaceAll('@', '').trim().toLowerCase() ?? '';
    final cleanRecipient = thread.recipientHandle?.replaceAll('@', '').trim().toLowerCase() ?? '';

    String targetHandle = thread.username;
    String targetAvatar = thread.avatarUrl;

    // Symmetrical peer detection:
    // If thread is labeled with current user, or if cleanRecipient == cleanMy, peer is sender.
    if (cleanThreadU == cleanMy || (cleanRecipient.isNotEmpty && cleanRecipient == cleanMy)) {
      if (cleanSender.isNotEmpty && cleanSender != cleanMy) {
        targetHandle = thread.senderHandle!;
        targetAvatar = (thread.senderAvatar != null && thread.senderAvatar!.isNotEmpty)
            ? thread.senderAvatar!
            : resolveUserAvatar(targetHandle);
      }
    } else if (cleanSender.isNotEmpty && cleanSender == cleanMy) {
      // Current user is the sender; peer is recipient.
      if (cleanRecipient.isNotEmpty && cleanRecipient != cleanMy) {
        targetHandle = thread.recipientHandle!;
        targetAvatar = (thread.recipientAvatar != null && thread.recipientAvatar!.isNotEmpty)
            ? thread.recipientAvatar!
            : resolveUserAvatar(targetHandle);
      }
    }

    final formattedHandle = targetHandle.startsWith('@') ? targetHandle : '@$targetHandle';
    final resolvedAvatar = (targetAvatar.isNotEmpty && !targetAvatar.contains('dicebear.com'))
        ? targetAvatar
        : resolveUserAvatar(formattedHandle, candidateAvatar: targetAvatar);

    // Map each message to correctly orient based on active user
    final mappedMessages = thread.messages.map((m) {
      if (m.senderHandle != null && m.senderHandle!.trim().isNotEmpty) {
        final cleanMsgSender = m.senderHandle!.replaceAll('@', '').trim().toLowerCase();
        return m.copyWith(isMe: cleanMsgSender == cleanMy);
      }
      if (cleanThreadU == cleanMy || cleanRecipient == cleanMy) {
        // Viewing as the recipient, incoming message was from peer
        return m.copyWith(isMe: false);
      }
      return m;
    }).toList();

    return thread.copyWith(
      username: formattedHandle,
      avatarUrl: resolvedAvatar,
      messages: mappedMessages,
    );
  }

  DirectMessageThread? getThread(String id) {
    try {
      final cleanId = id.trim().toLowerCase();
      final found = _threads.firstWhere((t) => t.id.trim().toLowerCase() == cleanId);
      return resolveThreadForActiveUser(found);
    } catch (_) {
      return null;
    }
  }

  DirectMessageThread? getThreadByUsername(String username) {
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    try {
      final found = _threads.firstWhere(
        (t) => t.username.replaceAll('@', '').trim().toLowerCase() == clean,
      );
      return resolveThreadForActiveUser(found);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new thread or moves the existing thread to the top (index 0).
  /// If it exists, merges messages and updates lastMessage/timeAgo.
  DirectMessageThread addOrUpdateThread(DirectMessageThread rawThread) {
    final inMemoryId = ProfileSyncService.instance.cachedMyProfile?.id;
    if (inMemoryId != null) {
      _activeUserId = inMemoryId;
    } else if (_activeUserId == null) {
      final tokenUserId = TokenStorage.instance.getUserModel()?.id;
      if (tokenUserId != null) {
        _activeUserId = tokenUserId;
      }
    }
    final thread = resolveThreadForActiveUser(rawThread);
    final cleanUsername = thread.username.replaceAll('@', '').trim().toLowerCase();
    final cleanPeer = resolvePeerHandle(thread).replaceAll('@', '').trim().toLowerCase();
    final existingIndex = _threads.indexWhere((t) {
      if (t.id.trim().toLowerCase() == thread.id.trim().toLowerCase()) return true;
      final tPeer = resolvePeerHandle(t).replaceAll('@', '').trim().toLowerCase();
      final tUser = t.username.replaceAll('@', '').trim().toLowerCase();
      return (cleanPeer.isNotEmpty && (tPeer == cleanPeer || tUser == cleanPeer)) ||
          (cleanUsername.isNotEmpty && (tPeer == cleanUsername || tUser == cleanUsername));
    });

    DirectMessageThread resolvedThread;
    var shouldSyncLastMessage = false;

    if (existingIndex != -1) {
      final existing = _threads[existingIndex];
      // Merge messages preventing duplicates by id
      final existingIds = existing.messages.map((m) => m.id).toSet();
      final newMessages = [
        ...existing.messages,
        ...thread.messages.where((m) => !existingIds.contains(m.id)),
      ];
      shouldSyncLastMessage = newMessages.length > existing.messages.length;

      resolvedThread = existing.copyWith(
        id: thread.id,
        username: thread.username,
        avatarUrl: thread.avatarUrl.isNotEmpty ? thread.avatarUrl : existing.avatarUrl,
        lastMessage: thread.lastMessage.isNotEmpty ? thread.lastMessage : existing.lastMessage,
        timeAgo: thread.timeAgo.isNotEmpty ? thread.timeAgo : 'Just now',
        isVerified: thread.isVerified || existing.isVerified,
        followersCount: thread.followersCount.isNotEmpty ? thread.followersCount : existing.followersCount,
        senderHandle: thread.senderHandle ?? existing.senderHandle,
        senderAvatar: thread.senderAvatar ?? existing.senderAvatar,
        recipientHandle: thread.recipientHandle ?? existing.recipientHandle,
        recipientAvatar: thread.recipientAvatar ?? existing.recipientAvatar,
        messages: newMessages,
      );

      _threads.removeAt(existingIndex);
    } else {
      resolvedThread = thread;
      shouldSyncLastMessage = resolvedThread.messages.isNotEmpty;
    }

    _threads.insert(0, resolvedThread);
    _deduplicateAndSortThreads();
    threadsNotifier.value = _threads.map(resolveThreadForActiveUser).toList();
    _persistInBackground();

    // Also sync the message to backend PostgreSQL database if authenticated
    if (shouldSyncLastMessage && resolvedThread.messages.isNotEmpty) {
      final lastMsg = resolvedThread.messages.last;
      _syncMessageToBackend(
        resolvedThread.id,
        _transportHandle(resolvePeerHandle(resolvedThread)),
        lastMsg.text,
        imageUrl: lastMsg.imageUrl,
        imageUrls: lastMsg.imageUrls,
        productTitle: lastMsg.orderProductTitle,
        orderReference: lastMsg.orderReference,
      );
    }

    return resolvedThread;
  }

  /// Appends an individual message to an existing or new thread and brings it to the top.
  Future<void> addMessageToThread(String threadId, ChatMessage message) async {
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      final thread = _threads[index];
      final updatedMessages = List<ChatMessage>.from(thread.messages)..add(message);
      final updatedThread = thread.copyWith(
        messages: updatedMessages,
        lastMessage: message.text,
        timeAgo: 'Just now',
      );
      _threads.removeAt(index);
      _threads.insert(0, updatedThread);
      threadsNotifier.value = _threads.map(resolveThreadForActiveUser).toList();
      await _persist();

      // Sync to backend using the actual peer participant handle
      await _syncMessageToBackend(
        threadId,
        _transportHandle(resolvePeerHandle(thread)),
        message.text,
        imageUrl: message.imageUrl,
        imageUrls: message.imageUrls,
        productTitle: message.orderProductTitle,
        orderReference: message.orderReference,
      );
    }
  }

  /// Updates an individual message within an existing thread (e.g. status change or cancellation).
  Future<void> updateMessageInThread(String threadId, ChatMessage updatedMessage) async {
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      final thread = _threads[index];
      final msgIndex = thread.messages.indexWhere((m) => m.id == updatedMessage.id);
      if (msgIndex != -1) {
        final wasCancelled = thread.messages[msgIndex].isCancelled;
        final updatedMessages = List<ChatMessage>.from(thread.messages);
        updatedMessages[msgIndex] = updatedMessage;
        final updatedThread = thread.copyWith(
          messages: updatedMessages,
        );
        _threads[index] = updatedThread;
        threadsNotifier.value = _threads.map(resolveThreadForActiveUser).toList();
        await _persist();
        if (!wasCancelled && updatedMessage.isCancelled) {
          await _syncCancellationToBackend(thread, updatedMessage);
        }
      }
    }
  }

  Future<void> _syncCancellationToBackend(
    DirectMessageThread thread,
    ChatMessage message,
  ) async {
    final peer = _transportHandle(resolvePeerHandle(thread));
    if (peer.isEmpty) return;
    final cancellationText =
        'Order cancelled by ${message.cancelledBy ?? 'participant'}'
        '${message.cancellationTime == null ? '' : ' at ${message.cancellationTime}'}.';
    await _syncMessageToBackend(
      thread.id,
      peer,
      cancellationText,
      productTitle: message.orderProductTitle,
      orderReference: message.orderReference,
    );
  }

  /// Updates an order message across threads when cancelled from outside the chat (e.g. from Order History).
  Future<void> cancelOrderInChats({
    required String productTitle,
    String? orderId,
    String? orderNumber,
  }) async {
    final nowUtc = DateTime.now().toUtc();
    final phnomPenh = nowUtc.add(const Duration(hours: 7));
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = phnomPenh.hour % 12 == 0 ? 12 : phnomPenh.hour % 12;
    final period = phnomPenh.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = phnomPenh.minute.toString().padLeft(2, '0');
    final formattedTime = '${months[phnomPenh.month - 1]} ${phnomPenh.day}, ${phnomPenh.year} at ${hour12.toString().padLeft(2, '0')}:$minuteStr $period (Phnom Penh)';

    final myHandle = ProfileSyncService.instance.currentUsername;
    final cancelledDisplay = 'Buyer ($myHandle)';
    final cleanTitle = productTitle.trim().toLowerCase();
    final cleanOrderNumber = (orderNumber ?? '').trim();
    bool hasChanged = false;

    for (int i = 0; i < _threads.length; i++) {
      final thread = _threads[i];
      bool threadChanged = false;
      ChatMessage? newlyCancelledMessage;
      final updatedMessages = thread.messages.map((m) {
        if (m.isOrder && (m.orderStatus == null || m.orderStatus == 'Active')) {
          final mTitle = (m.orderProductTitle ?? '').trim().toLowerCase();
          final matchesTitle = (cleanTitle.isNotEmpty && mTitle == cleanTitle) ||
              (cleanTitle.isNotEmpty && m.text.toLowerCase().contains(cleanTitle));
          final matchesItem = m.orderItems?.any((it) => (it['title']?.toString() ?? '').toLowerCase() == cleanTitle) ?? false;
          final matchesId = (orderId != null && m.orderProductId == orderId);
          final matchesOrderNumber = cleanOrderNumber.isNotEmpty && m.orderReference?.trim() == cleanOrderNumber;

          // Current orders have a unique reference. Use it exclusively so
          // cancelling one order cannot cancel another order for the same title.
          // Title/id matching remains only for legacy messages created before
          // order references were added.
          final matchesOrder = cleanOrderNumber.isNotEmpty
              ? matchesOrderNumber
              : (matchesTitle || matchesItem || matchesId);

          if (matchesOrder) {
            threadChanged = true;
            newlyCancelledMessage = m.copyWith(
              orderStatus: 'Cancelled',
              cancelledBy: cancelledDisplay,
              cancellationTime: formattedTime,
              orderReference: orderNumber ?? m.orderReference,
            );
            return newlyCancelledMessage!;
          }
        }
        return m;
      }).toList();

      if (threadChanged) {
        hasChanged = true;
        final updatedThread = thread.copyWith(messages: updatedMessages);
        _threads[i] = updatedThread;
        if (newlyCancelledMessage != null) {
          await _syncCancellationToBackend(updatedThread, newlyCancelledMessage!);
        }
      }
    }

    if (hasChanged) {
      _deduplicateAndSortThreads();
      threadsNotifier.value = _threads.map(resolveThreadForActiveUser).toList();
      await _persist();
    }
  }

  /// Symmetrically identifies the peer participant handle from the active user's perspective.
  static String resolvePeerHandle(DirectMessageThread thread) {
    final activeProfile = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
    final rawUsername = activeProfile?.username ?? ProfileSyncService.instance.currentUsername;
    final cleanMy = rawUsername.replaceAll('@', '').trim().toLowerCase();

    final cleanThreadU = thread.username.replaceAll('@', '').trim().toLowerCase();
    final cleanSender = thread.senderHandle?.replaceAll('@', '').trim().toLowerCase() ?? '';
    final cleanRecipient = thread.recipientHandle?.replaceAll('@', '').trim().toLowerCase() ?? '';

    if (cleanMy.isNotEmpty) {
      if (cleanRecipient == cleanMy || cleanThreadU == cleanMy) {
        if (cleanSender.isNotEmpty && cleanSender != cleanMy) {
          return thread.senderHandle!;
        }
      } else if (cleanSender == cleanMy) {
        if (cleanRecipient.isNotEmpty && cleanRecipient != cleanMy) {
          return thread.recipientHandle!;
        }
      }
    }
    return thread.recipientHandle ?? thread.username;
  }

  String _transportHandle(String handle) {
    final canonical = canonicalHandle(handle);
    return canonical.isNotEmpty ? canonical : handle.replaceAll('@', '').trim();
  }

  static String canonicalHandle(String? handle) {
    final clean = (handle ?? '').replaceAll('@', '').trim();
    if (clean.isEmpty) return '';
    try {
      final cached = ProfileRemoteDataSource.instance.getCachedUser(clean);
      if (cached != null && cached.username.trim().isNotEmpty) {
        return cached.username.replaceAll('@', '').trim();
      }
    } catch (_) {}
    return clean;
  }

  Future<void> _syncMessageToBackend(
    String threadId,
    String recipientHandle,
    String messageText, {
    String? imageUrl,
    List<String>? imageUrls,
    String? productTitle,
    String? orderReference,
  }) async {
    try {
      if (!await TokenStorage.instance.hasValidToken()) return;
      final String? combinedImages = (imageUrls != null && imageUrls.isNotEmpty)
          ? imageUrls.join(',')
          : imageUrl;
      await ApiClient.instance.post(
        '/chats/messages',
        body: {
          'threadId': threadId,
          'recipientHandle': recipientHandle,
          'messageText': messageText,
          if (productTitle != null && productTitle.trim().isNotEmpty)
            'productTitle': productTitle,
          if (orderReference != null && orderReference.trim().isNotEmpty)
            'orderReference': orderReference,
          if (combinedImages != null && combinedImages.isNotEmpty) 'imageUrl': combinedImages,
        },
        requireAuth: true,
      );
    } catch (error) {
      debugPrint('[InboxMessageManager] Remote chat sync deferred (offline): $error');
    }
  }

  static final Map<String, String> knownPlatformUsers = {
    'mongkol': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
    'bunheng': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
    'rithysak': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
    'setkimliza': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
    'trenmono': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80',
    'tryphien': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=80',
    'nenseanghai': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500&auto=format&fit=crop&q=80',
    'admin': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80',
    'craftsman_bob': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500',
    'serey': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500',
    'techhorizon global': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
    'techgear official': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
    'god gear official': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
    'master tech': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
  };

  static final Set<String> _pendingUserPrefetches = {};

  static void _prefetchUserAvatar(String cleanHandle) {
    if (cleanHandle.isEmpty || _pendingUserPrefetches.contains(cleanHandle)) return;
    _pendingUserPrefetches.add(cleanHandle);
    ProfileRemoteDataSource.instance.getUser(cleanHandle).then((user) {
      if (user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty) {
        InboxMessageManager.instance._hydratePeerAvatars().catchError((_) {});
      }
    }).catchError((_) {}).whenComplete(() {
      _pendingUserPrefetches.remove(cleanHandle);
    });
  }

  /// Resolves a genuine creator or user avatar URL rather than a product thumbnail or fallback.
  static String resolveUserAvatar(String handle, {String? candidateAvatar}) {
    final clean = handle.replaceAll('@', '').trim().toLowerCase();

    try {
      final cached = ProfileRemoteDataSource.instance.getCachedUser(clean);
      if (cached != null && cached.avatarUrl != null && cached.avatarUrl!.trim().isNotEmpty) {
        return cached.avatarUrl!.trim();
      }
    } catch (_) {}

    if (candidateAvatar != null &&
        candidateAvatar.trim().isNotEmpty &&
        (candidateAvatar.startsWith('http://') ||
            candidateAvatar.startsWith('https://') ||
            candidateAvatar.startsWith('assets/')) &&
        !candidateAvatar.contains('dicebear.com') &&
        !candidateAvatar.contains('iphone_17') &&
        !candidateAvatar.contains('case.jpg') &&
        !candidateAvatar.contains('deal.jpg') &&
        !candidateAvatar.contains('watch') &&
        !candidateAvatar.contains('hoodie') &&
        !candidateAvatar.contains('shoes') &&
        !candidateAvatar.contains('serum') &&
        !candidateAvatar.contains('cooker') &&
        !candidateAvatar.contains('tote')) {
      return candidateAvatar.trim();
    }
    if (clean.isEmpty) {
      return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
    }

    final activeProfile = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
    final cleanMy = (activeProfile?.username ?? ProfileSyncService.instance.currentUsername)
        .replaceAll('@', '')
        .trim()
        .toLowerCase();
    if (clean == cleanMy) {
      final myAvatar = activeProfile?.avatarUrl ?? ProfileSyncService.instance.currentUserAvatar;
      if (myAvatar.isNotEmpty) return myAvatar;
    }

    if (knownPlatformUsers.containsKey(clean)) {
      return knownPlatformUsers[clean]!;
    }

    // Trigger prefetch in the background so genuine database avatar loads
    _prefetchUserAvatar(clean);

    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
  }

  /// Resolves a genuine creator avatar URL rather than a product thumbnail (backward-compatible alias).
  static String resolveSellerAvatar({String? candidateAvatar, required String sellerHandle}) {
    return resolveUserAvatar(sellerHandle, candidateAvatar: candidateAvatar);
  }

  Future<void> _syncFromRemoteDatabase({bool retryDeferredCancellations = true}) async {
    try {
      if (!await TokenStorage.instance.hasValidToken()) return;

      final dynamic response = await ApiClient.instance.get('/chats/conversations', requireAuth: true);
      final List<dynamic> list;
      if (response is List) {
        list = response;
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        list = response['data'] as List<dynamic>;
      } else {
        return;
      }
      if (list.isEmpty) return;
      bool hasChanges = false;
      final deferredCancellationItems = <Map<String, dynamic>>[];

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final threadId = item['threadId'] as String? ?? '';
        final recipient = item['recipientHandle'] as String? ?? '';
        final msgText = item['messageText'] as String? ?? '';
        final msgId = 'remote_${item['id']}';
        if (threadId.isEmpty || msgText.isEmpty) continue;

        final isCancellationText = msgText.toLowerCase().startsWith('order cancelled by ');
        if (isCancellationText && retryDeferredCancellations) {
          // Process the original order rows first. This handles a cancellation
          // saved immediately after an order whose rows are returned out of
          // order by the database or whose first sync raced the order save.
          deferredCancellationItems.add(item);
          continue;
        }

        final isMe = item['isMe'] as bool? ?? true;
        final rawPeer = (item['peerUsername'] as String? ??
                (isMe ? recipient : (item['senderHandle'] as String? ?? '')))
            .trim();
        final peerHandleRaw = rawPeer.isNotEmpty
            ? rawPeer
            : recipient;
        final canonicalPeer = canonicalHandle(peerHandleRaw);
        final peerHandle = canonicalPeer.isNotEmpty
            ? (canonicalPeer.startsWith('@') ? canonicalPeer : '@$canonicalPeer')
            : (peerHandleRaw.startsWith('@') ? peerHandleRaw : '@$peerHandleRaw');
        final peerAvatar = (item['peerAvatarUrl'] as String? ??
                (isMe
                    ? (item['recipientAvatar'] as String? ?? '')
                    : (item['senderAvatar'] as String? ?? '')))
            .trim();
        final resolvedAvatar = resolveUserAvatar(peerHandle, candidateAvatar: peerAvatar);
        final String? msgImageUrl = item['imageUrl'] as String?;
        final List<String> parsedImages = (msgImageUrl != null && msgImageUrl.trim().isNotEmpty)
            ? (msgImageUrl.contains(',')
                ? msgImageUrl.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
                : [msgImageUrl.trim()])
            : const [];
        final senderHandle = item['senderHandle'] as String?;
        final senderAvatar = item['senderAvatar'] as String?;
        final recipientAvatar = item['recipientAvatar'] as String?;

        final rawCreatedAt = item['orderCreatedAtMs'] ?? item['createdAt'];
        int? createdAtMs;
        if (rawCreatedAt != null) {
          if (rawCreatedAt is int) {
            createdAtMs = rawCreatedAt;
          } else if (rawCreatedAt is num) {
            createdAtMs = rawCreatedAt.toInt();
          } else {
            final parsed = DateTime.tryParse(rawCreatedAt.toString());
            if (parsed != null) {
              createdAtMs = parsed.millisecondsSinceEpoch;
            } else {
              createdAtMs = int.tryParse(rawCreatedAt.toString());
            }
          }
        }

        final bool isOrderInquiry = (item['isOrder'] as bool?) == true ||
            msgText.contains('I would like to order') ||
            msgText.contains('Order Inquiry') ||
            msgText.contains('order inquiry');
        final bool isCancellation = msgText.toLowerCase().startsWith('order cancelled by ');
        final String? cancellationOrderReference = item['orderReference'] as String?;
        final String remoteOrderReference = (cancellationOrderReference ?? '').trim();

        final String? orderStatus = (item['orderStatus'] as String?) ??
            (isOrderInquiry ? 'Active' : null);

        final String? orderProductId = item['orderProductId'] as String?;
        final String? orderProductTitle = (item['orderProductTitle'] as String?) ?? (item['productTitle'] as String?);
        final int? orderQuantity = item['orderQuantity'] as int?;

        final remoteMessage = ChatMessage(
          id: msgId,
          text: msgText,
          isMe: isMe,
          senderHandle: senderHandle,
          timestamp: 'Recently',
          status: 'Sent',
          imageUrl: parsedImages.isNotEmpty ? parsedImages.first : null,
          imageUrls: parsedImages.isNotEmpty ? parsedImages : null,
          isOrder: isOrderInquiry,
          orderCreatedAtMs: createdAtMs,
          orderStatus: orderStatus,
          orderProductId: orderProductId,
          orderProductTitle: orderProductTitle,
          orderReference: item['orderReference'] as String?,
          orderQuantity: orderQuantity,
        );

        // Find the actual stored thread object. getThread() returns a resolved
        // copy, so using its identity caused new remote messages to be dropped.
        var index = _threads.indexWhere((thread) => thread.id.trim().toLowerCase() == threadId.trim().toLowerCase());
        if (index == -1) {
          final cleanPeer = peerHandle.replaceAll('@', '').trim().toLowerCase();
          index = _threads.indexWhere((thread) {
            final participants = [
              thread.username,
              thread.senderHandle ?? '',
              thread.recipientHandle ?? '',
            ].map((value) => value.replaceAll('@', '').trim().toLowerCase());
            return participants.contains(cleanPeer);
          });
        }

        // A product can carry a store/display alias while the backend resolves
        // it to the real account username. If the exact message already exists
        // locally, merge into that thread instead of creating a second chat.
        if (index == -1) {
          index = _threads.indexWhere((thread) => thread.messages.any(
                (message) =>
                    message.text.trim() == msgText.trim() &&
                    message.isMe == isMe,
              ));
        }

        // Cancellation events must follow the exact order reference even when
        // the backend returns a canonical thread id different from the local
        // store alias thread id.
        if (isCancellation && remoteOrderReference.isNotEmpty) {
          final referencedThreadIndex = _threads.indexWhere((thread) =>
              thread.messages.any((message) =>
                  message.isOrder &&
                  message.orderReference?.trim() == remoteOrderReference));
          if (referencedThreadIndex != -1) {
            index = referencedThreadIndex;
          }
        }

        if (index == -1) {
          // An unmatched cancellation is stale or belongs to an order that
          // has not been created in this account. Never create a new order
          // bubble from it; doing so made one participant appear cancelled
          // while the other still showed the active order.
          if (isCancellation) continue;
          _threads.insert(
            0,
            DirectMessageThread(
              id: threadId,
              username: peerHandle,
              avatarUrl: resolvedAvatar,
              senderHandle: senderHandle,
              senderAvatar: senderAvatar,
              recipientHandle: recipient,
              recipientAvatar: recipientAvatar,
              lastMessage: msgText,
              timeAgo: 'Recently',
              isVerified: true,
              messages: [remoteMessage],
            ),
          );
          hasChanges = true;
          continue;
        }

        final existing = _threads[index];

        // Cancellation rows are status events for the original order message,
        // not a second ordinary chat bubble. Apply the event to that order so
        // buyer and seller render the same cancelled card.
        if (isCancellation) {
          final reference = (cancellationOrderReference ?? '').trim();
          var orderIndex = existing.messages.indexWhere((message) {
            if (!message.isOrder || message.isCancelled) return false;
            return reference.isNotEmpty && message.orderReference?.trim() == reference;
          });

          if (orderIndex == -1 && reference.isEmpty && orderProductTitle != null) {
            // Legacy cancellation rows were written before orderReference was
            // added. Match them deterministically by product and event time so
            // both participants resolve the same historical conversation.
            final legacyTitle = orderProductTitle.trim().toLowerCase();
            var bestIndex = -1;
            var bestCreatedAt = -1;
            for (var i = 0; i < existing.messages.length; i++) {
              final message = existing.messages[i];
              if (!message.isOrderMessage || message.isCancelled || message.orderReference != null) {
                continue;
              }
              final messageTitle = (message.orderProductTitle ?? '').trim().toLowerCase();
              final hasMatchingItem = message.orderItems?.any(
                    (item) => (item['title']?.toString() ?? '').trim().toLowerCase() == legacyTitle,
                  ) ??
                  false;
              if (messageTitle != legacyTitle && !hasMatchingItem) continue;

              final createdAt = message.orderCreatedAtMs ?? 0;
              if (createdAtMs != null && createdAt > createdAtMs) continue;
              if (createdAt >= bestCreatedAt) {
                bestCreatedAt = createdAt;
                bestIndex = i;
              }
            }
            orderIndex = bestIndex;
          }

          if (orderIndex != -1) {
            final match = RegExp(r'^Order cancelled by (.+?)(?: at (.+))?\.$')
                .firstMatch(msgText);
            final updatedMessages = List<ChatMessage>.from(existing.messages);
            updatedMessages[orderIndex] = updatedMessages[orderIndex].copyWith(
              id: updatedMessages[orderIndex].id,
              orderStatus: 'Cancelled',
              cancelledBy: match?.group(1),
              cancellationTime: match?.group(2),
              orderReference: updatedMessages[orderIndex].orderReference ??
                  (reference.isNotEmpty ? reference : null),
            );
            _threads[index] = existing.copyWith(
              id: threadId,
              username: peerHandle,
              avatarUrl: resolvedAvatar.isNotEmpty ? resolvedAvatar : existing.avatarUrl,
              messages: updatedMessages,
            );
            hasChanges = true;
          }
          // Do not append an unmatched cancellation as a normal chat bubble;
          // that would make one account look cancelled while the other looks
          // active. A later sync can apply it once the order is present.
          continue;
        }
        final localIndex = existing.messages.indexWhere((m) {
          if (remoteOrderReference.isNotEmpty) {
            return m.orderReference?.trim() == remoteOrderReference;
          }
          if (m.id == msgId) return true;
          final textMatches = m.text.trim() == msgText.trim();
          final sameDirection = m.isMe == isMe;
          if (textMatches && sameDirection) {
            if (createdAtMs != null && m.orderCreatedAtMs != null) {
              return (m.orderCreatedAtMs! - createdAtMs).abs() < 120000;
            }
            return true;
          }
          return false;
        });

        final bool hasMessage = localIndex != -1;
        List<ChatMessage> resolvedMessages = existing.messages;
        if (localIndex != -1) {
          final localMsg = existing.messages[localIndex];
          final updatedMsg = localMsg.copyWith(
            id: msgId,
            orderCreatedAtMs: localMsg.orderCreatedAtMs ?? createdAtMs,
            isOrder: localMsg.isOrder || isOrderInquiry,
            orderStatus: localMsg.orderStatus ?? orderStatus,
            orderReference: localMsg.orderReference ?? (remoteOrderReference.isNotEmpty ? remoteOrderReference : null),
          );
          resolvedMessages = List<ChatMessage>.from(existing.messages)..[localIndex] = updatedMsg;
        } else {
          resolvedMessages = [...existing.messages, remoteMessage];
        }

        final updated = existing.copyWith(
          id: threadId,
          username: peerHandle,
          avatarUrl: resolvedAvatar.isNotEmpty ? resolvedAvatar : existing.avatarUrl,
          senderHandle: senderHandle ?? existing.senderHandle,
          senderAvatar: senderAvatar ?? existing.senderAvatar,
          recipientHandle: recipient.isNotEmpty ? recipient : existing.recipientHandle,
          recipientAvatar: recipientAvatar ?? existing.recipientAvatar,
          messages: resolvedMessages,
          lastMessage: hasMessage ? existing.lastMessage : msgText,
          timeAgo: hasMessage ? existing.timeAgo : 'Recently',
        );

        final profileChanged = updated.username != existing.username ||
            updated.avatarUrl != existing.avatarUrl ||
            updated.senderAvatar != existing.senderAvatar ||
            updated.recipientAvatar != existing.recipientAvatar;
        if (!hasMessage || profileChanged || resolvedMessages != existing.messages) {
          _threads.removeAt(index);
          _threads.insert(0, updated);
          hasChanges = true;
        }
      }

      final validRemoteIds = list.map((item) => 'remote_${item['id']}').toSet();
      for (var i = 0; i < _threads.length; i++) {
        final thread = _threads[i];
        final filteredMessages = thread.messages
            .where((m) => !m.id.startsWith('remote_') || validRemoteIds.contains(m.id))
            .toList();
        if (filteredMessages.length != thread.messages.length) {
          _threads[i] = thread.copyWith(
            messages: filteredMessages,
            lastMessage: filteredMessages.isNotEmpty ? filteredMessages.last.text : thread.lastMessage,
          );
          hasChanges = true;
        }
      }
      _threads.removeWhere((t) => t.messages.isEmpty);
      _deduplicateAndSortThreads();

      if (hasChanges) {
        threadsNotifier.value = _threads.map(resolveThreadForActiveUser).toList();
        _persistInBackground();
      }

      if (deferredCancellationItems.isNotEmpty && retryDeferredCancellations) {
        // Re-read after normal messages have been merged. The second pass is
        // bounded by retryDeferredCancellations=false and cannot recurse.
        await _syncFromRemoteDatabase(retryDeferredCancellations: false);
      }
      await _hydratePeerAvatars();
    } catch (error) {
      debugPrint('[InboxMessageManager] Remote conversation sync deferred: $error');
    }
  }

  Future<void> _hydratePeerAvatars() async {
    bool changed = false;
    for (var i = 0; i < _threads.length; i++) {
      final thread = _threads[i];
      final handle = canonicalHandle(thread.username);
      if (handle.isEmpty) continue;
      try {
        var user = ProfileRemoteDataSource.instance.getCachedUser(handle);
        user ??= await ProfileRemoteDataSource.instance.getUser(handle);
        final avatar = user.avatarUrl?.trim() ?? '';
        final username = user.username.trim().isNotEmpty
            ? '@${user.username.replaceAll('@', '').trim()}'
            : thread.username;
        if (avatar.isEmpty) continue;
        if (thread.avatarUrl != avatar || thread.username != username) {
          _threads[i] = thread.copyWith(username: username, avatarUrl: avatar);
          changed = true;
        }
      } catch (_) {}
    }
    if (changed) {
      threadsNotifier.value = _threads.map(resolveThreadForActiveUser).toList();
      _persistInBackground();
    }
  }

  /// Resets threads to an empty list (no static chat/messages).
  void resetToDefault() {
    _threads.clear();
    threadsNotifier.value = [];
    _drafts.clear();
    _persistInBackground();
  }
}
