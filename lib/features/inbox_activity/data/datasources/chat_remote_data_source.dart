import '../../../../core/network/api_client.dart';
import '../../domain/entities/inbox_item.dart';
import 'static_inbox_data.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource._();
  static final ChatRemoteDataSource instance = ChatRemoteDataSource._();

  Future<List<DirectMessageThread>> getConversations() async {
    try {
      final response = await ApiClient.instance.get('/chats/conversations');
      if (response is List && response.isNotEmpty) {
        return response.map<DirectMessageThread>((json) {
          final otherId = json['otherUserId']?.toString() ?? '';
          final otherUsername = json['otherUsername'] ?? 'User';
          final otherDisplayName = json['otherDisplayName'] ?? otherUsername;
          final avatarUrl = json['otherAvatarUrl'] ??
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
          final lastMsg = json['lastMessageContent'] ?? '';
          final isVerified = json['isOtherVerified'] == true;

          return DirectMessageThread(
            id: otherId,
            username: otherDisplayName,
            avatarUrl: avatarUrl,
            lastMessage: lastMsg,
            timeAgo: 'Recently',
            isVerified: isVerified,
            followersCount: '1.2M',
            messages: const [],
          );
        }).toList();
      }
    } catch (_) {
      // Fallback to static threads if offline
    }
    return StaticInboxData.threads;
  }

  Future<List<ChatMessage>> getMessages(int userId, {int page = 0, int size = 50}) async {
    try {
      final response = await ApiClient.instance.get('/chats/$userId/messages?page=$page&size=$size');
      final content = (response is Map && response['content'] is List)
          ? response['content'] as List
          : (response is List ? response : null);

      if (content != null) {
        final messages = content.map<ChatMessage>((json) {
          final id = json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
          final text = json['content'] ?? '';
          final isMe = json['isMe'] == true;

          return ChatMessage(
            id: id,
            text: text,
            isMe: isMe,
            timestamp: 'Just now',
            status: json['isRead'] == true ? 'Read' : 'Sent',
          );
        }).toList();

        // Spring returns paginated messages DESC, so reverse for chat view (oldest to newest)
        return messages.reversed.toList();
      }
    } catch (_) {
      // Fallback to static thread messages if available
    }

    final thread = StaticInboxData.threads.firstWhere(
      (t) => t.id == userId.toString(),
      orElse: () => StaticInboxData.threads.first,
    );
    return List.from(thread.messages);
  }

  Future<ChatMessage> sendMessage(int userId, String content, {String? mediaUrl}) async {
    try {
      final response = await ApiClient.instance.post(
        '/chats/$userId/messages',
        body: {
          'content': content,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
        },
      );

      if (response is Map) {
        return ChatMessage(
          id: response['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: response['content'] ?? content,
          isMe: true,
          timestamp: 'Just now',
          status: 'Sent',
        );
      }
    } catch (_) {}

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: content,
      isMe: true,
      timestamp: 'Just now',
      status: 'Sent',
    );
  }
}
