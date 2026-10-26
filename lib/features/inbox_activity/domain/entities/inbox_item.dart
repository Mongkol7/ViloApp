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

  DirectMessageThread copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    String? lastMessage,
    String? timeAgo,
    bool? isVerified,
    String? followersCount,
    List<ChatMessage>? messages,
  }) {
    return DirectMessageThread(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      timeAgo: timeAgo ?? this.timeAgo,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
      messages: messages ?? this.messages,
    );
  }

  factory DirectMessageThread.fromJson(Map<String, dynamic> json) {
    return DirectMessageThread(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      followersCount: json['followersCount'] as String? ?? '',
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((message) => ChatMessage.fromJson(message as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'avatarUrl': avatarUrl,
        'lastMessage': lastMessage,
        'timeAgo': timeAgo,
        'isVerified': isVerified,
        'followersCount': followersCount,
        'messages': messages.map((message) => message.toJson()).toList(),
      };
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String timestamp;
  final String? status;
  final String? imageUrl;
  final List<String>? imageUrls;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.status = 'Sent',
    this.imageUrl,
    this.imageUrls,
  });

  bool get hasImages =>
      (imageUrl != null && imageUrl!.trim().isNotEmpty) ||
      (imageUrls != null && imageUrls!.isNotEmpty);

  List<String> get allImages {
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      return imageUrls!;
    }
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return [imageUrl!];
    }
    return const [];
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        isMe: json['isMe'] as bool? ?? false,
        timestamp: json['timestamp'] as String? ?? '',
        status: json['status'] as String?,
        imageUrl: json['imageUrl'] as String?,
        imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isMe': isMe,
        'timestamp': timestamp,
        'status': status,
        'imageUrl': imageUrl,
        'imageUrls': imageUrls,
      };
}
