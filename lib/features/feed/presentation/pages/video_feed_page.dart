import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/app.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/video_feed_model.dart';
import '../widgets/share_bottom_sheet.dart';
import '../widgets/comment_bottom_sheet.dart';
import 'sound_detail_page.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';

class VideoFeedPage extends StatefulWidget {
  final bool isActive;
  final String feedType; // 'FOR_YOU' or 'FOLLOWING'

  const VideoFeedPage({
    super.key,
    this.isActive = true,
    this.feedType = 'FOR_YOU',
  });

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> with AutomaticKeepAliveClientMixin {
  static final Map<String, int> _savedPageIndices = {};

  late int _currentPage;
  late PageController _pageController;
  List<VideoFeedModel> _videos = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentPage = _savedPageIndices[widget.feedType] ?? 0;
    _pageController = PageController(initialPage: _currentPage);

    // Instant zero-latency display if feed is already in memory cache
    final cached = FeedRemoteDataSource.instance.getCachedFeed(widget.feedType);
    if (cached != null && cached.isNotEmpty) {
      _videos = cached;
      _isLoading = false;
    }

    _loadVideos();
    ProfileSyncService.instance.followEvents.addListener(_onGlobalFollowChanged);
  }

  @override
  void didUpdateWidget(covariant VideoFeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedType != widget.feedType) {
      _currentPage = _savedPageIndices[widget.feedType] ?? 0;
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentPage);
      _loadVideos();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    ProfileSyncService.instance.followEvents.removeListener(_onGlobalFollowChanged);
    super.dispose();
  }

  void _onGlobalFollowChanged() {
    if (!mounted) return;
    final event = ProfileSyncService.instance.followEvents.value;
    if (event != null) {
      setState(() {
        _videos = _videos.map((v) {
          if (v.creatorId == event.targetUserId) {
            return v.copyWith(isFollowing: event.isFollowing);
          }
          return v;
        }).toList();
      });
    }
  }

  Future<void> _loadVideos() async {
    if (_videos.isEmpty) {
      setState(() => _isLoading = true);
    }
    final feed = await FeedRemoteDataSource.instance.getFeed(feedType: widget.feedType);
    if (mounted) {
      setState(() {
        _videos = feed;
        _isLoading = false;
      });
      if (_currentPage >= feed.length && feed.isNotEmpty) {
        _currentPage = feed.length - 1;
        _savedPageIndices[widget.feedType] = _currentPage;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_outlined, color: Colors.white38, size: 56),
              const SizedBox(height: 12),
              Text(
                widget.feedType == 'FOLLOWING'
                    ? 'Follow creators to see their videos here!'
                    : 'No videos available yet.',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: PageView.builder(
          key: PageStorageKey('video_page_view_${widget.feedType}'),
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _videos.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
              _savedPageIndices[widget.feedType] = index;
            });
          },
          itemBuilder: (context, index) {
            return _VideoPostWidget(
              key: ValueKey('video_${_videos[index].id}'),
              video: _videos[index],
              isCurrentPage: _currentPage == index,
              isActive: widget.isActive,
            );
          },
        ),
      ),
    );
  }
}

class _VideoPostWidget extends StatefulWidget {
  final VideoFeedModel video;
  final bool isCurrentPage;
  final bool isActive;

  const _VideoPostWidget({
    super.key,
    required this.video,
    required this.isCurrentPage,
    required this.isActive,
  });

  @override
  State<_VideoPostWidget> createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<_VideoPostWidget>
    with RouteAware, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _manuallyPaused = false;
  late bool _isFollowing;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.video.isFollowing;
    WidgetsBinding.instance.addObserver(this);

    final url = widget.video.videoUrl;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      _controller = VideoPlayerController.asset(url);
    }

    _controller.addListener(_videoListener);
    _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.setLooping(true);
      setState(() {});
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
        _controller.play();
      }
    }).catchError((error) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _videoListener() {
    if (!mounted || !_controller.value.isInitialized) return;
    final value = _controller.value;
    if (value.duration > Duration.zero && value.position >= value.duration) {
      _controller.seekTo(Duration.zero);
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
        _controller.play();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final modalRoute = ModalRoute.of(context);
      if (modalRoute != null) {
        routeObserver.subscribe(this, modalRoute);
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _VideoPostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.isFollowing != widget.video.isFollowing) {
      _isFollowing = widget.video.isFollowing;
    }

    if (oldWidget.video.videoUrl != widget.video.videoUrl) {
      _controller.removeListener(_videoListener);
      _controller.dispose();
      final url = widget.video.videoUrl;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        _controller = VideoPlayerController.asset(url);
      }
      _controller.addListener(_videoListener);
      _controller.initialize().then((_) {
        if (!mounted) return;
        _controller.setLooping(true);
        setState(() {});
        if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
          _controller.play();
        }
      }).catchError((_) {});
    }

    final shouldPlay = widget.isActive && widget.isCurrentPage && !_manuallyPaused;
    if (_controller.value.isInitialized) {
      if (shouldPlay && !_controller.value.isPlaying) {
        _controller.play();
      } else if (!shouldPlay && _controller.value.isPlaying) {
        _controller.pause();
      }
    }
  }

  @override
  void didPushNext() {
    if (_controller.value.isInitialized && _controller.value.isPlaying) {
      _controller.pause();
      if (mounted) setState(() {});
    }
  }

  @override
  void didPopNext() {
    if (widget.isActive && widget.isCurrentPage && !_manuallyPaused && _controller.value.isInitialized) {
      _controller.play();
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_controller.value.isInitialized && _controller.value.isPlaying) {
        _controller.pause();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused && _controller.value.isInitialized) {
        _controller.play();
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _manuallyPaused = true;
        _controller.pause();
      } else {
        _manuallyPaused = false;
        _controller.play();
      }
    });
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicProfileScreen(
          userId: widget.video.creatorId > 0 ? widget.video.creatorId : null,
          username: widget.video.username,
          displayName: widget.video.displayName,
          avatarUrl: widget.video.avatarUrl,
          isFollowing: _isFollowing,
          initialVideos: [widget.video],
        ),
      ),
    );
  }

  void _toggleFollow() async {
    final newFollowState = !_isFollowing;
    setState(() {
      _isFollowing = newFollowState;
    });

    ProfileSyncService.instance.notifyFollowChanged(
      targetUserId: widget.video.creatorId,
      isFollowing: newFollowState,
      targetUser: UserModel(
        id: widget.video.creatorId,
        username: widget.video.username.replaceAll('@', ''),
        email: '',
        displayName: widget.video.displayName,
        avatarUrl: widget.video.avatarUrl,
        isVerified: widget.video.isVerified,
        isFollowing: newFollowState,
        followersCount: 0,
        followingCount: 0,
      ),
    );

    final identifier = widget.video.creatorId > 0 ? widget.video.creatorId : widget.video.username;
    await FeedRemoteDataSource.instance.toggleFollow(identifier, skipNotify: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        // Background Video
        Positioned.fill(
          child: _controller.value.isInitialized &&
                  _controller.value.size.width > 0 &&
                  _controller.value.size.height > 0
              ? GestureDetector(
                  onTap: _togglePlayPause,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                      if (!_controller.value.isPlaying)
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                    ],
                  ),
                )
              : Container(
                  color: const Color(0xFF121216),
                  child: Center(
                    child: _controller.value.hasError
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_circle_outline_rounded, color: Colors.white24, size: 54),
                              const SizedBox(height: 10),
                              Text(
                                'Video playback paused',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13),
                              ),
                            ],
                          )
                        : const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          ),
                  ),
                ),
        ),

        // Dark gradient overlay at the bottom for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Right side interaction buttons
        Positioned(
          right: 16,
          bottom: 140, // Leave space for bottom nav
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Avatar with + follow button
              SizedBox(
                height: 56,
                width: 48,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _goToProfile,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.2),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(widget.video.avatarUrl),
                          onBackgroundImageError: (_, __) {},
                          backgroundColor: Colors.grey[900],
                        ),
                      ),
                    ),
                    // Only show + badge if NOT already followed and NOT current user
                    if (!_isFollowing && !widget.video.isMe)
                      Positioned(
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _toggleFollow,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFE2C55), // Red follow badge
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Like
              _InteractionButton(
                icon: Icons.favorite, 
                label: widget.video.likes,
                activeColor: Colors.red,
                isToggleable: true,
              ),
              
              // Comment
              _InteractionButton(
                icon: Icons.comment, 
                label: widget.video.comments,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CommentBottomSheet(),
                  );
                },
              ),
              
              // Bookmark
              _InteractionButton(
                icon: Icons.bookmark, 
                label: widget.video.saves,
                activeColor: Colors.yellow,
                isToggleable: true,
              ),
              
              // Share
              _InteractionButton(
                icon: Icons.reply, 
                label: 'Share', 
                showLabel: false,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ShareBottomSheet(),
                  );
                },
              ),
              
              // Music Disc
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SoundDetailPage(),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1518770660439-4636190af475?w=100'),
                  onBackgroundImageError: (_, __) {},
                ),
              ),
            ],
          ),
        ),

        // Bottom left user info and caption
        Positioned(
          left: 16,
          bottom: 140, // Leave space for bottom nav
          right: 80, // Prevent overlapping with right column
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _goToProfile,
                    child: Text(
                      widget.video.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (widget.video.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: Colors.blueAccent, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.video.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.video.musicTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InteractionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool showLabel;
  final Color? activeColor;
  final bool isToggleable;
  final VoidCallback? onTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    this.showLabel = true,
    this.activeColor,
    this.isToggleable = false,
    this.onTap,
  });

  @override
  State<_InteractionButton> createState() => _InteractionButtonState();
}

class _InteractionButtonState extends State<_InteractionButton> {
  bool _isActive = false;

  void _handleTap() {
    if (widget.isToggleable) {
      setState(() {
        _isActive = !_isActive;
      });
    }
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = (_isActive && widget.activeColor != null) 
        ? widget.activeColor! 
        : Colors.white;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          children: [
            Icon(widget.icon, color: color, size: 32),
            if (widget.showLabel) ...[
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
