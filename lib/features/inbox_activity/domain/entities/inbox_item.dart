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
  final String? senderHandle;
  final String? senderAvatar;
  final String? recipientHandle;
  final String? recipientAvatar;

  const DirectMessageThread({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timeAgo,
    this.isVerified = false,
    this.followersCount = '',
    this.messages = const [],
    this.senderHandle,
    this.senderAvatar,
    this.recipientHandle,
    this.recipientAvatar,
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
    String? senderHandle,
    String? senderAvatar,
    String? recipientHandle,
    String? recipientAvatar,
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
      senderHandle: senderHandle ?? this.senderHandle,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      recipientHandle: recipientHandle ?? this.recipientHandle,
      recipientAvatar: recipientAvatar ?? this.recipientAvatar,
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
      senderHandle: json['senderHandle'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      recipientHandle: json['recipientHandle'] as String?,
      recipientAvatar: json['recipientAvatar'] as String?,
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
        'senderHandle': senderHandle,
        'senderAvatar': senderAvatar,
        'recipientHandle': recipientHandle,
        'recipientAvatar': recipientAvatar,
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
  final String? senderHandle;
  final bool isOrder;
  final int? orderCreatedAtMs;
  final String? orderStatus;
  final String? orderProductId;
  final String? orderProductTitle;
  final String? orderReference;
  final int? orderQuantity;
  final List<Map<String, dynamic>>? orderItems;
  final String? cancelledBy;
  final String? cancellationTime;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.status = 'Sent',
    this.imageUrl,
    this.imageUrls,
    this.senderHandle,
    this.isOrder = false,
    this.orderCreatedAtMs,
    this.orderStatus,
    this.orderProductId,
    this.orderProductTitle,
    this.orderReference,
    this.orderQuantity,
    this.orderItems,
    this.cancelledBy,
    this.cancellationTime,
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

  bool get isOrderMessage =>
      isOrder ||
      text.contains('I would like to order') ||
      text.contains('Order Inquiry') ||
      text.contains('order inquiry');

  bool get isCancelled => orderStatus == 'Cancelled';

  int get cancelRemainingSeconds {
    final created = orderCreatedAtMs;
    if (created == null) {
      return 0;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSec = (now - created) ~/ 1000;
    final remaining = (4 * 3600) - elapsedSec;
    return remaining > 0 ? remaining : 0;
  }

  bool get canCancel => isOrderMessage && !isCancelled && cancelRemainingSeconds > 0;

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isMe,
    String? timestamp,
    String? status,
    String? imageUrl,
    List<String>? imageUrls,
    String? senderHandle,
    bool? isOrder,
    int? orderCreatedAtMs,
    String? orderStatus,
    String? orderProductId,
    String? orderProductTitle,
    String? orderReference,
    int? orderQuantity,
    List<Map<String, dynamic>>? orderItems,
    String? cancelledBy,
    String? cancellationTime,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      senderHandle: senderHandle ?? this.senderHandle,
      isOrder: isOrder ?? this.isOrder,
      orderCreatedAtMs: orderCreatedAtMs ?? this.orderCreatedAtMs,
      orderStatus: orderStatus ?? this.orderStatus,
      orderProductId: orderProductId ?? this.orderProductId,
      orderProductTitle: orderProductTitle ?? this.orderProductTitle,
      orderReference: orderReference ?? this.orderReference,
      orderQuantity: orderQuantity ?? this.orderQuantity,
      orderItems: orderItems ?? this.orderItems,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationTime: cancellationTime ?? this.cancellationTime,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        isMe: json['isMe'] as bool? ?? false,
        timestamp: json['timestamp'] as String? ?? '',
        status: json['status'] as String?,
        imageUrl: json['imageUrl'] as String?,
        imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>(),
        senderHandle: json['senderHandle'] as String?,
        isOrder: json['isOrder'] as bool? ?? false,
        orderCreatedAtMs: json['orderCreatedAtMs'] as int?,
        orderStatus: json['orderStatus'] as String?,
        orderProductId: json['orderProductId'] as String?,
        orderProductTitle: json['orderProductTitle'] as String?,
        orderReference: json['orderReference'] as String?,
        orderQuantity: json['orderQuantity'] as int?,
        orderItems: (json['orderItems'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        cancelledBy: json['cancelledBy'] as String?,
        cancellationTime: json['cancellationTime'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isMe': isMe,
        'timestamp': timestamp,
        'status': status,
        'imageUrl': imageUrl,
        'imageUrls': imageUrls,
        'senderHandle': senderHandle,
        'isOrder': isOrder,
        'orderCreatedAtMs': orderCreatedAtMs,
        'orderStatus': orderStatus,
        'orderProductId': orderProductId,
        'orderProductTitle': orderProductTitle,
        'orderReference': orderReference,
        'orderQuantity': orderQuantity,
        'orderItems': orderItems,
        'cancelledBy': cancelledBy,
        'cancellationTime': cancellationTime,
      };
}
