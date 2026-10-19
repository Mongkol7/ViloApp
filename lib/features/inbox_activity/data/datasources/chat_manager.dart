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

  bool _isSamePerson(DirectMessageThread a, DirectMessageThread b) {
    if (a.userId != null && b.userId != null && a.userId! > 0 && b.userId! > 0) {
      if (a.userId == b.userId) return true;
    }
    if (a.id.isNotEmpty && b.id.isNotEmpty && a.id == b.id) return true;
    final uA = a.username.replaceAll('@', '').toLowerCase().trim();
    final uB = b.username.replaceAll('@', '').toLowerCase().trim();
    if (uA.isNotEmpty && uB.isNotEmpty && uA == uB) return true;
    return false;
  }

  List<DirectMessageThread> _consolidateThreads(List<DirectMessageThread> list) {
    final List<DirectMessageThread> result = [];
    for (final thread in list) {
      final existingIndex = result.indexWhere((t) => _isSamePerson(t, thread));
      if (existingIndex == -1) {
        result.add(thread);
      } else {
        final existing = result[existingIndex];
        final combinedMessages = List<ChatMessage>.from(existing.messages);
        for (final m in thread.messages) {
          if (!combinedMessages.any((cm) => cm.id == m.id || (cm.text == m.text && cm.timestamp == m.timestamp))) {
            combinedMessages.add(m);
          }
        }
        result[existingIndex] = existing.copyWith(
          userId: existing.userId ?? thread.userId,
          avatarUrl: existing.avatarUrl.isNotEmpty ? existing.avatarUrl : thread.avatarUrl,
          lastMessage: thread.lastMessage.isNotEmpty ? thread.lastMessage : existing.lastMessage,
          timeAgo: (thread.timeAgo.isNotEmpty && thread.timeAgo != 'Just now') ? thread.timeAgo : existing.timeAgo,
          isFollowing: existing.isFollowing || thread.isFollowing,
          followsYou: existing.followsYou || thread.followsYou,
          isVerified: existing.isVerified || thread.isVerified,
          messages: combinedMessages,
        );
      }
    }
    return result;
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
          _threadsNotifier.value = _consolidateThreads(loaded);
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
    _threadsNotifier.value = _consolidateThreads(List.from(StaticInboxData.threads));
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
      final current = _threadsNotifier.value;
      final merged = <DirectMessageThread>[];

      for (final remote in remoteThreads) {
        final existing = current.cast<DirectMessageThread?>().firstWhere(
          (t) => t != null && _isSamePerson(t, remote),
          orElse: () => null,
        );
        if (existing != null) {
          final combinedMsgs = List<ChatMessage>.from(existing.messages);
          for (final m in remote.messages) {
            if (!combinedMsgs.any((cm) => cm.id == m.id || (cm.text == m.text && cm.timestamp == m.timestamp))) {
              combinedMsgs.add(m);
            }
          }
          merged.add(
            DirectMessageThread(
              id: remote.id,
              userId: remote.userId ?? existing.userId,
              username: remote.username,
              avatarUrl: remote.avatarUrl.isNotEmpty ? remote.avatarUrl : existing.avatarUrl,
              lastMessage: existing.lastMessage.isNotEmpty ? existing.lastMessage : remote.lastMessage,
              timeAgo: existing.timeAgo.isNotEmpty ? existing.timeAgo : remote.timeAgo,
              isVerified: remote.isVerified || existing.isVerified,
              followersCount: remote.followersCount.isNotEmpty ? remote.followersCount : existing.followersCount,
              isFollowing: remote.isFollowing || existing.isFollowing,
              followsYou: remote.followsYou || existing.followsYou,
              messages: combinedMsgs,
            ),
          );
        } else {
          merged.add(remote);
        }
      }

      // Add any local threads not in remote
      for (final local in current) {
        if (!merged.any((t) => _isSamePerson(t, local))) {
          merged.add(local);
        }
      }

      _threadsNotifier.value = _consolidateThreads(merged);
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
    final cleanUsername = username.replaceAll('@', '').toLowerCase().trim();

    int idx = list.indexWhere((t) {
      if (t.userId != null && t.userId == userId) return true;
      if (t.id == idStr) return true;
      final tUser = t.username.replaceAll('@', '').toLowerCase().trim();
      return tUser.isNotEmpty && tUser == cleanUsername;
    });

    if (idx != -1) {
      final existing = list[idx];
      final updated = existing.copyWith(
        userId: userId,
        avatarUrl: existing.avatarUrl.isNotEmpty ? existing.avatarUrl : avatarUrl,
        isFollowing: isFollowing || existing.isFollowing,
        followsYou: followsYou || existing.followsYou,
      );
      list[idx] = updated;
      _threadsNotifier.value = _consolidateThreads(list);
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
    _threadsNotifier.value = _consolidateThreads(list);
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
    final cleanThreadId = threadId.toLowerCase().trim();
    final parsedUid = int.tryParse(threadId);

    int index = currentList.indexWhere((t) {
      if (t.id.toLowerCase().trim() == cleanThreadId) return true;
      if (parsedUid != null && t.userId == parsedUid) return true;
      if (t.userId != null && t.userId.toString() == cleanThreadId) return true;
      return false;
    });

    if (index == -1) {
      final resolvedUid = _resolveUserId(threadId, 'User');
      if (resolvedUid != null) {
        index = currentList.indexWhere((t) => t.userId == resolvedUid || t.id == resolvedUid.toString());
      }
    }

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
      _threadsNotifier.value = _consolidateThreads(currentList);
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
      _threadsNotifier.value = _consolidateThreads(currentList);
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
