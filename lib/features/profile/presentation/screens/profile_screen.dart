import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/media_url.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../inbox_activity/data/datasources/thought_story_manager.dart';
import '../../../inbox_activity/domain/entities/shared_thought_story.dart';
import '../../../inbox_activity/presentation/pages/share_thought_screen.dart';
import '../../../inbox_activity/presentation/pages/story_viewer_screen.dart';
import '../../../inbox_activity/presentation/widgets/animated_mini_music_wave.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/data/models/video_feed_model.dart';
import '../../../feed/presentation/pages/video_feed_page.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/profile_sync_service.dart';
import '../../../shop/services/shop_service.dart';
import '../../../shop/models/product.dart';
import '../mock/profile_mock_data.dart';
import '../pages/edit_profile_screen.dart';
import '../pages/followers_following_screen.dart';
import '../style/pulse_tokens.dart';
import '../widgets/profile_tab_content.dart';
import '../widgets/profile_menu_drawer.dart';
import '../widgets/vilo_tab_bar_view.dart';

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
  List<SoundTrack> _mySounds = [];
  List<VideoFeedModel> _myVideos = [];
  List<VideoFeedModel> _savedVideos = [];
  List<VideoFeedModel> _likedVideos = [];
  List<Product> _myProducts = [];
  final Set<int> _loadingCategories = <int>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    // Initialize with active profile from cache/token storage
    _user =
        ProfileSyncService.instance.cachedMyProfile ??
        UserModel(
          id: 0,
          username: '',
          email: '',
          displayName: 'User',
          bio: '',
          avatarUrl:
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
          isVerified: false,
          followersCount: 0,
          followingCount: 0,
        );
    ProfileSyncService.instance.followEvents.addListener(_onFollowEvent);
    ProfileSyncService.instance.videoUploadedEvents.addListener(
      _onVideoUploaded,
    );
    ProfileSyncService.instance.videoInteractionEvents.addListener(
      _onVideoInteractionEvent,
    );
    ProfileSyncService.instance.videoDeletedEvents.addListener(_onVideoDeleted);
    ProfileSyncService.instance.soundUploadedEvents.addListener(
      _onSoundUploaded,
    );
    ProfileSyncService.instance.soundDeletedEvents.addListener(_onSoundDeleted);
    ProfileSyncService.instance.interactionEvents.addListener(
      _onInteractionEvent,
    );
    ProfileSyncService.instance.profileUpdatedEvents.addListener(
      _onProfileUpdated,
    );
    ProfileSyncService.instance.productUploadedEvents.addListener(
      _onProductUploaded,
    );
    ShopService.instance.publishedProductNotifier.addListener(
      _onProductUploaded,
    );

    // Instant zero-latency seed from cache if available
    final cached = (_user != null && _user!.id > 0)
        ? (FeedRemoteDataSource.instance.getCachedUserVideos(_user!.id) ??
              FeedRemoteDataSource.instance.getCachedUserVideos(
                _user!.username,
              ))
        : null;
    if (cached != null && cached.isNotEmpty) {
      _myVideos = List.from(cached);
    }
    _loadProfile();
  }

  void _onProfileUpdated() {
    final updated = ProfileSyncService.instance.profileUpdatedEvents.value;
    if (updated != null && mounted) {
      setState(() => _user = updated);
    }
  }

  void _onProductUploaded() {
    final product =
        ProfileSyncService.instance.productUploadedEvents.value ??
        ShopService.instance.publishedProductNotifier.value;
    if (!mounted || product == null) return;

    final isMine =
        ProfileSyncService.instance.isCurrentUser(
          username: product.seller,
          id: product.sellerId,
        ) ||
        (_user?.id.toString() == product.sellerId) ||
        (_user?.username.isNotEmpty == true &&
            product.seller?.replaceAll('@', '').toLowerCase() ==
                _user!.username.replaceAll('@', '').toLowerCase());
    if (!isMine) return;

    setState(() {
      _myProducts.removeWhere((item) => item.id == product.id);
      _myProducts.insert(0, product);
    });
  }

  void _onFollowEvent() {
    final event = ProfileSyncService.instance.followEvents.value;
    if (event != null && mounted) {
      if (_user != null) {
        final updatedFollowing = (_user!.followingCount + event.delta).clamp(
          0,
          999999999,
        );
        setState(() {
          _user = _user!.copyWith(followingCount: updatedFollowing);
        });
      }
    }
  }

  void _onVideoUploaded() {
    final video = ProfileSyncService.instance.videoUploadedEvents.value;
    if (video != null && mounted) {
      setState(() {
        final existingIndex = _myVideos.indexWhere((v) => v.id == video.id);
        if (existingIndex != -1) {
          _myVideos[existingIndex] = video;
        } else {
          _myVideos = [video, ..._myVideos];
        }
      });
    }
  }

  void _onVideoDeleted() {
    final deletedId = ProfileSyncService.instance.videoDeletedEvents.value;
    if (deletedId != null && mounted) {
      setState(() {
        _myVideos.removeWhere((v) => v.id == deletedId);
        _likedVideos.removeWhere((v) => v.id == deletedId);
        _savedVideos.removeWhere((v) => v.id == deletedId);
      });
    }
  }

  void _onSoundUploaded() {
    final sound = ProfileSyncService.instance.soundUploadedEvents.value;
    if (sound != null && mounted) {
      setState(() {
        _mySounds.removeWhere((s) => s.id == sound.id);
        _mySounds = [sound, ..._mySounds];
      });
    }
  }

  void _onSoundDeleted() {
    final deletedId = ProfileSyncService.instance.soundDeletedEvents.value;
    if (deletedId != null && mounted) {
      setState(() {
        _mySounds.removeWhere((s) => s.id == deletedId);
      });
    }
  }

  void _onVideoInteractionEvent() {
    final event = ProfileSyncService.instance.videoInteractionEvents.value;
    if (event == null || !mounted) return;

    setState(() {
      final myIdx = _myVideos.indexWhere((v) => v.id == event.videoId);
      if (myIdx != -1) {
        _myVideos[myIdx] = _myVideos[myIdx].copyWith(
          isLiked: event.isLiked,
          likeCount: event.likeCount,
          isSaved: event.isSaved,
          saveCount: event.saveCount,
          commentCount: event.commentCount,
        );
      }

      if (event.isSaved != null) {
        if (event.isSaved == true) {
          final existingIdx = _savedVideos.indexWhere(
            (v) => v.id == event.videoId,
          );
          if (existingIdx != -1) {
            _savedVideos[existingIdx] = _savedVideos[existingIdx].copyWith(
              isSaved: true,
              saveCount: event.saveCount,
              isLiked: event.isLiked,
              likeCount: event.likeCount,
              commentCount: event.commentCount,
            );
          } else if (event.video != null) {
            _savedVideos.insert(
              0,
              event.video!.copyWith(isSaved: true, saveCount: event.saveCount),
            );
          }
        } else {
          _savedVideos.removeWhere((v) => v.id == event.videoId);
        }
      } else {
        final existingIdx = _savedVideos.indexWhere(
          (v) => v.id == event.videoId,
        );
        if (existingIdx != -1) {
          _savedVideos[existingIdx] = _savedVideos[existingIdx].copyWith(
            isLiked: event.isLiked,
            likeCount: event.likeCount,
            commentCount: event.commentCount,
          );
        }
      }

      if (event.isLiked != null) {
        if (event.isLiked == true) {
          final existingIdx = _likedVideos.indexWhere(
            (v) => v.id == event.videoId,
          );
          if (existingIdx != -1) {
            _likedVideos[existingIdx] = _likedVideos[existingIdx].copyWith(
              isLiked: true,
              likeCount: event.likeCount,
              isSaved: event.isSaved,
              saveCount: event.saveCount,
              commentCount: event.commentCount,
            );
          } else if (event.video != null) {
            _likedVideos.insert(
              0,
              event.video!.copyWith(isLiked: true, likeCount: event.likeCount),
            );
          }
        } else {
          _likedVideos.removeWhere((v) => v.id == event.videoId);
        }
      } else {
        final existingIdx = _likedVideos.indexWhere(
          (v) => v.id == event.videoId,
        );
        if (existingIdx != -1) {
          _likedVideos[existingIdx] = _likedVideos[existingIdx].copyWith(
            isSaved: event.isSaved,
            saveCount: event.saveCount,
            commentCount: event.commentCount,
          );
        }
      }
    });
  }

  void _onInteractionEvent() {
    if (mounted) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    try {
      final user = await ProfileRemoteDataSource.instance.getMyProfile();
      if (mounted) {
        setState(() => _user = user);
        ProfileSyncService.instance.cachedMyProfile = user;
      }
    } catch (e) {
      debugPrint('[ProfileScreen] getMyProfile notice: $e');
    }

    // Load the seller's real products for the Shop tab. Do not use the global
    // catalog here because it contains products from other accounts.
    if (_user != null && _user!.id > 0) {
      try {
        final products = await ShopService.instance.getProductsForSeller(
          _user!.id.toString(),
        );
        if (mounted) setState(() => _myProducts = products);
      } catch (e) {
        debugPrint('[ProfileScreen] get seller products notice: $e');
      }
    }

    // 1. Load user's uploaded sounds
    try {
      final sounds = await FeedRemoteDataSource.instance.getMySounds();
      if (mounted) {
        setState(() => _mySounds = sounds);
      }
    } catch (_) {
      try {
        if (_user != null && _user!.id > 0) {
          final fallbackSounds = await FeedRemoteDataSource.instance
              .getUserSounds(_user!.id);
          if (mounted) {
            setState(() => _mySounds = fallbackSounds);
          }
        }
      } catch (_) {}
    }

    // 2. Always fetch posted videos from backend for the user
    try {
      final identifier = (_user?.id != null && _user!.id > 0)
          ? _user!.id
          : (_user?.username.isNotEmpty == true ? _user!.username : 'me');
      final videos = await FeedRemoteDataSource.instance.getUserVideos(
        identifier,
        forceRefresh: true,
      );
      if (mounted) {
        setState(() => _myVideos = List.from(videos));
      }
    } catch (_) {
      try {
        final videos = await FeedRemoteDataSource.instance.getMyVideos();
        if (mounted) {
          setState(() => _myVideos = videos);
        }
      } catch (e) {
        debugPrint('[ProfileScreen] getUserVideos notice: $e');
      }
    }

    // 3. Load user's saved/bookmarked videos
    try {
      final saved = await FeedRemoteDataSource.instance.getSavedVideos();
      if (mounted) {
        setState(() => _savedVideos = List.from(saved));
      }
    } catch (e) {
      debugPrint('[ProfileScreen] getSavedVideos notice: $e');
    }

    // 4. Load user's liked videos
    try {
      final liked = await FeedRemoteDataSource.instance.getLikedVideos();
      if (mounted) {
        setState(() => _likedVideos = List.from(liked));
      }
    } catch (e) {
      debugPrint('[ProfileScreen] getLikedVideos notice: $e');
    }

    // Pre-warm following & followers cache in background for zero-latency instant listing
    final targetId = _user?.id ?? 1;
    if (targetId > 0) {
      ProfileRemoteDataSource.instance
          .getFollowing(targetId)
          .then((fl) {
            ProfileSyncService.instance.cachedFollowing = List.from(fl);
          })
          .catchError((_) {});
      ProfileRemoteDataSource.instance
          .getFollowers(targetId)
          .then((f) {
            ProfileSyncService.instance.cachedFollowers = List.from(f);
          })
          .catchError((_) {});
    }
  }

  Future<void> _refreshCategory(int categoryIndex) async {
    if (categoryIndex < 0 ||
        categoryIndex > 4 ||
        _loadingCategories.contains(categoryIndex)) {
      return;
    }

    final minimumAnimation = Future<void>.delayed(
      const Duration(milliseconds: 450),
    );
    setState(() => _loadingCategories.add(categoryIndex));
    try {
      final identifier = (_user?.id != null && _user!.id > 0)
          ? _user!.id
          : (_user?.username.isNotEmpty == true ? _user!.username : 'me');

      switch (categoryIndex) {
        case 0:
          try {
            final sounds = await FeedRemoteDataSource.instance.getMySounds();
            if (mounted) setState(() => _mySounds = sounds);
          } catch (_) {
            if (_user != null && _user!.id > 0) {
              final fallback = await FeedRemoteDataSource.instance
                  .getUserSounds(_user!.id);
              if (mounted) setState(() => _mySounds = fallback);
            }
          }
          break;
        case 1:
          final videos = await FeedRemoteDataSource.instance.getUserVideos(
            identifier,
            forceRefresh: true,
          );
          if (mounted) setState(() => _myVideos = List.from(videos));
          break;
        case 2:
          if (_user != null && _user!.id > 0) {
            final products = await ShopService.instance.getProductsForSeller(
              _user!.id.toString(),
            );
            if (mounted) setState(() => _myProducts = products);
          }
          break;
        case 3:
          final saved = await FeedRemoteDataSource.instance.getSavedVideos();
          if (mounted) setState(() => _savedVideos = List.from(saved));
          break;
        case 4:
          final liked = await FeedRemoteDataSource.instance.getLikedVideos();
          if (mounted) setState(() => _likedVideos = List.from(liked));
          break;
      }
    } finally {
      await minimumAnimation;
      if (mounted) setState(() => _loadingCategories.remove(categoryIndex));
    }
  }

  bool _isCategoryLoading(int categoryIndex) =>
      _loadingCategories.contains(categoryIndex);

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

  Future<void> _handleEditProfile() async {
    if (_user == null) return;
    final updated = await Navigator.of(context).push<UserModel>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
    );
    if (updated != null && mounted) {
      setState(() => _user = updated);
      ProfileSyncService.instance.cachedMyProfile = updated;
    }
  }

  void _handleShareProfile() {
    HapticFeedback.lightImpact();
    Clipboard.setData(
      ClipboardData(
        text:
            'https://vilo.app/@${_user?.username ?? ProfileMockData.username}',
      ),
    );
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

  void _confirmDeleteProfileVideo(VideoFeedModel video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Video',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this video? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Deleting video...', style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(milliseconds: 1500),
          backgroundColor: Color(0xFF1E1E24),
        ),
      );

      final success = await FeedRemoteDataSource.instance.deleteVideo(video.id);
      if (!mounted) return;
      if (success) {
        ProfileSyncService.instance.notifyVideoDeleted(video.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video deleted successfully'),
            backgroundColor: Color(0xFF1E1E24),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to delete video. Please check your connection.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    ProfileSyncService.instance.followEvents.removeListener(_onFollowEvent);
    ProfileSyncService.instance.videoUploadedEvents.removeListener(
      _onVideoUploaded,
    );
    ProfileSyncService.instance.videoInteractionEvents.removeListener(
      _onVideoInteractionEvent,
    );
    ProfileSyncService.instance.videoDeletedEvents.removeListener(
      _onVideoDeleted,
    );
    ProfileSyncService.instance.soundUploadedEvents.removeListener(
      _onSoundUploaded,
    );
    ProfileSyncService.instance.soundDeletedEvents.removeListener(
      _onSoundDeleted,
    );
    ProfileSyncService.instance.interactionEvents.removeListener(
      _onInteractionEvent,
    );
    ProfileSyncService.instance.profileUpdatedEvents.removeListener(
      _onProfileUpdated,
    );
    ProfileSyncService.instance.productUploadedEvents.removeListener(
      _onProductUploaded,
    );
    ShopService.instance.publishedProductNotifier.removeListener(
      _onProductUploaded,
    );
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
        MaterialPageRoute(builder: (_) => const ShareThoughtScreen()),
      );

      if (result != null && mounted) {
        ThoughtStoryManager.instance.setStory(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUsername =
        (_user?.username != null && _user!.username.trim().isNotEmpty)
        ? _user!.username.trim()
        : ProfileMockData.username;
    final currentDisplayName =
        (_user?.displayName != null && _user!.displayName.trim().isNotEmpty)
        ? _user!.displayName.trim()
        : currentUsername;
    final currentAvatarUrl =
        (_user?.avatarUrl != null && _user!.avatarUrl!.trim().isNotEmpty)
        ? _user!.avatarUrl!.trim()
        : ProfileMockData.avatarUrl;
    final currentBio = _user?.bio != null
        ? (_user!.bio!.trim().isNotEmpty ? _user!.bio!.trim() : 'No bio yet.')
        : ProfileMockData.bio;
    final followersDisplay = _formatCount(_user?.followersCount ?? 0);
    final followingDisplay = _formatCount(_user?.followingCount ?? 0);
    final totalLikes = _myVideos.fold<int>(0, (sum, v) => sum + v.likeCount);
    final likesDisplay = _formatCount(totalLikes);

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
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF2F80ED),
                size: 16,
              ),
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
        onRefresh: () => _loadProfile(forceRefresh: true),
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
                      valueListenable:
                          ThoughtStoryManager.instance.storyNotifier,
                      builder: (context, currentStory, _) {
                        final isStoryActive = currentStory != null;
                        final messageText = isStoryActive
                            ? currentStory.message
                            : 'Share a thought...';
                        final hasMusic =
                            isStoryActive && currentStory.musicTrack != null;

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
                                constraints: const BoxConstraints(
                                  maxWidth: 160,
                                ),
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
                                      color: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
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
                                          child:
                                              currentAvatarUrl.startsWith(
                                                'assets/',
                                              )
                                              ? Image.asset(
                                                  resolveBackendMediaUrl(
                                                    currentAvatarUrl,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: PulseColors
                                                            .surfaceContainer,
                                                        child: const Icon(
                                                          Icons.person_rounded,
                                                          color: Colors.white70,
                                                          size: 48,
                                                        ),
                                                      ),
                                                )
                                              : Image.network(
                                                  resolveBackendMediaUrl(
                                                    currentAvatarUrl,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: PulseColors
                                                            .surfaceContainer,
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
                    Text(
                      '@$currentUsername',
                      style: PulseTypography.headlineSm,
                    ),
                    const SizedBox(height: 20),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem(
                          'Following',
                          followingDisplay,
                          onTap: () => _openFollowersFollowing(1),
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          'Followers',
                          followersDisplay,
                          onTap: () => _openFollowersFollowing(0),
                        ),
                        _buildDivider(),
                        _buildStatItem('Likes', likesDisplay),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPillButton(
                          'Edit Profile',
                          isPrimary: false,
                          onTap: _handleEditProfile,
                        ),
                        const SizedBox(width: 8),
                        _buildPillButton(
                          'Share Profile',
                          isPrimary: false,
                          onTap: _handleShareProfile,
                        ),
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
                    onTap: _refreshCategory,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(icon: Icon(Icons.music_note_rounded)), // Music (Left)
                      Tab(
                        icon: Icon(Icons.grid_view_rounded),
                      ), // Grid / Posted Videos (Right)
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
                  userSounds: _mySounds,
                  isLoading: _isCategoryLoading(0),
                  onSoundUpdated: (updatedSound) {
                    setState(() {
                      final idx = _mySounds.indexWhere(
                        (s) => s.id == updatedSound.id,
                      );
                      if (idx != -1) {
                        _mySounds[idx] = updatedSound;
                      }
                    });
                  },
                  onSoundDeleted: (deletedSound) {
                    setState(() {
                      _mySounds.removeWhere((s) => s.id == deletedSound.id);
                    });
                  },
                ),
              ), // Music (Index 0)
              _buildCategoryPage(
                1,
                buildProfileTabSlivers(
                  1,
                  userVideos: _myVideos,
                  isLoading: _isCategoryLoading(1),
                  onVideoTap: (video, index) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoFeedPage(
                          isActive: true,
                          initialVideos: _myVideos,
                          initialIndex: index,
                          canDelete:
                              true, // Only posted videos viewed from profile can be deleted
                        ),
                      ),
                    );
                  },
                  onVideoLongPress: (video, index) =>
                      _confirmDeleteProfileVideo(video),
                ),
              ), // Grid / Posted Videos (Index 1)
              _buildCategoryPage(
                2,
                buildProfileTabSlivers(
                  2,
                  userProducts: _myProducts,
                  username: _user?.username,
                  userAvatar:
                      _user?.avatarUrl ??
                      ProfileSyncService.instance.currentUserAvatar,
                  isCurrentUser: true,
                ),
              ), // Shop
              _buildCategoryPage(
                3,
                buildProfileTabSlivers(
                  3,
                  savedVideos: _savedVideos,
                  isLoading: _isCategoryLoading(3),
                  onSavedVideoTap: (video, index) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoFeedPage(
                          isActive: true,
                          initialVideos: _savedVideos,
                          initialIndex: index,
                          canDelete: false,
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
                  isLoading: _isCategoryLoading(4),
                  onLikedVideoTap: (video, index) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoFeedPage(
                          isActive: true,
                          initialVideos: _likedVideos,
                          initialIndex: index,
                          canDelete: false,
                        ),
                      ),
                    );
                  },
                ),
              ), // Liked
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
    bool isPrimary = true,
    VoidCallback? onTap,
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
