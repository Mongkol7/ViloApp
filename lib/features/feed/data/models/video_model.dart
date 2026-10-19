// ignore_for_file: prefer_initializing_formals
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/token_storage.dart';

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
  final List<String> mediaUrls;

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
    this.mediaUrls = const [],
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
    if (lower.contains('/uploads/photos/') ||
        RegExp(r'\.(jpg|jpeg|png|webp|gif)($|\?|,)', caseSensitive: false).hasMatch(lower)) {
      return true;
    }
    return mediaUrls.any((u) {
      final l = u.toLowerCase();
      return l.contains('/uploads/photos/') ||
          RegExp(r'\.(jpg|jpeg|png|webp|gif)($|\?|,)', caseSensitive: false).hasMatch(l);
    });
  }

  /// All resolved HTTP/asset media URLs for multi-image or single video posts.
  List<String> get resolvedMediaUrls {
    if (mediaUrls.isNotEmpty) {
      return mediaUrls.map((u) => resolveMediaUrl(u)).where((u) => u.isNotEmpty).toList();
    }
    if (videoUrl.contains(',')) {
      return videoUrl
          .split(',')
          .map((u) => resolveMediaUrl(u.trim()))
          .where((u) => u.isNotEmpty)
          .toList();
    }
    if (videoUrl.trim().isNotEmpty) {
      return [resolveMediaUrl(videoUrl)];
    }
    return const [];
  }

  /// Returns true if this video/post was created by the currently authenticated user.
  bool get isOwner {
    if (isMe) return true;
    final currentUser = TokenStorage.instance.getUserModel();
    if (currentUser != null) {
      if (currentUser.id > 0 && creatorId > 0 && currentUser.id == creatorId) return true;
      final myName = currentUser.username.replaceAll('@', '').trim().toLowerCase();
      final postName = username.replaceAll('@', '').trim().toLowerCase();
      if (myName.isNotEmpty && myName == postName) return true;
    }
    return false;
  }

  /// Returns true if this post contains 2 or more carousel photos.
  bool get isMultiImagePost => isImagePost && resolvedMediaUrls.length > 1;

  /// Returns the thumbnail URL, defaulting to the first image if this is an image post.
  String? get thumbnailUrl {
    if (_thumbnailUrl != null && _thumbnailUrl.trim().isNotEmpty) {
      return _thumbnailUrl;
    }
    if (isImagePost) {
      final list = resolvedMediaUrls;
      return list.isNotEmpty ? list.first : videoUrl;
    }
    return null;
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

  /// Resolves any media URL (including assets/...) to an absolute backend HTTP streaming URL
  static String toNetworkMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final clean = url.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
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

    final rawMediaUrls = (json['mediaUrls'] is List)
        ? (json['mediaUrls'] as List).map((u) => u.toString()).toList()
        : <String>[];

    if (rawMediaUrls.isEmpty && rawVideoUrl.contains(',')) {
      rawMediaUrls.addAll(
        rawVideoUrl
            .split(',')
            .map((u) => u.trim())
            .where((u) => u.isNotEmpty),
      );
    }

    final resolvedVideoUrl = resolveMediaUrl(rawVideoUrl);
    String? resolvedThumbUrl = (rawThumbUrl != null && rawThumbUrl.trim().isNotEmpty)
        ? resolveMediaUrl(rawThumbUrl)
        : null;

    final isImg = resolvedVideoUrl.toLowerCase().contains('/uploads/photos/') ||
        RegExp(r'\.(jpg|jpeg|png|webp|gif)($|\?)', caseSensitive: false).hasMatch(resolvedVideoUrl) ||
        rawMediaUrls.isNotEmpty;
    if (isImg && (resolvedThumbUrl == null || resolvedThumbUrl.isEmpty)) {
      resolvedThumbUrl = rawMediaUrls.isNotEmpty
          ? resolveMediaUrl(rawMediaUrls.first)
          : resolvedVideoUrl;
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
      mediaUrls: rawMediaUrls,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      formattedLikes: null,
      formattedComments: null,
      formattedSaves: null,
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
      'mediaUrls': mediaUrls,
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
    List<String>? mediaUrls,
    DateTime? createdAt,
    String? formattedLikes,
    String? formattedComments,
    String? formattedSaves,
    String? likes,
    String? comments,
    String? saves,
  }) {
    final nextLikeCount = likeCount ?? this.likeCount;
    final nextCommentCount = commentCount ?? this.commentCount;
    final nextSaveCount = saveCount ?? this.saveCount;

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
      likeCount: nextLikeCount,
      commentCount: nextCommentCount,
      saveCount: nextSaveCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      isMe: isMe ?? this.isMe,
      tags: tags ?? this.tags,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt ?? this.createdAt,
      formattedLikes: formattedLikes ?? (likeCount != null ? null : (likes ?? _formattedLikes)),
      formattedComments: formattedComments ?? (commentCount != null ? null : (comments ?? _formattedComments)),
      formattedSaves: formattedSaves ?? (saveCount != null ? null : (saves ?? _formattedSaves)),
    );
  }

  String get likes => formattedLikes;
  String get comments => formattedComments;
  String get saves => formattedSaves;

  String get formattedLikes => (likeCount > 0 || _formattedLikes == null) ? _formatCount(likeCount) : _formattedLikes;
  String get formattedComments => (commentCount > 0 || _formattedComments == null) ? _formatCount(commentCount) : _formattedComments;
  String get formattedSaves => (saveCount > 0 || _formattedSaves == null) ? _formatCount(saveCount) : _formattedSaves;
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
