import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/mock/profile_mock_data.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/video_model.dart';
import '../widgets/upload_video_sheet.dart';
import 'video_feed_page.dart';

class SoundDetailPage extends StatefulWidget {
  final String? soundId;
  final String? title;
  final String? artist;
  final String? albumArtUrl;
  final String? videosCount;
  final String? audioUrl;
  final int? durationSeconds;
  final int? creatorId;
  final String? creatorUsername;
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
    this.creatorId,
    this.creatorUsername,
    this.sourceVideo,
  });

  @override
  State<SoundDetailPage> createState() => _SoundDetailPageState();
}

class _SoundDetailPageState extends State<SoundDetailPage> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isFavorite = false;
  late AnimationController _rotationController;
  VideoPlayerController? _audioController;
  List<Map<String, dynamic>> _videos = [];
  List<VideoModel> _rawVideos = [];
  bool _isLoadingVideos = true;

  String? _title;
  String? _artist;
  String? _videosCount;
  String? _albumArtUrl;
  String? _audioUrl;
  int? _creatorId;
  String? _creatorUsername;
  bool _isUpdatingCover = false;
  bool _isDeleting = false;

  bool get _isOwner {
    final username = _creatorUsername ?? widget.creatorUsername ?? _artist ?? widget.artist;
    final id = (_creatorId ?? widget.creatorId)?.toString();
    return ProfileSyncService.instance.isCurrentUser(
      username: username,
      id: id,
    );
  }

  Future<void> _pickAndEditCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      setState(() => _isUpdatingCover = true);

      final sId = int.tryParse(widget.soundId ?? '');
      if (sId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot edit cover for this sound')),
          );
        }
        return;
      }

      final updated = await FeedRemoteDataSource.instance.updateSoundCover(
        soundId: sId,
        coverPath: picked.path,
        coverBytes: picked.bytes,
        coverFilename: picked.name,
      );

      if (mounted) {
        if (updated != null) {
          setState(() {
            _albumArtUrl = updated.coverUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cover art updated successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update cover art. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating cover: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingCover = false);
      }
    }
  }

  Future<void> _confirmDeleteSound() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Sound', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${_title ?? widget.title ?? 'this sound'}"? Existing videos using this sound will remain intact.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            key: const Key('sound_detail_confirm_delete_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final sId = widget.soundId;
    if (sId == null || sId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete this sound: invalid ID')),
      );
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final success = await FeedRemoteDataSource.instance.deleteSound(sId);
      if (mounted) {
        if (success) {
          final intId = int.tryParse(sId);
          if (intId != null) {
            ProfileSyncService.instance.notifySoundDeleted(intId);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF1E1E24),
              content: Text('Sound deleted successfully!'),
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF2C1A1D),
              content: Text('Failed to delete sound. You may not have permission.', style: TextStyle(color: Colors.redAccent)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2C1A1D),
            content: Text('Error deleting sound: $e', style: const TextStyle(color: Colors.redAccent)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _artist = widget.artist;
    _videosCount = widget.videosCount;
    _albumArtUrl = widget.albumArtUrl;
    _audioUrl = widget.audioUrl;
    _creatorId = widget.creatorId;
    _creatorUsername = widget.creatorUsername;
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _loadVideos();
  }

  @override
  void dispose() {
    _audioController?.pause();
    _audioController?.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      setState(() {
        _isPlaying = false;
        _rotationController.stop();
      });
      _audioController?.pause();
      return;
    }

    final rawAudio = _audioUrl ?? widget.audioUrl;
    if (rawAudio != null && rawAudio.trim().isNotEmpty) {
      final resolved = VideoModel.resolveMediaUrl(rawAudio);
      if (_audioController == null) {
        if (resolved.startsWith('assets/')) {
          _audioController = VideoPlayerController.asset(
            resolved,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        } else {
          _audioController = VideoPlayerController.networkUrl(
            Uri.parse(resolved),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        }

        try {
          await _audioController!.initialize();
          await _audioController!.setLooping(true);
          await _audioController!.setVolume(1.0);
        } catch (e) {
          debugPrint('[SoundDetailPage] Audio player init error: $e');
        }
      }

      if (_audioController != null && _audioController!.value.isInitialized) {
        await _audioController!.play();
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _rotationController.repeat();
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isPlaying = true;
        _rotationController.repeat();
      });
    }
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
    if (id != null && id.isNotEmpty && id != '0') {
      try {
        final details = await FeedRemoteDataSource.instance.getSoundDetails(id);
        final sound = details['sound'] as SoundTrack?;
        final videosList = details['videos'] as List<VideoModel>?;

        if (mounted && (sound != null || (videosList != null && videosList.isNotEmpty))) {
          setState(() {
            if (sound != null) {
              _title = sound.title;
              _artist = sound.artist ?? sound.creatorUsername;
              _videosCount = sound.usedByLabel;
              if (sound.creatorId != null) {
                _creatorId = sound.creatorId;
              }
              if (sound.creatorUsername != null && sound.creatorUsername!.isNotEmpty) {
                _creatorUsername = sound.creatorUsername;
              }
              if (sound.coverUrl.isNotEmpty) {
                _albumArtUrl = sound.coverUrl;
              }
              if (sound.audioUrl != null && sound.audioUrl!.isNotEmpty) {
                _audioUrl = sound.audioUrl;
              }
            }
            if (videosList != null) {
              _rawVideos = List.from(videosList);
              if (widget.sourceVideo != null && !_rawVideos.any((v) => v.id == widget.sourceVideo!.id)) {
                _rawVideos.insert(0, widget.sourceVideo!);
              }
              _videos = _rawVideos.map((v) => {
                'id': v.id.toString(),
                'thumbnailUrl': (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
                    ? v.thumbnailUrl!
                    : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500',
                'views': v.views,
                'viewCount': v.viewCount,
                'video': v,
              }).toList();
            } else if (widget.sourceVideo != null) {
              _rawVideos = [widget.sourceVideo!];
              _videos = [_sourceVideoMap()];
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
            _rawVideos = List.from(soundVideos);
            if (widget.sourceVideo != null && !_rawVideos.any((v) => v.id == widget.sourceVideo!.id)) {
              _rawVideos.insert(0, widget.sourceVideo!);
            }
            _videos = _rawVideos.map((v) => {
              'id': v.id.toString(),
              'thumbnailUrl': (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
                  ? v.thumbnailUrl!
                  : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500',
              'views': v.views,
              'viewCount': v.viewCount,
              'video': v,
            }).toList();
            _videosCount = '${_rawVideos.length} videos';
            _isLoadingVideos = false;
          });
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        if (widget.sourceVideo != null) {
          _rawVideos = [widget.sourceVideo!];
          _videos = [_sourceVideoMap()];
        } else {
          _videos = [];
        }
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
    final title = _title ?? widget.title ?? 'Original Sound';
    final artist = _artist ?? widget.artist ?? 'Creator';
    final count = _videosCount ?? widget.videosCount ?? '${_videos.length} videos';
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
          if (_audioController != null && _audioController!.value.isInitialized)
            Positioned(
              left: 0,
              top: 0,
              child: SizedBox(
                width: 1,
                height: 1,
                child: VideoPlayer(_audioController!),
              ),
            ),
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
                                if (_isOwner)
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: GestureDetector(
                                      onTap: _isUpdatingCover ? null : _pickAndEditCover,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.85),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white38, width: 1),
                                        ),
                                        child: _isUpdatingCover
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                                              )
                                            : const Icon(Icons.edit, size: 13, color: Colors.white),
                                      ),
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
                                if (_isOwner) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      InkWell(
                                        key: const Key('sound_detail_edit_cover_button'),
                                        onTap: _isUpdatingCover ? null : _pickAndEditCover,
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF242428),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.white24, width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_isUpdatingCover)
                                                const SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              else
                                                const Icon(Icons.image_outlined, size: 14, color: Colors.white),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'Edit Cover',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        key: const Key('sound_detail_delete_button'),
                                        onTap: _isDeleting ? null : _confirmDeleteSound,
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3A1C20),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (_isDeleting)
                                                const SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    color: Colors.redAccent,
                                                  ),
                                                )
                                              else
                                                const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _audioController?.pause();
                          setState(() {
                            _isPlaying = false;
                            _rotationController.stop();
                          });
                          if (_rawVideos.isNotEmpty && index < _rawVideos.length) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoFeedPage(
                                  isActive: true,
                                  initialVideos: _rawVideos,
                                  initialIndex: index,
                                  feedType: 'SOUND',
                                ),
                              ),
                            );
                          }
                        },
                        child: ClipRRect(
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
                final sId = int.tryParse(widget.soundId ?? '');
                UploadVideoSheet.show(
                  context,
                  initialSoundId: sId,
                  initialSoundTitle: title,
                  initialAudioUrl: widget.audioUrl,
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
