import '../../../auth/data/datasources/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/inbox_item.dart';
import 'chat_manager.dart';
import 'static_inbox_data.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource._();
  static final ChatRemoteDataSource instance = ChatRemoteDataSource._();

  Future<List<DirectMessageThread>> getConversations() async {
    try {
      final response = await ApiClient.instance.get('/chats/conversations');
      if (response is List) {
        return response.map<DirectMessageThread>((json) {
          final otherId = json['otherUserId']?.toString() ?? '';
          final otherUserId = json['otherUserId'] is int ? json['otherUserId'] as int : int.tryParse(otherId);
          final otherUsername = json['otherUsername'] ?? 'User';
          final otherDisplayName = json['otherDisplayName'] ?? otherUsername;
          final avatarUrl = json['otherAvatarUrl'] ??
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
          final lastMsg = json['lastMessageContent'] ?? '';
          final isVerified = json['isOtherVerified'] == true;
          final isFollowing = json['isFollowing'] == true;
          final followsYou = json['followsYou'] == true;

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
            messages: const [],
          );
        }).toList();
      }
    } catch (_) {
      // Fallback to static threads only if demo user
    }
    final isDemoUser = TokenStorage.instance.isDemoUserSync;
    if (isDemoUser) {
      return StaticInboxData.threads;
    }
    return const [];
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
      // Fallback to local thread messages
    }

    final localMessages = ChatManager.instance.getMessages(userId.toString());
    if (localMessages.isNotEmpty) {
      return localMessages;
    }

    final isDemoUser = TokenStorage.instance.currentUserIdSync == 1;
    if (isDemoUser) {
      final threadMatch = StaticInboxData.threads.cast<DirectMessageThread?>().firstWhere(
        (t) => t?.id == userId.toString() || t?.userId == userId,
        orElse: () => null,
      );
      if (threadMatch != null) {
        return List.from(threadMatch.messages);
      }
    }
    return const [];
  }

  Future<ChatMessage> sendMessage(int userId, String content, {String? mediaUrl}) async {
    try {
      final response = await ApiClient.instance.post(
        '/chats/$userId/messages',
        body: {
          'content': content,
          'mediaUrl': ?mediaUrl,
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
    } catch (e) {
      // Backend log
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: content,
      isMe: true,
      timestamp: 'Just now',
      status: 'Sent',
    );
  }
}
