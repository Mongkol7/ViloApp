import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../auth/data/datasources/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/inbox_item.dart';
import 'chat_manager.dart';
import 'static_inbox_data.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource._();
  static final ChatRemoteDataSource instance = ChatRemoteDataSource._();

  String _resolveMediaUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty ||
        value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }
    return '${ApiClient.baseUrl.replaceFirst('/api/v1', '')}${value.startsWith('/') ? value : '/$value'}';
  }

  Future<List<DirectMessageThread>> getConversations() async {
    try {
      final response = await ApiClient.instance.get('/chats/conversations');
      if (response is List) {
        return response.map<DirectMessageThread>((json) {
          final otherId = json['otherUserId']?.toString() ?? '';
          final otherUserId = json['otherUserId'] is int
              ? json['otherUserId'] as int
              : int.tryParse(otherId);
          final otherUsername = json['otherUsername'] ?? 'User';
          final otherDisplayName = json['otherDisplayName'] ?? otherUsername;
          final avatarUrl =
              json['otherAvatarUrl'] ??
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
          final lastMsg = json['lastMessageContent'] ?? '';
          final isVerified = json['isOtherVerified'] == true;
          final isFollowing = json['isFollowing'] == true;
          final followsYou = json['followsYou'] == true;
          final unreadCount = json['unreadCount'] is num
              ? (json['unreadCount'] as num).toInt()
              : (int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0);

          return DirectMessageThread(
            id: otherId,
            userId: otherUserId,
            username: otherDisplayName,
            avatarUrl: avatarUrl,
            lastMessage: lastMsg,
            timeAgo: 'Recently',
            isVerified: isVerified,
            followersCount: '1.2M',
            isFollowing: isFollowing,
            followsYou: followsYou,
            unreadCount: unreadCount,
            messages: const [],
          );
        }).toList();
      }
    } catch (_) {
      // Fallback to static threads only if demo user
    }
    final isDemoUser = TokenStorage.instance.isDemoUserSync;
    if (isDemoUser ||
        TokenStorage.instance.currentUserIdSync == null ||
        TokenStorage.instance.currentUserIdSync == 1) {
      return StaticInboxData.threads;
    }
    return const [];
  }

  Future<List<ChatMessage>> getMessages(
    int userId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await ApiClient.instance.get(
        '/chats/$userId/messages?page=$page&size=$size',
      );
      final content = (response is Map && response['content'] is List)
          ? response['content'] as List
          : (response is List ? response : null);

      if (content != null) {
        final messages = content.map<ChatMessage>((json) {
          final id =
              json['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString();
          final deleted =
              json['deleted'] == true || json['deletedForEveryone'] == true;
          final isMe = json['isMe'] == true;
          final text = deleted
              ? (isMe ? 'You deleted a message' : 'This message was deleted')
              : (json['content'] ?? '');
          final isRead = json['isRead'] == true;
          final sentAt = DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          )?.toLocal();

          return ChatMessage(
            id: id,
            text: text,
            isMe: isMe,
            timestamp: sentAt != null ? _formatTime(sentAt) : 'Just now',
            status: isRead ? 'Seen' : 'Sent',
            mediaUrl: deleted
                ? null
                : _resolveMediaUrl(json['mediaUrl']?.toString()),
            isDeletedForEveryone: deleted,
            sentAt: sentAt,
          );
        }).toList();

        // Spring returns paginated messages DESC, so reverse for chat view (oldest to newest)
        return messages.reversed.toList();
      }
    } catch (_) {
      // Fallback to local thread messages
    }

    final localMessages = ChatManager.instance.getMessages(userId.toString());
    if (localMessages.isNotEmpty) {
      return localMessages;
    }

    final isDemoUser = TokenStorage.instance.currentUserIdSync == 1;
    if (isDemoUser) {
      final threadMatch = StaticInboxData.threads
          .cast<DirectMessageThread?>()
          .firstWhere(
            (t) => t?.id == userId.toString() || t?.userId == userId,
            orElse: () => null,
          );
      if (threadMatch != null) {
        return List.from(threadMatch.messages);
      }
    }
    return const [];
  }

  Future<bool> markAsRead(int userId) async {
    try {
      await ApiClient.instance.post('/chats/$userId/read');
      return true;
    } catch (_) {
      return false;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<ChatMessage> sendMessage(
    int userId,
    String content, {
    String? mediaUrl,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/chats/$userId/messages',
        body: {'content': content, 'mediaUrl': ?mediaUrl},
      );

      if (response is Map) {
        final sentAt = DateTime.tryParse(
          response['createdAt']?.toString() ?? '',
        )?.toLocal();
        return ChatMessage(
          id:
              response['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          text: response['content'] ?? content,
          isMe: true,
          timestamp: sentAt != null ? _formatTime(sentAt) : 'Just now',
          status: 'Sent',
          mediaUrl: _resolveMediaUrl(
            response['mediaUrl']?.toString() ?? mediaUrl,
          ),
          isDeletedForEveryone: false,
          sentAt: sentAt,
        );
      }
    } catch (e) {
      // Backend log
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: content,
      isMe: true,
      timestamp: 'Just now',
      status: 'Sent',
      mediaUrl: mediaUrl,
      isDeletedForEveryone: false,
      sentAt: DateTime.now(),
    );
  }

  Future<String> uploadChatImage(int userId, String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/chats/$userId/image'),
    );
    final token = await TokenStorage.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    final body = jsonDecode(await response.stream.bytesToString());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiResponseException('Image upload failed', response.statusCode);
    }
    final data = body is Map ? body['data'] : null;
    if (data == null || data.toString().isEmpty) {
      throw ApiResponseException('Image upload failed');
    }
    final raw = data.toString();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return '${ApiClient.baseUrl.replaceFirst('/api/v1', '')}${raw.startsWith('/') ? raw : '/$raw'}';
  }

  Future<bool> deleteConversation(dynamic userId) async {
    try {
      await ApiClient.instance.delete('/chats/$userId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMessage(
    String messageId, {
    bool forEveryone = false,
  }) async {
    try {
      await ApiClient.instance.delete(
        '/chats/messages/$messageId?forEveryone=$forEveryone',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
