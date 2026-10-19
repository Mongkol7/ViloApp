class StoryItem {
  final String id;
  final String title;
  final String imageUrl;
  final bool isCreate;
  final String? message;
  final String? musicTitle;
  final String? musicArtist;
  final String? timestamp;

  const StoryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.isCreate = false,
    this.message,
    this.musicTitle,
    this.musicArtist,
    this.timestamp,
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
  final int? userId;
  final String username;
  final String avatarUrl;
  final String lastMessage;
  final String timeAgo;
  final bool isVerified;
  final String followersCount;
  final bool isFollowing;
  final bool followsYou;
  final List<ChatMessage> messages;

  const DirectMessageThread({
    required this.id,
    this.userId,
    required this.username,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timeAgo,
    this.isVerified = false,
    this.followersCount = '',
    this.isFollowing = false,
    this.followsYou = false,
    this.messages = const [],
  });

  bool get isFriend => isFollowing && followsYou;

  DirectMessageThread copyWith({
    String? id,
    int? userId,
    String? username,
    String? avatarUrl,
    String? lastMessage,
    String? timeAgo,
    bool? isVerified,
    String? followersCount,
    bool? isFollowing,
    bool? followsYou,
    List<ChatMessage>? messages,
  }) {
    return DirectMessageThread(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      timeAgo: timeAgo ?? this.timeAgo,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
      isFollowing: isFollowing ?? this.isFollowing,
      followsYou: followsYou ?? this.followsYou,
      messages: messages ?? this.messages,
    );
  }
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
