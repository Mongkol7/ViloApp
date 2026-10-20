import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/video_model.dart';

class SoundDetailPage extends StatefulWidget {
  final String? soundId;
  final String? title;
  final String? artist;
  final String? albumArtUrl;
  final String? videosCount;
  final String? audioUrl;
  final int? durationSeconds;
  final VideoModel? sourceVideo;

  const SoundDetailPage({
    super.key,
    this.soundId,
    this.title,
    this.artist,
    this.albumArtUrl,
    this.videosCount,
    this.audioUrl,
    this.durationSeconds,
    this.sourceVideo,
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
    final id = await _resolveSoundId();
    if (id == null) {
      if (mounted) {
        setState(() {
          _videos = widget.sourceVideo == null ? [] : [_sourceVideoMap()];
          _isLoadingVideos = false;
        });
      }
      return;
    }

    try {
      final response = await ApiClient.instance.get('/sounds/$id/videos', requireAuth: false);
      if (mounted && response != null && response['success'] == true && response['data'] is List) {
        final videos = (response['data'] as List)
            .whereType<Map>()
            .map((video) => Map<String, dynamic>.from(video))
            .toList();
        _includeSourceVideo(videos);
        setState(() {
          _videos = videos;
          _isLoadingVideos = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _videos = widget.sourceVideo == null ? [] : [_sourceVideoMap()];
        _isLoadingVideos = false;
      });
    }
  }

  Map<String, dynamic> _sourceVideoMap() {
    final source = widget.sourceVideo!;
    return {
      'id': source.id,
      'thumbnailUrl': source.thumbnailUrl,
      'views': source.formattedViews,
      'viewCount': source.viewCount,
      'videoUrl': source.videoUrl,
      'soundTitle': source.musicTitle,
    };
  }

  void _includeSourceVideo(List<Map<String, dynamic>> videos) {
    if (widget.sourceVideo == null) return;

    final sourceId = widget.sourceVideo!.id.toString();
    videos.removeWhere((video) => video['id']?.toString() == sourceId);
    videos.insert(0, _sourceVideoMap());
  }

  Future<String?> _resolveSoundId() async {
    final providedId = widget.soundId?.trim();
    if (providedId != null && providedId.isNotEmpty) return providedId;

    final title = widget.title?.trim() ?? '';
    if (title.isEmpty) return null;

    try {
      final response = await ApiClient.instance.get(
        '/search?q=${Uri.encodeComponent(title)}&type=SOUNDS',
        requireAuth: false,
      );
      final data = response is Map && response['data'] is Map
          ? response['data'] as Map
          : response is Map
              ? response
              : null;
      final sounds = data?['sounds'];
      if (sounds is List && sounds.isNotEmpty) {
        final normalizedTitle = title.toLowerCase();
        for (final sound in sounds) {
          if (sound is Map) {
            final soundTitle = sound['title']?.toString().toLowerCase() ?? '';
            if (soundTitle == normalizedTitle ||
                soundTitle.contains(normalizedTitle) ||
                normalizedTitle.contains(soundTitle)) {
              final id = sound['id']?.toString();
              if (id != null && id.isNotEmpty) return id;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'Midnight City Pulse';
    final artist = widget.artist ?? 'Neon Dreams';
    final count = widget.videosCount ?? '${_videos.length} videos';
    final duration = '${widget.durationSeconds ?? 45}s';
    final albumArt = widget.albumArtUrl?.trim() ?? '';

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
                                      child: albumArt.isEmpty
                                          ? Container(
                                              color: AppColors.surface,
                                              child: const Icon(Icons.music_note_rounded, color: Colors.white),
                                            )
                                          : Image.network(
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
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 40),
                    child: Center(
                      child: Text(
                        'No videos using this sound yet.',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                        textAlign: TextAlign.center,
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
                            _buildVideoThumbnail(video['thumbnailUrl']?.toString() ?? ''),
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

  Widget _buildVideoThumbnail(String url) {
    final cleanUrl = url.trim();
    final placeholder = Container(
      color: AppColors.surface,
      child: const Icon(Icons.movie_outlined, color: AppColors.outline),
    );
    if (cleanUrl.startsWith('assets/')) {
      return Image.asset(
        cleanUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (cleanUrl.isEmpty) return placeholder;
    return Image.network(
      cleanUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
