import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../models/video_feed_model.dart';

class FeedRemoteDataSource {
  static final FeedRemoteDataSource instance = FeedRemoteDataSource._();
  FeedRemoteDataSource._();

  final ApiClient _client = ApiClient.instance;

  final Map<String, List<VideoFeedModel>> _feedCache = {};
  final Map<String, List<VideoFeedModel>> _userVideosCache = {};

  List<VideoFeedModel>? getCachedFeed(String feedType) => _feedCache[feedType];

  List<VideoFeedModel>? getCachedUserVideos(dynamic identifier) {
    if (identifier == null) return null;
    final clean = identifier.toString().replaceAll('@', '').trim().toLowerCase();
    final cached = _userVideosCache[clean];
    if (cached != null && cached.isNotEmpty) {
      return List<VideoFeedModel>.from(cached);
    }
    return null;
  }

  void cacheUserVideos(dynamic identifier, List<VideoFeedModel> videos) {
    if (identifier == null || videos.isEmpty) return;
    final clean = identifier.toString().replaceAll('@', '').trim().toLowerCase();
    _userVideosCache[clean] = List<VideoFeedModel>.from(videos);
  }

  Future<List<VideoFeedModel>> getFeed({required String feedType, bool forceRefresh = false}) async {
    if (!forceRefresh && _feedCache[feedType] != null && _feedCache[feedType]!.isNotEmpty) {
      return _feedCache[feedType]!;
    }

    try {
      final endpoint = '/videos/feed?type=${Uri.encodeComponent(feedType)}';
      final response = await _client.get(endpoint, requireAuth: false);

      List<dynamic>? list;
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      }

      if (list != null && list.isNotEmpty) {
        final videos = list
            .map((item) => VideoFeedModel.fromJson(item as Map<String, dynamic>))
            .toList();

        _feedCache[feedType] = videos;

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
      debugPrint('[FeedRemoteDataSource] Remote feed error, using local fallback: $e');
    }

    final fallback = _getFallbackFeed(feedType);
    _feedCache[feedType] = fallback;
    for (final v in fallback) {
      final uName = v.username.replaceAll('@', '').trim().toLowerCase();
      _userVideosCache.putIfAbsent(uName, () => []);
      if (!_userVideosCache[uName]!.any((x) => x.id == v.id)) {
        _userVideosCache[uName]!.add(v);
      }
    }
    return fallback;
  }

  Future<List<VideoFeedModel>> getUserVideos(dynamic identifier) async {
    final clean = identifier.toString().replaceAll('@', '').trim().toLowerCase();
    try {
      final endpoint = '/videos/user/$clean';
      final response = await _client.get(endpoint, requireAuth: false);

      List<dynamic>? list;
      if (response is List) {
        list = response;
      } else if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      }

      if (list != null && list.isNotEmpty) {
        final videos = list
            .map((item) => VideoFeedModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _userVideosCache[clean] = videos;
        return videos;
      }
    } catch (e) {
      debugPrint('[FeedRemoteDataSource] Get user videos error: $e');
    }

    // Return cached if available on error or empty
    return _userVideosCache[clean] ?? [];
  }

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

  List<VideoFeedModel> _getFallbackFeed(String feedType) {
    final allVideos = [
      VideoFeedModel(
        id: 1,
        creatorId: 2,
        username: '@bunheng',
        displayName: 'Lim Bunheng',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid2.mp4',
        caption: 'Night walk through the neon streets #citylife #neon #cyberpunk',
        musicTitle: 'Cyberpunk Beats - Synthwave',
        likes: '890K',
        comments: '12.1K',
        saves: '85K',
        isFollowing: true, // Default followed by mongkol
        isMe: false,
      ),
      VideoFeedModel(
        id: 2,
        creatorId: 7,
        username: '@sophia_art',
        displayName: 'Sophia Vance',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid1.mp4',
        caption: 'The view from the top is breathtaking ⛰️ #mountains #visuals',
        musicTitle: 'Epic Mountain Theme - Hans Zimmer',
        likes: '2.1M',
        comments: '110K',
        saves: '400K',
        isFollowing: true, // Default followed by mongkol
        isMe: false,
      ),
      VideoFeedModel(
        id: 3,
        creatorId: 10,
        username: '@davi_beats',
        displayName: 'David Miller',
        avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid3.mp4',
        caption: 'Found this hidden waterfall today! 🌿💧 #hiking #nature',
        musicTitle: 'Nature Sounds - Waterfall',
        likes: '340K',
        comments: '3.2K',
        saves: '20K',
        isFollowing: true, // Default followed by mongkol
        isMe: false,
      ),
      VideoFeedModel(
        id: 4,
        creatorId: 11,
        username: '@sarah_fit',
        displayName: 'Sarah Connor',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
        isVerified: false,
        videoUrl: 'assets/videos/vid4.mp4',
        caption: 'Morning workout done! 💪 HIIT session #fitness #gym',
        musicTitle: 'Workout Mix 2026 - DJ Flex',
        likes: '550K',
        comments: '8.4K',
        saves: '15K',
        isFollowing: false,
        isMe: false,
      ),
      VideoFeedModel(
        id: 5,
        creatorId: 9,
        username: '@linda_travel',
        displayName: 'Linda Chen',
        avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid2.mp4',
        caption: 'Peaceful morning on the lake 🛶 #lake #peace',
        musicTitle: 'Morning Coffee Acoustic - Indie Band',
        likes: '420K',
        comments: '5.1K',
        saves: '18K',
        isFollowing: false,
        isMe: false,
      ),
      VideoFeedModel(
        id: 6,
        creatorId: 16,
        username: '@kevin_tech',
        displayName: 'Kevin Zhang',
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid3.mp4',
        caption: 'Next-gen desk setup tour 🖥️ Minimal aesthetic #tech',
        musicTitle: 'Midnight City Pulse - Neon Dreams',
        likes: '310K',
        comments: '4.2K',
        saves: '31K',
        isFollowing: false,
        isMe: false,
      ),
      VideoFeedModel(
        id: 7,
        creatorId: 1,
        username: '@mongkol',
        displayName: 'Thoeung Sereymongkol',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
        isVerified: true,
        videoUrl: 'assets/videos/vid1.mp4',
        caption: 'Building modern reactive Flutter UI with Spring Boot #coding',
        musicTitle: 'Seven7 Team Anthem - Seven7 Beats',
        likes: '1.2M',
        comments: '45.2K',
        saves: '120K',
        isFollowing: false,
        isMe: true,
      ),
    ];

    if (feedType.toUpperCase() == 'FOLLOWING') {
      return allVideos.where((v) => v.isFollowing).toList();
    }
    return allVideos;
  }
}
