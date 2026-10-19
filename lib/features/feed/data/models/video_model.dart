import '../../../../core/network/api_client.dart';

class VideoModel {
  final int id;
  final int creatorId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String caption;
  final String videoUrl;
  final String? _thumbnailUrl;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final bool isLiked;
  final bool isSaved;
  final List<String> tags;
  final DateTime? createdAt;

  const VideoModel({
    required this.id,
    required this.creatorId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.caption,
    required this.videoUrl,
    String? thumbnailUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.tags = const [],
    this.createdAt,
  }) : _thumbnailUrl = thumbnailUrl;

  /// Returns true if the media represents an image post rather than a video.
  bool get isImagePost {
    final lower = videoUrl.toLowerCase();
    return lower.contains('/uploads/photos/') ||
        RegExp(r'\.(jpg|jpeg|png|webp|gif)($|\?)', caseSensitive: false).hasMatch(lower);
  }

  /// Returns the thumbnail URL, defaulting to [videoUrl] if this is an image post.
  String? get thumbnailUrl {
    if (_thumbnailUrl != null && _thumbnailUrl!.trim().isNotEmpty) {
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
    // Base host without /api/v1
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
      caption: json['caption']?.toString() ?? '',
      videoUrl: resolvedVideoUrl,
      thumbnailUrl: resolvedThumbUrl,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      isLiked: (json['isLiked'] ?? json['liked']) == true,
      isSaved: (json['isSaved'] ?? json['saved']) == true,
      tags: tagsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'caption': caption,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'saveCount': saveCount,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  VideoModel copyWith({
    int? id,
    int? creatorId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    int? saveCount,
    bool? isLiked,
    bool? isSaved,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return VideoModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      caption: caption ?? this.caption,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? _thumbnailUrl,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      saveCount: saveCount ?? this.saveCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedLikes => _formatCount(likeCount);
  String get formattedComments => _formatCount(commentCount);
  String get formattedSaves => _formatCount(saveCount);
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
