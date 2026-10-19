import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../bottom_nav/presentation/pages/main_navigation_shell.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/profile_sync_service.dart';
import '../mock/profile_mock_data.dart';
import '../pages/edit_profile_screen.dart';
import '../pages/followers_following_screen.dart';
import '../style/pulse_tokens.dart';
import '../widgets/profile_tab_content.dart';
import '../../../inbox_activity/data/datasources/chat_manager.dart';
import '../../../inbox_activity/presentation/pages/chat_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final int? userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isFollowing;
  final bool followsYou;

  const PublicProfileScreen({
    super.key,
    this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.isFollowing = false,
    this.followsYou = false,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isFollowing;
  int _followersCount = 0;
  UserModel? _loadedUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    _isFollowing = widget.isFollowing;
    _followersCount = (widget.userId == 1) ? ProfileSyncService.instance.mockFollowersCount : 0;
    if (widget.userId != null) {
      _fetchPublicProfile();
    }
  }

  Future<void> _fetchPublicProfile() async {
    if (widget.userId == null) return;
    setState(() => _isLoading = true);
    try {
      final user = await ProfileRemoteDataSource.instance.getUserById(widget.userId!);
      if (mounted) {
        setState(() {
          _loadedUser = user;
          _isFollowing = user.isFollowing;
          _followersCount = user.followersCount;
        });
      }
    } catch (_) {
      // Fallback to widget initial properties
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationShell(initialIndex: 0)),
        (route) => false,
      );
    }
  }

  Future<void> _handleToggleFollow() async {
    HapticFeedback.lightImpact();
    final newFollowState = !_isFollowing;
    setState(() {
      _isFollowing = newFollowState;
      if (newFollowState) {
        _followersCount++;
      } else if (_followersCount > 0) {
        _followersCount--;
      }
    });

    final targetUid = _loadedUser?.id ?? widget.userId;
    // Broadcast follow change immediately so own profile followingCount updates
    ProfileSyncService.instance.notifyFollowChanged(
      targetUserId: targetUid ?? 0,
      isFollowing: newFollowState,
    );

    if (targetUid != null && targetUid > 0) {
      try {
        if (newFollowState) {
          await ProfileRemoteDataSource.instance.toggleFollow(targetUid);
        } else {
          await ProfileRemoteDataSource.instance.unfollow(targetUid);
        }
      } catch (_) {
        // Revert on error
        if (mounted) {
          setState(() {
            _isFollowing = !newFollowState;
            if (newFollowState) {
              _followersCount--;
            } else {
              _followersCount++;
            }
          });
          ProfileSyncService.instance.notifyFollowChanged(
            targetUserId: targetUid,
            isFollowing: !newFollowState,
          );
        }
      }
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
  Widget build(BuildContext context) {
    final username = _loadedUser?.username ?? widget.username ?? ProfileMockData.username;
    final displayName = _loadedUser?.displayName.isNotEmpty == true
        ? _loadedUser!.displayName
        : (widget.displayName?.isNotEmpty == true ? widget.displayName! : username);
    final avatarUrl = _loadedUser?.avatarUrl?.isNotEmpty == true
        ? _loadedUser!.avatarUrl!
        : (widget.avatarUrl?.isNotEmpty == true ? widget.avatarUrl! : ProfileMockData.avatarUrl);
    final bio = _loadedUser?.bio?.isNotEmpty == true
        ? _loadedUser!.bio!
        : (widget.bio?.isNotEmpty == true ? widget.bio! : ProfileMockData.bio);
    final isVerified = _loadedUser?.isVerified ?? false;

    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PulseColors.onSurface),
          onPressed: _handleBack,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayName, style: PulseTypography.bodyLg),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, color: Color(0xFF2F80ED), size: 16),
            ],
          ],
        ),
        centerTitle: true,
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F80ED)),
                  minHeight: 2,
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: PulseColors.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  ClipOval(
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: Image.network(
                        avatarUrl,
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
                  const SizedBox(height: 12),
                  // Username
                  Text('@$username', style: PulseTypography.headlineSm),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(
                        'Following',
                        '${_loadedUser?.followingCount ?? (widget.userId == 1 ? ProfileSyncService.instance.mockFollowingCount : 0)}',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FollowersFollowingScreen(
                                userId: _loadedUser?.id ?? widget.userId,
                                username: username,
                                initialTabIndex: 1,
                                initialFollowingCount: _loadedUser?.followingCount,
                                initialFollowersCount: _loadedUser?.followersCount ?? _followersCount,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        'Followers',
                        _formatCount(_followersCount),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FollowersFollowingScreen(
                                userId: _loadedUser?.id ?? widget.userId,
                                username: username,
                                initialTabIndex: 0,
                                initialFollowersCount: _loadedUser?.followersCount ?? _followersCount,
                                initialFollowingCount: _loadedUser?.followingCount,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildStatItem('Likes', (widget.userId == 1 || _loadedUser?.id == 1) ? '154K' : '0'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Builder(
                    builder: (context) {
                      final isMe = ProfileSyncService.instance.isCurrentUser(
                        username: username,
                        id: _loadedUser?.id.toString() ?? widget.userId?.toString(),
                      );

                      if (isMe) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPillButton(
                              'Edit Profile',
                              isPrimary: false,
                              onTap: () {
                                final userModel = _loadedUser ??
                                    UserModel(
                                      id: widget.userId ?? 1,
                                      username: username,
                                      email: 'mongkol@vilo.app',
                                      displayName: displayName,
                                      bio: bio,
                                      avatarUrl: avatarUrl,
                                      isVerified: isVerified,
                                      followersCount: _followersCount,
                                      followingCount: ProfileSyncService.instance.mockFollowingCount,
                                    );
                                Navigator.of(context).push<UserModel>(
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(user: userModel),
                                  ),
                                ).then((updated) {
                                  if (updated != null && mounted) {
                                    setState(() {
                                      _loadedUser = updated;
                                    });
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildPillButton(
                              'Share Profile',
                              isPrimary: false,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: 'https://vilo.app/@$username'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile link copied to clipboard!'),
                                    backgroundColor: Color(0xFF2F80ED),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }

                      final bool effectiveFollowsYou = _loadedUser?.followsYou ?? widget.followsYou;
                      final bool isFriend = _isFollowing && effectiveFollowsYou;
                      String followLabel = 'Follow';
                      if (isFriend) {
                        followLabel = 'Friends 👥';
                      } else if (_isFollowing) {
                        followLabel = 'Following';
                      } else if (effectiveFollowsYou) {
                        followLabel = 'Follow Back';
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPillButton(
                            followLabel,
                            isPrimary: !_isFollowing,
                            onTap: _handleToggleFollow,
                          ),
                          const SizedBox(width: 8),
                          _buildPillButton(
                            'Message',
                            isPrimary: false,
                            onTap: () {
                              final targetUid = _loadedUser?.id ?? widget.userId ?? 4;
                              final thread = ChatManager.instance.getOrCreateThread(
                                userId: targetUid,
                                username: displayName.isNotEmpty ? displayName : username,
                                avatarUrl: avatarUrl,
                                isVerified: isVerified,
                                isFollowing: _isFollowing,
                                followsYou: effectiveFollowsYou,
                                followersCount: _formatCount(_followersCount),
                              );
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(thread: thread),
                                ),
                              ).then((_) {
                                if (mounted) {
                                  final currentThread = ChatManager.instance.getThread(thread.id);
                                  if (currentThread.isFollowing != _isFollowing) {
                                    setState(() {
                                      _isFollowing = currentThread.isFollowing;
                                    });
                                  }
                                }
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Bio
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      bio,
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
            CustomScrollView(slivers: buildProfileTabSlivers(0, isCleanSlate: (_loadedUser?.id ?? widget.userId) != 1)), // Music
            CustomScrollView(slivers: buildProfileTabSlivers(1, isCleanSlate: (_loadedUser?.id ?? widget.userId) != 1)), // Grid
            CustomScrollView(slivers: buildProfileTabSlivers(2, isCleanSlate: (_loadedUser?.id ?? widget.userId) != 1)), // Shop
            CustomScrollView(slivers: buildProfileTabSlivers(3, isCleanSlate: (_loadedUser?.id ?? widget.userId) != 1)), // Saved
            CustomScrollView(slivers: buildProfileTabSlivers(4, isCleanSlate: (_loadedUser?.id ?? widget.userId) != 1)), // Liked
          ],
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

  Widget _buildPillButton(String label, {required bool isPrimary, required VoidCallback onTap}) {
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
