import 'package:flutter/foundation.dart';
import '../../domain/entities/inbox_item.dart';
import 'static_inbox_data.dart';

/// Centralized in-memory manager for direct message threads and active conversations.
///
/// Ensures real-time state synchronization between Cart inquiries, ChatDetailScreen,
/// and the InboxScreen MESSAGES list.
class InboxMessageManager {
  InboxMessageManager._internal() {
    _threads = List<DirectMessageThread>.from(StaticInboxData.threads);
    threadsNotifier = ValueNotifier<List<DirectMessageThread>>(_threads);
  }

  static final InboxMessageManager instance = InboxMessageManager._internal();

  late final List<DirectMessageThread> _threads;
  late final ValueNotifier<List<DirectMessageThread>> threadsNotifier;

  List<DirectMessageThread> get threads => List.unmodifiable(_threads);

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
    return resolvedThread;
  }

  /// Appends an individual message to an existing or new thread and brings it to the top.
  void addMessageToThread(String threadId, ChatMessage message) {
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
    }
  }

  /// Resets threads to initial StaticInboxData for testing.
  void resetToDefault() {
    _threads.clear();
    _threads.addAll(StaticInboxData.threads);
    threadsNotifier.value = List.unmodifiable(_threads);
  }
}
