import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/static_search_data.dart';
import '../../domain/entities/search_results.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<SearchAccount> _accounts;
  late List<SearchSound> _sounds;

  @override
  void initState() {
    super.initState();
    _accounts = List.from(StaticSearchData.accounts);
    _sounds = List.from(StaticSearchData.sounds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFollow(int index) {
    setState(() {
      final account = _accounts[index];
      _accounts[index] = account.copyWith(isFollowed: !account.isFollowed);
    });
  }

  void _toggleBookmark(int index) {
    setState(() {
      final sound = _sounds[index];
      _sounds[index] = sound.copyWith(isSaved: !sound.isSaved);
    });
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
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
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
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Content Body
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // --- SECTION 1: Trending Results ---
                  _buildSectionHeader('Trending Results'),
                  const SizedBox(height: 12),
                  _buildTrendingGrid(),
                  const SizedBox(height: 28),

                  // --- SECTION 2: Accounts ---
                  _buildSectionHeader('Accounts'),
                  const SizedBox(height: 12),
                  ...List.generate(_accounts.length, (index) {
                    return _buildAccountItem(index);
                  }),
                  const SizedBox(height: 28),

                  // --- SECTION 3: Sounds ---
                  _buildSectionHeader('Sounds'),
                  const SizedBox(height: 12),
                  ...List.generate(_sounds.length, (index) {
                    return _buildSoundItem(index);
                  }),
                  const SizedBox(height: 40),
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
    final videos = StaticSearchData.trendingVideos;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 0.62, // 9:14.5 vertical shortform aspect ratio
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail Image
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.movie_outlined, color: AppColors.outline),
                ),
              ),

              // Bottom Vignette Gradient
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

              // Bottom Left View Count Overlay
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
          // Avatar
          Container(
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
          const SizedBox(width: 14),

          // Username & Followers
          Expanded(
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

    IconData soundIcon;
    switch (sound.iconType) {
      case 'equalizer':
        soundIcon = Icons.equalizer_rounded;
        break;
      case 'ambience':
        soundIcon = Icons.graphic_eq_rounded;
        break;
      case 'music':
      default:
        soundIcon = Icons.music_note_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Sound Icon Box
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
            child: Icon(
              soundIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Videos Count
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
                  sound.videosCount,
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

          // Bookmark / Save Action
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
    );
  }
}
