import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../domain/entities/inbox_item.dart';
import 'static_inbox_data.dart';

/// Centralized in-memory manager for direct message threads and active conversations.
///
/// Ensures real-time state synchronization between Cart inquiries, ChatDetailScreen,
/// and the InboxScreen MESSAGES list, with dual persistence:
/// 1. Local per-account SharedPreferences (works on Web, Windows, Android, iOS).
/// 2. Remote PostgreSQL database (/api/v1/chats) when authenticated.
class InboxMessageManager {
  InboxMessageManager._internal() {
    _threads = List<DirectMessageThread>.from(StaticInboxData.threads);
    threadsNotifier = ValueNotifier<List<DirectMessageThread>>(_threads);
  }

  static final InboxMessageManager instance = InboxMessageManager._internal();

  late final List<DirectMessageThread> _threads;
  late final ValueNotifier<List<DirectMessageThread>> threadsNotifier;
  final Map<String, String> _drafts = {};
  int? _activeUserId;
  Future<void> _writeQueue = Future<void>.value();
  Future<void>? _loadFuture;

  List<DirectMessageThread> get threads => List.unmodifiable(_threads);

  Future<void> loadForCurrentUser() async {
    final userId = await TokenStorage.instance.getUserId();
    if (userId == null) {
      _activeUserId = null;
      _loadFuture = null;
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_guestStorageKey);
      if (saved != null) {
        try {
          final decoded = jsonDecode(saved) as Map<String, dynamic>;
          final savedThreads = (decoded['threads'] as List<dynamic>? ?? const [])
              .map((thread) => DirectMessageThread.fromJson(thread as Map<String, dynamic>))
              .toList();
          final savedDrafts = decoded['drafts'] as Map<String, dynamic>? ?? const {};
          if (savedThreads.isNotEmpty) {
            _threads
              ..clear()
              ..addAll(savedThreads);
            _drafts
              ..clear()
              ..addAll(savedDrafts.map((k, v) => MapEntry(k, v as String)));
            threadsNotifier.value = List.unmodifiable(_threads);
            return;
          }
        } catch (_) {}
      }
      if (_threads.isEmpty) {
        _threads.addAll(StaticInboxData.threads);
      }
      threadsNotifier.value = List.unmodifiable(_threads);
      return;
    }
    await loadForUser(userId);
  }

  @visibleForTesting
  Future<void> loadForUser(int userId) async {
    _activeUserId = userId;
    _threads.clear();
    threadsNotifier.value = const [];
    _drafts.clear();
    _loadFuture = _loadUserData(userId);
    await _loadFuture;
    _syncFromRemoteDatabase();
  }

  @visibleForTesting
  Future<void> reloadForUser(int userId) {
    _activeUserId = null;
    _loadFuture = null;
    return loadForUser(userId);
  }

  Future<void> _loadUserData(int userId) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_storageKey(userId));
    _drafts.clear();
    if (saved == null) {
      // First time user logs in: check if there are guest threads that were created
      final guestSaved = preferences.getString(_guestStorageKey);
      if (guestSaved != null) {
        try {
          final decoded = jsonDecode(guestSaved) as Map<String, dynamic>;
          final guestThreads = (decoded['threads'] as List<dynamic>? ?? const [])
              .map((thread) => DirectMessageThread.fromJson(thread as Map<String, dynamic>))
              .toList();
          if (guestThreads.isNotEmpty) {
            _threads
              ..clear()
              ..addAll(guestThreads);
            threadsNotifier.value = List.unmodifiable(_threads);
            await _persist();
            return;
          }
        } catch (_) {}
      }
      _threads
        ..clear()
        ..addAll(StaticInboxData.threads);
    } else {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      final savedThreads = (decoded['threads'] as List<dynamic>? ?? const [])
          .map((thread) => DirectMessageThread.fromJson(thread as Map<String, dynamic>))
          .toList();
      final savedDrafts = decoded['drafts'] as Map<String, dynamic>? ?? const {};
      _threads
        ..clear()
        ..addAll(savedThreads);
      _drafts.addAll(savedDrafts.map((key, value) => MapEntry(key, value as String)));
    }
    threadsNotifier.value = List.unmodifiable(_threads);
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

  static const String _guestStorageKey = 'inbox_guest_messages';

  Future<void> _persist() {
    final key = _activeUserId != null ? _storageKey(_activeUserId!) : _guestStorageKey;
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

  String _storageKey(int userId) => 'inbox_user_$userId';

  DirectMessageThread? getThread(String id) {
    try {
      return _threads.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  DirectMessageThread? getThreadByUsername(String username) {
    final clean = username.replaceAll('@', '').trim().toLowerCase();
    try {
      return _threads.firstWhere(
        (t) => t.username.replaceAll('@', '').trim().toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// Adds a new thread or moves the existing thread to the top (index 0).
  /// If it exists, merges messages and updates lastMessage/timeAgo.
  DirectMessageThread addOrUpdateThread(DirectMessageThread thread) {
    final cleanUsername = thread.username.replaceAll('@', '').trim().toLowerCase();
    final existingIndex = _threads.indexWhere(
      (t) => t.id == thread.id || t.username.replaceAll('@', '').trim().toLowerCase() == cleanUsername,
    );

    DirectMessageThread resolvedThread;

    if (existingIndex != -1) {
      final existing = _threads[existingIndex];
      // Merge messages preventing duplicates by id
      final existingIds = existing.messages.map((m) => m.id).toSet();
      final newMessages = [
        ...existing.messages,
        ...thread.messages.where((m) => !existingIds.contains(m.id)),
      ];

      resolvedThread = existing.copyWith(
        username: thread.username,
        avatarUrl: thread.avatarUrl.isNotEmpty ? thread.avatarUrl : existing.avatarUrl,
        lastMessage: thread.lastMessage.isNotEmpty ? thread.lastMessage : existing.lastMessage,
        timeAgo: thread.timeAgo.isNotEmpty ? thread.timeAgo : 'Just now',
        isVerified: thread.isVerified || existing.isVerified,
        followersCount: thread.followersCount.isNotEmpty ? thread.followersCount : existing.followersCount,
        messages: newMessages,
      );

      _threads.removeAt(existingIndex);
    } else {
      resolvedThread = thread;
    }

    _threads.insert(0, resolvedThread);
    threadsNotifier.value = List.unmodifiable(_threads);
    _persistInBackground();

    // Also sync the message to backend PostgreSQL database if authenticated
    if (resolvedThread.messages.isNotEmpty) {
      final lastMsg = resolvedThread.messages.last;
      _syncMessageToBackend(resolvedThread.id, resolvedThread.username, lastMsg.text);
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
      threadsNotifier.value = List.unmodifiable(_threads);
      await _persist();

      // Sync to backend
      _syncMessageToBackend(threadId, thread.username, message.text);
    }
  }

  void _syncMessageToBackend(String threadId, String recipientHandle, String messageText) {
    TokenStorage.instance.hasValidToken().then((hasToken) {
      if (!hasToken) return;
      ApiClient.instance.post(
        '/chats/messages',
        body: {
          'threadId': threadId,
          'recipientHandle': recipientHandle,
          'messageText': messageText,
        },
        requireAuth: true,
      ).catchError((Object err) {
        debugPrint('[InboxMessageManager] Remote chat sync deferred (offline): $err');
      });
    });
  }

  void _syncFromRemoteDatabase() {
    TokenStorage.instance.hasValidToken().then((hasToken) {
      if (!hasToken) return;
      ApiClient.instance.get('/chats/conversations', requireAuth: true).then((response) {
        if (response is Map<String, dynamic> && response['data'] is List) {
          final list = response['data'] as List<dynamic>;
          if (list.isEmpty) return;
          bool hasChanges = false;
          for (final item in list) {
            if (item is! Map<String, dynamic>) continue;
            final threadId = item['threadId'] as String? ?? '';
            final recipient = item['recipientHandle'] as String? ?? '';
            final msgText = item['messageText'] as String? ?? '';
            final msgId = 'remote_${item['id']}';
            if (threadId.isEmpty || msgText.isEmpty) continue;

            final existing = getThread(threadId);
            if (existing == null) {
              final newThread = DirectMessageThread(
                id: threadId,
                username: recipient,
                avatarUrl: '',
                lastMessage: msgText,
                timeAgo: 'Recently',
                isVerified: true,
                followersCount: '',
                messages: [
                  ChatMessage(
                    id: msgId,
                    text: msgText,
                    isMe: item['isMe'] as bool? ?? true,
                    timestamp: 'Recently',
                    status: 'Sent',
                  ),
                ],
              );
              _threads.insert(0, newThread);
              hasChanges = true;
            } else {
              final hasMsg = existing.messages.any((m) => m.id == msgId || m.text == msgText);
              if (!hasMsg) {
                final updated = existing.copyWith(
                  messages: [
                    ...existing.messages,
                    ChatMessage(
                      id: msgId,
                      text: msgText,
                      isMe: item['isMe'] as bool? ?? true,
                      timestamp: 'Recently',
                      status: 'Sent',
                    ),
                  ],
                  lastMessage: msgText,
                );
                final idx = _threads.indexOf(existing);
                if (idx != -1) {
                  _threads[idx] = updated;
                  hasChanges = true;
                }
              }
            }
          }
          if (hasChanges) {
            threadsNotifier.value = List.unmodifiable(_threads);
            _persistInBackground();
          }
        }
      }).catchError((Object err) {
        debugPrint('[InboxMessageManager] Remote conversation sync deferred: $err');
      });
    });
  }

  /// Resets threads to initial StaticInboxData for testing.
  void resetToDefault() {
    _threads.clear();
    _threads.addAll(StaticInboxData.threads);
    threadsNotifier.value = List.unmodifiable(_threads);
    _drafts.clear();
    _persistInBackground();
  }
}
