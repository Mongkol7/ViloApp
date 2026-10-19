import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';

class SoundDetailPage extends StatefulWidget {
  final String? soundId;
  final String? title;
  final String? artist;
  final String? albumArtUrl;
  final String? videosCount;
  final String? audioUrl;
  final int? durationSeconds;

  const SoundDetailPage({
    super.key,
    this.soundId,
    this.title,
    this.artist,
    this.albumArtUrl,
    this.videosCount,
    this.audioUrl,
    this.durationSeconds,
  });

  @override
  State<SoundDetailPage> createState() => _SoundDetailPageState();
}

class _SoundDetailPageState extends State<SoundDetailPage> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isFavorite = false;
  late AnimationController _rotationController;
  List<Map<String, dynamic>> _videos = [];
  bool _isLoadingVideos = true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _loadVideos();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Added to your favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadVideos() async {
    final id = widget.soundId ?? '1';
    try {
      final response = await ApiClient.instance.get('/sounds/$id/videos', requireAuth: false);
      if (mounted && response != null && response['success'] == true && response['data'] is List) {
        setState(() {
          _videos = List<Map<String, dynamic>>.from(response['data']);
          _isLoadingVideos = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      final fallbackThumbs = [
        'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=500&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=500&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=500&auto=format&fit=crop&q=80',
      ];
      final fallbackViews = ['1.8M', '820K', '542K', '310K', '295K', '180K', '125K', '98K', '64K'];

      setState(() {
        _videos = List.generate(fallbackThumbs.length, (i) => {
          'id': 'v_$i',
          'thumbnailUrl': fallbackThumbs[i],
          'views': fallbackViews[i],
        });
        _isLoadingVideos = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'Midnight City Pulse';
    final artist = widget.artist ?? 'Neon Dreams';
    final count = widget.videosCount ?? '1.8M videos';
    final duration = '${widget.durationSeconds ?? 45}s';
    final albumArt = widget.albumArtUrl?.isNotEmpty == true
        ? widget.albumArtUrl!
        : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.black,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sound link copied to clipboard'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Rotating Album Vinyl Disk
                          GestureDetector(
                            onTap: _togglePlay,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                RotationTransition(
                                  turns: _rotationController,
                                  child: Container(
                                    width: 86,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2C2C2E), Color(0xFF141416)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(color: Colors.white24, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        albumArt,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppColors.surface,
                                          child: const Icon(Icons.music_note_rounded, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Play / Pause Floating Overlay
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white54, width: 1),
                                  ),
                                  child: Icon(
                                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person_rounded, color: AppColors.outline, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      artist,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Metadata stats pill
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white54, size: 15),
                          const SizedBox(width: 4),
                          Text(duration, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 12, color: Colors.white24),
                          const SizedBox(width: 12),
                          const Text('Original sound', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          const Spacer(),
                          Text(count, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Action Buttons: Play Sample & Favorite
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: _isPlaying ? Colors.white : const Color(0xFF242428),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.surfaceStroke, width: 1.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                      color: _isPlaying ? Colors.black : Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isPlaying ? 'Pause Sample' : 'Play Sample',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: _isPlaying ? Colors.black : Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _toggleFavorite,
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF242428),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.surfaceStroke, width: 1.0),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                      color: _isFavorite ? Colors.pinkAccent : Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isFavorite ? 'Favorited' : 'Add to Favorites',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: _isFavorite ? Colors.pinkAccent : Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Grid of Short Videos
              if (_isLoadingVideos)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                )
              else
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final video = _videos[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              video['thumbnailUrl'] ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surface,
                                child: const Icon(Icons.movie_outlined, color: AppColors.outline),
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                                    stops: const [0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 6,
                              bottom: 6,
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    video['views'] ?? '',
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
                    childCount: _videos.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),

          // Bottom Fixed "Use this sound" Bar
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected "$title" for creation Studio!'),
                    backgroundColor: Colors.white,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_rounded, color: Colors.black, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Use this sound',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
