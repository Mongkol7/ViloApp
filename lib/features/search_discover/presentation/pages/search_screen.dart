import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../feed/presentation/pages/sound_detail_page.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../data/datasources/search_remote_data_source.dart';
import '../../data/datasources/static_search_data.dart';
import '../../domain/entities/search_results.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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
    _loadInitialData();
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
        _trendingVideos = explore['trendingVideos'] ?? StaticSearchData.trendingVideos;
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
        _trendingVideos = result['trendingVideos'] ?? [];
        _hashtags = result['hashtags'] ?? [];
        if (!_recentSearches.contains(query.trim())) {
          _recentSearches.insert(0, query.trim());
          if (_recentSearches.length > 8) {
            _recentSearches.removeLast();
          }
        }
        _isLoading = false;
      });
    }
  }

  void _toggleFollow(int index) {
    setState(() {
      final account = _accounts[index];
      final newFollowState = !account.isFollowed;
      _accounts[index] = account.copyWith(isFollowed: newFollowState);
      ProfileSyncService.instance.notifyFollowChanged(
        targetUserId: int.tryParse(account.id) ?? 0,
        isFollowing: newFollowState,
      );
    });
  }

  void _toggleBookmark(int index) {
    setState(() {
      final sound = _sounds[index];
      _sounds[index] = sound.copyWith(isSaved: !sound.isSaved);
    });
  }

  void _onSelectHashtag(String tag) {
    final query = tag.replaceAll('#', '');
    _searchController.text = query;
    _executeSearch(query);
  }

  void _removeHistoryItem(String item) {
    setState(() {
      _recentSearches.remove(item);
    });
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
                separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                              return Container(
                                padding: const EdgeInsets.only(left: 12, right: 6, top: 4, bottom: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF202024),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.surfaceStroke, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.text = term;
                                        _executeSearch(term);
                                      },
                                      child: Text(
                                        term,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _removeHistoryItem(term),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Trending Hashtags
                        if (_hashtags.isNotEmpty && (_selectedCategory == 'Top' || _selectedCategory == 'Videos')) ...[
                          _buildSectionHeader('Trending Hashtags'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _hashtags.map((tag) {
                              return GestureDetector(
                                onTap: () => _onSelectHashtag(tag),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF28282D),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white12, width: 0.8),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // --- SECTION 1: Trending / Videos ---
                        if ((_selectedCategory == 'Top' || _selectedCategory == 'Videos') && _trendingVideos.isNotEmpty) ...[
                          _buildSectionHeader(_searchController.text.isEmpty ? 'Trending Results' : 'Videos'),
                          const SizedBox(height: 12),
                          _buildTrendingGrid(),
                          const SizedBox(height: 28),
                        ],

                        // --- SECTION 2: Accounts ---
                        if ((_selectedCategory == 'Top' || _selectedCategory == 'Users') && _accounts.isNotEmpty) ...[
                          _buildSectionHeader('Accounts'),
                          const SizedBox(height: 12),
                          ...List.generate(_accounts.length, (index) {
                            return _buildAccountItem(index);
                          }),
                          const SizedBox(height: 28),
                        ],

                        // --- SECTION 3: Sounds ---
                        if ((_selectedCategory == 'Top' || _selectedCategory == 'Sounds') && _sounds.isNotEmpty) ...[
                          _buildSectionHeader('Sounds'),
                          const SizedBox(height: 12),
                          ...List.generate(_sounds.length, (index) {
                            return _buildSoundItem(index);
                          }),
                          const SizedBox(height: 40),
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.movie_outlined, color: AppColors.outline),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.6, 1.0],
                    ),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountItem(int index) {
    final account = _accounts[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Avatar with routing to PublicProfileScreen
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(
                    userId: int.tryParse(account.id),
                    username: account.username,
                    displayName: account.username,
                    avatarUrl: account.avatarUrl,
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
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  account.avatarUrl,
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(
                      userId: int.tryParse(account.id),
                      username: account.username,
                      displayName: account.username,
                      avatarUrl: account.avatarUrl,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    account.username,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    account.followersCount,
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
          ),

          // Follow Button
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
