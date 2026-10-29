import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/network/media_url.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/presentation/pages/sound_detail_page.dart';
import '../../../feed/presentation/pages/video_feed_page.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../data/datasources/search_remote_data_source.dart';
import '../../data/datasources/static_search_data.dart';
import '../../domain/entities/search_results.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchRemoteDataSource _dataSource = SearchRemoteDataSource.instance;

  Timer? _debounceTimer;
  String _selectedCategory = 'Top'; // 'Top', 'Users', 'Videos', 'Sounds'
  bool _isLoading = false;

  List<SearchAccount> _accounts = [];
  List<SearchSound> _sounds = [];
  List<TrendingVideo> _trendingVideos = [];
  List<String> _hashtags = [];
  List<String> _recentSearches = [];

  final List<String> _categories = const ['Top', 'Users', 'Videos', 'Sounds'];

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _executeSearch(initialQuery);
      });
    } else {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final explore = await _dataSource.getTrendingExplore();
    final history = await _dataSource.getSearchHistory();

    if (mounted) {
      setState(() {
        _accounts = explore['accounts'] ?? StaticSearchData.accounts;
        _sounds = explore['sounds'] ?? StaticSearchData.sounds;
        _trendingVideos = _sortVideosByViews(
          explore['trendingVideos'] ?? StaticSearchData.trendingVideos,
        );
        _hashtags = explore['hashtags'] ?? ['#viloapp', '#flutterdev', '#tokyocoding'];
        _recentSearches = history;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 320), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadInitialData();
      return;
    }

    setState(() => _isLoading = true);

    String backendType = 'ALL';
    if (_selectedCategory == 'Users') backendType = 'USERS';
    if (_selectedCategory == 'Sounds') backendType = 'SOUNDS';
    if (_selectedCategory == 'Videos') backendType = 'VIDEOS';

    final result = await _dataSource.search(query.trim(), type: backendType);

    if (mounted) {
      setState(() {
        _accounts = result['accounts'] ?? [];
        _sounds = result['sounds'] ?? [];
        _trendingVideos = _sortVideosByRelevance(result['trendingVideos'] ?? [], query);
        _hashtags = result['hashtags'] ?? [];
        final term = query.trim();
        _recentSearches.remove(term);
        _recentSearches.insert(0, term);
        if (_recentSearches.length > 8) {
          _recentSearches.removeLast();
        }
        _dataSource.addSearchHistory(term);
        _isLoading = false;
      });
    }
  }

  List<TrendingVideo> _sortVideosByViews(Iterable<TrendingVideo> videos) {
    final sorted = List<TrendingVideo>.from(videos);
    sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sorted;
  }

  List<TrendingVideo> _sortVideosByRelevance(Iterable<TrendingVideo> videos, String query) {
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.isEmpty) {
      return _sortVideosByViews(videos);
    }
    final sorted = List<TrendingVideo>.from(videos);
    sorted.sort((a, b) {
      final scoreB = _computeVideoScore(b, cleanQ);
      final scoreA = _computeVideoScore(a, cleanQ);
      if (scoreB != scoreA) {
        return scoreB.compareTo(scoreA);
      }
      return b.viewCount.compareTo(a.viewCount);
    });
    return sorted;
  }

  int _computeVideoScore(TrendingVideo v, String q) {
    int score = 0;
    final title = v.title.toLowerCase().trim();
    final caption = v.caption.toLowerCase().trim();
    final author = v.authorUsername.toLowerCase().replaceAll('@', '').trim();
    final authorName = v.authorName.toLowerCase().trim();

    // 1. Exact match on title (Strongest signal)
    if (title == q) {
      score += 1000;
    } else if (title.startsWith(q)) {
      score += 800;
    } else if (title.contains(q)) {
      score += 600;
    }

    // 2. Caption matches
    if (caption == q) {
      score += 500;
    } else if (caption.startsWith(q)) {
      score += 400;
    } else if (caption.contains(q)) {
      score += 300;
    }

    // 3. Exact author match
    if (author == q || authorName == q) {
      score += 250;
    } else if (author.contains(q) || authorName.contains(q)) {
      score += 150;
    }

    // 4. Tag match
    for (final tag in v.tags) {
      final t = tag.toLowerCase().replaceAll('#', '').trim();
      if (t == q) {
        score += 200;
        break;
      } else if (t.contains(q)) {
        score += 100;
      }
    }

    // 5. Token match
    final tokens = q.split(RegExp(r'[\s_.\-]+')).where((tok) => tok.length >= 2);
    for (final tok in tokens) {
      if (title.contains(tok)) score += 50;
      if (caption.contains(tok)) score += 30;
    }

    return score;
  }

  Future<void> _toggleFollow(int index) async {
    final account = _accounts[index];
    final targetId = int.tryParse(account.id);
    if (targetId == null || targetId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This account is not available right now.')),
      );
      return;
    }

    final newFollowState = !account.isFollowed;
    setState(() {
      _accounts[index] = account.copyWith(isFollowed: newFollowState);
    });

    try {
      final serverFollowState = newFollowState
          ? await ProfileRemoteDataSource.instance.toggleFollow(targetId)
          : await ProfileRemoteDataSource.instance.unfollow(targetId);
      if (!mounted) return;
      if (serverFollowState != newFollowState) {
        setState(() {
          _accounts[index] = account.copyWith(isFollowed: serverFollowState);
        });
      }
      ProfileSyncService.instance.notifyFollowChanged(
        targetUserId: targetId,
        isFollowing: serverFollowState,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _accounts[index] = account;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update follow: $error')),
      );
    }
  }

  void _toggleBookmark(int index) {
    setState(() {
      final sound = _sounds[index];
      _sounds[index] = sound.copyWith(isSaved: !sound.isSaved);
    });
  }

  void _onSelectHashtag(String tag) {
    final cleanTag = tag.startsWith('#') ? tag : '#$tag';
    _searchController.text = cleanTag;
    _executeSearch(cleanTag);
  }

  void _removeHistoryItem(String item) {
    setState(() {
      _recentSearches.remove(item);
    });
    _dataSource.removeSearchHistory(item);
  }

  void _clearAllHistory() {
    setState(() {
      _recentSearches.clear();
    });
    _dataSource.clearSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Search Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.surfaceStroke,
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search videos, creators, sounds...',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.outline,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.outline,
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.outline,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loadInitialData();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Filter Category Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      if (_searchController.text.isNotEmpty) {
                        _executeSearch(_searchController.text);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : const Color(0xFF242428),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: isSelected ? Colors.white : AppColors.surfaceStroke,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.black : AppColors.outline,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // 3. Search Content Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // Search History Section (when input is empty)
                        if (_searchController.text.isEmpty && _recentSearches.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader('Recent Searches'),
                              GestureDetector(
                                onTap: _clearAllHistory,
                                child: const Text(
                                  'Clear all',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _recentSearches.map((term) {
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    _searchController.text = term;
                                    _executeSearch(term);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.only(left: 10, right: 6, top: 5, bottom: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF202024),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.surfaceStroke, width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          term.startsWith('#') ? Icons.tag_rounded : Icons.history_rounded,
                                          size: 14,
                                          color: AppColors.outline,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          term,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => _removeHistoryItem(term),
                                          child: const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 15,
                                              color: AppColors.outline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // === VIEW 1: SEARCH ACTIVE (Text input is NOT empty) ===
                        if (_searchController.text.isNotEmpty) ...[
                          if (_selectedCategory == 'Top') ...[
                            // 1. Accounts matching query (Top priority)
                            if (_accounts.isNotEmpty) ...[
                              _buildSectionHeader('Accounts'),
                              const SizedBox(height: 12),
                              ...List.generate(_accounts.length, (index) => _buildAccountItem(index)),
                              const SizedBox(height: 24),
                            ],

                            // 2. Videos matching query (including author's videos if searching user account)
                            if (_trendingVideos.isNotEmpty) ...[
                              _buildSectionHeader(
                                (_accounts.length == 1 && _accounts.first.username.isNotEmpty)
                                    ? 'Videos from ${_accounts.first.displayName.isNotEmpty ? _accounts.first.displayName : _accounts.first.username}'
                                    : 'Videos',
                              ),
                              const SizedBox(height: 12),
                              _buildTrendingGrid(),
                              const SizedBox(height: 28),
                            ],

                            // 3. Sounds matching query
                            if (_sounds.isNotEmpty) ...[
                              _buildSectionHeader('Sounds'),
                              const SizedBox(height: 12),
                              ...List.generate(_sounds.length, (index) => _buildSoundItem(index)),
                              const SizedBox(height: 28),
                            ],

                            // 4. Hashtags matching query
                            if (_hashtags.isNotEmpty) ...[
                              _buildSectionHeader('Hashtags'),
                              const SizedBox(height: 10),
                              _buildHashtagsWrap(),
                              const SizedBox(height: 28),
                            ],

                            // Empty state if nothing matches across any category
                            if (_accounts.isEmpty &&
                                _trendingVideos.isEmpty &&
                                _sounds.isEmpty &&
                                _hashtags.isEmpty)
                              _buildEmptyState('No results found for "${_searchController.text.trim()}"'),
                          ] else if (_selectedCategory == 'Users') ...[
                            if (_accounts.isNotEmpty) ...[
                              _buildSectionHeader('Accounts'),
                              const SizedBox(height: 12),
                              ...List.generate(_accounts.length, (index) => _buildAccountItem(index)),
                              if (_trendingVideos.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildSectionHeader(
                                  _accounts.length == 1
                                      ? 'Videos from ${_accounts.first.displayName.isNotEmpty ? _accounts.first.displayName : _accounts.first.username}'
                                      : 'Videos from these accounts',
                                ),
                                const SizedBox(height: 12),
                                _buildTrendingGrid(),
                              ],
                            ] else
                              _buildEmptyState('No accounts found for "${_searchController.text.trim()}"'),
                          ] else if (_selectedCategory == 'Videos') ...[
                            if (_trendingVideos.isNotEmpty) ...[
                              _buildSectionHeader('Videos'),
                              const SizedBox(height: 12),
                              _buildTrendingGrid(),
                            ] else
                              _buildEmptyState('No videos found for "${_searchController.text.trim()}"'),
                          ] else if (_selectedCategory == 'Sounds') ...[
                            if (_sounds.isNotEmpty) ...[
                              _buildSectionHeader('Sounds'),
                              const SizedBox(height: 12),
                              ...List.generate(_sounds.length, (index) => _buildSoundItem(index)),
                            ] else
                              _buildEmptyState('No sounds found for "${_searchController.text.trim()}"'),
                          ],
                        ]

                        // === VIEW 2: EXPLORE / LANDING (Text input is EMPTY) ===
                        else ...[
                          // Trending Hashtags
                          if (_hashtags.isNotEmpty) ...[
                            _buildSectionHeader('Trending Hashtags'),
                            const SizedBox(height: 10),
                            _buildHashtagsWrap(),
                            const SizedBox(height: 24),
                          ],

                          // Trending Results / Videos
                          if (_trendingVideos.isNotEmpty) ...[
                            _buildSectionHeader('Trending Results'),
                            const SizedBox(height: 12),
                            _buildTrendingGrid(),
                            const SizedBox(height: 28),
                          ],

                          // Suggested Creators
                          if (_accounts.isNotEmpty) ...[
                            _buildSectionHeader('Suggested Creators'),
                            const SizedBox(height: 12),
                            ...List.generate(
                              _accounts.length > 5 ? 5 : _accounts.length,
                              (index) => _buildAccountItem(index),
                            ),
                            const SizedBox(height: 28),
                          ],

                          // Popular Sounds
                          if (_sounds.isNotEmpty) ...[
                            _buildSectionHeader('Popular Sounds'),
                            const SizedBox(height: 12),
                            ...List.generate(
                              _sounds.length > 5 ? 5 : _sounds.length,
                              (index) => _buildSoundItem(index),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildTrendingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 0.62,
      ),
      itemCount: _trendingVideos.length,
      itemBuilder: (context, index) {
        final video = _trendingVideos[index];
        return GestureDetector(
          onTap: () {
            final videoList = _trendingVideos.map((tv) => tv.toVideoModel()).toList();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VideoFeedPage(
                  initialVideos: videoList,
                  initialIndex: index,
                  hasBottomNav: false,
                  canDelete: false,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildVideoThumbnail(video.thumbnailUrl),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                if (video.title.isNotEmpty)
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 22,
                    child: Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        video.views,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoThumbnail(String url) {
    final cleanUrl = url.trim();
    final placeholder = Container(
      color: AppColors.surface,
      child: const Icon(Icons.movie_outlined, color: AppColors.outline),
    );
    if (cleanUrl.startsWith('assets/')) {
      return Image.asset(
        cleanUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (cleanUrl.isEmpty) return placeholder;
    return Image.network(
      resolveBackendMediaUrl(cleanUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }

  Widget _buildAccountItem(int index) {
    final account = _accounts[index];
    final cleanUsername = account.username.replaceAll('@', '');
    final isMe = ProfileSyncService.instance.isCurrentUser(
      username: account.username,
      id: account.id,
    );
    final effectiveDisplayName = isMe
        ? ProfileSyncService.instance.currentUserDisplayName
        : (account.displayName.isNotEmpty ? account.displayName : cleanUsername);
    final effectiveAvatarUrl = isMe
        ? ProfileSyncService.instance.currentUserAvatar
        : account.avatarUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Avatar with routing to PublicProfileScreen
          GestureDetector(
            onTap: () {
              final cached = FeedRemoteDataSource.instance.getCachedUserVideos(cleanUsername) ??
                  (account.id.isNotEmpty ? FeedRemoteDataSource.instance.getCachedUserVideos(account.id) : null);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(
                    userId: int.tryParse(account.id),
                    username: cleanUsername,
                    displayName: effectiveDisplayName,
                    avatarUrl: effectiveAvatarUrl,
                    isFollowing: account.isFollowed,
                    initialVideos: cached,
                  ),
                ),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMe
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.15),
                  width: isMe ? 1.5 : 1.0,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  resolveBackendMediaUrl(effectiveAvatarUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surface,
                    child: const Icon(Icons.person, color: AppColors.outline),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Username & Followers
          Expanded(
            child: GestureDetector(
              onTap: () {
                final cached = FeedRemoteDataSource.instance.getCachedUserVideos(cleanUsername) ??
                    (account.id.isNotEmpty ? FeedRemoteDataSource.instance.getCachedUserVideos(account.id) : null);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(
                      userId: int.tryParse(account.id),
                      username: cleanUsername,
                      displayName: effectiveDisplayName,
                      avatarUrl: effectiveAvatarUrl,
                      isFollowing: account.isFollowed,
                      initialVideos: cached,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          effectiveDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (account.isVerified || isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF20D5EC),
                          size: 15,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isMe
                        ? '@$cleanUsername • You'
                        : (account.displayName.isNotEmpty
                            ? '@$cleanUsername • ${account.followersCount}'
                            : account.followersCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isMe ? Colors.white60 : AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Follow Button or You Indicator
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF242428),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.2,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _toggleFollow(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  color: account.isFollowed ? AppColors.surface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: account.isFollowed
                      ? Border.all(color: AppColors.surfaceStroke, width: 1.0)
                      : null,
                  boxShadow: account.isFollowed
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.25),
                            blurRadius: 12,
                            spreadRadius: 0.5,
                          ),
                        ],
                ),
                child: Text(
                  account.isFollowed ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: account.isFollowed ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHashtagsWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _hashtags.map((tag) {
        final formattedTag = tag.startsWith('#') ? tag : '#$tag';
        return GestureDetector(
          onTap: () => _onSelectHashtag(formattedTag),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF28282D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag_rounded, size: 14, color: Color(0xFF20D5EC)),
                const SizedBox(width: 4),
                Text(
                  formattedTag.replaceAll('#', ''),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF202024),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceStroke, width: 1),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.outline,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching for another keyword, creator name, or hashtag.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundItem(int index) {
    final sound = _sounds[index];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SoundDetailPage(
              soundId: sound.id,
              title: sound.title,
              artist: sound.artist,
              audioUrl: sound.audioUrl,
              albumArtUrl: sound.albumArtUrl,
              videosCount: sound.videosCount,
              creatorUsername: sound.artist.replaceAll('@', '').trim(),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF242428),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.surfaceStroke,
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sound.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${sound.artist} • ${sound.videosCount}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              icon: Icon(
                sound.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: sound.isSaved ? Colors.white : AppColors.outline,
                size: 24,
              ),
              onPressed: () => _toggleBookmark(index),
            ),
          ],
        ),
      ),
    );
  }
}
