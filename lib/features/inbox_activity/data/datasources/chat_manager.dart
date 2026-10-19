import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../domain/entities/inbox_item.dart';
import 'chat_remote_data_source.dart';
import 'chat_stomp_service.dart';
import 'static_inbox_data.dart';

/// Centralized ChatManager for Direct Messages.
///
/// Ensures real-time state synchronization, message persistence in the database
/// (via backend REST API and WebSocket STOMP) plus local file persistence.
/// NO auto-replies are generated so that all messages reflect real user chat.
class ChatManager {
  ChatManager._internal() {
    _loadFromLocalDisk();
  }
  static final ChatManager instance = ChatManager._internal();

  final ValueNotifier<List<DirectMessageThread>> _threadsNotifier =
      ValueNotifier<List<DirectMessageThread>>([]);

  ValueListenable<List<DirectMessageThread>> get threadsNotifier => _threadsNotifier;
  List<DirectMessageThread> get threads => _threadsNotifier.value;

  File? _getLocalFile() {
    final uid = TokenStorage.instance.currentUserIdSync ?? 1;
    return _getLocalFileForUser(uid);
  }

  File? _getLocalFileForUser(int uid) {
    try {
      if (Platform.isAndroid) {
        final dir = Directory('/data/user/0/com.example.viloapp/files');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        return File('${dir.path}/vilo_chat_threads_$uid.json');
      }
      final dir = Directory.systemTemp;
      return File('${dir.path}/vilo_chat_threads_$uid.json');
    } catch (_) {
      return null;
    }
  }

  void switchUser(int newUserId) {
    _loadFromLocalDisk();
  }

  void clear() {
    _threadsNotifier.value = [];
  }

  void _loadFromLocalDisk() {
    try {
      final file = _getLocalFile();
      if (file != null && file.existsSync()) {
        final jsonStr = file.readAsStringSync();
        final rawList = jsonDecode(jsonStr) as List<dynamic>;
        final loaded = rawList.map<DirectMessageThread>((item) {
          final msgs = (item['messages'] as List<dynamic>? ?? []).map<ChatMessage>((m) {
            return ChatMessage(
              id: m['id']?.toString() ?? '',
              text: m['text'] ?? '',
              isMe: m['isMe'] == true,
              timestamp: m['timestamp'] ?? 'Just now',
              status: m['status'],
            );
          }).toList();

          final idStr = item['id']?.toString() ?? '';
          final uid = item['userId'] is int ? item['userId'] as int : int.tryParse(idStr);

          DirectMessageThread? staticMatch;
          try {
            staticMatch = StaticInboxData.threads.firstWhere(
              (t) => t.id == idStr || (uid != null && t.userId == uid) || t.username == item['username'],
            );
          } catch (_) {}

          final bool isFollowing = item['isFollowing'] != null
              ? (item['isFollowing'] == true)
              : (staticMatch?.isFollowing ?? false);

          final bool followsYou = item['followsYou'] != null
              ? (item['followsYou'] == true)
              : (staticMatch?.followsYou ?? false);

          return DirectMessageThread(
            id: idStr,
            userId: uid ?? staticMatch?.userId,
            username: item['username'] ?? staticMatch?.username ?? 'User',
            avatarUrl: item['avatarUrl'] ?? staticMatch?.avatarUrl ?? '',
            lastMessage: item['lastMessage'] ?? staticMatch?.lastMessage ?? '',
            timeAgo: item['timeAgo'] ?? staticMatch?.timeAgo ?? '',
            isVerified: item['isVerified'] == true || (staticMatch?.isVerified == true),
            followersCount: item['followersCount'] ?? staticMatch?.followersCount ?? '',
            isFollowing: isFollowing,
            followsYou: followsYou,
            messages: msgs,
          );
        }).toList();

        if (loaded.isNotEmpty) {
          _threadsNotifier.value = loaded;
          return;
        }
      }
    } catch (e) {
      debugPrint('[ChatManager] Error loading local cache: $e');
    }

    final uid = TokenStorage.instance.currentUserIdSync;
    if (uid != null && uid > 1) {
      _threadsNotifier.value = [];
      return;
    }
    _threadsNotifier.value = List.from(StaticInboxData.threads);
  }

  void _persistToLocalDisk() {
    try {
      final file = _getLocalFile();
      if (file == null) return;
      final data = _threadsNotifier.value.map((t) {
        return {
          'id': t.id,
          'userId': t.userId,
          'username': t.username,
          'avatarUrl': t.avatarUrl,
          'lastMessage': t.lastMessage,
          'timeAgo': t.timeAgo,
          'isVerified': t.isVerified,
          'followersCount': t.followersCount,
          'isFollowing': t.isFollowing,
          'followsYou': t.followsYou,
          'messages': t.messages.map((m) => {
            'id': m.id,
            'text': m.text,
            'isMe': m.isMe,
            'timestamp': m.timestamp,
            'status': m.status,
          }).toList(),
        };
      }).toList();
      file.writeAsStringSync(jsonEncode(data));
    } catch (e) {
      debugPrint('[ChatManager] Error persisting local cache: $e');
    }
  }

  void cancelTimers() {
    // No timers used as auto-reply is disabled
  }

  void init(List<DirectMessageThread> remoteThreads) {
    if (remoteThreads.isNotEmpty) {
      final merged = <DirectMessageThread>[];
      final current = _threadsNotifier.value;

      for (final remote in remoteThreads) {
        final existing = current.firstWhere(
          (t) => t.id == remote.id || (remote.userId != null && t.userId == remote.userId),
          orElse: () => remote,
        );
        // Keep any local messages if available
        merged.add(
          DirectMessageThread(
            id: remote.id,
            userId: remote.userId ?? existing.userId,
            username: remote.username,
            avatarUrl: remote.avatarUrl,
            lastMessage: existing.lastMessage.isNotEmpty ? existing.lastMessage : remote.lastMessage,
            timeAgo: existing.timeAgo.isNotEmpty ? existing.timeAgo : remote.timeAgo,
            isVerified: remote.isVerified,
            followersCount: remote.followersCount,
            isFollowing: remote.isFollowing,
            followsYou: remote.followsYou,
            messages: existing.messages.isNotEmpty ? existing.messages : remote.messages,
          ),
        );
      }

      // Add any local threads not in remote
      for (final local in current) {
        if (!merged.any((t) => t.id == local.id || (local.userId != null && t.userId == local.userId))) {
          merged.add(local);
        }
      }

      _threadsNotifier.value = merged;
      _persistToLocalDisk();
    }
  }

  DirectMessageThread getOrCreateThread({
    required int userId,
    required String username,
    required String avatarUrl,
    bool isVerified = false,
    bool isFollowing = false,
    bool followsYou = false,
    String followersCount = '',
  }) {
    final list = List<DirectMessageThread>.from(_threadsNotifier.value);
    final idStr = userId.toString();
    int idx = list.indexWhere((t) => t.id == idStr);
    if (idx == -1) {
      idx = list.indexWhere((t) => t.username.toLowerCase() == username.toLowerCase());
    }
    if (idx == -1) {
      idx = list.indexWhere((t) => t.userId == userId);
    }

    if (idx != -1) {
      final existing = list[idx];
      final updated = existing.copyWith(
        isFollowing: isFollowing,
        followsYou: followsYou,
      );
      list[idx] = updated;
      _threadsNotifier.value = list;
      return updated;
    }

    final newThread = DirectMessageThread(
      id: idStr,
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      lastMessage: 'Started a new conversation',
      timeAgo: 'Just now',
      isVerified: isVerified,
      followersCount: followersCount,
      isFollowing: isFollowing,
      followsYou: followsYou,
      messages: const [],
    );

    list.insert(0, newThread);
    _threadsNotifier.value = list;
    _persistToLocalDisk();
    return newThread;
  }

  void updateFollowState(int userId, bool isFollowing) {
    final list = List<DirectMessageThread>.from(_threadsNotifier.value);
    bool changed = false;
    for (int i = 0; i < list.length; i++) {
      if (list[i].userId == userId || list[i].id == userId.toString()) {
        list[i] = list[i].copyWith(isFollowing: isFollowing);
        changed = true;
      }
    }
    if (changed) {
      _threadsNotifier.value = list;
      _persistToLocalDisk();
    }
  }

  DirectMessageThread getThread(String threadId) {
    return _threadsNotifier.value.cast<DirectMessageThread?>().firstWhere(
      (t) => t?.id == threadId || (t?.userId != null && t!.userId.toString() == threadId),
      orElse: () => null,
    ) ?? DirectMessageThread(
      id: threadId,
      username: 'User',
      avatarUrl: '',
      lastMessage: '',
      timeAgo: 'Just now',
      messages: const [],
    );
  }

  List<ChatMessage> getMessages(String threadId) {
    final thread = _threadsNotifier.value.cast<DirectMessageThread?>().firstWhere(
      (t) => t?.id == threadId || (t?.userId != null && t!.userId.toString() == threadId),
      orElse: () => null,
    );
    if (thread != null) {
      return List.from(thread.messages);
    }
    return const [];
  }

  void reset() {
    _threadsNotifier.value = List.from(StaticInboxData.threads);
    _persistToLocalDisk();
  }

  static bool immediateRepliesForTesting = false;

  int? _resolveUserId(String threadId, String username) {
    final thread = _threadsNotifier.value.cast<DirectMessageThread?>().firstWhere(
      (t) => t?.id == threadId || (t?.userId != null && t!.userId.toString() == threadId),
      orElse: () => null,
    );
    if (thread?.userId != null) return thread!.userId;

    int? id = int.tryParse(threadId);
    if (id != null) return id;

    final digits = threadId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      id = int.tryParse(digits);
      if (id != null) return id;
    }

    final lower = username.toLowerCase();
    if (lower == 'sak') return 23;
    if (lower == 'liza') return 22;
    if (lower == 's1' || lower.contains('s1')) return 99;
    if (lower.contains('fashion')) return 100;
    if (lower.contains('kimliza') || lower.contains('liza')) return 4;
    if (lower.contains('bunheng') || lower.contains('heng')) return 2;
    if (lower.contains('rithysak') || lower.contains('sak')) return 3;
    if (lower.contains('mono')) return 5;
    if (lower.contains('sophia')) return 7;
    if (lower.contains('alex')) return 8;
    if (lower.contains('linda')) return 9;
    if (lower.contains('davi')) return 10;
    if (lower.contains('sarah')) return 11;
    if (lower.contains('junta')) return 2;

    return null;
  }

  /// Sends a chat message.
  ///
  /// Saves message in database via REST API and STOMP WebSocket.
  /// NO auto-reply is generated.
  void sendMessage({
    required String threadId,
    required String text,
    // Kept optional for backwards-compatibility; never invoked
    Function(ChatMessage incomingReply)? onAutoReply,
  }) {
    if (text.trim().isEmpty) return;

    final trimmed = text.trim();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMsg = ChatMessage(
      id: tempId,
      text: trimmed,
      isMe: true,
      timestamp: 'Just now',
      status: 'Sent',
    );

    final currentList = List<DirectMessageThread>.from(_threadsNotifier.value);
    final index = currentList.indexWhere(
      (t) => t.id == threadId || (t.userId != null && t.userId.toString() == threadId),
    );

    String recipientName = 'User';
    if (index != -1) {
      final thread = currentList[index];
      recipientName = thread.username;
      final updatedMessages = List<ChatMessage>.from(thread.messages)..add(newMsg);

      final updatedThread = thread.copyWith(
        lastMessage: trimmed,
        timeAgo: 'Just now',
        messages: updatedMessages,
      );

      currentList.removeAt(index);
      currentList.insert(0, updatedThread);
      _threadsNotifier.value = currentList;
      _persistToLocalDisk();
    } else {
      final newThread = DirectMessageThread(
        id: threadId,
        userId: int.tryParse(threadId),
        username: recipientName,
        avatarUrl: '',
        lastMessage: trimmed,
        timeAgo: 'Just now',
        messages: [newMsg],
      );
      currentList.insert(0, newThread);
      _threadsNotifier.value = currentList;
      _persistToLocalDisk();
    }

    // Save message to database (REST + WebSocket STOMP)
    final userId = _resolveUserId(threadId, recipientName);
    if (userId != null) {
      debugPrint('[ChatManager] Saving message to database for recipientId=$userId: "$trimmed"');
      ChatStompService.instance.sendMessage(recipientId: userId, content: trimmed);
      ChatRemoteDataSource.instance.sendMessage(userId, trimmed).then((savedMsg) {
        debugPrint('[ChatManager] Message successfully persisted in DB with id=${savedMsg.id}');
        _updateMessageWithDbId(threadId, tempId, savedMsg.id);
      }).catchError((err) {
        debugPrint('[ChatManager] Backend DB save note: $err');
      });
      _mirrorMessageToRecipientLocalCache(userId, trimmed);
    }

    // CRITICAL: NO AUTO-REPLY IS EXECUTED HERE.
    // The message is pure peer-to-peer real chat and saved to DB.
  }

  void _mirrorMessageToRecipientLocalCache(int recipientId, String text) {
    try {
      final senderUid = TokenStorage.instance.currentUserIdSync;
      final senderUsername = TokenStorage.instance.currentDisplayNameSync ??
          TokenStorage.instance.currentUsernameSync ?? 'User';
      final senderAvatar = ProfileSyncService.instance.currentUserAvatar;

      final recipientFile = _getLocalFileForUser(recipientId);
      if (recipientFile == null) return;

      List<dynamic> rawList = [];
      if (recipientFile.existsSync()) {
        try {
          rawList = jsonDecode(recipientFile.readAsStringSync()) as List<dynamic>;
        } catch (_) {}
      }

      final incomingMsg = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'isMe': false,
        'timestamp': 'Just now',
        'status': 'Delivered',
      };

      final senderIdStr = senderUid != null ? senderUid.toString() : '21';
      int idx = rawList.indexWhere((item) =>
          item['id']?.toString() == senderIdStr ||
          (senderUid != null && item['userId'] == senderUid) ||
          item['username']?.toString().toLowerCase() == senderUsername.toLowerCase());

      if (idx != -1) {
        final existing = Map<String, dynamic>.from(rawList[idx] as Map);
        final msgs = List<dynamic>.from(existing['messages'] as List? ?? [])..add(incomingMsg);
        existing['lastMessage'] = text;
        existing['timeAgo'] = 'Just now';
        existing['messages'] = msgs;
        rawList.removeAt(idx);
        rawList.insert(0, existing);
      } else {
        rawList.insert(0, {
          'id': senderIdStr,
          'userId': senderUid,
          'username': senderUsername,
          'avatarUrl': senderAvatar,
          'lastMessage': text,
          'timeAgo': 'Just now',
          'isVerified': true,
          'followersCount': '520K followers',
          'isFollowing': false,
          'followsYou': true,
          'messages': [incomingMsg],
        });
      }

      recipientFile.writeAsStringSync(jsonEncode(rawList));
    } catch (e) {
      debugPrint('[ChatManager] Error mirroring message locally: $e');
    }
  }

  void _updateMessageWithDbId(String threadId, String oldId, String newId) {
    final list = List<DirectMessageThread>.from(_threadsNotifier.value);
    final idx = list.indexWhere(
      (t) => t.id == threadId || (t.userId != null && t.userId.toString() == threadId),
    );
    if (idx != -1) {
      final thread = list[idx];
      final updatedMsgs = thread.messages.map((m) {
        if (m.id == oldId) {
          return ChatMessage(
            id: newId,
            text: m.text,
            isMe: m.isMe,
            timestamp: m.timestamp,
            status: 'Sent',
          );
        }
        return m;
      }).toList();

      list[idx] = thread.copyWith(messages: updatedMsgs);
      _threadsNotifier.value = list;
      _persistToLocalDisk();
    }
  }
}
