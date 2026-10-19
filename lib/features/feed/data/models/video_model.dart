import '../../../../core/network/api_client.dart';

class VideoModel {
  final int id;
  final int creatorId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool isVerified;
  final String caption;
  final String videoUrl;
  final String? _thumbnailUrl;
  final String musicTitle;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final bool isMe;
  final List<String> tags;
  final DateTime? createdAt;
  final String? _formattedLikes;
  final String? _formattedComments;
  final String? _formattedSaves;

  const VideoModel({
    required this.id,
    required this.creatorId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.isVerified = false,
    required this.caption,
    required this.videoUrl,
    String? thumbnailUrl,
    this.musicTitle = 'Original Sound',
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    this.isMe = false,
    this.tags = const [],
    this.createdAt,
    String? formattedLikes,
    String? formattedComments,
    String? formattedSaves,
    String? likes,
    String? comments,
    String? saves,
  })  : _thumbnailUrl = thumbnailUrl,
        _formattedLikes = formattedLikes ?? likes,
        _formattedComments = formattedComments ?? comments,
        _formattedSaves = formattedSaves ?? saves;

  /// Returns true if the media represents an image post rather than a video.
  bool get isImagePost {
    final lower = videoUrl.toLowerCase();
    return lower.contains('/uploads/photos/') ||
        RegExp(r'\.(jpg|jpeg|png|webp|gif)($|\?)', caseSensitive: false).hasMatch(lower);
  }

  /// Returns the thumbnail URL, defaulting to [videoUrl] if this is an image post.
  String? get thumbnailUrl {
    if (_thumbnailUrl != null && _thumbnailUrl.trim().isNotEmpty) {
      return _thumbnailUrl;
    }
    return isImagePost ? videoUrl : null;
  }

  /// Resolves relative URLs (e.g., /uploads/videos/abc.mp4) to full HTTP URLs using ApiClient
  static String resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final clean = url.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://') || clean.startsWith('assets/')) {
      return clean;
    }
    final host = ApiClient.baseUrl.replaceAll('/api/v1', '');
    if (clean.startsWith('/')) {
      return '$host$clean';
    }
    return '$host/$clean';
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final rawVideoUrl = json['videoUrl']?.toString() ?? '';
    final rawThumbUrl = json['thumbnailUrl']?.toString();

    final tagsList = (json['tags'] is List)
        ? (json['tags'] as List).map((t) => t.toString()).toList()
        : <String>[];

    final resolvedVideoUrl = resolveMediaUrl(rawVideoUrl);
    String? resolvedThumbUrl = (rawThumbUrl != null && rawThumbUrl.trim().isNotEmpty)
        ? resolveMediaUrl(rawThumbUrl)
        : null;

    final isImg = resolvedVideoUrl.toLowerCase().contains('/uploads/photos/') ||
        RegExp(r'\.(jpg|jpeg|png|webp|gif)($|\?)', caseSensitive: false).hasMatch(resolvedVideoUrl);
    if (isImg && (resolvedThumbUrl == null || resolvedThumbUrl.isEmpty)) {
      resolvedThumbUrl = resolvedVideoUrl;
    }

    return VideoModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      creatorId: (json['creatorId'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '@user',
      displayName: json['displayName']?.toString() ?? 'User',
      avatarUrl: json['avatarUrl']?.toString(),
      isVerified: json['isVerified'] == true,
      caption: json['caption']?.toString() ?? '',
      videoUrl: resolvedVideoUrl,
      thumbnailUrl: resolvedThumbUrl,
      musicTitle: json['musicTitle']?.toString() ?? 'Original Sound',
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      isLiked: (json['isLiked'] ?? json['liked']) == true,
      isSaved: (json['isSaved'] ?? json['saved']) == true,
      isFollowing: json['isFollowing'] == true,
      isMe: json['isMe'] == true,
      tags: tagsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      formattedLikes: json['formattedLikes']?.toString(),
      formattedComments: json['formattedComments']?.toString(),
      formattedSaves: json['formattedSaves']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'caption': caption,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'musicTitle': musicTitle,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'saveCount': saveCount,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'isFollowing': isFollowing,
      'isMe': isMe,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'formattedLikes': formattedLikes,
      'formattedComments': formattedComments,
      'formattedSaves': formattedSaves,
    };
  }

  VideoModel copyWith({
    int? id,
    int? creatorId,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool? isVerified,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    String? musicTitle,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    int? saveCount,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
    bool? isMe,
    List<String>? tags,
    DateTime? createdAt,
    String? formattedLikes,
    String? formattedComments,
    String? formattedSaves,
    String? likes,
    String? comments,
    String? saves,
  }) {
    return VideoModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      caption: caption ?? this.caption,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? _thumbnailUrl,
      musicTitle: musicTitle ?? this.musicTitle,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      saveCount: saveCount ?? this.saveCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      isMe: isMe ?? this.isMe,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      formattedLikes: formattedLikes ?? likes ?? _formattedLikes,
      formattedComments: formattedComments ?? comments ?? _formattedComments,
      formattedSaves: formattedSaves ?? saves ?? _formattedSaves,
    );
  }

  String get likes => formattedLikes;
  String get comments => formattedComments;
  String get saves => formattedSaves;

  String get formattedLikes => _formattedLikes ?? _formatCount(likeCount);
  String get formattedComments => _formattedComments ?? _formatCount(commentCount);
  String get formattedSaves => _formattedSaves ?? _formatCount(saveCount);
  String get formattedViews => _formatCount(viewCount);

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
