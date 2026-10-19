import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../domain/entities/search_results.dart';
import 'static_search_data.dart';

class SearchRemoteDataSource {
  static final SearchRemoteDataSource instance = SearchRemoteDataSource._();
  SearchRemoteDataSource._();

  final ApiClient _client = ApiClient.instance;

  final List<String> _localHistory = [
    'neon aesthetic',
    'tokyo cyberpunk',
    'flutter ui',
    'seven7',
  ];

  Future<Map<String, dynamic>> search(String query, {String type = 'ALL'}) async {
    final cleanQuery = query.trim().replaceAll(RegExp(r'^[@#]+'), '');
    addSearchHistory(query.trim());
    try {
      final endpoint = '/search?q=${Uri.encodeComponent(cleanQuery)}&type=${Uri.encodeComponent(type)}';
      final response = await _client.get(endpoint, requireAuth: false);

      if (response != null && response['success'] == true && response['data'] != null) {
        final parsed = _parseSearchSummary(response['data'], isSearch: true);
        final List<TrendingVideo> remoteVideos = (parsed['trendingVideos'] as List?)?.cast<TrendingVideo>() ?? [];
        if (remoteVideos.isEmpty) {
          final local = _fallbackLocalSearch(query, type);
          parsed['trendingVideos'] = local['trendingVideos'];
        }
        return parsed;
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
      'accounts': _getSynchronizedAccounts(),
      'sounds': StaticSearchData.sounds,
      'hashtags': StaticSearchData.hashtags,
    };
  }

  Future<List<String>> getSearchHistory() async {
    try {
      final response = await _client.get('/search/history', requireAuth: true);
      if (response != null && response['success'] == true && response['data'] is List) {
        final remote = (response['data'] as List)
            .map((item) => item['query']?.toString() ?? '')
            .where((q) => q.isNotEmpty)
            .toList();
        if (remote.isNotEmpty) {
          return remote;
        }
      }
    } catch (e) {
      debugPrint('[SearchRemoteDataSource] History error: $e');
    }
    return List<String>.from(_localHistory);
  }

  void addSearchHistory(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    _localHistory.remove(trimmed);
    _localHistory.insert(0, trimmed);
    if (_localHistory.length > 12) {
      _localHistory.removeLast();
    }
  }

  void removeSearchHistory(String term) {
    _localHistory.remove(term.trim());
  }

  Future<void> clearSearchHistory() async {
    _localHistory.clear();
    try {
      await _client.delete('/search/history', requireAuth: true);
    } catch (e) {
      debugPrint('[SearchRemoteDataSource] Clear history error: $e');
    }
  }

  List<SearchAccount> _getSynchronizedAccounts() {
    final currentAvatar = ProfileSyncService.instance.currentUserAvatar;
    final currentDisplayName = ProfileSyncService.instance.currentUserDisplayName;

    return StaticSearchData.accounts.map((acc) {
      if (ProfileSyncService.instance.isCurrentUser(username: acc.username, id: acc.id)) {
        return acc.copyWith(
          avatarUrl: currentAvatar,
          displayName: currentDisplayName,
        );
      }
      return acc;
    }).toList();
  }

  Map<String, dynamic> _parseSearchSummary(Map<String, dynamic> data, {bool isSearch = false}) {
    final List<SearchAccount> accounts = [];
    if (data['users'] is List) {
      for (final u in data['users']) {
        final rawUsername = u['username']?.toString() ?? '';
        final username = rawUsername.startsWith('@') ? rawUsername : '@$rawUsername';
        final displayName = u['displayName']?.toString() ?? rawUsername;
        final count = u['followersCount'] is int ? u['followersCount'] as int : int.tryParse(u['followersCount']?.toString() ?? '0') ?? 0;
        final followers = '$count followers';

        final isMe = ProfileSyncService.instance.isCurrentUser(
          username: username,
          id: u['id']?.toString(),
        );
        final effectiveAvatar = isMe
            ? ProfileSyncService.instance.currentUserAvatar
            : ((u['avatarUrl'] != null && u['avatarUrl'].toString().isNotEmpty)
                ? u['avatarUrl'].toString()
                : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150');
        final effectiveDisplayName = isMe
            ? ProfileSyncService.instance.currentUserDisplayName
            : displayName;

        final isFollowing = isMe ? false : (u['isFollowing'] == true);
        final followsYou = isMe ? false : (u['followsYou'] == true);

        accounts.add(SearchAccount(
          id: u['id']?.toString() ?? '',
          username: username,
          displayName: effectiveDisplayName,
          followersCount: followers,
          avatarUrl: effectiveAvatar,
          isFollowed: isFollowing,
          followsYou: followsYou,
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
          authorUsername: v['authorUsername']?.toString() ?? '',
          authorName: v['authorName']?.toString() ?? '',
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
      'accounts': accounts.isNotEmpty ? accounts : _getSynchronizedAccounts(),
      'sounds': sounds.isNotEmpty ? sounds : StaticSearchData.sounds,
      'trendingVideos': videos.isNotEmpty ? videos : StaticSearchData.trendingVideos,
      'hashtags': hashtags.isNotEmpty ? hashtags : StaticSearchData.hashtags,
    };
  }

  /// Forgiving fuzzy matcher: handles partial words, substrings, tokens, and ignores symbols
  bool _matchesFuzzy(String target, String query) {
    if (query.isEmpty) return true;
    final t = target.toLowerCase();
    final q = query.toLowerCase();
    if (t.contains(q)) return true;

    final normT = t.replaceAll(RegExp(r'[@#_\.\-\s]+'), '');
    final normQ = q.replaceAll(RegExp(r'[@#_\.\-\s]+'), '');
    if (normQ.isNotEmpty && normT.contains(normQ)) return true;

    final tokens = q.split(RegExp(r'[\s_.\-]+')).where((tok) => tok.isNotEmpty).toList();
    if (tokens.isNotEmpty && tokens.every((tok) => t.contains(tok) || normT.contains(tok))) {
      return true;
    }

    // Match if any token is a prefix of any word in target
    final words = t.split(RegExp(r'[\s_.\-]+')).where((w) => w.isNotEmpty);
    for (final tok in tokens) {
      if (words.any((w) => w.startsWith(tok) || tok.startsWith(w))) {
        return true;
      }
    }

    return false;
  }

  Map<String, dynamic> _fallbackLocalSearch(String query, String type) {
    final cleanQ = query.trim().toLowerCase().replaceAll(RegExp(r'^[@#]+'), '');
    final synchronizedAccounts = _getSynchronizedAccounts();

    // 1. Match Accounts (flexible search by username or displayName)
    List<SearchAccount> filteredAccounts = [];
    if (type == 'ALL' || type == 'USERS') {
      filteredAccounts = synchronizedAccounts.where((a) {
        final u = a.username.toLowerCase().replaceAll('@', '');
        final d = a.displayName.toLowerCase();
        return _matchesFuzzy(u, cleanQ) || _matchesFuzzy(d, cleanQ);
      }).toList();
    }

    // 2. Match Sounds (by title or artist)
    List<SearchSound> filteredSounds = [];
    if (type == 'ALL' || type == 'SOUNDS') {
      filteredSounds = StaticSearchData.sounds.where((s) {
        return _matchesFuzzy(s.title, cleanQ) || _matchesFuzzy(s.artist, cleanQ);
      }).toList();
    }

    // 3. Match Hashtags
    List<String> filteredHashtags = [];
    if (type == 'ALL') {
      filteredHashtags = StaticSearchData.hashtags.where((tag) {
        return _matchesFuzzy(tag, cleanQ) || cleanQ.isEmpty;
      }).toList();
    }

    // 4. Match Videos:
    // - by title
    // - by author username or author display name (shows videos from that person if searching that user account!)
    // - by hashtag tags
    // - if an account was found, include all public videos authored by that person
    final matchedUsernames = filteredAccounts
        .map((a) => a.username.toLowerCase().replaceAll('@', ''))
        .toSet();

    List<TrendingVideo> filteredVideos = [];
    if (type == 'ALL' || type == 'VIDEOS') {
      filteredVideos = StaticSearchData.trendingVideos.where((v) {
        final vAuthor = v.authorUsername.toLowerCase().replaceAll('@', '');
        final vAuthorName = v.authorName.toLowerCase();

        if (matchedUsernames.contains(vAuthor)) return true;
        if (_matchesFuzzy(v.title, cleanQ)) return true;
        if (v.authorUsername.isNotEmpty && _matchesFuzzy(vAuthor, cleanQ)) return true;
        if (v.authorName.isNotEmpty && _matchesFuzzy(vAuthorName, cleanQ)) return true;
        if (v.tags.any((tag) => _matchesFuzzy(tag, cleanQ))) return true;
        return false;
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
