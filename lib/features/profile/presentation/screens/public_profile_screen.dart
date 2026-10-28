import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../inbox_activity/data/datasources/inbox_message_manager.dart';
import '../../../inbox_activity/domain/entities/inbox_item.dart';
import '../../../inbox_activity/presentation/pages/chat_detail_screen.dart';
import '../../../bottom_nav/presentation/pages/main_navigation_shell.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/data/models/video_feed_model.dart';
import '../../../feed/presentation/pages/video_feed_page.dart';
import '../../../shop/models/product.dart';
import '../../../shop/services/shop_service.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/profile_sync_service.dart';
import '../mock/profile_mock_data.dart';
import '../pages/edit_profile_screen.dart';
import '../pages/followers_following_screen.dart';
import '../style/pulse_tokens.dart';
import '../widgets/profile_tab_content.dart';
import '../widgets/vilo_tab_bar_view.dart';

class PublicProfileScreen extends StatefulWidget {
  final int? userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isFollowing;
  final List<VideoFeedModel>? initialVideos;

  const PublicProfileScreen({
    super.key,
    this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.isFollowing = false,
    this.initialVideos,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isFollowing;
  int _followersCount = 0;
  UserModel? _loadedUser;
  List<SoundTrack> _userSounds = [];
  List<VideoFeedModel> _userVideos = [];
  List<VideoFeedModel> _savedVideos = [];
  List<VideoFeedModel> _likedVideos = [];
  List<Product> _userProducts = [];
  bool _isLoading = false;
  bool _isFollowUpdating = false;
  final Set<int> _loadingCategories = <int>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    _isFollowing = widget.isFollowing;
    ProfileSyncService.instance.videoInteractionEvents.addListener(
      _onVideoInteractionEvent,
    );
    ProfileSyncService.instance.videoDeletedEvents.addListener(_onVideoDeleted);
    ProfileSyncService.instance.productUploadedEvents.addListener(
      _onProductUploaded,
    );
    ShopService.instance.publishedProductNotifier.addListener(
      _onProductUploaded,
    );

    // Zero-latency instant load: Check initialVideos or in-memory cache
    final identifier = (widget.username != null && widget.username!.isNotEmpty)
        ? widget.username!
        : widget.userId?.toString();

    final cachedUser = identifier != null
        ? ProfileRemoteDataSource.instance.getCachedUser(identifier)
        : (widget.userId != null
              ? ProfileRemoteDataSource.instance.getCachedUser(widget.userId)
              : null);

    if (cachedUser != null) {
      _loadedUser = cachedUser;
      _isFollowing = cachedUser.isFollowing;
      _followersCount = cachedUser.followersCount;
    }

    final cachedVideos =
        widget.initialVideos ??
        (identifier != null
            ? FeedRemoteDataSource.instance.getCachedUserVideos(identifier)
            : null) ??
        (widget.username != null
            ? FeedRemoteDataSource.instance.getCachedUserVideos(
                widget.username!,
              )
            : null) ??
        (widget.userId != null
            ? FeedRemoteDataSource.instance.getCachedUserVideos(
                widget.userId.toString(),
              )
            : null);

    if (cachedVideos != null && cachedVideos.isNotEmpty) {
      _userVideos = List.from(cachedVideos);
    }

    ProfileSyncService.instance.interactionEvents.addListener(
      _onInteractionEvent,
    );

    if (widget.userId != null ||
        (widget.username != null && widget.username!.isNotEmpty)) {
      _fetchPublicProfile();
    }
  }

  void _onInteractionEvent() {
    if (mounted) {
      _fetchPublicProfile();
    }
  }

  void _onProductUploaded() {
    final product =
        ProfileSyncService.instance.productUploadedEvents.value ??
        ShopService.instance.publishedProductNotifier.value;
    if (!mounted || product == null) return;

    final sellerId = _loadedUser?.id.toString() ?? widget.userId?.toString();
    final sellerName = (widget.username ?? _loadedUser?.username ?? '')
        .replaceAll('@', '')
        .toLowerCase();
    final productSeller = (product.seller ?? '')
        .replaceAll('@', '')
        .toLowerCase();
    if (product.sellerId != sellerId &&
        (sellerName.isEmpty || productSeller != sellerName)) {
      return;
    }

    setState(() {
      _userProducts.removeWhere((item) => item.id == product.id);
      _userProducts.insert(0, product);
    });
  }

  Future<void> _fetchPublicProfile() async {
    final identifier = (widget.username != null && widget.username!.isNotEmpty)
        ? widget.username!
        : widget.userId?.toString();
    if (identifier == null) return;

    if (_userVideos.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      // Execute profile fetch, sounds, postings, saved, and liked concurrently
      await Future.wait([
        ProfileRemoteDataSource.instance
            .getUser(identifier)
            .then((user) {
              if (mounted) {
                setState(() {
                  _loadedUser = user;
                  _isFollowing = user.isFollowing;
                  _followersCount = user.followersCount;
                });
              }
            })
            .catchError((_) {}),
        FeedRemoteDataSource.instance
            .getUserVideos(identifier, forceRefresh: true)
            .then((videos) {
              if (mounted) {
                setState(() {
                  _userVideos = videos.isNotEmpty
                      ? videos
                      : (widget.initialVideos ?? []);
                });
              }
            })
            .catchError((_) {}),
        FeedRemoteDataSource.instance
            .getUserSounds(identifier)
            .then((sounds) {
              if (mounted) {
                setState(() => _userSounds = sounds);
              }
            })
            .catchError((_) {}),
        FeedRemoteDataSource.instance
            .getUserSavedVideos(identifier)
            .then((saved) {
              if (mounted) {
                setState(() => _savedVideos = saved);
              }
            })
            .catchError((_) {}),
        FeedRemoteDataSource.instance
            .getUserLikedVideos(identifier)
            .then((liked) {
              if (mounted) {
                setState(() => _likedVideos = liked);
              }
            })
            .catchError((_) {}),
      ]);

      if (ProfileSyncService.instance.isCurrentUser(
        username: widget.username,
        id: widget.userId?.toString() ?? identifier,
      )) {
        FeedRemoteDataSource.instance
            .getSavedVideos()
            .then((saved) {
              if (mounted) {
                setState(() {
                  _savedVideos = List.from(saved);
                });
              }
            })
            .catchError((_) {});
      }

      final sellerId = _loadedUser?.id ?? widget.userId;
      if (sellerId != null && sellerId > 0) {
        final products = await ShopService.instance.getProductsForSeller(
          sellerId.toString(),
        );
        if (mounted) setState(() => _userProducts = products);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCategory(int categoryIndex) async {
    if (categoryIndex < 0 ||
        categoryIndex > 4 ||
        _loadingCategories.contains(categoryIndex)) {
      return;
    }

    final identifier = (widget.username != null && widget.username!.isNotEmpty)
        ? widget.username!
        : widget.userId?.toString();
    if (identifier == null) return;

    final minimumAnimation = Future<void>.delayed(
      const Duration(milliseconds: 450),
    );
    setState(() => _loadingCategories.add(categoryIndex));
    try {
      switch (categoryIndex) {
        case 1:
          final videos = await FeedRemoteDataSource.instance.getUserVideos(
            identifier,
            forceRefresh: true,
          );
          if (mounted) setState(() => _userVideos = List.from(videos));
          break;
        case 2:
          final sellerId = _loadedUser?.id ?? widget.userId;
          if (sellerId != null && sellerId > 0) {
            final products = await ShopService.instance.getProductsForSeller(
              sellerId.toString(),
            );
            if (mounted) setState(() => _userProducts = products);
          }
          break;
        case 3:
          if (ProfileSyncService.instance.isCurrentUser(
            username: widget.username,
            id: widget.userId?.toString() ?? identifier,
          )) {
            final saved = await FeedRemoteDataSource.instance.getSavedVideos();
            if (mounted) setState(() => _savedVideos = List.from(saved));
          }
          break;
        case 4:
          final liked = await FeedRemoteDataSource.instance.getLikedVideos(
            userId: identifier,
          );
          if (mounted) setState(() => _likedVideos = List.from(liked));
          break;
      }
    } finally {
      await minimumAnimation;
      if (mounted) setState(() => _loadingCategories.remove(categoryIndex));
    }
  }

  Widget _buildCategoryPage(int categoryIndex, List<Widget> slivers) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: slivers,
        ),
        if (_loadingCategories.contains(categoryIndex))
          const ColoredBox(
            color: Color(0x66000000),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.2,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    ProfileSyncService.instance.videoInteractionEvents.removeListener(
      _onVideoInteractionEvent,
    );
    ProfileSyncService.instance.videoDeletedEvents.removeListener(
      _onVideoDeleted,
    );
    ProfileSyncService.instance.productUploadedEvents.removeListener(
      _onProductUploaded,
    );
    ShopService.instance.publishedProductNotifier.removeListener(
      _onProductUploaded,
    );
    _tabController.dispose();
    ProfileSyncService.instance.interactionEvents.removeListener(
      _onInteractionEvent,
    );
    super.dispose();
  }

  void _onVideoDeleted() {
    final deletedId = ProfileSyncService.instance.videoDeletedEvents.value;
    if (deletedId != null && mounted) {
      setState(() {
        _userVideos.removeWhere((v) => v.id == deletedId);
        _likedVideos.removeWhere((v) => v.id == deletedId);
        _savedVideos.removeWhere((v) => v.id == deletedId);
      });
    }
  }

  void _onVideoInteractionEvent() {
    final event = ProfileSyncService.instance.videoInteractionEvents.value;
    if (event == null || !mounted) return;

    setState(() {
      final idx = _userVideos.indexWhere((v) => v.id == event.videoId);
      if (idx != -1) {
        _userVideos[idx] = _userVideos[idx].copyWith(
          isLiked: event.isLiked,
          likeCount: event.likeCount,
          isSaved: event.isSaved,
          saveCount: event.saveCount,
          commentCount: event.commentCount,
        );
      }

      final likedIdx = _likedVideos.indexWhere((v) => v.id == event.videoId);
      if (likedIdx != -1) {
        _likedVideos[likedIdx] = _likedVideos[likedIdx].copyWith(
          isLiked: event.isLiked,
          likeCount: event.likeCount,
          isSaved: event.isSaved,
          saveCount: event.saveCount,
          commentCount: event.commentCount,
        );
      }

      final savedIdx = _savedVideos.indexWhere((v) => v.id == event.videoId);
      if (savedIdx != -1) {
        _savedVideos[savedIdx] = _savedVideos[savedIdx].copyWith(
          isLiked: event.isLiked,
          likeCount: event.likeCount,
          isSaved: event.isSaved,
          saveCount: event.saveCount,
          commentCount: event.commentCount,
        );
      }
    });
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainNavigationShell(initialIndex: 0),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _handleToggleFollow() async {
    if (_isFollowUpdating || !mounted) return;
    HapticFeedback.lightImpact();

    var targetUid = _loadedUser?.id ?? widget.userId;
    if (targetUid == null || targetUid <= 0) {
      final identifier = widget.username?.trim();
      if (identifier == null || identifier.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to identify this account.')),
        );
        return;
      }

      setState(() => _isFollowUpdating = true);
      try {
        final user = await ProfileRemoteDataSource.instance.getUser(identifier);
        targetUid = user.id;
        if (targetUid <= 0) {
          throw StateError('The account has no valid user ID.');
        }
        if (mounted) {
          setState(() {
            _loadedUser = user;
            _followersCount = user.followersCount;
            _isFollowing = user.isFollowing;
          });
        }
      } catch (error) {
        if (mounted) {
          setState(() => _isFollowUpdating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load this account: $error')),
          );
        }
        return;
      }
    }

    final followTargetId = targetUid;
    if (followTargetId <= 0) return;

    final newFollowState = !_isFollowing;
    setState(() => _isFollowUpdating = true);
    setState(() {
      _isFollowing = newFollowState;
      if (newFollowState) {
        _followersCount++;
      } else if (_followersCount > 0) {
        _followersCount--;
      }
    });

    // Broadcast follow change immediately so own profile followingCount updates
    ProfileSyncService.instance.notifyFollowChanged(
      targetUserId: followTargetId,
      isFollowing: newFollowState,
    );

    try {
      final serverFollowState = newFollowState
          ? await ProfileRemoteDataSource.instance.toggleFollow(followTargetId)
          : await ProfileRemoteDataSource.instance.unfollow(followTargetId);
      if (mounted && serverFollowState != newFollowState) {
        setState(() {
          _isFollowing = serverFollowState;
          if (serverFollowState && !newFollowState) {
            _followersCount++;
          } else if (!serverFollowState &&
              newFollowState &&
              _followersCount > 0) {
            _followersCount--;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isFollowing = !newFollowState;
          if (newFollowState) {
            _followersCount--;
          } else {
            _followersCount++;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update follow: $error')),
        );
        ProfileSyncService.instance.notifyFollowChanged(
          targetUserId: followTargetId,
          isFollowing: !newFollowState,
        );
      }
    } finally {
      if (mounted) setState(() => _isFollowUpdating = false);
    }
  }

  void _openDirectMessage({
    required String username,
    required String avatarUrl,
  }) {
    HapticFeedback.lightImpact();
    final buyerUser =
        ProfileSyncService.instance.cachedMyProfile ??
        TokenStorage.instance.getUserModel();
    final rawBuyerHandle =
        (buyerUser?.username != null && buyerUser!.username.trim().isNotEmpty)
        ? buyerUser.username.trim()
        : ProfileSyncService.instance.currentUsername;
    if (rawBuyerHandle.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to send a message.'),
          backgroundColor: Color(0xFF2A2A30),
        ),
      );
      return;
    }
    final buyerHandle = rawBuyerHandle.startsWith('@')
        ? rawBuyerHandle
        : '@$rawBuyerHandle';
    final buyerAvatar =
        buyerUser?.avatarUrl ?? ProfileSyncService.instance.currentUserAvatar;
    final peerHandle = username.startsWith('@') ? username : '@$username';
    final peerAvatar = InboxMessageManager.resolveUserAvatar(
      peerHandle,
      candidateAvatar: avatarUrl,
    );
    final threadId = InboxMessageManager.buildThreadId(buyerHandle, peerHandle);

    final existing =
        InboxMessageManager.instance.getThread(threadId) ??
        InboxMessageManager.instance.getThreadByUsername(peerHandle);
    final thread =
        existing ??
        InboxMessageManager.instance.addOrUpdateThread(
          DirectMessageThread(
            id: threadId,
            username: peerHandle,
            avatarUrl: peerAvatar,
            senderHandle: buyerHandle,
            senderAvatar: buyerAvatar,
            recipientHandle: peerHandle,
            recipientAvatar: peerAvatar,
            lastMessage: '',
            timeAgo: 'Just now',
            isVerified: _loadedUser?.isVerified ?? false,
            messages: const [],
          ),
        );

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatDetailScreen(thread: thread)));
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
    final rawUsername =
        _loadedUser?.username ?? widget.username ?? ProfileMockData.username;
    final cleanUsername = rawUsername.startsWith('@')
        ? rawUsername.substring(1)
        : rawUsername;
    final username = cleanUsername;
    final displayName = _loadedUser?.displayName.isNotEmpty == true
        ? _loadedUser!.displayName
        : (widget.displayName?.isNotEmpty == true
              ? widget.displayName!
              : cleanUsername);
    final avatarUrl = _loadedUser?.avatarUrl?.isNotEmpty == true
        ? _loadedUser!.avatarUrl!
        : (widget.avatarUrl?.isNotEmpty == true
              ? widget.avatarUrl!
              : ProfileMockData.avatarUrl);
    final bio = _loadedUser?.bio != null
        ? (_loadedUser!.bio!.trim().isNotEmpty
              ? _loadedUser!.bio!.trim()
              : 'No bio yet.')
        : (widget.bio?.isNotEmpty == true ? widget.bio! : 'No bio yet.');
    final isVerified = _loadedUser?.isVerified ?? false;

    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: PulseColors.onSurface,
          ),
          onPressed: _handleBack,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayName, style: PulseTypography.bodyLg),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF2F80ED),
                size: 16,
              ),
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
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: PulseColors.onSurface,
            ),
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
                      child: avatarUrl.startsWith('assets/')
                          ? Image.asset(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: PulseColors.surfaceContainer,
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white70,
                                      size: 48,
                                    ),
                                  ),
                            )
                          : Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
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
                  Text('@$cleanUsername', style: PulseTypography.headlineSm),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(
                        'Following',
                        _formatCount(_loadedUser?.followingCount ?? 0),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FollowersFollowingScreen(
                                userId: _loadedUser?.id ?? widget.userId,
                                username: username,
                                initialTabIndex: 1,
                                initialFollowingCount:
                                    _loadedUser?.followingCount,
                                initialFollowersCount:
                                    _loadedUser?.followersCount ??
                                    _followersCount,
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
                                initialFollowersCount:
                                    _loadedUser?.followersCount ??
                                    _followersCount,
                                initialFollowingCount:
                                    _loadedUser?.followingCount,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      Builder(
                        builder: (context) {
                          final totalLikes = _userVideos.fold<int>(
                            0,
                            (sum, v) => sum + v.likeCount,
                          );
                          return _buildStatItem(
                            'Likes',
                            _formatCount(totalLikes),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Builder(
                    builder: (context) {
                      final isMe = ProfileSyncService.instance.isCurrentUser(
                        username: username,
                        id:
                            _loadedUser?.id.toString() ??
                            widget.userId?.toString(),
                      );

                      if (isMe) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPillButton(
                              'Edit Profile',
                              isPrimary: false,
                              onTap: () {
                                final userModel =
                                    _loadedUser ??
                                    UserModel(
                                      id:
                                          widget.userId ??
                                          ProfileSyncService
                                              .instance
                                              .cachedMyProfile
                                              ?.id ??
                                          0,
                                      username: username,
                                      email:
                                          _loadedUser?.email ??
                                          ProfileSyncService
                                              .instance
                                              .cachedMyProfile
                                              ?.email ??
                                          '$username@vilo.app',
                                      displayName: displayName,
                                      bio: bio,
                                      avatarUrl: avatarUrl,
                                      isVerified: isVerified,
                                      followersCount: _followersCount,
                                      followingCount:
                                          _loadedUser?.followingCount ?? 0,
                                    );
                                Navigator.of(context)
                                    .push<UserModel>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EditProfileScreen(user: userModel),
                                      ),
                                    )
                                    .then((updated) {
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
                                Clipboard.setData(
                                  ClipboardData(
                                    text: 'https://vilo.app/@$username',
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profile link copied to clipboard!',
                                    ),
                                    backgroundColor: Color(0xFF2F80ED),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPillButton(
                            _isFollowing ? 'Following' : 'Follow',
                            isPrimary: !_isFollowing,
                            onTap: _handleToggleFollow,
                          ),
                          const SizedBox(width: 8),
                          _buildPillButton(
                            'Message',
                            isPrimary: false,
                            onTap: () => _openDirectMessage(
                              username: username,
                              avatarUrl: avatarUrl,
                            ),
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
                  onTap: _refreshCategory,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.music_note_rounded),
                    ), // Music (Index 0)
                    Tab(icon: Icon(Icons.grid_view_rounded)), // Grid (Index 1)
                    Tab(icon: Icon(Icons.shopping_bag_outlined)), // Shop
                    Tab(icon: Icon(Icons.bookmark_border_rounded)), // Saved
                    Tab(icon: Icon(Icons.favorite_border_rounded)), // Liked
                  ],
                ),
              ),
            ),
          ];
        },
        body: ViloTabBarView(
          controller: _tabController,
          children: [
            _buildCategoryPage(
              0,
              buildProfileTabSlivers(
                0,
                userSounds: _userSounds,
                isLoading: _isLoading,
              ),
            ), // Music (Index 0)
            _buildCategoryPage(
              1,
              buildProfileTabSlivers(
                1,
                userVideos: _userVideos,
                isLoading: _isLoading,
                onVideoTap: (video, index) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoFeedPage(
                        isActive: true,
                        initialVideos: _userVideos,
                        initialIndex: index,
                        canDelete: false,
                      ),
                    ),
                  );
                },
              ),
            ), // Grid (Index 1)
            _buildCategoryPage(
              2,
              buildProfileTabSlivers(
                2,
                userProducts: _userProducts,
                username: username,
                userAvatar: avatarUrl,
                isCurrentUser: ProfileSyncService.instance.isCurrentUser(
                  username: username,
                  id: _loadedUser?.id.toString() ?? widget.userId?.toString(),
                ),
              ),
            ), // Shop
            _buildCategoryPage(
              3,
              buildProfileTabSlivers(
                3,
                savedVideos: _savedVideos,
                isLoading: _isLoading || _loadingCategories.contains(3),
                isCurrentUser: ProfileSyncService.instance.isCurrentUser(
                  username: username,
                  id: _loadedUser?.id.toString() ?? widget.userId?.toString(),
                ),
                onSavedVideoTap: (video, index) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoFeedPage(
                        isActive: true,
                        initialVideos: _savedVideos,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
              ),
            ), // Saved
            _buildCategoryPage(
              4,
              buildProfileTabSlivers(
                4,
                likedVideos: _likedVideos,
                isLoading: _isLoading || _loadingCategories.contains(4),
                onLikedVideoTap: (video, index) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoFeedPage(
                        isActive: true,
                        initialVideos: _likedVideos,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
              ),
            ), // Liked
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
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 15,
      width: 1,
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }

  Widget _buildPillButton(
    String label, {
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: PulseColors.background, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
