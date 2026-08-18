class StoryItem {
  final String id;
  final String title;
  final String imageUrl;
  final bool isCreate;

  const StoryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.isCreate = false,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String iconType; // 'followers', 'activity', 'system'
  final int? badgeCount;
  final bool hasDot;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconType,
    this.badgeCount,
    this.hasDot = false,
  });
}

class DirectMessageThread {
  final String id;
  final String username;
  final String avatarUrl;
  final String lastMessage;
  final String timeAgo;
  final bool isVerified;
  final String followersCount;
  final List<ChatMessage> messages;

  const DirectMessageThread({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timeAgo,
    this.isVerified = false,
    this.followersCount = '',
    this.messages = const [],
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String timestamp;
  final String? status;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.status = 'Sent',
  });
}
