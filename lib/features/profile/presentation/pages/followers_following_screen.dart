import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/profile_sync_service.dart';
import '../screens/public_profile_screen.dart';
import '../style/pulse_tokens.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final int? userId;
  final String username;
  final int initialTabIndex; // 0: Followers, 1: Following
  final int? initialFollowersCount;
  final int? initialFollowingCount;
  final List<UserModel>? initialFollowers;
  final List<UserModel>? initialFollowing;

  const FollowersFollowingScreen({
    super.key,
    this.userId,
    required this.username,
    this.initialTabIndex = 0,
    this.initialFollowersCount,
    this.initialFollowingCount,
    this.initialFollowers,
    this.initialFollowing,
  });

  @override
  State<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  String _searchQuery = '';

  static final List<UserModel> _mockFollowers = [
    UserModel(
      id: 2,
      username: 'bunheng',
      email: 'bunheng@vilo.app',
      displayName: 'Lim Bunheng',
      bio: 'Video Engine & Feed Specialist | Vilo Team',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
      isVerified: true,
      isFollowing: true,
      followsYou: true,
      followersCount: 1,
      followingCount: 1,
    ),
    UserModel(
      id: 3,
      username: 'rithysak',
      email: 'rithysak@vilo.app',
      displayName: 'Chhuon Rithysak',
      bio: 'Mobile UI/UX Developer & Orders Lead',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
      isVerified: true,
      isFollowing: false,
      followsYou: true,
      followersCount: 0,
      followingCount: 1,
    ),
    UserModel(
      id: 4,
      username: 'kimliza',
      email: 'kimliza@vilo.app',
      displayName: 'Kim Liza',
      bio: 'Social Stories & Real-Time Chat Specialist',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
      isVerified: true,
      isFollowing: false,
      followsYou: true,
      followersCount: 0,
      followingCount: 1,
    ),
    UserModel(
      id: 7,
      username: 'sophia_art',
      email: 'sophia@vilo.app',
      displayName: 'Sophia Vance',
      bio: 'Digital Artist & Visual Storyteller',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80',
      isVerified: true,
      isFollowing: true,
      followsYou: true,
      followersCount: 1,
      followingCount: 1,
    ),
  ];

  static final List<UserModel> _mockFollowing = [
    UserModel(
      id: 2,
      username: 'bunheng',
      email: 'bunheng@vilo.app',
      displayName: 'Lim Bunheng',
      bio: 'Video Engine & Feed Specialist | Vilo Team',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
      isVerified: true,
      isFollowing: true,
      followsYou: true,
      followersCount: 1,
      followingCount: 1,
    ),
    UserModel(
      id: 7,
      username: 'sophia_art',
      email: 'sophia@vilo.app',
      displayName: 'Sophia Vance',
      bio: 'Digital Artist & Visual Storyteller',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80',
      isVerified: true,
      isFollowing: true,
      followsYou: true,
      followersCount: 1,
      followingCount: 1,
    ),
    UserModel(
      id: 10,
      username: 'davi_beats',
      email: 'davi@vilo.app',
      displayName: 'David Miller',
      bio: 'Lo-fi producer & sound designer',
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=80',
      isVerified: true,
      isFollowing: true,
      followsYou: false,
      followersCount: 1,
      followingCount: 0,
    ),
  ];

  int get _displayFollowersCount {
    if (_followers.isNotEmpty) return _followers.length;
    if (widget.initialFollowersCount != null) return widget.initialFollowersCount!;
    return 0;
  }

  int get _displayFollowingCount {
    if (_following.isNotEmpty) return _following.where((u) => u.isFollowing).length;
    if (widget.initialFollowingCount != null) return widget.initialFollowingCount!;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );

    final isMe = (widget.userId == null || widget.userId == ProfileSyncService.instance.cachedMyProfile?.id);
    final cachedF = isMe ? ProfileSyncService.instance.cachedFollowers : null;
    final cachedFl = isMe ? ProfileSyncService.instance.cachedFollowing : null;

    _followers = widget.initialFollowers ?? (cachedF != null ? List.from(cachedF) : []);
    _following = widget.initialFollowing ?? (cachedFl != null ? List.from(cachedFl) : []);

    _isLoadingFollowers = _followers.isEmpty;
    _isLoadingFollowing = _following.isEmpty;

    _fetchLists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLists() async {
    final uid = widget.userId;
    if (uid == null) return;

    if (mounted) {
      setState(() {
        _isLoadingFollowers = _followers.isEmpty;
        _isLoadingFollowing = _following.isEmpty;
      });
    }

    final isMe = (uid == ProfileSyncService.instance.cachedMyProfile?.id);

    final followersFuture = ProfileRemoteDataSource.instance.getFollowers(uid).then((fList) {
      if (mounted) {
        setState(() {
          _followers = fList;
          _isLoadingFollowers = false;
        });
      }
      if (isMe) {
        ProfileSyncService.instance.cachedFollowers = List.from(fList);
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          if (_followers.isEmpty) _followers = List.from(_mockFollowers);
          _isLoadingFollowers = false;
        });
      }
    });

    final followingFuture = ProfileRemoteDataSource.instance.getFollowing(uid).then((flList) {
      if (mounted) {
        setState(() {
          _following = flList;
          _isLoadingFollowing = false;
        });
      }
      if (isMe) {
        ProfileSyncService.instance.cachedFollowing = List.from(flList);
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          if (_following.isEmpty) _following = List.from(_mockFollowing);
          _isLoadingFollowing = false;
        });
      }
    });

    await Future.wait([followersFuture, followingFuture]);
  }

  Future<void> _toggleFollowUser(UserModel targetUser, bool isFollowersTab) async {
    HapticFeedback.lightImpact();
    final newStatus = !targetUser.isFollowing;

    setState(() {
      if (isFollowersTab) {
        final index = _followers.indexWhere((u) => u.id == targetUser.id);
        if (index != -1) {
          _followers[index] = _followers[index].copyWith(isFollowing: newStatus);
        }
      } else {
        final index = _following.indexWhere((u) => u.id == targetUser.id);
        if (index != -1) {
          _following[index] = _following[index].copyWith(isFollowing: newStatus);
        }
      }
    });

    ProfileSyncService.instance.notifyFollowChanged(
      targetUserId: targetUser.id,
      isFollowing: newStatus,
      targetUser: targetUser,
    );

    try {
      if (targetUser.id > 0) {
        if (newStatus) {
          await ProfileRemoteDataSource.instance.toggleFollow(targetUser.id);
        } else {
          await ProfileRemoteDataSource.instance.unfollow(targetUser.id);
        }
      }
    } catch (_) {
      // Revert if API fails
      if (mounted) {
        ProfileSyncService.instance.notifyFollowChanged(
          targetUserId: targetUser.id,
          isFollowing: !newStatus,
          targetUser: targetUser,
        );
        setState(() {
          if (isFollowersTab) {
            final index = _followers.indexWhere((u) => u.id == targetUser.id);
            if (index != -1) {
              _followers[index] = _followers[index].copyWith(isFollowing: !newStatus);
            }
          } else {
            final index = _following.indexWhere((u) => u.id == targetUser.id);
            if (index != -1) {
              _following[index] = _following[index].copyWith(isFollowing: !newStatus);
            }
          }
        });
      }
    }
  }

  List<UserModel> _filterList(List<UserModel> originalList) {
    if (_searchQuery.trim().isEmpty) return originalList;
    final q = _searchQuery.toLowerCase();
    return originalList.where((u) {
      return u.username.toLowerCase().contains(q) ||
          u.displayName.toLowerCase().contains(q) ||
          (u.bio != null && u.bio!.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PulseColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('@${widget.username}', style: PulseTypography.bodyLg),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: [
                Tab(text: '$_displayFollowersCount Followers'),
                Tab(text: '$_displayFollowingCount Following'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: PulseColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PulseColors.surfaceStroke),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Search followers or following...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                    ),
                ],
              ),
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(_filterList(_followers), isFollowersTab: true, isLoading: _isLoadingFollowers),
                _buildUserList(_filterList(_following), isFollowersTab: false, isLoading: _isLoadingFollowing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users, {required bool isFollowersTab, required bool isLoading}) {
    if (isLoading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowersTab ? Icons.people_outline_rounded : Icons.person_add_outlined,
              color: Colors.white24,
              size: 64,
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching users found'
                  : (isFollowersTab ? 'No followers yet' : 'Not following anyone yet'),
              style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              isFollowersTab
                  ? 'Users who follow this profile will appear here'
                  : 'Profiles followed by this account will appear here',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLists,
      color: Colors.white,
      backgroundColor: const Color(0xFF1E1E24),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: users.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = users[index];
          final avatarUrl = user.avatarUrl ??
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: PulseColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PulseColors.surfaceStroke),
            ),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => _openPublicProfile(user),
                  child: ClipOval(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: PulseColors.surfaceContainer,
                          child: const Icon(Icons.person, color: Colors.white70, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Username
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openPublicProfile(user),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.displayName.isNotEmpty ? user.displayName : user.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Color(0xFF2F80ED), size: 14),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Follow / Following action button
                GestureDetector(
                  onTap: () => _toggleFollowUser(user, isFollowersTab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: user.isFollowing ? PulseColors.actionSecondary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: user.isFollowing ? Border.all(color: PulseColors.surfaceStroke) : null,
                    ),
                    child: Text(
                      user.isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: user.isFollowing ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openPublicProfile(UserModel user) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: user.id,
          username: user.username,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          bio: user.bio,
          isFollowing: user.isFollowing,
        ),
      ),
    );
    if (mounted) {
      _fetchLists();
    }
  }
}
