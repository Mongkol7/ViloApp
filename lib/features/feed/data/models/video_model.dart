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
  final int? soundId;
  final String musicTitle;
  final String? musicArtist;
  final String? audioUrl;
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
  final String? _formattedViews;
  final List<String> mediaUrls;
  final List<String> imageUrls;

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
    this.soundId,
    this.musicTitle = 'Original Sound',
    this.musicArtist,
    this.audioUrl,
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
    this.imageUrls = const [],
    String? formattedLikes,
    String? formattedComments,
    String? formattedSaves,
    String? formattedViews,
    String? likes,
    String? comments,
    String? saves,
    String? views,
  })  : _thumbnailUrl = thumbnailUrl,
        _formattedLikes = formattedLikes ?? likes,
        _formattedComments = formattedComments ?? comments,
        _formattedSaves = formattedSaves ?? saves,
        _formattedViews = formattedViews ?? views;

  static bool isVideoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final lower = url.trim().toLowerCase();
    return RegExp(r'\.(mp4|mov|mkv|webm|avi|m4v)($|\?)', caseSensitive: false).hasMatch(lower);
  }

  static bool isImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final lower = url.trim().toLowerCase();
    return lower.contains('/uploads/photos/') ||
        RegExp(r'\.(jpg|jpeg|png|webp|gif)($|\?)', caseSensitive: false).hasMatch(lower);
  }

  /// Returns true if the media represents an image post rather than a video.
  bool get isImagePost {
    final lowerVideo = videoUrl.trim().toLowerCase();
    final lowerResolved = resolvedVideoUrl.trim().toLowerCase();
    final hasVideoExt = isVideoUrl(lowerVideo) || isVideoUrl(lowerResolved);

    // Filter genuine photos from imageUrls
    final validImages = imageUrls.where((u) => isImageUrl(u)).toSet().toList();

    // If videoUrl (or resolvedVideoUrl) is an mp4/mov/etc. video and imageUrls does not contain multiple distinct photo files,
    // it MUST be false!
    if (hasVideoExt && validImages.length <= 1) {
      return false;
    }

    if (validImages.isNotEmpty) return true;

    if (isImageUrl(lowerVideo) || isImageUrl(lowerResolved)) {
      return true;
    }

    return mediaUrls.any((u) => isImageUrl(u));
  }

  /// All resolved HTTP/asset media URLs for multi-image or single video posts.
  List<String> get resolvedMediaUrls {
    if (isImagePost) {
      if (imageUrls.isNotEmpty) {
        final imgs = imageUrls.where((u) => isImageUrl(u)).map((u) => resolveMediaUrl(u)).toList();
        if (imgs.isNotEmpty) return imgs;
      }
      if (mediaUrls.isNotEmpty) {
        final imgs = mediaUrls.where((u) => isImageUrl(u)).map((u) => resolveMediaUrl(u)).toList();
        if (imgs.isNotEmpty) return imgs;
      }
      if (isImageUrl(videoUrl)) {
        return [resolveMediaUrl(videoUrl)];
      }
    }
    if (videoUrl.trim().isNotEmpty) {
      return [resolveMediaUrl(videoUrl)];
    }
    return const [];
  }

  List<String> get resolvedImageUrls => resolvedMediaUrls;

  String get resolvedVideoUrl => resolveMediaUrl(videoUrl);

  String? get resolvedAudioUrl {
    if (audioUrl == null || audioUrl!.trim().isEmpty) return null;
    return resolveMediaUrl(audioUrl);
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
    final raw = videoUrl.trim();
    if (raw.startsWith('assets/videos/vid') && raw.endsWith('.mp4')) {
      final numStr = RegExp(r'vid(\d+)\.mp4').firstMatch(raw)?.group(1);
      if (numStr != null) {
        return 'assets/video_thumbnails/vid$numStr.jpg';
      }
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

    final rawImageUrls = <String>[];
    if (json['imageUrls'] is List) {
      for (final u in json['imageUrls']) {
        final s = u?.toString() ?? '';
        if (s.isNotEmpty && !isVideoUrl(s) && isImageUrl(s)) {
          rawImageUrls.add(s);
        }
      }
    } else if (json['imageUrls'] is String && json['imageUrls'].toString().trim().isNotEmpty) {
      for (final s in json['imageUrls'].toString().split(',')) {
        final clean = s.trim();
        if (clean.isNotEmpty && !isVideoUrl(clean) && isImageUrl(clean)) {
          rawImageUrls.add(clean);
        }
      }
    }

    final rawMediaUrls = <String>[];
    if (json['mediaUrls'] is List) {
      for (final u in json['mediaUrls']) {
        final s = u?.toString() ?? '';
        if (s.isNotEmpty && !isVideoUrl(s) && isImageUrl(s)) {
          rawMediaUrls.add(s);
        }
      }
    }

    if (rawMediaUrls.isEmpty && rawImageUrls.isNotEmpty) {
      rawMediaUrls.addAll(rawImageUrls);
    } else if (rawImageUrls.isEmpty && rawMediaUrls.isNotEmpty) {
      rawImageUrls.addAll(rawMediaUrls);
    }

    if (rawMediaUrls.isEmpty && rawVideoUrl.contains(',') && !isVideoUrl(rawVideoUrl)) {
      rawMediaUrls.addAll(
        rawVideoUrl
            .split(',')
            .map((u) => u.trim())
            .where((u) => u.isNotEmpty && isImageUrl(u)),
      );
      if (rawImageUrls.isEmpty) {
        rawImageUrls.addAll(rawMediaUrls);
      }
    }

    final resolvedVideoUrl = resolveMediaUrl(rawVideoUrl);
    String? resolvedThumbUrl = (rawThumbUrl != null && rawThumbUrl.trim().isNotEmpty)
        ? resolveMediaUrl(rawThumbUrl)
        : null;

    final isImg = !isVideoUrl(resolvedVideoUrl) &&
        (isImageUrl(resolvedVideoUrl) || rawImageUrls.isNotEmpty || rawMediaUrls.isNotEmpty);
    if (isImg && (resolvedThumbUrl == null || resolvedThumbUrl.isEmpty)) {
      resolvedThumbUrl = rawImageUrls.isNotEmpty
          ? resolveMediaUrl(rawImageUrls.first)
          : (rawMediaUrls.isNotEmpty ? resolveMediaUrl(rawMediaUrls.first) : resolvedVideoUrl);
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
      soundId: (json['soundId'] as num?)?.toInt(),
      musicTitle: json['musicName']?.toString() ?? json['musicTitle']?.toString() ?? 'Original Sound',
      musicArtist: json['musicArtist']?.toString(),
      audioUrl: json['audioUrl']?.toString(),
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
      imageUrls: rawImageUrls,
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
      'soundId': soundId,
      'musicTitle': musicTitle,
      'musicName': musicTitle,
      'musicArtist': musicArtist,
      'audioUrl': audioUrl,
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
      'imageUrls': imageUrls,
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
    int? soundId,
    String? musicTitle,
    String? musicName,
    String? musicArtist,
    String? audioUrl,
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
    List<String>? imageUrls,
    DateTime? createdAt,
    String? formattedLikes,
    String? formattedComments,
    String? formattedSaves,
    String? formattedViews,
    String? likes,
    String? comments,
    String? saves,
    String? views,
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
      soundId: soundId ?? this.soundId,
      musicTitle: musicTitle ?? musicName ?? this.musicTitle,
      musicArtist: musicArtist ?? this.musicArtist,
      audioUrl: audioUrl ?? this.audioUrl,
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
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      formattedLikes: formattedLikes ?? (likeCount != null ? null : (likes ?? _formattedLikes)),
      formattedComments: formattedComments ?? (commentCount != null ? null : (comments ?? _formattedComments)),
      formattedSaves: formattedSaves ?? (saveCount != null ? null : (saves ?? _formattedSaves)),
      formattedViews: formattedViews ?? (viewCount != null ? null : (views ?? _formattedViews)),
    );
  }

  String get musicName => musicTitle;

  String get likes => formattedLikes;
  String get comments => formattedComments;
  String get saves => formattedSaves;
  String get views => formattedViews;

  String get formattedLikes => (likeCount > 0 || _formattedLikes == null) ? _formatCount(likeCount) : _formattedLikes;
  String get formattedComments => (commentCount > 0 || _formattedComments == null) ? _formatCount(commentCount) : _formattedComments;
  String get formattedSaves => (saveCount > 0 || _formattedSaves == null) ? _formatCount(saveCount) : _formattedSaves;
  String get formattedViews => (viewCount > 0 || _formattedViews == null) ? _formatCount(viewCount) : _formattedViews;

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
