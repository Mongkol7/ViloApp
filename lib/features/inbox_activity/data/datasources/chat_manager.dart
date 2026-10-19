import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/inbox_item.dart';
import 'chat_remote_data_source.dart';
import 'chat_stomp_service.dart';
import 'static_inbox_data.dart';

/// Centralized in-memory ChatManager for Direct Messages.
///
/// Ensures real-time state synchronization, message persistence across screens,
/// simulated incoming replies for testing, and seamless fallback to WebSocket/REST.
class ChatManager {
  ChatManager._internal() {
    _threadsNotifier.value = List.from(StaticInboxData.threads);
  }
  static final ChatManager instance = ChatManager._internal();

  final ValueNotifier<List<DirectMessageThread>> _threadsNotifier =
      ValueNotifier<List<DirectMessageThread>>([]);
  Timer? _replyTimer;

  ValueListenable<List<DirectMessageThread>> get threadsNotifier => _threadsNotifier;
  List<DirectMessageThread> get threads => _threadsNotifier.value;

  void cancelTimers() {
    _replyTimer?.cancel();
    _replyTimer = null;
  }

  void init(List<DirectMessageThread> remoteThreads) {
    if (remoteThreads.isNotEmpty) {
      _threadsNotifier.value = List.from(remoteThreads);
    }
  }

  DirectMessageThread getThread(String threadId) {
    return _threadsNotifier.value.firstWhere(
      (t) => t.id == threadId,
      orElse: () => _threadsNotifier.value.first,
    );
  }

  List<ChatMessage> getMessages(String threadId) {
    final thread = _threadsNotifier.value.firstWhere(
      (t) => t.id == threadId,
      orElse: () => _threadsNotifier.value.first,
    );
    return List.from(thread.messages);
  }

  static bool immediateRepliesForTesting = false;

  void reset() {
    cancelTimers();
    _threadsNotifier.value = List.from(StaticInboxData.threads);
  }

  void sendMessage({
    required String threadId,
    required String text,
    Function(ChatMessage incomingReply)? onAutoReply,
  }) {
    if (text.trim().isEmpty) return;

    final trimmed = text.trim();
    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      isMe: true,
      timestamp: 'Just now',
      status: 'Sent',
    );

    final currentList = List<DirectMessageThread>.from(_threadsNotifier.value);
    final index = currentList.indexWhere((t) => t.id == threadId);

    String recipientName = 'User';
    if (index != -1) {
      final thread = currentList[index];
      recipientName = thread.username;
      final updatedMessages = List<ChatMessage>.from(thread.messages)..add(newMsg);

      // Update thread with last message and move to top
      final updatedThread = DirectMessageThread(
        id: thread.id,
        username: thread.username,
        avatarUrl: thread.avatarUrl,
        lastMessage: trimmed,
        timeAgo: 'Just now',
        isVerified: thread.isVerified,
        followersCount: thread.followersCount,
        messages: updatedMessages,
      );

      currentList.removeAt(index);
      currentList.insert(0, updatedThread);
      _threadsNotifier.value = currentList;
    }

    // Forward to WebSocket STOMP and REST API if backend is active
    final userId = int.tryParse(threadId);
    if (userId != null) {
      ChatStompService.instance.sendMessage(recipientId: userId, content: trimmed);
      ChatRemoteDataSource.instance.sendMessage(userId, text);
    }

    void executeReply() {
      final replyText = _generateAutoReply(recipientName, trimmed);
      final replyMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: replyText,
        isMe: false,
        timestamp: 'Just now',
      );

      final list = List<DirectMessageThread>.from(_threadsNotifier.value);
      final idx = list.indexWhere((t) => t.id == threadId);
      if (idx != -1) {
        final thread = list[idx];
        final updatedMsgs = List<ChatMessage>.from(thread.messages)..add(replyMsg);
        list[idx] = DirectMessageThread(
          id: thread.id,
          username: thread.username,
          avatarUrl: thread.avatarUrl,
          lastMessage: replyText,
          timeAgo: 'Just now',
          isVerified: thread.isVerified,
          followersCount: thread.followersCount,
          messages: updatedMsgs,
        );
        _threadsNotifier.value = list;
      }

      onAutoReply?.call(replyMsg);
    }

    if (immediateRepliesForTesting) {
      executeReply();
    } else {
      // Auto-reply simulation for seamless interactive testing on device
      _replyTimer?.cancel();
      _replyTimer = Timer(const Duration(milliseconds: 1400), executeReply);
    }
  }

  String _generateAutoReply(String recipient, String message) {
    final lower = message.toLowerCase();
    if (lower.contains('hi') || lower.contains('hello') || lower.contains('hey')) {
      return 'Hey there! Thanks for reaching out 👋 How can I help you today?';
    } else if (lower.contains('price') || lower.contains('size') || lower.contains('dress')) {
      return 'Yes! We have that available in stock. Would you like me to reserve one for you? ✨';
    } else if (lower.contains('ship') || lower.contains('order')) {
      return 'We offer express worldwide shipping! Orders typically arrive in 3-5 business days 📦';
    } else if (lower.contains('thanks') || lower.contains('thank you')) {
      return 'You are most welcome! Let me know if you need anything else ❤️';
    } else {
      return 'Awesome! Sounds great. Let me check that for you right away 👍';
    }
  }
}
