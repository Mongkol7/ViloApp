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
import '../../../profile/presentation/screens/public_profile_screen.dart';

class VideoFeedPage extends StatefulWidget {
  final bool isActive;
  final String feedType;

  const VideoFeedPage({
    super.key,
    this.isActive = true,
    this.feedType = 'foryou',
  });

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  final FeedRemoteDataSource _dataSource = FeedRemoteDataSource();
  late final PageController _pageController = PageController();

  List<VideoModel> _videos = [];
  bool _isLoading = true;
  int _currentPage = 0;
  int _apiPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  static final List<VideoModel> _fallbackVideos = [
    const VideoModel(
      id: 1,
      creatorId: 1,
      username: '@beach_lover',
      displayName: 'Beach Lover',
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      caption: 'Enjoying the sunset at the beach #sunset #vibes',
      videoUrl: 'assets/videos/vid1.mp4',
      likeCount: 1200000,
      commentCount: 45200,
      saveCount: 120000,
    ),
    const VideoModel(
      id: 2,
      creatorId: 2,
      username: '@city_explorer',
      displayName: 'City Explorer',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      caption: 'Night walk through the neon streets #citylife #neon',
      videoUrl: 'assets/videos/vid2.mp4',
      likeCount: 890000,
      commentCount: 12100,
      saveCount: 85000,
    ),
    const VideoModel(
      id: 3,
      creatorId: 3,
      username: '@nature_hiker',
      displayName: 'Nature Hiker',
      avatarUrl: 'https://i.pravatar.cc/150?img=13',
      caption: 'Found this hidden waterfall today! 🌿💧 #hiking #nature',
      videoUrl: 'assets/videos/vid3.mp4',
      likeCount: 340000,
      commentCount: 3200,
      saveCount: 20000,
    ),
    const VideoModel(
      id: 4,
      creatorId: 4,
      username: '@fitness_journey',
      displayName: 'Fitness Journey',
      avatarUrl: 'https://i.pravatar.cc/150?img=14',
      caption: 'Morning workout done! 💪 #fitness #gym',
      videoUrl: 'assets/videos/vid4.mp4',
      likeCount: 550000,
      commentCount: 8400,
      saveCount: 15000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    VideoFeedManager.instance.latestUploadedVideoNotifier.addListener(_onNewVideoUploaded);
    _fetchFeed();
  }

  @override
  void dispose() {
    VideoFeedManager.instance.latestUploadedVideoNotifier.removeListener(_onNewVideoUploaded);
    _pageController.dispose();
    super.dispose();
  }

  void _onNewVideoUploaded() {
    final newVideo = VideoFeedManager.instance.latestUploadedVideoNotifier.value;
    if (newVideo == null || !mounted) return;

    if (!_videos.any((v) => v.id == newVideo.id)) {
      setState(() {
        _videos.insert(0, newVideo);
        _currentPage = 0;
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

    try {
      final fetched = await _dataSource.getFeed(
        page: _apiPage,
        size: 10,
        type: widget.feedType,
      );

      if (!mounted) return;
      setState(() {
        if (refresh) {
          _videos = fetched.isNotEmpty ? fetched : _fallbackVideos;
        } else {
          if (fetched.isNotEmpty) {
            _videos.addAll(fetched);
          } else if (_videos.isEmpty) {
            _videos = List.from(_fallbackVideos);
          }
        }
        _hasMore = fetched.length >= 10;
        _isLoading = false;
        _isLoadingMore = false;
      });

      // Record view count for first video if active
      if (_videos.isNotEmpty && widget.isActive) {
        _recordView(_videos[0].id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_videos.isEmpty) {
          _videos = List.from(_fallbackVideos);
        }
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _videos.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
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
    with RouteAware, WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _manuallyPaused = false;
  bool _hasControllerError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
  }

  void _initController() {
    final url = widget.video.videoUrl;
    if (url.startsWith('assets/')) {
      _controller = VideoPlayerController.asset(url);
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
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
      if (mounted) {
        setState(() {
          _hasControllerError = true;
        });
      }
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
        builder: (context) => const PublicProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final avatar = video.avatarUrl ?? 'https://i.pravatar.cc/150?img=11';

    return Stack(
      children: [
        // Background Video / Cover
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
                      // Center Pause / Play indicator icon when paused
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
                    child: (_controller.value.hasError || _hasControllerError)
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
          bottom: 140,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Avatar with + button
              GestureDetector(
                onTap: _goToProfile,
                child: SizedBox(
                  height: 56,
                  width: 48,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(avatar),
                        backgroundColor: Colors.grey,
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  backgroundImage: const NetworkImage('https://i.pravatar.cc/100?img=50'),
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
              const SizedBox(height: 8),
              Text(
                video.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.music_note, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Original Sound - Vilo Audio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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
