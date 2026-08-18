import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/static_music_data.dart';
import '../../domain/entities/music_track.dart';
import 'music_trimmer_bottom_sheet.dart';

class MusicPickerBottomSheet extends StatefulWidget {
  final ValueChanged<MusicTrack>? onTrackSelected;

  const MusicPickerBottomSheet({
    super.key,
    this.onTrackSelected,
  });

  static Future<MusicTrack?> show(BuildContext context) {
    return showModalBottomSheet<MusicTrack>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MusicPickerBottomSheet(),
    );
  }

  @override
  State<MusicPickerBottomSheet> createState() => _MusicPickerBottomSheetState();
}

class _MusicPickerBottomSheetState extends State<MusicPickerBottomSheet> {
  int _selectedTabIndex = 0; // 0: For you, 1: Trending, 2: Saved
  final TextEditingController _searchController = TextEditingController();

  late List<MusicTrack> _forYouList;
  late List<MusicTrack> _trendingList;
  late List<MusicTrack> _savedList;
  late List<MusicTrack> _featuredCarousel;

  late PageController _carouselPageController;
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _forYouList = List.from(StaticMusicData.forYouTracks);
    _trendingList = List.from(StaticMusicData.trendingTracks);
    _savedList = List.from(StaticMusicData.savedTracks);
    _featuredCarousel = [
      _forYouList[0], // petal
      _forYouList[4], // Am I Dreaming
      _forYouList[2], // august
      _forYouList[1], // AH HA
    ];

    _carouselPageController = PageController();
    _startCarouselAutoScroll();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startCarouselAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 3200), (timer) {
      if (_carouselPageController.hasClients && _selectedTabIndex == 0) {
        int nextPage = _currentCarouselIndex + 1;
        if (nextPage >= _featuredCarousel.length) {
          nextPage = 0;
          _carouselPageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
          );
        } else {
          _carouselPageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });
  }

  Future<void> _selectAndTrimTrack(MusicTrack track) async {
    final confirmedTrack = await MusicTrimmerBottomSheet.show(
      context,
      track: track,
      onChangeSong: () {
        // Just stays on the music picker
      },
    );

    if (confirmedTrack != null && mounted) {
      Navigator.of(context).pop(confirmedTrack);
      widget.onTrackSelected?.call(confirmedTrack);
    }
  }

  void _toggleSave(MusicTrack track, int tabIndex, int index) {
    setState(() {
      if (tabIndex == 0) {
        final updated = _forYouList[index].copyWith(isSaved: !_forYouList[index].isSaved);
        _forYouList[index] = updated;
      } else if (tabIndex == 1) {
        final updated = _trendingList[index].copyWith(isSaved: !_trendingList[index].isSaved);
        _trendingList[index] = updated;
      } else {
        final updated = _savedList[index].copyWith(isSaved: !_savedList[index].isSaved);
        _savedList[index] = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF18181C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2E2E34), width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // 1. Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFF48484E),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Search Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF26262B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF383840),
                  width: 1.0,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF8E8E93),
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF8E8E93),
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Filter Tabs (For you, Trending, Saved)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabPill(0, 'For you'),
                const SizedBox(width: 10),
                _buildTabPill(1, 'Trending'),
                const SizedBox(width: 10),
                _buildTabPill(2, 'Saved'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Tab Content Body
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildForYouTab(),
                _buildTrendingTab(),
                _buildSavedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF26262B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF383840),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? const Color(0xFF141416) : Colors.white,
          ),
        ),
      ),
    );
  }

  // --- TAB 1: For You ---
  Widget _buildForYouTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // Top Auto-Scrolling Featured Carousel Card
        SizedBox(
          height: 106,
          child: PageView.builder(
            controller: _carouselPageController,
            itemCount: _featuredCarousel.length,
            onPageChanged: (page) {
              setState(() {
                _currentCarouselIndex = page;
              });
            },
            itemBuilder: (context, index) {
              final track = _featuredCarousel[index];
              return GestureDetector(
                onTap: () => _selectAndTrimTrack(track),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222226),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF33333A),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track.albumArtUrl,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 54,
                            height: 54,
                            color: AppColors.surface,
                            child: const Icon(Icons.music_note, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (track.isExplicit) ...[
                                  _buildExplicitBadge(),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    track.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF9E9EA4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Dots Indicator for Carousel
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_featuredCarousel.length, (dotIndex) {
            final isActive = _currentCarouselIndex == dotIndex;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 6 : 5,
              height: isActive ? 6 : 5,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2F80ED) : const Color(0xFF48484E),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        // Tracks List
        ...List.generate(_forYouList.length, (index) {
          final track = _forYouList[index];
          return _buildTrackTile(track, 0, index);
        }),
      ],
    );
  }

  // --- TAB 2: Trending ---
  Widget _buildTrendingTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        ...List.generate(_trendingList.length, (index) {
          final track = _trendingList[index];
          return _buildTrackTile(track, 1, index);
        }),
      ],
    );
  }

  // --- TAB 3: Saved ---
  Widget _buildSavedTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        ...List.generate(_savedList.length, (index) {
          final track = _savedList[index];
          return _buildTrackTile(track, 2, index);
        }),
      ],
    );
  }

  Widget _buildTrackTile(MusicTrack track, int tabIndex, int index) {
    return InkWell(
      onTap: () => _selectAndTrimTrack(track),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Optional Rank Indicator (for Trending / Saved)
            if (tabIndex == 1) ...[
              SizedBox(
                width: 28,
                child: _buildTrendingRankBadge(track),
              ),
              const SizedBox(width: 4),
            ] else if (tabIndex == 2) ...[
              SizedBox(
                width: 22,
                child: Text(
                  '${track.rankNumber ?? index + 1}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9EA4),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],

            // Album Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                track.albumArtUrl,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 46,
                  height: 46,
                  color: AppColors.surface,
                  child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (track.isExplicit) ...[
                        const SizedBox(width: 6),
                        _buildExplicitBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _buildSubtitle(track),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9E9EA4),
                    ),
                  ),
                ],
              ),
            ),

            // Bookmark / Save Action
            IconButton(
              icon: Icon(
                track.isSaved || tabIndex == 2
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => _toggleSave(track, tabIndex, index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingRankBadge(MusicTrack track) {
    if (track.rankType == 'number') {
      return Text(
        '${track.rankNumber}',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9E9EA4),
        ),
      );
    } else if (track.rankType == 'up') {
      return const Icon(
        Icons.arrow_upward_rounded,
        color: Color(0xFF27AE60),
        size: 18,
      );
    } else if (track.rankType == 'new') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2F80ED).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF2F80ED), width: 0.8),
        ),
        child: const Text(
          'NEW',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Color(0xFF56CCF2),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildExplicitBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFF383840),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Text(
        'E',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Color(0xFFD0D0D5),
        ),
      ),
    );
  }

  String _buildSubtitle(MusicTrack track) {
    final buffer = StringBuffer(track.artist);
    if (track.reelsCount != null) {
      buffer.write(' • ${track.reelsCount}');
    }
    if (track.duration != null) {
      buffer.write(' • ${track.duration}');
    }
    return buffer.toString();
  }
}
