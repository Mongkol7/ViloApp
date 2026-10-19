import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/search_results.dart';
import 'static_search_data.dart';

class SearchRemoteDataSource {
  static final SearchRemoteDataSource instance = SearchRemoteDataSource._();
  SearchRemoteDataSource._();

  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> search(String query, {String type = 'ALL'}) async {
    final cleanQuery = query.trim().replaceAll(RegExp(r'^@+'), '');
    try {
      final endpoint = '/search?q=${Uri.encodeComponent(cleanQuery)}&type=${Uri.encodeComponent(type)}';
      final response = await _client.get(endpoint, requireAuth: false);

      if (response != null && response['success'] == true && response['data'] != null) {
        return _parseSearchSummary(response['data'], isSearch: true);
      }
    } catch (e) {
      debugPrint('[SearchRemoteDataSource] Live search error, falling back to local: $e');
    }

    return _fallbackLocalSearch(query, type);
  }

  Future<Map<String, dynamic>> getTrendingExplore() async {
    try {
      final response = await _client.get('/explore/trending', requireAuth: false);
      if (response != null && response['success'] == true && response['data'] != null) {
        return _parseSearchSummary(response['data'], isSearch: false);
      }
    } catch (e) {
      debugPrint('[SearchRemoteDataSource] Trending error: $e');
    }

    return {
      'trendingVideos': StaticSearchData.trendingVideos,
      'accounts': StaticSearchData.accounts,
      'sounds': StaticSearchData.sounds,
      'hashtags': StaticSearchData.hashtags,
    };
  }

  Future<List<String>> getSearchHistory() async {
    try {
      final response = await _client.get('/search/history', requireAuth: true);
      if (response != null && response['success'] == true && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => item['query']?.toString() ?? '')
            .where((q) => q.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('[SearchRemoteDataSource] History error: $e');
    }
    return ['neon aesthetic', 'tokyo cyberpunk', 'flutter ui', 'seven7'];
  }

  Future<void> clearSearchHistory() async {
    try {
      await _client.delete('/search/history', requireAuth: true);
    } catch (e) {
      debugPrint('[SearchRemoteDataSource] Clear history error: $e');
    }
  }

  Map<String, dynamic> _parseSearchSummary(Map<String, dynamic> data, {bool isSearch = false}) {
    final List<SearchAccount> accounts = [];
    if (data['users'] is List) {
      for (final u in data['users']) {
        final rawUsername = u['username']?.toString() ?? '';
        final username = rawUsername.startsWith('@') ? rawUsername : '@$rawUsername';
        final displayName = u['displayName']?.toString() ?? rawUsername;
        final followers = u['followersCount'] != null && u['followersCount'] != 0
            ? '${u['followersCount']} followers'
            : (u['followerCountFormatted']?.toString() ?? '12.4K followers');

        accounts.add(SearchAccount(
          id: u['id']?.toString() ?? '',
          username: username,
          displayName: displayName,
          followersCount: followers,
          avatarUrl: u['avatarUrl']?.toString() ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          isFollowed: u['isFollowing'] == true,
          isVerified: u['isVerified'] == true,
        ));
      }
    }

    final List<SearchSound> sounds = [];
    if (data['sounds'] is List) {
      for (final s in data['sounds']) {
        sounds.add(SearchSound(
          id: s['id']?.toString() ?? '',
          title: s['title']?.toString() ?? 'Original Sound',
          videosCount: s['formattedUsageCount']?.toString() ?? '${s['usageCount'] ?? 0} videos',
          iconType: 'music',
          artist: s['artist']?.toString() ?? 'Artist',
          audioUrl: s['audioUrl']?.toString() ?? '',
          albumArtUrl: s['albumArtUrl']?.toString() ?? '',
        ));
      }
    }

    final List<TrendingVideo> videos = [];
    if (data['trendingVideos'] is List) {
      for (final v in data['trendingVideos']) {
        videos.add(TrendingVideo(
          id: v['id']?.toString() ?? '',
          title: v['title']?.toString() ?? '',
          thumbnailUrl: v['thumbnailUrl']?.toString() ?? '',
          views: v['views']?.toString() ?? '1.2M',
        ));
      }
    }

    final List<String> hashtags = [];
    if (data['hashtags'] is List) {
      for (final h in data['hashtags']) {
        hashtags.add(h['formattedTag']?.toString() ?? '#${h['tag']}');
      }
    }

    if (isSearch) {
      return {
        'accounts': accounts,
        'sounds': sounds,
        'trendingVideos': videos,
        'hashtags': hashtags,
      };
    }

    return {
      'accounts': accounts.isNotEmpty ? accounts : StaticSearchData.accounts,
      'sounds': sounds.isNotEmpty ? sounds : StaticSearchData.sounds,
      'trendingVideos': videos.isNotEmpty ? videos : StaticSearchData.trendingVideos,
      'hashtags': hashtags.isNotEmpty ? hashtags : StaticSearchData.hashtags,
    };
  }

  Map<String, dynamic> _fallbackLocalSearch(String query, String type) {
    final cleanQ = query.trim().toLowerCase().replaceAll(RegExp(r'^[@#]+'), '');

    // 1. Match Accounts (by username without @, or by displayName)
    List<SearchAccount> filteredAccounts = [];
    if (type == 'ALL' || type == 'USERS') {
      filteredAccounts = StaticSearchData.accounts.where((a) {
        final u = a.username.toLowerCase().replaceAll('@', '');
        final d = a.displayName.toLowerCase();
        return u.contains(cleanQ) || d.contains(cleanQ);
      }).toList();
    }

    // 2. Match Sounds (by title or artist)
    List<SearchSound> filteredSounds = [];
    if (type == 'ALL' || type == 'SOUNDS') {
      filteredSounds = StaticSearchData.sounds.where((s) {
        final t = s.title.toLowerCase();
        final a = s.artist.toLowerCase();
        return t.contains(cleanQ) || a.contains(cleanQ);
      }).toList();
    }

    // 3. Match Hashtags
    List<String> filteredHashtags = [];
    if (type == 'ALL') {
      filteredHashtags = StaticSearchData.hashtags.where((tag) {
        return tag.toLowerCase().replaceAll('#', '').contains(cleanQ);
      }).toList();
    }

    // 4. Match Videos (by title or show sample if generic)
    List<TrendingVideo> filteredVideos = [];
    if (type == 'ALL' || type == 'VIDEOS') {
      filteredVideos = StaticSearchData.trendingVideos.where((v) {
        final t = v.title.toLowerCase();
        return t.contains(cleanQ);
      }).toList();
    }

    return {
      'accounts': filteredAccounts,
      'sounds': filteredSounds,
      'trendingVideos': filteredVideos,
      'hashtags': filteredHashtags,
    };
  }
}
