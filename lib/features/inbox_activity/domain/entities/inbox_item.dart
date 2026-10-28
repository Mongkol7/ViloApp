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
  final String iconType; // 'followers', 'activity', 'comment'
  final int? badgeCount;
  final bool hasDot;
  final String type;
  final int? actorId;
  final String? actorUsername;
  final String? actorDisplayName;
  final String? actorAvatarUrl;
  final int? videoId;
  final int? commentId;
  final int? targetUserId;
  final String? commentExcerpt;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    this.title = '',
    this.subtitle = '',
    this.iconType = 'system',
    this.badgeCount,
    this.hasDot = false,
    this.type = 'SYSTEM',
    this.actorId,
    this.actorUsername,
    this.actorDisplayName,
    this.actorAvatarUrl,
    this.videoId,
    this.commentId,
    this.targetUserId,
    this.commentExcerpt,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? 'SYSTEM').toUpperCase();
    final actorName = (json['actorDisplayName'] as String?)?.trim();
    final actorUsername = (json['actorUsername'] as String?)?.trim();
    final actor =
        (actorName?.isNotEmpty == true ? actorName : actorUsername) ??
        'Someone';
    final excerpt = (json['commentExcerpt'] as String?)?.trim();
    final title = switch (type) {
      'LIKE' => 'Likes',
      'COMMENT' => 'Comments',
      'REPLY' => 'Replies',
      'FOLLOW' => 'New followers',
      _ => 'Activity',
    };
    final subtitle = switch (type) {
      'LIKE' => '$actor liked your video',
      'COMMENT' =>
        excerpt?.isNotEmpty == true
            ? '$actor commented: $excerpt'
            : '$actor commented on your video',
      'REPLY' =>
        excerpt?.isNotEmpty == true
            ? '$actor replied: $excerpt'
            : '$actor replied to your comment',
      'FOLLOW' => '$actor followed you',
      _ => '$actor interacted with you',
    };
    return NotificationItem(
      id: '${json['id']}',
      title: title,
      subtitle: subtitle,
      iconType: type == 'FOLLOW'
          ? 'followers'
          : (type == 'LIKE' ? 'activity' : 'comment'),
      hasDot: !(json['read'] as bool? ?? false),
      type: type,
      actorId: (json['actorId'] as num?)?.toInt(),
      actorUsername: json['actorUsername'] as String?,
      actorDisplayName: json['actorDisplayName'] as String?,
      actorAvatarUrl: json['actorAvatarUrl'] as String?,
      videoId: (json['videoId'] as num?)?.toInt(),
      commentId: (json['commentId'] as num?)?.toInt(),
      targetUserId: (json['targetUserId'] as num?)?.toInt(),
      commentExcerpt: json['commentExcerpt'] as String?,
      isRead: json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    title: title,
    subtitle: subtitle,
    iconType: iconType,
    badgeCount: badgeCount,
    hasDot: !(isRead ?? this.isRead),
    type: type,
    actorId: actorId,
    actorUsername: actorUsername,
    actorDisplayName: actorDisplayName,
    actorAvatarUrl: actorAvatarUrl,
    videoId: videoId,
    commentId: commentId,
    targetUserId: targetUserId,
    commentExcerpt: commentExcerpt,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
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
          .map(
            (message) => ChatMessage.fromJson(message as Map<String, dynamic>),
          )
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
  final int? remoteId;
  final String contentType;
  final String? linkUrl;
  final int? sharedVideoId;
  final String? sharedVideoUrl;
  final String? sharedVideoThumbnailUrl;
  final String? sharedVideoCreator;
  final String? sharedVideoCaption;
  final bool deletedForEveryone;
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
    this.remoteId,
    this.contentType = 'TEXT',
    this.linkUrl,
    this.sharedVideoId,
    this.sharedVideoUrl,
    this.sharedVideoThumbnailUrl,
    this.sharedVideoCreator,
    this.sharedVideoCaption,
    this.deletedForEveryone = false,
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

  bool get isVideoShare =>
      contentType.toUpperCase() == 'VIDEO' ||
      sharedVideoId != null ||
      (sharedVideoUrl?.isNotEmpty ?? false);

  bool get isLinkMessage =>
      contentType.toUpperCase() == 'LINK' || (linkUrl?.isNotEmpty ?? false);

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

  bool get canCancel =>
      isOrderMessage && !isCancelled && cancelRemainingSeconds > 0;

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isMe,
    String? timestamp,
    String? status,
    String? imageUrl,
    List<String>? imageUrls,
    String? senderHandle,
    int? remoteId,
    String? contentType,
    String? linkUrl,
    int? sharedVideoId,
    String? sharedVideoUrl,
    String? sharedVideoThumbnailUrl,
    String? sharedVideoCreator,
    String? sharedVideoCaption,
    bool? deletedForEveryone,
    bool clearRichContent = false,
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
      imageUrl: clearRichContent ? null : (imageUrl ?? this.imageUrl),
      imageUrls: clearRichContent ? null : (imageUrls ?? this.imageUrls),
      senderHandle: senderHandle ?? this.senderHandle,
      remoteId: remoteId ?? this.remoteId,
      contentType: contentType ?? this.contentType,
      linkUrl: clearRichContent ? null : (linkUrl ?? this.linkUrl),
      sharedVideoId: clearRichContent
          ? null
          : (sharedVideoId ?? this.sharedVideoId),
      sharedVideoUrl: clearRichContent
          ? null
          : (sharedVideoUrl ?? this.sharedVideoUrl),
      sharedVideoThumbnailUrl: clearRichContent
          ? null
          : (sharedVideoThumbnailUrl ?? this.sharedVideoThumbnailUrl),
      sharedVideoCreator: clearRichContent
          ? null
          : (sharedVideoCreator ?? this.sharedVideoCreator),
      sharedVideoCaption: clearRichContent
          ? null
          : (sharedVideoCaption ?? this.sharedVideoCaption),
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawImageUrl = json['imageUrl'];
    final legacyImageUrls = rawImageUrl is List
        ? rawImageUrl
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList()
        : const <String>[];
    final storedImageUrls = json['imageUrls'] is List
        ? (json['imageUrls'] as List)
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList()
        : const <String>[];
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String? ?? '',
      isMe: json['isMe'] as bool? ?? false,
      timestamp: json['timestamp'] as String? ?? '',
      status: json['status'] as String?,
      imageUrl: rawImageUrl is String
          ? rawImageUrl
          : (legacyImageUrls.isNotEmpty ? legacyImageUrls.first : null),
      imageUrls: storedImageUrls.isNotEmpty
          ? storedImageUrls
          : (legacyImageUrls.isNotEmpty ? legacyImageUrls : null),
      senderHandle: json['senderHandle'] as String?,
      remoteId: (json['remoteId'] as num?)?.toInt(),
      contentType: json['contentType'] as String? ?? 'TEXT',
      linkUrl: json['linkUrl'] as String?,
      sharedVideoId: (json['sharedVideoId'] as num?)?.toInt(),
      sharedVideoUrl: json['sharedVideoUrl'] as String?,
      sharedVideoThumbnailUrl: json['sharedVideoThumbnailUrl'] as String?,
      sharedVideoCreator: json['sharedVideoCreator'] as String?,
      sharedVideoCaption: json['sharedVideoCaption'] as String?,
      deletedForEveryone: json['deletedForEveryone'] as bool? ?? false,
      isOrder: json['isOrder'] as bool? ?? false,
      orderCreatedAtMs: json['orderCreatedAtMs'] as int?,
      orderStatus: json['orderStatus'] as String?,
      orderProductId: json['orderProductId'] as String?,
      orderProductTitle: json['orderProductTitle'] as String?,
      orderReference: json['orderReference'] as String?,
      orderQuantity: (json['orderQuantity'] as num?)?.toInt(),
      orderItems: (json['orderItems'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      cancelledBy: json['cancelledBy'] as String?,
      cancellationTime: json['cancellationTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isMe': isMe,
    'timestamp': timestamp,
    'status': status,
    'imageUrl': imageUrl,
    'imageUrls': imageUrls,
    'senderHandle': senderHandle,
    'remoteId': remoteId,
    'contentType': contentType,
    'linkUrl': linkUrl,
    'sharedVideoId': sharedVideoId,
    'sharedVideoUrl': sharedVideoUrl,
    'sharedVideoThumbnailUrl': sharedVideoThumbnailUrl,
    'sharedVideoCreator': sharedVideoCreator,
    'sharedVideoCaption': sharedVideoCaption,
    'deletedForEveryone': deletedForEveryone,
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
