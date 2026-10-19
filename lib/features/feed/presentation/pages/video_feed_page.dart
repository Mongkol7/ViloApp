import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/app.dart';
import '../widgets/share_bottom_sheet.dart';
import '../widgets/comment_bottom_sheet.dart';
import 'sound_detail_page.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../shop/presentation/pages/product_detail_page.dart';

class VideoFeedPage extends StatefulWidget {
  final bool isActive;

  const VideoFeedPage({super.key, this.isActive = true});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    // Mock data for the video feed
    final List<Map<String, dynamic>> mockVideos = [
      {
        'videoUrl': 'assets/videos/vid1.mp4',
        'username': '@beach_lover',
        'caption': 'Enjoying the sunset at the beach #sunset #vibes',
        'music': 'Relaxing Waves - Ocean Sounds',
        'likes': '1.2M',
        'comments': '45.2K',
        'saves': '120K',
        'avatar': 'https://i.pravatar.cc/150?img=11',
        'product': {
          'title': "Nike Air Force 1 '07 Pro",
          'price': '\$129.99',
          'imageUrl': 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800',
        },
      },
      {
        'videoUrl': 'assets/videos/vid2.mp4',
        'username': '@city_explorer',
        'caption': 'Night walk through the neon streets #citylife #neon',
        'music': 'Cyberpunk Beats - Synthwave',
        'likes': '890K',
        'comments': '12.1K',
        'saves': '85K',
        'avatar': 'https://i.pravatar.cc/150?img=12',
        'product': {
          'title': 'Cyberpunk RGB Keyboard',
          'price': '\$149.50',
          'imageUrl': 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800',
        },
      },
      {
        'videoUrl': 'assets/videos/vid3.mp4',
        'username': '@nature_hiker',
        'caption': 'Found this hidden waterfall today! 🌿💧 #hiking #nature',
        'music': 'Nature Sounds - Waterfall',
        'likes': '340K',
        'comments': '3.2K',
        'saves': '20K',
        'avatar': 'https://i.pravatar.cc/150?img=13',
        'product': {
          'title': 'AirPods Max Space Gray',
          'price': '\$549.00',
          'imageUrl': 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=800',
        },
      },
      {
        'videoUrl': 'assets/videos/vid4.mp4',
        'username': '@fitness_journey',
        'caption': 'Morning workout done! 💪 #fitness #gym',
        'music': 'Workout Mix 2026 - DJ Flex',
        'likes': '550K',
        'comments': '8.4K',
        'saves': '15K',
        'avatar': 'https://i.pravatar.cc/150?img=14',
        'product': {
          'title': 'Streetwear Heavyweight Hoodie',
          'price': '\$78.00',
          'imageUrl': 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800',
        },
      },
      {
        'videoUrl': 'assets/videos/vid1.mp4',
        'username': '@travel_diaries',
        'caption': 'The view from the top is breathtaking ⛰️ #mountains',
        'music': 'Epic Mountain Theme - Hans Zimmer',
        'likes': '2.1M',
        'comments': '110K',
        'saves': '400K',
        'avatar': 'https://i.pravatar.cc/150?img=15',
      },
      {
        'videoUrl': 'assets/videos/vid2.mp4',
        'username': '@boathouse',
        'caption': 'Peaceful morning on the lake 🛶 #lake #peace',
        'music': 'Morning Coffee Acoustic - Indie Band',
        'likes': '420K',
        'comments': '5.1K',
        'saves': '18K',
        'avatar': 'https://i.pravatar.cc/150?img=16',
      },
    ];

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
          scrollDirection: Axis.vertical,
          itemCount: mockVideos.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return _VideoPostWidget(
              data: mockVideos[index],
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
  final Map<String, dynamic> data;
  final bool isCurrentPage;
  final bool isActive;

  const _VideoPostWidget({
    required this.data,
    required this.isCurrentPage,
    required this.isActive,
  });

  @override
  State<_VideoPostWidget> createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<_VideoPostWidget>
    with RouteAware, WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _manuallyPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(widget.data['videoUrl']);
    _controller.addListener(_videoListener);
    _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.setLooping(true);
      setState(() {});
      if (widget.isActive && widget.isCurrentPage && !_manuallyPaused) {
        _controller.play();
      }
    }).catchError((error) {
      if (mounted) setState(() {});
    });
  }

  void _videoListener() {
    if (!mounted || !_controller.value.isInitialized) return;
    final value = _controller.value;
    // Guarantee non-stop continuous looping even across short video bounds
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
    // Automatically pause video when navigating to another page (like SearchScreen)
    if (_controller.value.isInitialized && _controller.value.isPlaying) {
      _controller.pause();
      if (mounted) setState(() {});
    }
  }

  @override
  void didPopNext() {
    // Automatically resume video when returning back to Home feed from SearchScreen
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
    return Stack(
      children: [
        // Background Video/Image
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
                        backgroundImage: NetworkImage(widget.data['avatar']),
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
                label: widget.data['likes'],
                activeColor: Colors.red,
                isToggleable: true,
              ),
              
              // Comment
              _InteractionButton(
                icon: Icons.comment, 
                label: widget.data['comments'],
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
                label: widget.data['saves'],
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
          bottom: 140, // Leave space for bottom nav
          right: 80, // Prevent overlapping with right column
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating Video-Shop Featured Product Tag
              if (widget.data['product'] != null) ...[
                GestureDetector(
                  onTap: () {
                    final productMap = widget.data['product'] as Map<String, dynamic>;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(
                          title: productMap['title'] as String?,
                          price: productMap['price'] as String?,
                          imageUrl: productMap['imageUrl'] as String?,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.amberAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag, color: Colors.black, size: 11),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            widget.data['product']['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.data['product']['price'] as String,
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 10),
                      ],
                    ),
                  ),
                ),
              ],
              GestureDetector(
                onTap: _goToProfile,
                child: Text(
                  widget.data['username'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.data['caption'],
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
                  Text(
                    widget.data['music'],
                    style: const TextStyle(
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
