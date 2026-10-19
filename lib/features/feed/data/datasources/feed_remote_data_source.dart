import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../models/comment_model.dart';
import '../models/video_model.dart';

class FeedRemoteDataSource {
  static final FeedRemoteDataSource instance = FeedRemoteDataSource._();

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  final Map<String, List<VideoModel>> _feedCache = {};
  final Map<String, List<VideoModel>> _userVideosCache = {};

  FeedRemoteDataSource({ApiClient? client, TokenStorage? tokenStorage})
      : _client = client ?? ApiClient.instance,
        _tokenStorage = tokenStorage ?? TokenStorage.instance;

  FeedRemoteDataSource._()
      : _client = ApiClient.instance,
        _tokenStorage = TokenStorage.instance;

  List<VideoModel>? getCachedFeed(String feedType) {
    final clean = feedType.toLowerCase().replaceAll('_', '');
    return _feedCache[clean];
  }

  List<VideoModel>? getCachedUserVideos(dynamic identifier) {
    if (identifier == null) return null;
    final clean = identifier.toString().replaceAll('@', '').trim().toLowerCase();
    final cached = _userVideosCache[clean];
    if (cached != null && cached.isNotEmpty) {
      return List<VideoModel>.from(cached);
    }
    return null;
  }

  void cacheUserVideos(dynamic identifier, List<VideoModel> videos) {
    if (identifier == null || videos.isEmpty) return;
    final clean = identifier.toString().replaceAll('@', '').trim().toLowerCase();
    _userVideosCache[clean] = List<VideoModel>.from(videos);
  }

  void prependUserVideo(dynamic identifier, VideoModel video) {
    if (identifier == null) return;
    final clean = identifier.toString().replaceAll('@', '').trim().toLowerCase();
    _userVideosCache.putIfAbsent(clean, () => []);
    final list = _userVideosCache[clean]!;
    list.removeWhere((v) => v.id == video.id);
    list.insert(0, video);
  }

  void invalidateUserVideos(dynamic identifier) {
    if (identifier == null) return;
    final clean = identifier.toString().replaceAll('@', '').trim().toLowerCase();
    _userVideosCache.remove(clean);
  }

  /// Synchronize like, save, or comment changes across all in-memory caches instantly
  void updateCachedVideo({
    required int videoId,
    bool? isLiked,
    int? likeCount,
    bool? isSaved,
    int? saveCount,
    int? commentCount,
  }) {
    for (final key in _feedCache.keys) {
      final list = _feedCache[key];
      if (list != null) {
        for (int i = 0; i < list.length; i++) {
          if (list[i].id == videoId) {
            list[i] = list[i].copyWith(
              isLiked: isLiked,
              likeCount: likeCount,
              isSaved: isSaved,
              saveCount: saveCount,
              commentCount: commentCount,
            );
          }
        }
      }
    }

    for (final key in _userVideosCache.keys) {
      final list = _userVideosCache[key];
      if (list != null) {
        for (int i = 0; i < list.length; i++) {
          if (list[i].id == videoId) {
            list[i] = list[i].copyWith(
              isLiked: isLiked,
              likeCount: likeCount,
              isSaved: isSaved,
              saveCount: saveCount,
              commentCount: commentCount,
            );
          }
        }
      }
    }
  }

  /// Unified getFeed supporting pagination, cache, and both feedType and type parameters
  Future<List<VideoModel>> getFeed({
    int page = 0,
    int size = 10,
    String? type,
    String? feedType,
    bool forceRefresh = false,
  }) async {
    final rawType = (type ?? feedType ?? 'foryou').trim();
    final normalizedType = (rawType.toUpperCase() == 'FOLLOWING') ? 'following' : 'foryou';
    final cacheKey = normalizedType.replaceAll('_', '');

    if (!forceRefresh && page == 0 && _feedCache[cacheKey] != null && _feedCache[cacheKey]!.isNotEmpty) {
      return _feedCache[cacheKey]!;
    }

    try {
      final endpoint = '/videos/feed?page=$page&size=$size&type=$normalizedType';
      final response = await _client.get(endpoint, requireAuth: false);

      List<dynamic>? list;
      if (response is Map && response['videos'] is List) {
        list = response['videos'] as List;
      } else if (response is Map && response['data'] is Map && response['data']['videos'] is List) {
        list = response['data']['videos'] as List;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is List) {
        list = response;
      }

      if (list != null && list.isNotEmpty) {
        final videos = list
            .whereType<Map<String, dynamic>>()
            .map((item) => VideoModel.fromJson(item))
            .toList();

        if (page == 0) {
          _feedCache[cacheKey] = videos;
        }

        // Pre-cache user videos into _userVideosCache so opening their profiles is instantaneous
        for (final v in videos) {
          final uName = v.username.replaceAll('@', '').trim().toLowerCase();
          _userVideosCache.putIfAbsent(uName, () => []);
          if (!_userVideosCache[uName]!.any((x) => x.id == v.id)) {
            _userVideosCache[uName]!.add(v);
          }
          if (v.creatorId > 0) {
            final idStr = v.creatorId.toString();
            _userVideosCache.putIfAbsent(idStr, () => []);
            if (!_userVideosCache[idStr]!.any((x) => x.id == v.id)) {
              _userVideosCache[idStr]!.add(v);
            }
          }
        }

        return videos;
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Remote feed error: $e');
    }

    if (page == 0) {
      final fallback = _getFallbackFeed(normalizedType);
      _feedCache[cacheKey] = fallback;
      for (final v in fallback) {
        final uName = v.username.replaceAll('@', '').trim().toLowerCase();
        _userVideosCache.putIfAbsent(uName, () => []);
        if (!_userVideosCache[uName]!.any((x) => x.id == v.id)) {
          _userVideosCache[uName]!.add(v);
        }
      }
      return fallback;
    }

    return [];
  }

  /// Fetch single video by ID
  Future<VideoModel> getVideoById(int id) async {
    final response = await _client.get(
      '/videos/$id',
      requireAuth: true,
    );
    final data = (response is Map && response['data'] is Map)
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return VideoModel.fromJson(data);
  }

  /// Fetch creator videos for instant profile loading
  Future<List<VideoModel>> getUserVideos(dynamic identifier, {bool forceRefresh = false}) async {
    final clean = identifier.toString().replaceAll('@', '').trim().toLowerCase();
    if (!forceRefresh && _userVideosCache.containsKey(clean) && _userVideosCache[clean]!.isNotEmpty) {
      _fetchUserVideosFromNetwork(clean).catchError((_) => <VideoModel>[]);
      return List<VideoModel>.from(_userVideosCache[clean]!);
    }

    return await _fetchUserVideosFromNetwork(clean);
  }

  Future<List<VideoModel>> _fetchUserVideosFromNetwork(String clean) async {
    try {
      final endpoint = '/videos/user/$clean';
      final response = await _client.get(endpoint, requireAuth: false);

      List<dynamic>? list;
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is Map && response['videos'] is List) {
        list = response['videos'] as List;
      }

      if (list != null) {
        final videos = list
            .whereType<Map<String, dynamic>>()
            .map((item) => VideoModel.fromJson(item))
            .toList();
        _userVideosCache[clean] = videos;
        return videos;
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Get user videos error: $e');
    }

    return _userVideosCache[clean] ?? [];
  }

  /// Toggle follow creator
  Future<bool> toggleFollow(dynamic creatorId, {bool skipNotify = false}) async {
    try {
      final clean = creatorId.toString().replaceAll('@', '').trim();
      final response = await _client.post(
        '/users/$clean/follow',
        requireAuth: true,
      );
      bool isFollowing = false;
      if (response is Map && response['following'] != null) {
        isFollowing = response['following'] == true;
      }
      if (!skipNotify) {
        final numericId = int.tryParse(clean) ?? 0;
        ProfileSyncService.instance.notifyFollowChanged(
          targetUserId: numericId,
          isFollowing: isFollowing,
        );
      }
      return isFollowing;
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Toggle follow error: $e');
      return false;
    }
  }

  /// Toggle like status
  Future<Map<String, dynamic>> toggleLike(
    int videoId, {
    required bool currentlyLiked,
  }) async {
    final endpoint = '/videos/$videoId/like';
    final dynamic response;
    if (currentlyLiked) {
      response = await _client.delete(endpoint, requireAuth: true);
    } else {
      response = await _client.post(endpoint, requireAuth: true);
    }
    final data = (response is Map && response['data'] is Map)
        ? response['data'] as Map<String, dynamic>
        : (response is Map ? response : <String, dynamic>{});
    return {
      'isLiked': data['isLiked'] ?? !currentlyLiked,
      'likeCount': (data['likeCount'] as num?)?.toInt() ?? 0,
    };
  }

  /// Toggle save/bookmark status
  Future<Map<String, dynamic>> toggleSave(
    int videoId, {
    required bool currentlySaved,
  }) async {
    final endpoint = '/videos/$videoId/save';
    final dynamic response;
    if (currentlySaved) {
      response = await _client.delete(endpoint, requireAuth: true);
    } else {
      response = await _client.post(endpoint, requireAuth: true);
    }
    final data = (response is Map && response['data'] is Map)
        ? response['data'] as Map<String, dynamic>
        : (response is Map ? response : <String, dynamic>{});
    return {
      'isSaved': data['isSaved'] ?? !currentlySaved,
      'saveCount': (data['saveCount'] as num?)?.toInt() ?? 0,
    };
  }

  /// Fetch all real saved/bookmarked videos for the current user
  Future<List<VideoModel>> getSavedVideos() async {
    try {
      final response = await _client.get('/videos/saved', requireAuth: true);
      List<dynamic>? list;
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is Map && response['videos'] is List) {
        list = response['videos'] as List;
      }

      if (list != null) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => VideoModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Get saved videos error: $e');
    }
    return [];
  }

  /// Fetch all real liked videos for the current user or a specific user
  Future<List<VideoModel>> getLikedVideos({dynamic userId}) async {
    try {
      final endpoint = userId != null
          ? '/videos/user/${userId.toString().replaceAll('@', '').trim()}/liked'
          : '/videos/liked';
      final response = await _client.get(endpoint, requireAuth: userId == null);
      List<dynamic>? list;
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is Map && response['videos'] is List) {
        list = response['videos'] as List;
      }

      if (list != null) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => VideoModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Get liked videos error: $e');
    }
    return [];
  }

  /// Increment view count asynchronously
  Future<int> incrementView(int videoId) async {
    try {
      final response = await _client.post(
        '/videos/$videoId/view',
        requireAuth: false,
      );
      if (response is Map) {
        final data = response['data'] ?? response;
        if (data is Map && data['viewCount'] != null) {
          return (data['viewCount'] as num).toInt();
        }
      }
    } catch (_) {}
    return 0;
  }

  /// Fetch paginated comments for a video
  Future<List<CommentModel>> getComments(
    int videoId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      '/videos/$videoId/comments?page=$page&size=$size',
      requireAuth: false,
    );

    List<dynamic>? list;
    if (response is Map && response['comments'] is List) {
      list = response['comments'] as List;
    } else if (response is Map && response['data'] is Map && response['data']['comments'] is List) {
      list = response['data']['comments'] as List;
    } else if (response is List) {
      list = response;
    }

    if (list != null) {
      return list
          .whereType<Map<String, dynamic>>()
          .map((json) => CommentModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Post a new comment or reply
  Future<CommentModel> postComment(
    int videoId,
    String content, {
    int? parentId,
  }) async {
    final body = <String, dynamic>{
      'content': content.trim(),
    };
    if (parentId != null) {
      body['parentId'] = parentId;
    }

    final response = await _client.post(
      '/videos/$videoId/comments',
      body: body,
      requireAuth: true,
    );

    final data = (response is Map && response['data'] is Map)
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return CommentModel.fromJson(data);
  }

  /// Multipart video upload
  Future<VideoModel> uploadVideo({
    required String caption,
    String? videoPath,
    List<int>? videoBytes,
    String videoFilename = 'upload.mp4',
    List<String>? imagePaths,
    List<List<int>>? imageBytesList,
    List<String>? imageFilenames,
    String? thumbnailPath,
    List<int>? thumbnailBytes,
    String thumbnailFilename = 'thumbnail.jpg',
    List<String>? tags,
  }) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/videos/upload');
    final request = http.MultipartRequest('POST', uri);

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['caption'] = caption;

    // Handle tags (normalize, strip leading #, join by comma)
    final tagsList = <String>[];
    if (tags != null) {
      tagsList.addAll(
        tags
            .map((t) => t.replaceAll('#', '').trim())
            .where((t) => t.isNotEmpty),
      );
    }
    if (tagsList.isEmpty) {
      final matches = RegExp(r'#(\w+)').allMatches(caption);
      for (final m in matches) {
        final t = m.group(1);
        if (t != null && t.isNotEmpty && !tagsList.contains(t)) {
          tagsList.add(t);
        }
      }
    }
    if (tagsList.isNotEmpty) {
      request.fields['tags'] = tagsList.join(',');
    }

    // Media payload: multiple photos or single video/photo
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (int i = 0; i < imagePaths.length; i++) {
        final path = imagePaths[i].trim();
        final name = (imageFilenames != null && i < imageFilenames.length)
            ? imageFilenames[i]
            : path.split(Platform.pathSeparator).last;
        final file = File(path);
        if (file.existsSync()) {
          try {
            request.files.add(
              await http.MultipartFile.fromPath('photos', path, filename: name),
            );
          } catch (_) {
            final bytes = await file.readAsBytes();
            request.files.add(
              http.MultipartFile.fromBytes('photos', bytes, filename: name),
            );
          }
        } else if (imageBytesList != null && i < imageBytesList.length && imageBytesList[i].isNotEmpty) {
          request.files.add(
            http.MultipartFile.fromBytes('photos', imageBytesList[i], filename: name),
          );
        }
      }
    } else if (imageBytesList != null && imageBytesList.isNotEmpty) {
      for (int i = 0; i < imageBytesList.length; i++) {
        final bytes = imageBytesList[i];
        final name = (imageFilenames != null && i < imageFilenames.length) ? imageFilenames[i] : 'photo_$i.jpg';
        request.files.add(
          http.MultipartFile.fromBytes('photos', bytes, filename: name),
        );
      }
    } else if (videoPath != null && videoPath.trim().isNotEmpty) {
      final trimmedPath = videoPath.trim();
      final fileOnDisk = File(trimmedPath);

      if (fileOnDisk.existsSync()) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath(
              'videoFile',
              trimmedPath,
              filename: videoFilename.isNotEmpty ? videoFilename : trimmedPath.split(Platform.pathSeparator).last,
            ),
          );
        } catch (e) {
          debugPrint('[FeedRemoteDataSource] MultipartFile.fromPath failed, fallback to bytes: $e');
          final bytes = await fileOnDisk.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'videoFile',
              bytes,
              filename: videoFilename.isNotEmpty ? videoFilename : trimmedPath.split(Platform.pathSeparator).last,
            ),
          );
        }
      } else if (videoBytes != null && videoBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'videoFile',
            videoBytes,
            filename: videoFilename,
          ),
        );
      } else if (trimmedPath.startsWith('assets/')) {
        try {
          final byteData = await rootBundle.load(trimmedPath);
          final bytes = byteData.buffer.asUint8List();
          final name = trimmedPath.split('/').last;
          request.files.add(
            http.MultipartFile.fromBytes(
              'videoFile',
              bytes,
              filename: name.isNotEmpty ? name : videoFilename,
            ),
          );
        } catch (_) {}
      } else {
        request.fields['videoPath'] = trimmedPath;
      }
    } else if (videoBytes != null && videoBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'videoFile',
          videoBytes,
          filename: videoFilename,
        ),
      );
    } else {
      throw ApiResponseException('A video path or video/photo file(s) must be provided', 400);
    }

    // Thumbnail payload (optional)
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      final thumbOnDisk = File(thumbnailPath);
      if (thumbOnDisk.existsSync()) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath(
              'thumbnailFile',
              thumbnailPath,
              filename: thumbnailFilename.isNotEmpty ? thumbnailFilename : 'thumbnail.jpg',
            ),
          );
        } catch (e) {
          debugPrint('[FeedRemoteDataSource] Thumbnail fromPath failed: $e');
          final bytes = await thumbOnDisk.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'thumbnailFile',
              bytes,
              filename: thumbnailFilename,
            ),
          );
        }
      } else if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'thumbnailFile',
            thumbnailBytes,
            filename: thumbnailFilename,
          ),
        );
      } else if (thumbnailPath.startsWith('assets/')) {
        try {
          final byteData = await rootBundle.load(thumbnailPath);
          final bytes = byteData.buffer.asUint8List();
          final name = thumbnailPath.split('/').last;
          request.files.add(
            http.MultipartFile.fromBytes(
              'thumbnailFile',
              bytes,
              filename: name.isNotEmpty ? name : thumbnailFilename,
            ),
          );
        } catch (_) {}
      }
    } else if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'thumbnailFile',
          thumbnailBytes,
          filename: thumbnailFilename,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final data = json['data'] ?? json;
      final newVideo = VideoModel.fromJson(data as Map<String, dynamic>);

      // Prepend to creator's caches for instant profile grid display
      if (newVideo.creatorId > 0) {
        prependUserVideo(newVideo.creatorId, newVideo);
      }
      if (newVideo.username.isNotEmpty) {
        prependUserVideo(newVideo.username, newVideo);
      }

      return newVideo;
    } else {
      String errorMessage = 'Failed to upload video (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['message'] != null) {
          errorMessage = errJson['message'];
        }
      } catch (_) {}
      throw ApiResponseException(errorMessage, response.statusCode);
    }
  }

  List<VideoModel> _getFallbackFeed(String feedType) {
    final allVideos = [
      const VideoModel(
        id: 1,
        creatorId: 2,
        username: '@bunheng',
        displayName: 'Lim Bunheng',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid2.mp4',
        caption: 'Night walk through the neon streets #citylife #neon #cyberpunk',
        musicTitle: 'Cyberpunk Beats - Synthwave',
        likeCount: 890000,
        commentCount: 12100,
        saveCount: 85000,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 2,
        creatorId: 7,
        username: '@sophia_art',
        displayName: 'Sophia Vance',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid1.mp4',
        caption: 'The view from the top is breathtaking ⛰️ #mountains #visuals',
        musicTitle: 'Epic Mountain Theme - Hans Zimmer',
        likeCount: 2100000,
        commentCount: 110000,
        saveCount: 400000,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 3,
        creatorId: 10,
        username: '@davi_beats',
        displayName: 'David Miller',
        avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid3.mp4',
        caption: 'Found this hidden waterfall today! 🌿💧 #hiking #nature',
        musicTitle: 'Nature Sounds - Waterfall',
        likeCount: 340000,
        commentCount: 3200,
        saveCount: 20000,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 4,
        creatorId: 11,
        username: '@sarah_fit',
        displayName: 'Sarah Connor',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
        isVerified: false,
        videoUrl: 'assets/videos/vid4.mp4',
        caption: 'Morning workout done! 💪 HIIT session #fitness #gym',
        musicTitle: 'Workout Mix 2026 - DJ Flex',
        likeCount: 550000,
        commentCount: 8400,
        saveCount: 15000,
        isFollowing: false,
        isMe: false,
      ),
      const VideoModel(
        id: 5,
        creatorId: 9,
        username: '@linda_travel',
        displayName: 'Linda Chen',
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid2.mp4',
        caption: 'Peaceful morning on the lake 🛶 #lake #peace',
        musicTitle: 'Morning Coffee Acoustic - Indie Band',
        likeCount: 420000,
        commentCount: 5100,
        saveCount: 18000,
        isFollowing: false,
        isMe: false,
      ),
      const VideoModel(
        id: 6,
        creatorId: 16,
        username: '@kevin_tech',
        displayName: 'Kevin Zhang',
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid3.mp4',
        caption: 'Next-gen desk setup tour 🖥️ Minimal aesthetic #tech',
        musicTitle: 'Midnight City Pulse - Neon Dreams',
        likeCount: 310000,
        commentCount: 4200,
        saveCount: 31000,
        isFollowing: false,
        isMe: false,
      ),
      const VideoModel(
        id: 7,
        creatorId: 1,
        username: '@mongkol',
        displayName: 'Thoeung Sereymongkol',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid1.mp4',
        caption: 'Building modern reactive Flutter UI with Spring Boot #coding',
        musicTitle: 'Seven7 Team Anthem - Seven7 Beats',
        likeCount: 1200000,
        commentCount: 45200,
        saveCount: 120000,
        isFollowing: false,
        isMe: true,
      ),
    ];

    if (feedType.toLowerCase() == 'following') {
      return allVideos.where((v) => v.isFollowing).toList();
    }
    return allVideos;
  }
}
