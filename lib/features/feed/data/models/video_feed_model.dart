class VideoFeedModel {
  final int id;
  final int creatorId;
  final String username;
  final String displayName;
  final String avatarUrl;
  final bool isVerified;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String musicTitle;
  final String likes;
  final String comments;
  final String saves;
  final bool isFollowing;
  final bool isMe;

  const VideoFeedModel({
    required this.id,
    required this.creatorId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    this.isVerified = false,
    required this.videoUrl,
    this.thumbnailUrl = '',
    required this.caption,
    required this.musicTitle,
    required this.likes,
    required this.comments,
    required this.saves,
    this.isFollowing = false,
    this.isMe = false,
  });

  factory VideoFeedModel.fromJson(Map<String, dynamic> json) {
    return VideoFeedModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      creatorId: json['creatorId'] is int ? json['creatorId'] : int.tryParse(json['creatorId']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '@vilo_user',
      displayName: json['displayName']?.toString() ?? 'Vilo User',
      avatarUrl: (json['avatarUrl'] != null && json['avatarUrl'].toString().isNotEmpty)
          ? json['avatarUrl'].toString()
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      isVerified: json['isVerified'] == true,
      videoUrl: json['videoUrl']?.toString() ?? 'assets/videos/vid1.mp4',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      musicTitle: json['musicTitle']?.toString() ?? 'Original Sound',
      likes: json['formattedLikes']?.toString() ?? '1.2M',
      comments: json['formattedComments']?.toString() ?? '45.2K',
      saves: json['formattedSaves']?.toString() ?? '120K',
      isFollowing: json['isFollowing'] == true,
      isMe: json['isMe'] == true,
    );
  }

  VideoFeedModel copyWith({
    int? id,
    int? creatorId,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool? isVerified,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    String? musicTitle,
    String? likes,
    String? comments,
    String? saves,
    bool? isFollowing,
    bool? isMe,
  }) {
    return VideoFeedModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      musicTitle: musicTitle ?? this.musicTitle,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      saves: saves ?? this.saves,
      isFollowing: isFollowing ?? this.isFollowing,
      isMe: isMe ?? this.isMe,
    );
  }
}
