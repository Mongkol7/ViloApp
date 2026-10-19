import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/search_results.dart';
import 'static_search_data.dart';

class SearchRemoteDataSource {
  static final SearchRemoteDataSource instance = SearchRemoteDataSource._();
  SearchRemoteDataSource._();

  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> search(String query, {String type = 'ALL'}) async {
    try {
      final endpoint = '/search?q=${Uri.encodeComponent(query)}&type=${Uri.encodeComponent(type)}';
      final response = await _client.get(endpoint, requireAuth: false);

      if (response != null && response['success'] == true && response['data'] != null) {
        return _parseSearchSummary(response['data']);
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
        return _parseSearchSummary(response['data']);
      }
    } catch (e) {
      debugPrint('[SearchRemoteDataSource] Trending error: $e');
    }

    return {
      'trendingVideos': StaticSearchData.trendingVideos,
      'accounts': StaticSearchData.accounts,
      'sounds': StaticSearchData.sounds,
      'hashtags': <String>['#viloapp', '#flutterdev', '#tokyocoding', '#cambodiavibes', '#springsecurity'],
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

  Map<String, dynamic> _parseSearchSummary(Map<String, dynamic> data) {
    final List<SearchAccount> accounts = [];
    if (data['users'] is List) {
      for (final u in data['users']) {
        accounts.add(SearchAccount(
          id: u['id']?.toString() ?? '',
          username: u['username']?.toString() ?? '',
          followersCount: u['followersCount']?.toString() ?? '0 followers',
          avatarUrl: u['avatarUrl']?.toString() ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          isFollowed: u['isFollowing'] == true,
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

    return {
      'accounts': accounts.isNotEmpty ? accounts : StaticSearchData.accounts,
      'sounds': sounds.isNotEmpty ? sounds : StaticSearchData.sounds,
      'trendingVideos': videos.isNotEmpty ? videos : StaticSearchData.trendingVideos,
      'hashtags': hashtags.isNotEmpty ? hashtags : ['#viloapp', '#flutterdev', '#tokyocoding'],
    };
  }

  Map<String, dynamic> _fallbackLocalSearch(String query, String type) {
    final q = query.toLowerCase();
    final filteredAccounts = StaticSearchData.accounts
        .where((a) => a.username.toLowerCase().contains(q))
        .toList();

    final filteredSounds = StaticSearchData.sounds
        .where((s) => s.title.toLowerCase().contains(q) || s.artist.toLowerCase().contains(q))
        .toList();

    final filteredVideos = StaticSearchData.trendingVideos;

    return {
      'accounts': filteredAccounts,
      'sounds': filteredSounds,
      'trendingVideos': filteredVideos,
      'hashtags': ['#viloapp', '#flutterdev', '#tokyocoding'],
    };
  }
}
