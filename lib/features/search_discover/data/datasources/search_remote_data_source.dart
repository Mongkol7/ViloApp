import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/data/models/video_model.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../domain/entities/search_results.dart';
import 'static_search_data.dart';

class SearchRemoteDataSource {
  static final SearchRemoteDataSource instance = SearchRemoteDataSource._();
  SearchRemoteDataSource._() {
    _loadPersistedHistory();
  }

  final ApiClient _client = ApiClient.instance;

  List<String> _localHistory = [
    'neon aesthetic',
    'tokyo cyberpunk',
    'flutter ui',
    'seven7',
  ];

  File? _getHistoryFile() {
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) {
        final dir = Directory('/data/user/0/com.example.viloapp/files');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        return File('${dir.path}/vilo_search_history.json');
      }
      final dir = Directory.systemTemp;
      return File('${dir.path}/vilo_search_history.json');
    } catch (_) {
      return null;
    }
  }

  void _loadPersistedHistory() {
    try {
      final file = _getHistoryFile();
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        final list = jsonDecode(content);
        if (list is List) {
          final items = list
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (items.isNotEmpty) {
            _localHistory = items;
          }
        }
      }
    } catch (_) {}
  }

  void _persistLocalHistory() {
    try {
      final file = _getHistoryFile();
      if (file != null) {
        file.writeAsStringSync(jsonEncode(_localHistory));
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> search(String query, {String type = 'ALL'}) async {
    final cleanQuery = query.trim().replaceAll(RegExp(r'^[@#]+'), '');
    addSearchHistory(query.trim());
    try {
      final endpoint = '/search?q=${Uri.encodeComponent(cleanQuery)}&type=${Uri.encodeComponent(type)}';
      final response = await _client.get(endpoint, requireAuth: false);

      Map<String, dynamic>? dataMap;
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
          dataMap = response['data'] as Map<String, dynamic>;
        } else {
          dataMap = response;
        }
      }

      if (dataMap != null) {
        final parsed = _parseSearchSummary(dataMap, isSearch: true);
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
      Map<String, dynamic>? dataMap;
      if (response is Map<String, dynamic>) {
        if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
          dataMap = response['data'] as Map<String, dynamic>;
        } else {
          dataMap = response;
        }
      }

      if (dataMap != null) {
        return _parseSearchSummary(dataMap, isSearch: false);
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
      List<dynamic>? historyList;
      if (response is List) {
        historyList = response;
      } else if (response is Map && response['data'] is List) {
        historyList = response['data'] as List;
      }

      if (historyList != null) {
        final remote = historyList
            .map((item) {
              if (item is Map) {
                return item['query']?.toString() ?? '';
              }
              return item?.toString() ?? '';
            })
            .where((q) => q.trim().isNotEmpty)
            .map((q) => q.trim())
            .toList();

        if (remote.isNotEmpty) {
          _localHistory = remote;
          _persistLocalHistory();
          return List<String>.from(_localHistory);
        }
      }
    } catch (e) {
      debugPrint('[SearchRemoteDataSource] History remote fetch error, using local: $e');
    }
    return List<String>.from(_localHistory);
  }

  void addSearchHistory(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    _localHistory.remove(trimmed);
    _localHistory.insert(0, trimmed);
    if (_localHistory.length > 20) {
      _localHistory.removeLast();
    }
    _persistLocalHistory();

    // Asynchronously record search history on the user account in DB
    _client.post(
      '/search/history',
      body: {'query': trimmed, 'type': 'ALL'},
      requireAuth: true,
    ).then((_) {
      debugPrint('[SearchRemoteDataSource] Search query recorded in DB: $trimmed');
    }).catchError((e) {
      debugPrint('[SearchRemoteDataSource] Search query DB sync note: $e');
    });
  }

  void removeSearchHistory(String term) {
    final trimmed = term.trim();
    _localHistory.remove(trimmed);
    _persistLocalHistory();

    // Remove from user account in DB
    _client.delete(
      '/search/history?q=${Uri.encodeComponent(trimmed)}',
      requireAuth: true,
    ).then((_) {
      debugPrint('[SearchRemoteDataSource] Removed query from DB: $trimmed');
    }).catchError((e) {
      debugPrint('[SearchRemoteDataSource] Remove query DB sync note: $e');
    });
  }

  Future<void> clearSearchHistory() async {
    _localHistory.clear();
    _persistLocalHistory();
    try {
      await _client.delete('/search/history', requireAuth: true);
      debugPrint('[SearchRemoteDataSource] Cleared all search history in DB');
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
        final followers = u['followersCount'] != null && u['followersCount'] != 0
            ? '${u['followersCount']} followers'
            : (u['followerCountFormatted']?.toString() ?? '12.4K followers');

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

        accounts.add(SearchAccount(
          id: u['id']?.toString() ?? '',
          username: username,
          displayName: effectiveDisplayName,
          followersCount: followers,
          avatarUrl: effectiveAvatar,
          isFollowed: isMe ? false : (u['isFollowing'] == true),
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
        final rawThumb = v['thumbnailUrl']?.toString() ?? '';
        final resolvedThumb = VideoModel.resolveMediaUrl(rawThumb);
        final rawVideo = v['videoUrl']?.toString() ?? '';
        final resolvedVideo = VideoModel.resolveMediaUrl(rawVideo);

        final rawTags = v['tags'];
        final List<String> tagsList = [];
        if (rawTags is List) {
          for (final t in rawTags) {
            final clean = t?.toString().replaceAll('#', '').trim() ?? '';
            if (clean.isNotEmpty && !tagsList.contains(clean)) {
              tagsList.add(clean);
            }
          }
        }

        final title = v['title']?.toString() ?? '';
        final caption = v['caption']?.toString() ?? title;

        final List<String> mediaList = [];
        if (v['mediaUrls'] is List) {
          for (final item in v['mediaUrls']) {
            if (item != null && item.toString().trim().isNotEmpty) {
              mediaList.add(item.toString().trim());
            }
          }
        } else if (v['imageUrls'] is List) {
          for (final item in v['imageUrls']) {
            if (item != null && item.toString().trim().isNotEmpty) {
              mediaList.add(item.toString().trim());
            }
          }
        } else if (v['imageUrls'] is String && (v['imageUrls'] as String).contains(',')) {
          for (final item in (v['imageUrls'] as String).split(',')) {
            if (item.trim().isNotEmpty) mediaList.add(item.trim());
          }
        } else if (rawVideo.contains(',')) {
          for (final item in rawVideo.split(',')) {
            if (item.trim().isNotEmpty) mediaList.add(item.trim());
          }
        }

        final audioUrl = v['audioUrl']?.toString() ?? v['audio_url']?.toString();
        final soundId = (v['soundId'] is num)
            ? (v['soundId'] as num).toInt()
            : ((v['sound_id'] is num) ? (v['sound_id'] as num).toInt() : null);
        final musicArtist = v['musicArtist']?.toString() ?? v['music_artist']?.toString();

        videos.add(TrendingVideo(
          id: v['id']?.toString() ?? '',
          title: title,
          caption: caption,
          authorUsername: v['authorUsername']?.toString() ?? '',
          authorName: v['authorName']?.toString() ?? '',
          thumbnailUrl: resolvedThumb.isNotEmpty ? resolvedThumb : rawThumb,
          videoUrl: resolvedVideo.isNotEmpty ? resolvedVideo : rawVideo,
          mediaUrls: mediaList,
          imageUrls: mediaList,
          audioUrl: audioUrl,
          soundId: soundId,
          musicArtist: musicArtist,
          views: v['views']?.toString() ?? (v['viewCount'] != null ? '${v['viewCount']}' : '0'),
          viewCount: (v['viewCount'] is num) ? (v['viewCount'] as num).toInt() : 0,
          likeCount: (v['likeCount'] is num) ? (v['likeCount'] as num).toInt() : ((v['likesCount'] is num) ? (v['likesCount'] as num).toInt() : 0),
          commentCount: (v['commentCount'] is num) ? (v['commentCount'] as num).toInt() : ((v['commentsCount'] is num) ? (v['commentsCount'] as num).toInt() : 0),
          saveCount: (v['saveCount'] is num) ? (v['saveCount'] as num).toInt() : ((v['savesCount'] is num) ? (v['savesCount'] as num).toInt() : 0),
          musicTitle: v['musicTitle']?.toString() ?? 'Original Sound',
          creatorId: (v['creatorId'] is num) ? (v['creatorId'] as num).toInt() : null,
          avatarUrl: v['avatarUrl']?.toString(),
          tags: tagsList,
        ));
      }
    }

    final List<String> hashtags = [];
    if (data['hashtags'] is List) {
      for (final h in data['hashtags']) {
        final rawTag = h['formattedTag']?.toString() ?? '#${h['tag']}';
        if (rawTag.isNotEmpty && !hashtags.contains(rawTag)) {
          hashtags.add(rawTag);
        }
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

    // 3. Match Hashtags (combine static tags + tags from cached/posted videos)
    final cachedVideos = FeedRemoteDataSource.instance.getAllCachedVideos();
    final Set<String> allHashtags = Set.from(StaticSearchData.hashtags);
    for (final v in cachedVideos) {
      for (final t in v.tags) {
        allHashtags.add(t.startsWith('#') ? t : '#$t');
      }
      final matches = RegExp(r'#([a-zA-Z0-9_]+)').allMatches(v.caption);
      for (final m in matches) {
        final tag = m.group(1);
        if (tag != null && tag.isNotEmpty) {
          allHashtags.add('#$tag');
        }
      }
    }

    List<String> filteredHashtags = [];
    if (type == 'ALL') {
      filteredHashtags = allHashtags.where((tag) {
        final cleanTag = tag.replaceAll('#', '').toLowerCase();
        return _matchesFuzzy(cleanTag, cleanQ) || cleanQ.isEmpty;
      }).toList();
    }

    // 4. Match Videos:
    // Gather all local video candidates (Cached/posted videos + static mock videos)
    final Map<String, TrendingVideo> allCandidates = {};

    for (final cv in cachedVideos) {
      final key = 'cached_${cv.id}';
      allCandidates[key] = TrendingVideo(
        id: '${cv.id}',
        title: cv.caption,
        caption: cv.caption,
        authorUsername: cv.username.startsWith('@') ? cv.username : '@${cv.username}',
        authorName: cv.displayName,
        thumbnailUrl: cv.thumbnailUrl ?? cv.videoUrl,
        videoUrl: cv.videoUrl,
        mediaUrls: cv.mediaUrls.isNotEmpty ? cv.mediaUrls : cv.imageUrls,
        imageUrls: cv.imageUrls.isNotEmpty ? cv.imageUrls : cv.mediaUrls,
        audioUrl: cv.audioUrl,
        soundId: cv.soundId,
        musicArtist: cv.musicArtist,
        views: '${cv.viewCount}',
        viewCount: cv.viewCount,
        likeCount: cv.likeCount,
        commentCount: cv.commentCount,
        saveCount: cv.saveCount,
        musicTitle: cv.musicTitle,
        tags: cv.tags,
        avatarUrl: cv.avatarUrl,
        creatorId: cv.creatorId,
      );
    }

    // 4c. Static mock videos
    for (final sv in StaticSearchData.trendingVideos) {
      if (!allCandidates.containsKey(sv.id)) {
        allCandidates[sv.id] = sv;
      }
    }

    final matchedUsernames = filteredAccounts
        .map((a) => a.username.toLowerCase().replaceAll('@', ''))
        .toSet();

    List<TrendingVideo> filteredVideos = [];
    if (type == 'ALL' || type == 'VIDEOS' || type == 'USERS') {
      filteredVideos = allCandidates.values.where((v) {
        final vAuthor = v.authorUsername.toLowerCase().replaceAll('@', '');
        final vAuthorName = v.authorName.toLowerCase();
        final vTitle = v.title.toLowerCase();
        final vCaption = v.caption.toLowerCase();

        if (type == 'USERS') return matchedUsernames.contains(vAuthor);
        if (matchedUsernames.contains(vAuthor)) return true;
        if (_matchesFuzzy(vTitle, cleanQ)) return true;
        if (_matchesFuzzy(vCaption, cleanQ)) return true;
        if (v.authorUsername.isNotEmpty && _matchesFuzzy(vAuthor, cleanQ)) return true;
        if (v.authorName.isNotEmpty && _matchesFuzzy(vAuthorName, cleanQ)) return true;
        if (v.tags.any((tag) => _matchesFuzzy(tag, cleanQ))) return true;

        // Also check if caption has matching hashtag
        if (vCaption.contains('#$cleanQ') || (cleanQ.length >= 2 && vCaption.contains(cleanQ))) return true;

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
