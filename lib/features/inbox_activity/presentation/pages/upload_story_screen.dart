import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/story_remote_data_source.dart';
import '../../data/datasources/thought_story_manager.dart';
import '../../domain/entities/music_track.dart';

class UploadStoryScreen extends StatefulWidget {
  final String initialPrivacy;

  const UploadStoryScreen({
    super.key,
    this.initialPrivacy = 'PUBLIC',
  });

  @override
  State<UploadStoryScreen> createState() => _UploadStoryScreenState();
}

class _UploadStoryScreenState extends State<UploadStoryScreen> {
  final TextEditingController _captionController = TextEditingController();
  String _mediaType = 'IMAGE'; // 'IMAGE' or 'VIDEO'
  late String _privacy; // 'PUBLIC', 'FOLLOWERS', 'FRIENDS'
  String? _selectedMediaUrl;
  MusicTrack? _selectedMusic;
  bool _isPosting = false;

  static const List<Map<String, String>> _presetPhotos = [
    {
      'title': 'Sunset Glow',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Tokyo Lights',
      'url': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Coffee Vibe',
      'url': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Urban Life',
      'url': 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Neon Dreams',
      'url': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Mountain Mist',
      'url': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800&auto=format&fit=crop&q=80',
    },
  ];

  static const List<Map<String, String>> _presetVideos = [
    {
      'title': 'Nature Flow',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'thumbnail': 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'City Drive',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      'thumbnail': 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Ocean Surf',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      'thumbnail': 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800&auto=format&fit=crop&q=80',
    },
  ];

  static const List<MusicTrack> _curatedTracks = [
    MusicTrack(
      id: 'm1',
      title: 'Espresso',
      artist: 'Sabrina Carpenter',
      albumArtUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=150',
      duration: '0:30',
    ),
    MusicTrack(
      id: 'm2',
      title: 'Starboy',
      artist: 'The Weeknd ft. Daft Punk',
      albumArtUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=150',
      duration: '0:30',
    ),
    MusicTrack(
      id: 'm3',
      title: 'Cruel Summer',
      artist: 'Taylor Swift',
      albumArtUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=150',
      duration: '0:30',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _privacy = widget.initialPrivacy;
    _selectedMediaUrl = _presetPhotos[0]['url'];
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48484E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Who can view this story?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose who is allowed to see this story for 24 hours.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 18),
                _buildPrivacyOption(
                  icon: Icons.public_rounded,
                  title: 'Public',
                  subtitle: 'Anyone on Vilo can view your story',
                  value: 'PUBLIC',
                  color: const Color(0xFF2F80ED),
                  modalCtx: modalCtx,
                ),
                const SizedBox(height: 8),
                _buildPrivacyOption(
                  icon: Icons.people_outline_rounded,
                  title: 'Followers',
                  subtitle: 'Only accounts that follow you can view',
                  value: 'FOLLOWERS',
                  color: const Color(0xFF56CCF2),
                  modalCtx: modalCtx,
                ),
                const SizedBox(height: 8),
                _buildPrivacyOption(
                  icon: Icons.favorite_rounded,
                  title: 'Friends only',
                  subtitle: 'Only mutual friends you follow back can view',
                  value: 'FRIENDS',
                  color: const Color(0xFF27AE60),
                  modalCtx: modalCtx,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required BuildContext modalCtx,
  }) {
    final isSelected = _privacy == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() => _privacy = value);
        Navigator.pop(modalCtx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFF26262B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF333338),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFFE5E5EA),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  void _showMusicPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48484E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Add Background Sound',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                ..._curatedTracks.map((track) {
                  final isSelected = _selectedMusic?.id == track.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        track.albumArtUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      track.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      track.artist,
                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF2F80ED))
                        : const Icon(Icons.play_circle_outline_rounded, color: Colors.white70),
                    onTap: () {
                      setState(() {
                        _selectedMusic = isSelected ? null : track;
                      });
                      Navigator.pop(modalCtx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePostStory() async {
    if (_selectedMediaUrl == null || _selectedMediaUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo or video to upload')),
      );
      return;
    }

    setState(() => _isPosting = true);
    HapticFeedback.mediumImpact();

    try {
      final story = await StoryRemoteDataSource.instance.createStory(
        message: _captionController.text.trim(),
        mediaUrl: _selectedMediaUrl,
        mediaType: _mediaType,
        privacy: _privacy,
        musicTrack: _selectedMusic,
      );

      if (story != null) {
        ThoughtStoryManager.instance.setStory(story);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _privacy == 'FRIENDS'
                  ? 'Story shared with Close Friends 👥!'
                  : (_privacy == 'FOLLOWERS'
                      ? 'Story shared with your Followers!'
                      : 'Story posted publicly!'),
            ),
            backgroundColor: _privacy == 'FRIENDS' ? const Color(0xFF27AE60) : const Color(0xFF2F80ED),
          ),
        );
        Navigator.pop(context, story);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post story: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  String get _privacyLabel {
    switch (_privacy) {
      case 'FRIENDS':
        return 'Friends 👥';
      case 'FOLLOWERS':
        return 'Followers';
      default:
        return 'Public 🌐';
    }
  }

  Color get _privacyColor {
    switch (_privacy) {
      case 'FRIENDS':
        return const Color(0xFF27AE60);
      case 'FOLLOWERS':
        return const Color(0xFF56CCF2);
      default:
        return const Color(0xFF2F80ED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = _mediaType == 'IMAGE' ? _presetPhotos : _presetVideos;

    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Story',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // Privacy pill button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: _showPrivacyPicker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _privacyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _privacyColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _privacy == 'FRIENDS'
                            ? Icons.favorite_rounded
                            : (_privacy == 'FOLLOWERS'
                                ? Icons.people_rounded
                                : Icons.public_rounded),
                        color: _privacyColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _privacyLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _privacyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Selector Tabs (Photo, Video)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeTab(
                        label: '📸 Photo Story',
                        isSelected: _mediaType == 'IMAGE',
                        onTap: () {
                          setState(() {
                            _mediaType = 'IMAGE';
                            _selectedMediaUrl = _presetPhotos[0]['url'];
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildModeTab(
                        label: '🎥 Video Story',
                        isSelected: _mediaType == 'VIDEO',
                        onTap: () {
                          setState(() {
                            _mediaType = 'VIDEO';
                            _selectedMediaUrl = _presetVideos[0]['url'];
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Live Media Preview Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF161618),
                    border: Border.all(color: const Color(0xFF2C2C32)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image / video thumbnail
                        if (_selectedMediaUrl != null)
                          Image.network(
                            _mediaType == 'VIDEO'
                                ? (_presetVideos.firstWhere(
                                      (v) => v['url'] == _selectedMediaUrl,
                                      orElse: () => _presetVideos[0],
                                    )['thumbnail'] ??
                                    '')
                                : _selectedMediaUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1E1E22),
                              child: const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48),
                              ),
                            ),
                          ),

                        // Gradient overlay for readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),

                        // Video Play Indicator (if video mode)
                        if (_mediaType == 'VIDEO')
                          Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                            ),
                          ),

                        // Top Overlays: Music Pill & Story Ring badge
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 14,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: _showMusicPicker,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.music_note_rounded, color: Color(0xFF56CCF2), size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedMusic != null
                                            ? '${_selectedMusic!.title} • ${_selectedMusic!.artist}'
                                            : 'Add Music',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _mediaType == 'IMAGE' ? 'PHOTO STORY' : 'VIDEO STORY',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Overlay: Caption Input Field
                        Positioned(
                          bottom: 14,
                          left: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: TextField(
                              controller: _captionController,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              minLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Add a caption to your story...',
                                hintStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white60,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Media Preset Thumbnails Strip
            Container(
              height: 74,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final url = _mediaType == 'VIDEO' ? (preset['thumbnail'] ?? '') : preset['url']!;
                  final isSelected = _selectedMediaUrl == preset['url'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMediaUrl = preset['url'];
                      });
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2F80ED) : const Color(0xFF333338),
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Action Bar: Post Story & Close Friends Shortcut
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  // Post Story Primary Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80ED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isPosting ? null : _handlePostStory,
                      child: _isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Your Story ($_privacyLabel)',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Close Friends Quick Post
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60).withValues(alpha: 0.15),
                      side: const BorderSide(color: Color(0xFF27AE60)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.favorite_rounded, color: Color(0xFF27AE60), size: 22),
                    tooltip: 'Post to Friends Only',
                    onPressed: _isPosting
                        ? null
                        : () {
                            setState(() => _privacy = 'FRIENDS');
                            _handlePostStory();
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F80ED) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}
