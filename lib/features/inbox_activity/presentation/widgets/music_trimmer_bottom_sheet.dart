import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/music_track.dart';

class MusicTrimmerBottomSheet extends StatefulWidget {
  final MusicTrack track;
  final ValueChanged<MusicTrack>? onConfirmed;
  final VoidCallback? onChangeSong;

  const MusicTrimmerBottomSheet({
    super.key,
    required this.track,
    this.onConfirmed,
    this.onChangeSong,
  });

  static Future<MusicTrack?> show(
    BuildContext context, {
    required MusicTrack track,
    VoidCallback? onChangeSong,
  }) {
    return showModalBottomSheet<MusicTrack>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MusicTrimmerBottomSheet(
        track: track,
        onChangeSong: onChangeSong,
      ),
    );
  }

  @override
  State<MusicTrimmerBottomSheet> createState() => _MusicTrimmerBottomSheetState();
}

class _MusicTrimmerBottomSheetState extends State<MusicTrimmerBottomSheet>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  int _durationSeconds = 30; // 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 20, 25, 30, 45, 60s
  double _playbackProgress = 0.0;
  Timer? _playbackTimer;

  late ScrollController _waveformScrollController;
  final List<double> _waveformData = List.generate(
    50,
    (i) => 0.2 + (math.sin(i * 0.5).abs() * 0.75 + math.cos(i * 0.8).abs() * 0.25) / 1.25,
  );

  @override
  void initState() {
    super.initState();
    _waveformScrollController = ScrollController(initialScrollOffset: 120);
    _startPlaybackSimulation();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _waveformScrollController.dispose();
    super.dispose();
  }

  void _startPlaybackSimulation() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPlaying) {
        setState(() {
          _playbackProgress += 0.05 / _durationSeconds;
          if (_playbackProgress >= 1.0) {
            _playbackProgress = 0.0; // Loop playing snippet
          }
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _onWaveformReselected() {
    // Replay from beginning whenever the user scrolls or reselects the waveform
    setState(() {
      _playbackProgress = 0.0;
      _isPlaying = true;
    });
    _startPlaybackSimulation();
  }

  void _openDurationPicker() {
    int tempDuration = _durationSeconds;
    final List<int> durationOptions = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 20, 25, 30, 45, 60];
    final initialItemIndex =
        durationOptions.indexOf(_durationSeconds).clamp(0, durationOptions.length - 1);
    final FixedExtentScrollController wheelController =
        FixedExtentScrollController(initialItem: initialItemIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 330,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Color(0xFF333338), width: 1.0),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48484E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Clip duration',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Selection highlight box
                        Container(
                          height: 44,
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.0,
                            ),
                          ),
                        ),
                        ListWheelScrollView.useDelegate(
                          controller: wheelController,
                          itemExtent: 44,
                          perspective: 0.003,
                          diameterRatio: 1.3,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setModalState(() {
                              tempDuration = durationOptions[index];
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: durationOptions.length,
                            builder: (context, index) {
                              final seconds = durationOptions[index];
                              final isSelected = seconds == tempDuration;
                              return Center(
                                child: Text(
                                  '$seconds seconds',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isSelected ? 18 : 15,
                                    fontWeight:
                                        isSelected ? FontWeight.w700 : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF8E8E93),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        setState(() {
                          _durationSeconds = tempDuration;
                          _playbackProgress = 0.0;
                          _isPlaying = true;
                        });
                        _startPlaybackSimulation();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text(
                            'Done',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF141416),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Dynamic squeeze: longer seconds -> box is squeezed smaller (e.g. 5s is 170px, 60s is 105px)
    final double trimmerBoxWidth = (175.0 - ((_durationSeconds - 5) / 55.0) * 70.0).clamp(105.0, 175.0);

    return Container(
      height: screenHeight * 0.78,
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
          const SizedBox(height: 12),

          // 2. Top Header Action Bar (New song & Checkmark)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // "New song" Pill Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onChangeSong?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26262B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF383840),
                        width: 1.0,
                      ),
                    ),
                    child: const Text(
                      'New song',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Blue Confirm Checkmark Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(widget.track);
                    widget.onConfirmed?.call(widget.track);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F80ED),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x662F80ED),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Album Cover Artwork
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.track.albumArtUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF26262B),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 4. Song Title & Artist
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  widget.track.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.track.artist,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9EA4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 5. Snippet Playback Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: SizedBox(
              height: 20,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2.5,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: const Color(0xFF383840),
                  thumbColor: const Color(0xFF2F80ED),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: _playbackProgress.clamp(0.0, 1.0),
                  onChanged: (val) {
                    setState(() {
                      _playbackProgress = val;
                    });
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 6. Interactive Waveform Audio Trimmer Scroller with Moving Playhead Layer & Dynamic Box Squeeze
          SizedBox(
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Horizontally scrollable waveform bars with replay trigger
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      _onWaveformReselected();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _waveformScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.35,
                    ),
                    itemCount: _waveformData.length,
                    itemBuilder: (context, index) {
                      final heightRatio = _waveformData[index];
                      return Center(
                        child: Container(
                          width: 3.5,
                          height: 52 * heightRatio,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF484852),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Center Blue Trimming Window Box with Dynamic Width & Moving Playhead Layer
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: trimmerBoxWidth,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF2F80ED),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F80ED).withValues(alpha: 0.3),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7.5),
                    child: Stack(
                      children: [
                        // Layer 1: Synchronized Moving Tint Fill
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: trimmerBoxWidth * _playbackProgress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F80ED).withValues(alpha: 0.22),
                            ),
                          ),
                        ),

                        // Layer 2: Synchronized Moving Glowing Playhead Cursor
                        Positioned(
                          left: ((trimmerBoxWidth - 3) * _playbackProgress.clamp(0.0, 1.0))
                              .clamp(0.0, trimmerBoxWidth - 3),
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2F80ED).withValues(alpha: 0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 7. Bottom Action Controls (Duration Picker & Play/Pause)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Duration Button (opens scroll wheel picker like Instagram)
                GestureDetector(
                  onTap: _openDurationPicker,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF222226),
                      border: Border.all(
                        color: const Color(0xFF383842),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$_durationSeconds',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Play / Pause Circle Button
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF141416),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
