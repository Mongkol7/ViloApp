import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../inbox_activity/data/datasources/thought_story_manager.dart';
import '../../../inbox_activity/domain/entities/shared_thought_story.dart';
import '../../../inbox_activity/presentation/pages/share_thought_screen.dart';
import '../../../inbox_activity/presentation/pages/story_viewer_screen.dart';
import '../../../inbox_activity/presentation/widgets/animated_mini_music_wave.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/data/models/video_feed_model.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/profile_sync_service.dart';
import '../mock/profile_mock_data.dart';
import '../pages/edit_profile_screen.dart';
import '../pages/followers_following_screen.dart';
import '../style/pulse_tokens.dart';
import '../widgets/profile_tab_content.dart';
import '../widgets/profile_menu_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isOwnProfile = true});
  final bool isOwnProfile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserModel? _user;
  List<VideoFeedModel> _myVideos = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    // Initialize with local default for immediate render / testing
    _user = ProfileSyncService.instance.cachedMyProfile ??
        UserModel(
          id: 1,
          username: ProfileMockData.username,
          email: 'mongkol@vilo.app',
          displayName: ProfileMockData.name,
          bio: ProfileMockData.bio,
          avatarUrl: ProfileMockData.avatarUrl,
          isVerified: true,
          followersCount: ProfileSyncService.instance.mockFollowersCount,
          followingCount: ProfileSyncService.instance.mockFollowingCount,
        );
    ProfileSyncService.instance.followEvents.addListener(_onFollowEvent);
    _loadProfile();
  }

  void _onFollowEvent() {
    final event = ProfileSyncService.instance.followEvents.value;
    if (event != null && mounted) {
      if (_user != null) {
        final updatedFollowing = (_user!.followingCount + event.delta).clamp(0, 999999999);
        setState(() {
          _user = _user!.copyWith(followingCount: updatedFollowing);
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ProfileRemoteDataSource.instance.getMyProfile();
      if (mounted) {
        setState(() => _user = user);
        ProfileSyncService.instance.cachedMyProfile = user;
      }

      // Load user's posted videos from backend
      try {
        final videos = await FeedRemoteDataSource.instance.getUserVideos(user.id);
        if (mounted && videos.isNotEmpty) {
          setState(() => _myVideos = videos);
        }
      } catch (_) {}

      // Pre-warm following & followers cache in background for zero-latency instant listing
      if (user.id > 0) {
        ProfileRemoteDataSource.instance.getFollowing(user.id).then((fl) {
          ProfileSyncService.instance.cachedFollowing = List.from(fl);
        }).catchError((_) {});
        ProfileRemoteDataSource.instance.getFollowers(user.id).then((f) {
          ProfileSyncService.instance.cachedFollowers = List.from(f);
        }).catchError((_) {});
      }
    } catch (_) {
      // Keep existing user state if network fetch fails
    }
  }

  Future<void> _handleEditProfile() async {
    if (_user == null) return;
    final updated = await Navigator.of(context).push<UserModel>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _user!),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _user = updated);
      ProfileSyncService.instance.cachedMyProfile = updated;
    }
  }

  void _handleShareProfile() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: 'https://vilo.app/@${_user?.username ?? ProfileMockData.username}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile link copied to clipboard!'),
        backgroundColor: Color(0xFF2F80ED),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openFollowersFollowing(int initialTab) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowersFollowingScreen(
          userId: _user?.id ?? 1,
          username: _user?.username ?? ProfileMockData.username,
          initialTabIndex: initialTab,
          initialFollowersCount: _user?.followersCount,
          initialFollowingCount: _user?.followingCount,
          initialFollowers: ProfileSyncService.instance.cachedFollowers,
          initialFollowing: ProfileSyncService.instance.cachedFollowing,
        ),
      ),
    );
    if (mounted) {
      _loadProfile();
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  @override
  void dispose() {
    ProfileSyncService.instance.followEvents.removeListener(_onFollowEvent);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateOrViewStory() async {
    final currentStory = ThoughtStoryManager.instance.currentStory;
    if (currentStory != null) {
      // If story exists, open StoryViewerScreen and handle deletion
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => StoryViewerScreen(story: currentStory),
        ),
      );

      if (result == 'delete' && mounted) {
        ThoughtStoryManager.instance.deleteStory();
      }
    } else {
      // If no story, open ShareThoughtScreen
      final result = await Navigator.of(context).push<SharedThoughtStory>(
        MaterialPageRoute(
          builder: (_) => const ShareThoughtScreen(),
        ),
      );

      if (result != null && mounted) {
        ThoughtStoryManager.instance.setStory(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUsername = _user?.username.isNotEmpty == true ? _user!.username : ProfileMockData.username;
    final currentDisplayName = _user?.displayName.isNotEmpty == true ? _user!.displayName : currentUsername;
    final currentAvatarUrl = _user?.avatarUrl?.isNotEmpty == true ? _user!.avatarUrl! : ProfileMockData.avatarUrl;
    final currentBio = _user?.bio?.isNotEmpty == true ? _user!.bio! : ProfileMockData.bio;
    final followersDisplay = _formatCount(_user?.followersCount ?? ProfileSyncService.instance.mockFollowersCount);
    final followingDisplay = _formatCount(_user?.followingCount ?? ProfileSyncService.instance.mockFollowingCount);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: PulseColors.background,
      endDrawer: const ProfileMenuDrawer(),
      appBar: AppBar(
        backgroundColor: PulseColors.background,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentDisplayName, style: PulseTypography.bodyLg),
            if (_user?.isVerified == true) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, color: Color(0xFF2F80ED), size: 16),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: PulseColors.onSurface),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: Colors.white,
        backgroundColor: const Color(0xFF1E1E24),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Avatar with Share Mind Thought Balloon & Story Ring
                    ValueListenableBuilder<SharedThoughtStory?>(
                      valueListenable: ThoughtStoryManager.instance.storyNotifier,
                      builder: (context, currentStory, _) {
                        final isStoryActive = currentStory != null;
                        final messageText =
                            isStoryActive ? currentStory.message : 'Share a thought...';
                        final hasMusic = isStoryActive && currentStory.musicTrack != null;

                        return GestureDetector(
                          onTap: _handleCreateOrViewStory,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Floating Thought Message Balloon on top of Profile Avatar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              constraints: const BoxConstraints(maxWidth: 160),
                              decoration: BoxDecoration(
                                color: isStoryActive
                                    ? const Color(0xFF222228)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: isStoryActive
                                    ? Border.all(
                                        color: const Color(0xFF383842),
                                        width: 1.2,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      messageText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isStoryActive
                                            ? Colors.white
                                            : const Color(0xFF141416),
                                      ),
                                    ),
                                  ),
                                  if (hasMusic) ...[
                                    const SizedBox(width: 6),
                                    const AnimatedMiniMusicWave(),
                                  ],
                                ],
                              ),
                            ),
                            // Speech balloon triangle pointer
                            CustomPaint(
                              size: const Size(10, 6),
                              painter: _SpeechTrianglePainter(
                                color: isStoryActive
                                    ? const Color(0xFF222228)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Profile Avatar with Instagram-style Story Gradient Ring (if active) or Plus Badge
                            Container(
                              width: 106,
                              height: 106,
                              padding: isStoryActive
                                  ? const EdgeInsets.all(3.0)
                                  : EdgeInsets.zero,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isStoryActive
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFE2C55),
                                          Color(0xFFFF9F43),
                                          Color(0xFF9B51E0),
                                          Color(0xFF2F80ED),
                                        ],
                                      )
                                    : null,
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: PulseColors.background,
                                ),
                                padding: isStoryActive
                                    ? const EdgeInsets.all(2.5)
                                    : EdgeInsets.zero,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipOval(
                                      child: SizedBox(
                                        width: 96,
                                        height: 96,
                                        child: Image.network(
                                          currentAvatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: PulseColors.surfaceContainer,
                                            child: const Icon(
                                              Icons.person_rounded,
                                              color: Colors.white70,
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!isStoryActive)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF2F80ED),
                                            border: Border.all(
                                              color: PulseColors.background,
                                              width: 2.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Username
                  Text('@$currentUsername', style: PulseTypography.headlineSm),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem('Following', followingDisplay, onTap: () => _openFollowersFollowing(1)),
                      _buildDivider(),
                      _buildStatItem('Followers', followersDisplay, onTap: () => _openFollowersFollowing(0)),
                      _buildDivider(),
                      _buildStatItem('Likes', '154K'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPillButton('Edit Profile', isPrimary: false, onTap: _handleEditProfile),
                      const SizedBox(width: 8),
                      _buildPillButton('Share Profile', isPrimary: false, onTap: _handleShareProfile),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bio
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      currentBio,
                      textAlign: TextAlign.center,
                      style: PulseTypography.bodyMd,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.music_note_rounded)), // Music
                    Tab(icon: Icon(Icons.grid_view_rounded)),  // Grid
                    Tab(icon: Icon(Icons.shopping_bag_outlined)), // Shop
                    Tab(icon: Icon(Icons.bookmark_border_rounded)), // Saved
                    Tab(icon: Icon(Icons.favorite_border_rounded)), // Liked
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            CustomScrollView(slivers: buildProfileTabSlivers(0)), // Music
            CustomScrollView(slivers: buildProfileTabSlivers(1, userVideos: _myVideos)), // Grid
            CustomScrollView(slivers: buildProfileTabSlivers(2)), // Shop
            CustomScrollView(slivers: buildProfileTabSlivers(3)), // Saved
            CustomScrollView(slivers: buildProfileTabSlivers(4)), // Liked
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 15, width: 1, color: Colors.grey.withValues(alpha: 0.3));
  }

  Widget _buildPillButton(String label, {bool isPrimary = true, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : PulseColors.actionSecondary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SpeechTrianglePainter extends CustomPainter {
  final Color color;

  _SpeechTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpeechTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: PulseColors.background, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
