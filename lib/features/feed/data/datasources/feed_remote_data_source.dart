import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/mock/profile_mock_data.dart';
import '../models/comment_model.dart';
import '../models/video_model.dart';

class FeedRemoteDataSource {
  static final FeedRemoteDataSource instance = FeedRemoteDataSource._();

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  final Map<String, List<VideoModel>> _feedCache = {};
  final Map<String, int> _feedCacheSeeds = {};
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

  List<VideoModel> getAllCachedVideos() {
    final Map<int, VideoModel> map = {};
    for (final list in _feedCache.values) {
      for (final v in list) {
        map[v.id] = v;
      }
    }
    for (final list in _userVideosCache.values) {
      for (final v in list) {
        map[v.id] = v;
      }
    }
    return map.values.toList();
  }

  void invalidateUserVideos(dynamic identifier) {
    if (identifier == null) return;
    final clean = identifier.toString().replaceAll('@', '').trim().toLowerCase();
    _userVideosCache.remove(clean);
  }

  void clearCache() {
    _feedCache.clear();
    _feedCacheSeeds.clear();
    _userVideosCache.clear();
  }

  /// Remove a video from all in-memory feed and user video caches
  void removeCachedVideo(int videoId) {
    for (final key in _feedCache.keys) {
      _feedCache[key]?.removeWhere((v) => v.id == videoId);
    }
    for (final key in _userVideosCache.keys) {
      _userVideosCache[key]?.removeWhere((v) => v.id == videoId);
    }
  }

  /// Delete video permanently from backend and purge from local caches
  Future<bool> deleteVideo(int videoId) async {
    try {
      await _client.delete(
        '/videos/$videoId',
        requireAuth: true,
      );
      removeCachedVideo(videoId);
      return true;
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Delete video error: $e');
      return false;
    }
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

  /// Unified getFeed supporting pagination, cache, seed, and creator interleaving
  Future<List<VideoModel>> getFeed({
    int page = 0,
    int size = 10,
    String? type,
    String? feedType,
    int? seed,
    bool forceRefresh = false,
  }) async {
    final rawType = (type ?? feedType ?? 'foryou').trim();
    final normalizedInput = rawType.toUpperCase();
    final normalizedType = normalizedInput == 'FOLLOWING' ? 'following' : 'foryou';
    // Community uses the same backend feed as For You, but must keep its own
    // cache so refreshing one top category never invalidates the other.
    final cacheKey = normalizedInput == 'COMMUNITY'
        ? 'community'
        : normalizedType.replaceAll('_', '');

    if (forceRefresh) {
      _feedCache.remove(cacheKey);
      _feedCacheSeeds.remove(cacheKey);
    }

    if (!forceRefresh && normalizedType != 'following' && page == 0 && _feedCache[cacheKey] != null && _feedCache[cacheKey]!.isNotEmpty) {
      if (seed == null || _feedCacheSeeds[cacheKey] == seed) {
        return _feedCache[cacheKey]!;
      }
    }

    try {
      final seedParam = (seed != null) ? '&seed=$seed' : '';
      final endpoint = '/videos/feed?page=$page&size=$size&type=$normalizedType$seedParam';
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

      if (list != null) {
        final rawVideos = list
            .whereType<Map<String, dynamic>>()
            .map((item) => VideoModel.fromJson(item))
            .toList();

        // Ensure creator interleaving is respected across creators
        final videos = (page == 0)
            ? interleaveAndRandomizeVideos(rawVideos, seed: seed)
            : rawVideos;

        if (page == 0) {
          _feedCache[cacheKey] = videos;
          if (seed != null) {
            _feedCacheSeeds[cacheKey] = seed;
          }
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

    if (normalizedType == 'following') {
      return [];
    }

    if (page == 0) {
      final fallback = _getFallbackFeed(normalizedType, seed: seed);
      _feedCache[cacheKey] = fallback;
      if (seed != null) {
        _feedCacheSeeds[cacheKey] = seed;
      }
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
      dynamic response;
      try {
        response = await _client.get('/users/$clean/videos', requireAuth: false);
      } catch (_) {
        response = await _client.get('/videos/user/$clean', requireAuth: false);
      }

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
    ProfileSyncService.instance.notifyInteraction();
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
    ProfileSyncService.instance.notifyInteraction();
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

  /// Delete a comment (author or video creator only)
  Future<bool> deleteComment(int videoId, int commentId) async {
    try {
      await _client.delete(
        '/videos/$videoId/comments/$commentId',
        requireAuth: true,
      );
      return true;
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Delete comment error: $e');
      return false;
    }
  }

  /// Fetch current user's posted videos
  Future<List<VideoModel>> getMyVideos() async {
    try {
      final response = await _client.get('/videos/my-videos', requireAuth: true);
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
      debugPrint('[FeedRemoteDataSource] Get my videos error: $e');
    }
    return [];
  }


  /// Fetch specific user's liked videos
  Future<List<VideoModel>> getUserLikedVideos(dynamic identifier) async {
    final clean = identifier.toString().replaceAll('@', '').trim();
    try {
      final response = await _client.get('/users/$clean/liked', requireAuth: true);
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
      debugPrint('[FeedRemoteDataSource] Get user liked videos error: $e');
    }
    return [];
  }


  /// Fetch specific user's bookmarked/saved videos
  Future<List<VideoModel>> getUserSavedVideos(dynamic identifier) async {
    final clean = identifier.toString().replaceAll('@', '').trim();
    try {
      final response = await _client.get('/users/$clean/saved', requireAuth: true);
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
      debugPrint('[FeedRemoteDataSource] Get user saved videos error: $e');
    }
    return [];
  }

  /// Fetch all available sounds for upload picker
  Future<List<SoundTrack>> getSounds() async {
    try {
      final response = await _client.get('/sounds', requireAuth: false);
      List<dynamic>? list;
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is Map && response['sounds'] is List) {
        list = response['sounds'] as List;
      }

      if (list != null) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => SoundTrack.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Get sounds error: $e');
    }
    return [];
  }

  /// Fetch current user's uploaded sounds
  Future<List<SoundTrack>> getMySounds() async {
    try {
      final response = await _client.get('/videos/my-sounds', requireAuth: true);
      List<dynamic>? list;
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is Map && response['sounds'] is List) {
        list = response['sounds'] as List;
      }

      if (list != null) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => SoundTrack.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Get my sounds error: $e');
    }
    return [];
  }

  /// Fetch specific user's uploaded sounds
  Future<List<SoundTrack>> getUserSounds(dynamic identifier) async {
    final clean = identifier.toString().replaceAll('@', '').trim();
    try {
      final response = await _client.get('/users/$clean/sounds', requireAuth: false);
      List<dynamic>? list;
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is Map && response['sounds'] is List) {
        list = response['sounds'] as List;
      }

      if (list != null) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => SoundTrack.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Get user sounds error: $e');
    }
    return [];
  }

  /// Fetch sound details and videos using this sound
  Future<Map<String, dynamic>> getSoundDetails(dynamic soundId) async {
    try {
      final response = await _client.get('/sounds/$soundId/videos', requireAuth: false);
      if (response is Map) {
        final rawSound = response['sound'] ?? response['soundTrack'] ?? response;
        final rawVideos = response['videos'] ?? (response['data'] is Map ? response['data']['videos'] : null);
        final sound = rawSound is Map<String, dynamic> ? SoundTrack.fromJson(rawSound) : null;
        final videos = (rawVideos is List)
            ? rawVideos.whereType<Map<String, dynamic>>().map((v) => VideoModel.fromJson(v)).toList()
            : <VideoModel>[];
        return {
          'sound': sound,
          'videos': videos,
        };
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Get sound details error: $e');
    }
    return {'sound': null, 'videos': <VideoModel>[]};
  }

  /// Fetch videos featuring a specific sound track
  Future<List<VideoModel>> getVideosBySound(String musicName) async {
    try {
      final endpoint = '/videos/by-sound?musicName=${Uri.encodeComponent(musicName)}';
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
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => VideoModel.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Get videos by sound error: $e');
    }
    return [];
  }

  /// Delete sound permanently from backend (owner only)
  Future<bool> deleteSound(String soundId) async {
    try {
      await _client.delete(
        '/sounds/$soundId',
        requireAuth: true,
      );
      return true;
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Delete sound error: $e');
      return false;
    }
  }

  /// Multipart sound/audio upload
  Future<SoundTrack> uploadSound({
    String? audioPath,
    List<int>? audioBytes,
    String audioFilename = 'sound.mp3',
    String? title,
    String? artist,
    String? coverPath,
    List<int>? coverBytes,
    String coverFilename = 'cover.jpg',
    String? coverUrl,
  }) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/sounds/upload');
    final request = http.MultipartRequest('POST', uri);

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (title != null && title.trim().isNotEmpty) {
      request.fields['title'] = title.trim();
    }
    if (artist != null && artist.trim().isNotEmpty) {
      request.fields['artist'] = artist.trim();
    }
    if (coverUrl != null && coverUrl.trim().isNotEmpty) {
      request.fields['coverUrl'] = coverUrl.trim();
    }

    if (audioPath != null && audioPath.trim().isNotEmpty) {
      final fileOnDisk = File(audioPath.trim());
      if (fileOnDisk.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('audioFile', fileOnDisk.path, filename: audioFilename),
        );
      } else if (audioBytes != null && audioBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes('audioFile', audioBytes, filename: audioFilename),
        );
      }
    } else if (audioBytes != null && audioBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes('audioFile', audioBytes, filename: audioFilename),
      );
    }

    if (coverPath != null && coverPath.trim().isNotEmpty) {
      final fileOnDisk = File(coverPath.trim());
      if (fileOnDisk.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('coverFile', fileOnDisk.path, filename: coverFilename),
        );
      } else if (coverBytes != null && coverBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes('coverFile', coverBytes, filename: coverFilename),
        );
      }
    } else if (coverBytes != null && coverBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes('coverFile', coverBytes, filename: coverFilename),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final data = json['data'] ?? json;
      return SoundTrack.fromJson(data as Map<String, dynamic>);
    }
    throw ApiResponseException('Sound upload failed: ${response.statusCode}', response.statusCode);
  }

  /// Update sound metadata and/or cover art via PATCH /sounds/{id}
  Future<SoundTrack?> updateSoundCover({
    required int soundId,
    String? title,
    String? coverPath,
    List<int>? coverBytes,
    String coverFilename = 'cover.jpg',
    String? coverUrl,
  }) async {
    try {
      final uri = Uri.parse('${ApiClient.baseUrl}/sounds/$soundId');
      final request = http.MultipartRequest('PATCH', uri);

      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (title != null && title.trim().isNotEmpty) {
        request.fields['title'] = title.trim();
      }
      if (coverUrl != null && coverUrl.trim().isNotEmpty) {
        request.fields['coverUrl'] = coverUrl.trim();
      }

      if (coverPath != null && coverPath.trim().isNotEmpty) {
        final fileOnDisk = File(coverPath.trim());
        if (fileOnDisk.existsSync()) {
          request.files.add(
            await http.MultipartFile.fromPath('coverFile', fileOnDisk.path, filename: coverFilename),
          );
        } else if (coverBytes != null && coverBytes.isNotEmpty) {
          request.files.add(
            http.MultipartFile.fromBytes('coverFile', coverBytes, filename: coverFilename),
          );
        }
      } else if (coverBytes != null && coverBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes('coverFile', coverBytes, filename: coverFilename),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
        if (data is Map<String, dynamic>) {
          return SoundTrack.fromJson(data);
        }
      } else {
        debugPrint('[FeedRemoteDataSource] Update sound cover error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Update sound cover exception: $e');
    }
    return null;
  }

  /// Multipart video upload
  Future<VideoModel> uploadVideo({
    required String caption,
    int? soundId,
    String? musicTitle,
    String? musicName,
    String? musicArtist,
    String? audioUrl,
    String? audioPath,
    List<int>? audioBytes,
    String audioFilename = 'music.mp3',
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

    if (soundId != null && soundId > 0) {
      request.fields['soundId'] = soundId.toString();
    }

    final soundTitle = (musicTitle != null && musicTitle.trim().isNotEmpty)
        ? musicTitle.trim()
        : (musicName != null && musicName.trim().isNotEmpty ? musicName.trim() : null);
    if (soundTitle != null) {
      request.fields['musicTitle'] = soundTitle;
      request.fields['musicName'] = soundTitle;
    }
    if (musicArtist != null && musicArtist.trim().isNotEmpty) {
      request.fields['musicArtist'] = musicArtist.trim();
    }
    if (audioUrl != null && audioUrl.trim().isNotEmpty) {
      request.fields['audioUrl'] = audioUrl.trim();
    }

    // Audio file payload (optional uploaded music)
    if (audioPath != null && audioPath.trim().isNotEmpty) {
      final audioOnDisk = File(audioPath.trim());
      if (audioOnDisk.existsSync()) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath(
              'audioFile',
              audioOnDisk.path,
              filename: audioFilename.isNotEmpty ? audioFilename : audioOnDisk.path.split(Platform.pathSeparator).last,
            ),
          );
        } catch (e) {
          debugPrint('[FeedRemoteDataSource] Audio fromPath failed: $e');
          final bytes = await audioOnDisk.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'audioFile',
              bytes,
              filename: audioFilename,
            ),
          );
        }
      } else if (audioBytes != null && audioBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'audioFile',
            audioBytes,
            filename: audioFilename,
          ),
        );
      }
    } else if (audioBytes != null && audioBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'audioFile',
          audioBytes,
          filename: audioFilename,
        ),
      );
    }

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
      ProfileSyncService.instance.notifyInteraction();
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

  /// Shuffles and round-robin interleaves videos across distinct creators.
  /// Ensures consecutive videos are not by the same user, and feed order is randomized.
  List<VideoModel> interleaveAndRandomizeVideos(List<VideoModel> videos, {int? seed}) {
    if (videos.isEmpty) return videos;

    final random = (seed != null) ? math.Random(seed) : math.Random();

    // 1. Group videos by creator identifier (creatorId or username)
    final byCreator = <String, List<VideoModel>>{};
    for (final v in videos) {
      final key = v.creatorId > 0
          ? v.creatorId.toString()
          : (v.username.isNotEmpty ? v.username.toLowerCase() : v.id.toString());
      byCreator.putIfAbsent(key, () => []).add(v);
    }

    // 2. Shuffle videos within each creator's list
    for (final list in byCreator.values) {
      list.shuffle(random);
    }

    // 3. Shuffle creator order
    final queues = byCreator.values.toList()..shuffle(random);

    // 4. Interleave round-robin across creators
    final result = <VideoModel>[];
    bool hasMore = true;
    while (hasMore) {
      hasMore = false;
      for (final queue in queues) {
        if (queue.isNotEmpty) {
          result.add(queue.removeAt(0));
          if (queue.isNotEmpty) {
            hasMore = true;
          }
        }
      }
    }
    return result;
  }

  List<VideoModel> _getFallbackFeed(String feedType, {int? seed}) {
    final allVideos = [
      const VideoModel(
        id: 1,
        creatorId: 1,
        username: '@mongkol',
        displayName: 'Thoeung Sereymongkol',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid1.mp4',
        caption: 'Building responsive Flutter UI with Spring Boot 🚀 #coding #flutterdev #vilo',
        musicTitle: 'Original Sound - Thoeung Sereymongkol',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: true,
      ),
      const VideoModel(
        id: 2,
        creatorId: 2,
        username: '@bunheng',
        displayName: 'Lim Bunheng',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid9.mp4',
        caption: '60fps video engine rendering benchmarks 🚀 #tech #videoengine #performance',
        musicTitle: 'High FPS Pulse - Seven7',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 3,
        creatorId: 8,
        username: '@rithysak',
        displayName: 'Sok Rithysak',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid3.mp4',
        caption: 'Designing smooth micro-animations in Flutter 🎨 #ui #flutter #animation',
        musicTitle: 'Smooth Motion Beats - Seven7',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 4,
        creatorId: 9,
        username: '@setkimliza',
        displayName: 'Set Kimliza',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid5.mp4',
        caption: 'Coffee shop morning aesthetics & Lo-Fi ☕ #coffee #vibes #morning',
        musicTitle: 'Rainy Day Acoustic - LoFi',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 5,
        creatorId: 10,
        username: '@trenmono',
        displayName: 'Tren Mono',
        avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid7.mp4',
        caption: 'Analog modular synth jam session in the lab 🎛️ #synth #modular #beats',
        musicTitle: 'Analog Pulse - Tren Mono',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 6,
        creatorId: 25,
        username: '@tryphien',
        displayName: 'Try Phien',
        avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid11.mp4',
        caption: 'Next-gen creative setup tour 🖥️ Minimal aesthetic #creativesetup #tech',
        musicTitle: 'Creative Waves - LoFi',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 7,
        creatorId: 26,
        username: '@nenseanghai',
        displayName: 'Nen Seanghai',
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid13.mp4',
        caption: 'Designing clean responsive layouts & mobile interactions 📱 #flutterdev #uiux',
        musicTitle: 'Motion Design Beats',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 8,
        creatorId: 1,
        username: '@mongkol',
        displayName: 'Thoeung Sereymongkol',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid2.mp4',
        caption: 'Late night coding session & neon vibes 🌃 #developer #tech #viloapp',
        musicTitle: 'Midnight City Pulse - Neon Dreams',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: true,
      ),
      const VideoModel(
        id: 9,
        creatorId: 8,
        username: '@rithysak',
        displayName: 'Sok Rithysak',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid4.mp4',
        caption: 'Weekend mountain trail ride 🚴 #nature #adventure #outdoor',
        musicTitle: 'Open Road Acoustic',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 10,
        creatorId: 9,
        username: '@setkimliza',
        displayName: 'Set Kimliza',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid6.mp4',
        caption: 'Golden hour city stroll after rain 🌧️✨ #aesthetic #mood #vilo',
        musicTitle: 'After The Rain - Chillhop',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 11,
        creatorId: 10,
        username: '@trenmono',
        displayName: 'Tren Mono',
        avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid8.mp4',
        caption: 'Minimalist architecture walk in the city 🏢 #architecture #design #minimalism',
        musicTitle: 'Mono Wave Vol 1',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 12,
        creatorId: 2,
        username: '@bunheng',
        displayName: 'Lim Bunheng',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid10.mp4',
        caption: 'Cyberpunk neon street walk at night #citylife #neon #cyberpunk',
        musicTitle: 'Cyberpunk Beats - Synthwave',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 13,
        creatorId: 25,
        username: '@tryphien',
        displayName: 'Try Phien',
        avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid12.mp4',
        caption: 'Exploring neon night streets & cinematic moments 🌆 #cinematic #night #vilo',
        musicTitle: 'Night Drive - Ambient',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
      const VideoModel(
        id: 14,
        creatorId: 26,
        username: '@nenseanghai',
        displayName: 'Nen Seanghai',
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid14.mp4',
        caption: 'Sunset vibes by the river with acoustic melodies 🌅🎸 #sunset #acoustic #chill',
        musicTitle: 'Sunset Glow - Acoustic',
        likeCount: 0,
        commentCount: 0,
        saveCount: 0,
        isFollowing: true,
        isMe: false,
      ),
    ];

    final filtered = (feedType.toLowerCase() == 'following')
        ? allVideos.where((v) => v.isFollowing && !v.isMe).toList()
        : allVideos;

    return interleaveAndRandomizeVideos(filtered, seed: seed);
  }
}
