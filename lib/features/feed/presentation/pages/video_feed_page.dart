import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/app.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/video_model.dart';
import '../controllers/video_feed_manager.dart';
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

  final FeedRemoteDataSource _dataSource = FeedRemoteDataSource.instance;
  late int _currentPage;
  late PageController _pageController;

  List<VideoModel> _videos = [];
  bool _isLoading = true;
  int _apiPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentPage = _savedPageIndices[widget.feedType] ?? 0;
    _pageController = PageController(initialPage: _currentPage);

    // Instant zero-latency display if feed is already in memory cache
    final cached = _dataSource.getCachedFeed(widget.feedType);
    if (cached != null && cached.isNotEmpty) {
      _videos = cached;
      _isLoading = false;
    }

    _fetchFeed();
    ProfileSyncService.instance.followEvents.addListener(_onGlobalFollowChanged);
    VideoFeedManager.instance.latestUploadedVideoNotifier.addListener(_onNewVideoUploaded);
  }

  @override
  void didUpdateWidget(covariant VideoFeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedType != widget.feedType) {
      _currentPage = _savedPageIndices[widget.feedType] ?? 0;
      _pageController.dispose();
      _pageController = PageController(initialPage: _currentPage);
      _fetchFeed(refresh: true);
    }
  }

  @override
  void dispose() {
    VideoFeedManager.instance.latestUploadedVideoNotifier.removeListener(_onNewVideoUploaded);
    ProfileSyncService.instance.followEvents.removeListener(_onGlobalFollowChanged);
    _pageController.dispose();
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

  void _onNewVideoUploaded() {
    final newVideo = VideoFeedManager.instance.latestUploadedVideoNotifier.value;
    if (newVideo == null || !mounted) return;

    if (!_videos.any((v) => v.id == newVideo.id)) {
      setState(() {
        _videos.insert(0, newVideo);
        _currentPage = 0;
        _savedPageIndices[widget.feedType] = 0;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  Future<void> _fetchFeed({bool refresh = false}) async {
    if (refresh) {
      _apiPage = 0;
      _hasMore = true;
    }

    if (_videos.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final fetched = await _dataSource.getFeed(
        page: _apiPage,
        size: 10,
        type: widget.feedType,
        forceRefresh: refresh,
      );

      if (!mounted) return;
      setState(() {
        if (refresh) {
          _videos = fetched;
        } else {
          if (_apiPage == 0) {
            _videos = fetched;
          } else {
            _videos.addAll(fetched);
          }
        }
        _hasMore = fetched.length >= 10;
        _isLoading = false;
        _isLoadingMore = false;
      });

      if (_currentPage >= _videos.length && _videos.isNotEmpty) {
        _currentPage = _videos.length - 1;
        _savedPageIndices[widget.feedType] = _currentPage;
      }

      if (_videos.isNotEmpty && widget.isActive && _currentPage < _videos.length) {
        _recordView(_videos[_currentPage].id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _apiPage++;
    await _fetchFeed(refresh: false);
  }

  void _recordView(int videoId) {
    _dataSource.incrementView(videoId);
  }

  void _onLikeToggled(int index) async {
    final video = _videos[index];
    final newLiked = !video.isLiked;
    final newLikeCount = newLiked ? video.likeCount + 1 : (video.likeCount > 0 ? video.likeCount - 1 : 0);

    setState(() {
      _videos[index] = video.copyWith(
        isLiked: newLiked,
        likeCount: newLikeCount,
      );
    });

    try {
      final res = await _dataSource.toggleLike(video.id, currentlyLiked: video.isLiked);
      if (mounted && res['likeCount'] != null) {
        setState(() {
          _videos[index] = _videos[index].copyWith(
            isLiked: res['isLiked'] as bool?,
            likeCount: res['likeCount'] as int?,
          );
        });
      }
    } catch (_) {}
  }

  void _onSaveToggled(int index) async {
    final video = _videos[index];
    final newSaved = !video.isSaved;
    final newSaveCount = newSaved ? video.saveCount + 1 : (video.saveCount > 0 ? video.saveCount - 1 : 0);

    setState(() {
      _videos[index] = video.copyWith(
        isSaved: newSaved,
        saveCount: newSaveCount,
      );
    });

    try {
      final res = await _dataSource.toggleSave(video.id, currentlySaved: video.isSaved);
      if (mounted && res['saveCount'] != null) {
        setState(() {
          _videos[index] = _videos[index].copyWith(
            isSaved: res['isSaved'] as bool?,
            saveCount: res['saveCount'] as int?,
          );
        });
      }
    } catch (_) {}
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
                widget.feedType.toUpperCase() == 'FOLLOWING'
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

            if (index < _videos.length) {
              _recordView(_videos[index].id);
            }

            if (index >= _videos.length - 2 && _hasMore) {
              _loadMore();
            }
          },
          itemBuilder: (context, index) {
            return _VideoPostWidget(
              key: ValueKey('video_${_videos[index].id}'),
              video: _videos[index],
              isCurrentPage: _currentPage == index,
              isActive: widget.isActive,
              onLikeTap: () => _onLikeToggled(index),
              onSaveTap: () => _onSaveToggled(index),
              onCommentCountChanged: (newCount) {
                setState(() {
                  _videos[index] = _videos[index].copyWith(commentCount: newCount);
                });
              },
            );
          },
        ),
      ),
    );
  }
}

class _VideoPostWidget extends StatefulWidget {
  final VideoModel video;
  final bool isCurrentPage;
  final bool isActive;
  final VoidCallback onLikeTap;
  final VoidCallback onSaveTap;
  final ValueChanged<int> onCommentCountChanged;

  const _VideoPostWidget({
    super.key,
    required this.video,
    required this.isCurrentPage,
    required this.isActive,
    required this.onLikeTap,
    required this.onSaveTap,
    required this.onCommentCountChanged,
  });

  @override
  State<_VideoPostWidget> createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<_VideoPostWidget>
    with RouteAware, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _manuallyPaused = false;
  bool _hasControllerError = false;
  bool _showHeartAnimation = false;
  late bool _isFollowing;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.video.isFollowing;
    WidgetsBinding.instance.addObserver(this);

    if (!widget.video.isImagePost) {
      _initController();
    }
  }

  void _initController() {
    final url = widget.video.videoUrl;
    if (url.startsWith('assets/')) {
      _controller = VideoPlayerController.asset(url);
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    _controller!.addListener(_videoListener);
    _controller!.initialize().then((_) {
      if (!mounted) return;
      _controller!.setLooping(true);
      setState(() {});
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
        _controller!.play();
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _hasControllerError = true;
        });
      }
    });
  }

  void _videoListener() {
    if (!mounted || _controller == null || !_controller!.value.isInitialized) return;
    final value = _controller!.value;
    if (value.duration > Duration.zero && value.position >= value.duration) {
      _controller!.seekTo(Duration.zero);
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
        _controller!.play();
      }
    }
  }

  void _handleDoubleTap() {
    setState(() {
      _showHeartAnimation = true;
    });
    if (!widget.video.isLiked) {
      widget.onLikeTap();
    }
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  Widget _buildImagePost(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildMediaError(),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _buildMediaError(),
    );
  }

  Widget _buildMediaError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 54),
        const SizedBox(height: 10),
        Text(
          'Photo unavailable',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13),
        ),
      ],
    );
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

    if (widget.video.isImagePost) {
      if (_controller != null) {
        _controller!.pause();
        _controller!.removeListener(_videoListener);
        _controller!.dispose();
        _controller = null;
      }
      return;
    }

    if (_controller == null || oldWidget.video.videoUrl != widget.video.videoUrl) {
      if (_controller != null) {
        _controller!.removeListener(_videoListener);
        _controller!.dispose();
      }
      _initController();
      return;
    }

    final shouldPlay = widget.isActive && widget.isCurrentPage && !_manuallyPaused;
    if (_controller!.value.isInitialized) {
      if (shouldPlay && !_controller!.value.isPlaying) {
        _controller!.play();
      } else if (!shouldPlay && _controller!.value.isPlaying) {
        _controller!.pause();
      }
    }
  }

  @override
  void didPushNext() {
    if (_controller != null && _controller!.value.isInitialized && _controller!.value.isPlaying) {
      _controller!.pause();
      if (mounted) setState(() {});
    }
  }

  @override
  void didPopNext() {
    if (widget.isActive && widget.isCurrentPage && !_manuallyPaused && _controller != null && _controller!.value.isInitialized) {
      _controller!.play();
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_controller!.value.isInitialized && _controller!.value.isPlaying) {
        _controller!.pause();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused && _controller!.value.isInitialized) {
        _controller!.play();
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _manuallyPaused = true;
        _controller!.pause();
      } else {
        _manuallyPaused = false;
        _controller!.play();
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
        avatarUrl: widget.video.avatarUrl ?? '',
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
    final video = widget.video;
    final avatar = (video.avatarUrl != null && video.avatarUrl!.isNotEmpty)
        ? video.avatarUrl!
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';

    return Stack(
      children: [
        // Background Video or Photo
        Positioned.fill(
          child: Container(
            color: const Color(0xFF121216),
            child: widget.video.isImagePost
                ? GestureDetector(
                    onDoubleTap: _handleDoubleTap,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: _buildImagePost(video.videoUrl),
                    ),
                  )
                : (_controller != null &&
                        _controller!.value.isInitialized &&
                        _controller!.value.size.width > 0 &&
                        _controller!.value.size.height > 0)
                    ? GestureDetector(
                        onTap: _togglePlayPause,
                        onDoubleTap: _handleDoubleTap,
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _controller!.value.size.width,
                                  height: _controller!.value.size.height,
                                  child: VideoPlayer(_controller!),
                                ),
                              ),
                            ),
                            // Center Pause / Play indicator icon when paused
                            if (!_controller!.value.isPlaying)
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
                    : Center(
                        child: (_controller != null && (_controller!.value.hasError || _hasControllerError))
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

        // Animated Double-Tap Heart pop
        if (_showHeartAnimation)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1.2),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 96,
                      ),
                    );
                  },
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
          bottom: 140,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Avatar with + button
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
                          backgroundImage: NetworkImage(avatar),
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
                label: video.formattedLikes,
                isActive: video.isLiked,
                activeColor: Colors.red,
                onTap: widget.onLikeTap,
              ),

              // Comment
              _InteractionButton(
                icon: Icons.comment,
                label: video.formattedComments,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentBottomSheet(
                      videoId: video.id,
                      initialCommentCount: video.commentCount,
                      onCommentCountChanged: widget.onCommentCountChanged,
                    ),
                  );
                },
              ),

              // Bookmark / Save
              _InteractionButton(
                icon: Icons.bookmark,
                label: video.formattedSaves,
                isActive: video.isSaved,
                activeColor: Colors.amber,
                onTap: widget.onSaveTap,
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

              // Record/Music Disc
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
          bottom: 140,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _goToProfile,
                    child: Text(
                      video.username.startsWith('@') ? video.username : '@${video.username}',
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
                video.caption,
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

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showLabel;
  final Color? activeColor;
  final bool isActive;
  final VoidCallback? onTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    this.showLabel = true,
    this.activeColor,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = (isActive && activeColor != null) ? activeColor! : Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            if (showLabel) ...[
              const SizedBox(height: 4),
              Text(
                label,
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
