import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/data/datasources/token_storage.dart';
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
  Future<void> loadForUser(int userId) {
    if (_activeUserId == userId && _loadFuture != null) return _loadFuture!;
    _activeUserId = userId;
    _threads.clear();
    threadsNotifier.value = const [];
    _drafts.clear();
    _loadFuture = _loadUserData(userId);
    return _loadFuture!;
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
    }
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
