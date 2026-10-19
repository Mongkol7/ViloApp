import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../profile/presentation/mock/profile_mock_data.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/video_model.dart';

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

  String? _title;
  String? _artist;
  String? _videosCount;
  String? _albumArtUrl;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _artist = widget.artist;
    _videosCount = widget.videosCount;
    _albumArtUrl = widget.albumArtUrl;
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
    // 1. If soundId is provided, query sound details from backend
    if (widget.soundId != null && widget.soundId!.isNotEmpty && widget.soundId != '0') {
      try {
        final details = await FeedRemoteDataSource.instance.getSoundDetails(widget.soundId!);
        final sound = details['sound'] as SoundTrack?;
        final videosList = details['videos'] as List<VideoModel>?;

        if (mounted && (sound != null || (videosList != null && videosList.isNotEmpty))) {
          setState(() {
            if (sound != null) {
              _title = sound.title;
              _artist = sound.artist ?? sound.creatorUsername;
              _videosCount = sound.usedByLabel;
              if (sound.coverUrl.isNotEmpty) {
                _albumArtUrl = sound.coverUrl;
              }
            }
            if (videosList != null) {
              _videos = videosList.map((v) => {
                'id': v.id.toString(),
                'thumbnailUrl': (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
                    ? v.thumbnailUrl!
                    : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500',
                'views': v.likes,
              }).toList();
            }
            _isLoadingVideos = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('[SoundDetailPage] Error loading sound details: $e');
      }
    }

    // 2. If sound title is provided, query videos by sound title
    final queryTitle = _title ?? widget.title;
    if (queryTitle != null && queryTitle.isNotEmpty && queryTitle != 'None') {
      try {
        final soundVideos = await FeedRemoteDataSource.instance.getVideosBySound(queryTitle);
        if (mounted && soundVideos.isNotEmpty) {
          setState(() {
            _videos = soundVideos.map((v) => {
              'id': v.id.toString(),
              'thumbnailUrl': (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
                  ? v.thumbnailUrl!
                  : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500',
              'views': v.likes,
            }).toList();
            _videosCount = '${soundVideos.length} videos';
            _isLoadingVideos = false;
          });
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isLoadingVideos = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _title ?? widget.title ?? 'Original Sound';
    final artist = _artist ?? widget.artist ?? 'Creator';
    final count = _videosCount ?? widget.videosCount ?? '0 videos';
    final duration = '${widget.durationSeconds ?? 45}s';
    final albumArt = (_albumArtUrl != null && _albumArtUrl!.isNotEmpty)
        ? _albumArtUrl!
        : (widget.albumArtUrl?.isNotEmpty == true
            ? widget.albumArtUrl!
            : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80');

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
              else if (_videos.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_off_outlined, color: Colors.white24, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'No videos using this sound yet',
                            style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
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
