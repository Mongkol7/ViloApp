import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/story_remote_data_source.dart';
import '../../data/datasources/thought_story_manager.dart';
import '../../domain/entities/music_track.dart';
import '../../domain/entities/shared_thought_story.dart';
import 'share_thought_screen.dart';

class GalleryMediaItem {
  final String id;
  final String title;
  final String duration;
  final String thumbnailUrl;
  final String mediaUrl;
  final String mediaType; // 'VIDEO' or 'IMAGE'
  final bool isLocal;

  const GalleryMediaItem({
    required this.id,
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
    required this.mediaUrl,
    this.mediaType = 'VIDEO',
    this.isLocal = false,
  });
}

class UploadStoryScreen extends StatefulWidget {
  final String initialPrivacy;

  const UploadStoryScreen({super.key, this.initialPrivacy = 'PUBLIC'});

  @override
  State<UploadStoryScreen> createState() => _UploadStoryScreenState();
}

class _UploadStoryScreenState extends State<UploadStoryScreen> {
  bool _isDropdownOpen = false;
  String _currentFilter = 'VIDEOS'; // 'VIDEOS' or 'ALL'
  int? _selectedIndex;
  late String _privacy; // 'PUBLIC', 'FOLLOWERS', 'FRIENDS'
  MusicTrack? _selectedMusic;
  final TextEditingController _captionController = TextEditingController();
  bool _isPosting = false;

  // 12 Visual Items matching the user screenshot grid
  late List<GalleryMediaItem> _mediaItems;

  static const List<MusicTrack> _curatedTracks = [
    MusicTrack(
      id: 'm1',
      title: 'Espresso',
      artist: 'Sabrina Carpenter',
      albumArtUrl:
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=150',
      duration: '0:30',
    ),
    MusicTrack(
      id: 'm2',
      title: 'Starboy',
      artist: 'The Weeknd ft. Daft Punk',
      albumArtUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=150',
      duration: '0:30',
    ),
    MusicTrack(
      id: 'm3',
      title: 'Cruel Summer',
      artist: 'Taylor Swift',
      albumArtUrl:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=150',
      duration: '0:30',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _privacy = widget.initialPrivacy;
    _initPresetGallery();
  }

  void _initPresetGallery() {
    _mediaItems = [
      // 1. Neon City Rain (0:15)
      const GalleryMediaItem(
        id: 'item_1',
        title: 'Neon Street in Rain',
        duration: '0:15',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        mediaType: 'VIDEO',
      ),
      // 2. Abstract Red Curves (0:08)
      const GalleryMediaItem(
        id: 'item_2',
        title: 'Red Abstract Fluid',
        duration: '0:08',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1541701494587-cb58502866ab?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        mediaType: 'VIDEO',
      ),
      // 3. Brutalist Architecture (0:24)
      const GalleryMediaItem(
        id: 'item_3',
        title: 'Brutalist Concrete',
        duration: '0:24',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        mediaType: 'VIDEO',
      ),
      // 4. Dark High Fashion Model (0:12)
      const GalleryMediaItem(
        id: 'item_4',
        title: 'High Fashion Walk',
        duration: '0:12',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
        mediaType: 'VIDEO',
      ),
      // 5. Red Neural Fiber Grid (0:59)
      const GalleryMediaItem(
        id: 'item_5',
        title: 'Neural Network Fibers',
        duration: '0:59',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507499739999-097706ad8914?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
        mediaType: 'VIDEO',
      ),
      // 6. Red Water Droplet Splash (0:05)
      const GalleryMediaItem(
        id: 'item_6',
        title: 'Crimson Droplet Splash',
        duration: '0:05',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        mediaType: 'VIDEO',
      ),
      // 7. City Skyline Sunset (0:10)
      const GalleryMediaItem(
        id: 'item_7',
        title: 'Tokyo Twilight Skyline',
        duration: '0:10',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackSeeTheWorld.mp4',
        mediaType: 'VIDEO',
      ),
      // 8. Cyberpunk UPLOAD GALLERY Sign (0:18)
      const GalleryMediaItem(
        id: 'item_8',
        title: 'Upload Gallery Screen',
        duration: '0:18',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
        mediaType: 'VIDEO',
      ),
      // 9. Bare Feet Spotlight Dance (0:31)
      const GalleryMediaItem(
        id: 'item_9',
        title: 'Bare Feet Stage Dance',
        duration: '0:31',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4',
        mediaType: 'VIDEO',
      ),
      // 10. Palm Shadow Wall (0:14)
      const GalleryMediaItem(
        id: 'item_10',
        title: 'Palm Silhouette Shadow',
        duration: '0:14',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4',
        mediaType: 'VIDEO',
      ),
      // 11. Studio Monitors Session (0:09)
      const GalleryMediaItem(
        id: 'item_11',
        title: 'Studio Creative Session',
        duration: '0:09',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        mediaType: 'VIDEO',
      ),
      // 12. Desert Starry Sky (0:45)
      const GalleryMediaItem(
        id: 'item_12',
        title: 'Milky Way Desert Sky',
        duration: '0:45',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=600&auto=format&fit=crop&q=80',
        mediaUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        mediaType: 'VIDEO',
      ),
    ];
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    HapticFeedback.selectionClick();
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  void _closeDropdown() {
    if (_isDropdownOpen) {
      setState(() => _isDropdownOpen = false);
    }
  }

  Future<void> _openPersonalMusicFlow() async {
    _closeDropdown();
    final result = await Navigator.of(context).push<SharedThoughtStory>(
      MaterialPageRoute(builder: (_) => const ShareThoughtScreen()),
    );

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _pickFromDeviceStorage() async {
    _closeDropdown();
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp4',
          'mov',
          'avi',
          'mkv',
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
        allowMultiple: false,
      );

      if (res != null && res.files.isNotEmpty && res.files.first.path != null) {
        final file = res.files.first;
        final path = file.path!;
        final ext = (file.extension ?? '').toLowerCase();
        final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);

        final newItem = GalleryMediaItem(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          title: file.name,
          duration: isVideo ? '0:30' : 'PHOTO',
          thumbnailUrl: path,
          mediaUrl: path,
          mediaType: isVideo ? 'VIDEO' : 'IMAGE',
          isLocal: true,
        );

        setState(() {
          _mediaItems.insert(0, newItem);
          _selectedIndex = 0;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF2F80ED),
              content: Text('Selected "${file.name}" from your device!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Could not load file: $e'),
          ),
        );
      }
    }
  }

  void _onMediaSelected(int index) {
    HapticFeedback.lightImpact();
    _closeDropdown();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleProceedToPreview() {
    _closeDropdown();
    if (_selectedIndex == null || _selectedIndex! >= _mediaItems.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a photo or video to continue'),
        ),
      );
      return;
    }

    final selected = _mediaItems[_selectedIndex!];
    _showStoryPreviewBottomSheet(selected);
  }

  void _showStoryPreviewBottomSheet(GalleryMediaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
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
                    const SizedBox(height: 16),

                    // Header Row
                    Row(
                      children: [
                        const Text(
                          'Share to Story',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2F80ED,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2F80ED),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                color: Color(0xFF2F80ED),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.duration,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2F80ED),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Preview Card & Caption
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 76,
                            height: 104,
                            child: item.isLocal
                                ? Image.file(
                                    File(item.thumbnailUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: const Color(0xFF222228),
                                              child: const Icon(
                                                Icons.videocam_rounded,
                                                color: Colors.white70,
                                              ),
                                            ),
                                  )
                                : Image.network(
                                    item.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: const Color(0xFF222228),
                                              child: const Icon(
                                                Icons.videocam_rounded,
                                                color: Colors.white70,
                                              ),
                                            ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _captionController,
                            maxLines: 4,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Add a thought or caption to your story...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF222228),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Interactive Settings Row (Music & Privacy)
                    Row(
                      children: [
                        // Sound Button
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              _showMusicSelector(setModalState);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF222228),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedMusic != null
                                      ? const Color(0xFF2F80ED)
                                      : const Color(0xFF333338),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.music_note_rounded,
                                    size: 18,
                                    color: _selectedMusic != null
                                        ? const Color(0xFF2F80ED)
                                        : const Color(0xFF8E8E93),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedMusic?.title ?? 'Add Sound',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedMusic != null
                                            ? Colors.white
                                            : const Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Privacy Button
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              _showPrivacySelector(setModalState);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF222228),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF333338),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _privacy == 'PUBLIC'
                                        ? Icons.public_rounded
                                        : (_privacy == 'FRIENDS'
                                              ? Icons.favorite_rounded
                                              : Icons.people_outline_rounded),
                                    size: 18,
                                    color: const Color(0xFF2F80ED),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _privacy == 'PUBLIC'
                                          ? 'Public'
                                          : (_privacy == 'FRIENDS'
                                                ? 'Friends only'
                                                : 'Followers'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Primary Publish Button
                    GestureDetector(
                      onTap: _isPosting
                          ? null
                          : () async {
                              final rootNav = Navigator.of(context);
                              final sheetNav = Navigator.of(sheetContext);
                              setModalState(() => _isPosting = true);
                              final story = await _publishStory(item);
                              if (mounted && story != null) {
                                sheetNav.pop(); // Close sheet
                                rootNav.pop(
                                  story,
                                ); // Return to caller with story
                              } else {
                                setModalState(() => _isPosting = false);
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF2F80ED,
                              ).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isPosting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Share to Story',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMusicSelector(StateSetter parentSetState) {
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      track.artist,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2F80ED),
                          )
                        : const Icon(
                            Icons.play_circle_outline_rounded,
                            color: Colors.white70,
                          ),
                    onTap: () {
                      parentSetState(() {
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

  void _showPrivacySelector(StateSetter parentSetState) {
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
                const SizedBox(height: 16),
                _buildPrivacyOption(
                  icon: Icons.public_rounded,
                  title: 'Public',
                  subtitle: 'Anyone on Vilo can view your story',
                  value: 'PUBLIC',
                  color: const Color(0xFF2F80ED),
                  onSelect: (v) {
                    parentSetState(() => _privacy = v);
                    Navigator.pop(modalCtx);
                  },
                ),
                const SizedBox(height: 8),
                _buildPrivacyOption(
                  icon: Icons.people_outline_rounded,
                  title: 'Followers',
                  subtitle: 'Only accounts that follow you can view',
                  value: 'FOLLOWERS',
                  color: const Color(0xFF56CCF2),
                  onSelect: (v) {
                    parentSetState(() => _privacy = v);
                    Navigator.pop(modalCtx);
                  },
                ),
                const SizedBox(height: 8),
                _buildPrivacyOption(
                  icon: Icons.favorite_rounded,
                  title: 'Friends only',
                  subtitle: 'Only mutual friends you follow back can view',
                  value: 'FRIENDS',
                  color: const Color(0xFF27AE60),
                  onSelect: (v) {
                    parentSetState(() => _privacy = v);
                    Navigator.pop(modalCtx);
                  },
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
    required ValueChanged<String> onSelect,
  }) {
    final isSelected = _privacy == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : const Color(0xFF26262B),
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
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFE5E5EA),
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

  Future<SharedThoughtStory?> _publishStory(GalleryMediaItem item) async {
    HapticFeedback.mediumImpact();
    try {
      final story = item.isLocal
          ? await StoryRemoteDataSource.instance.uploadMediaStory(
              filePath: item.mediaUrl,
              message: _captionController.text.trim().isNotEmpty
                  ? _captionController.text.trim()
                  : item.title,
              mediaType: item.mediaType,
              privacy: _privacy,
              musicTrack: _selectedMusic,
            )
          : await StoryRemoteDataSource.instance.createStory(
              message: _captionController.text.trim().isNotEmpty
                  ? _captionController.text.trim()
                  : item.title,
              mediaUrl: item.mediaUrl,
              mediaType: item.mediaType,
              privacy: _privacy,
              musicTrack: _selectedMusic,
            );

      if (story != null) {
        ThoughtStoryManager.instance.setStory(story);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF2F80ED),
              content: Text('Story posted to your profile and feed!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      return story;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to share story: $e'),
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedIndex != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Top Bar matching user mockup (Cancel | Recent VIDEOS v | Next)
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.black,
                  child: Row(
                    children: [
                      // Cancel Button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Center: "Recent" and "VIDEOS v" Dropdown Selector
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleDropdown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Recent',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentFilter,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF8E8E93),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    _isDropdownOpen
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: const Color(0xFF8E8E93),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Next Button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: hasSelection ? _handleProceedToPreview : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Next',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: hasSelection
                                  ? Colors.white
                                  : const Color(0xFF636366),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. 3-Column Gallery Media Grid (matching Screenshot 1)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeDropdown,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 1,
                        vertical: 2,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            childAspectRatio: 1.0,
                          ),
                      itemCount: _mediaItems.length,
                      itemBuilder: (context, index) {
                        final item = _mediaItems[index];
                        final isSelected = _selectedIndex == index;

                        return GestureDetector(
                          onTap: () => _onMediaSelected(index),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Thumbnail Image
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E24),
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xFF2F80ED),
                                          width: 2.5,
                                        )
                                      : null,
                                ),
                                child: item.isLocal
                                    ? Image.file(
                                        File(item.thumbnailUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white38,
                                                  ),
                                                ),
                                      )
                                    : Image.network(
                                        item.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white38,
                                                  ),
                                                ),
                                      ),
                              ),

                              // Bottom Dark Gradient for duration label legibility
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: 32,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black87,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Duration Label with Play icon in bottom-left (e.g. ▶ 0:15)
                              Positioned(
                                left: 6,
                                bottom: 6,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      item.duration,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection Circle Check Indicator in top-right
                              Positioned(
                                top: 6,
                                right: 6,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? const Color(0xFF2F80ED)
                                        : Colors.black.withValues(alpha: 0.35),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2F80ED)
                                          : Colors.white.withValues(alpha: 0.8),
                                      width: isSelected ? 2.0 : 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 3. Bottom Device Gallery Quick Action Bar
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickFromDeviceStorage,
                          icon: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Choose from Device Files',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 4. Dropdown Popover Card: "SELECT UPLOAD TYPE" (matching Screenshot 2)
            if (_isDropdownOpen) ...[
              // Outside tap dismiss barrier
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeDropdown,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // The Popover Card
              Positioned(
                top: 56,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 236,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26262B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label: SELECT UPLOAD TYPE
                        const Text(
                          'SELECT UPLOAD TYPE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8E8E93),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Item 1: Video & Photo Post
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _currentFilter = 'VIDEOS';
                              _isDropdownOpen = false;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.perm_media_outlined,
                                  color: Colors.white70,
                                  size: 19,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Video & Photo Post',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Item 2: Personal Music
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _openPersonalMusicFlow,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.music_note_outlined,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Personal Music',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
