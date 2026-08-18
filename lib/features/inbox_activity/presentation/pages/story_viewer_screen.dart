import 'package:flutter/material.dart';
import '../../domain/entities/shared_thought_story.dart';
import '../widgets/story_viewers_bottom_sheet.dart';

class StoryViewerScreen extends StatefulWidget {
  final SharedThoughtStory story;

  const StoryViewerScreen({
    super.key,
    required this.story,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _openViewersSheet() {
    _progressController.stop();
    StoryViewersBottomSheet.show(context, viewCount: widget.story.viewCount).then((_) {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  void _showStoryOptionsMenu() {
    _progressController.stop();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Material(
          color: const Color(0xFF1E1E22),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            padding: const EdgeInsets.only(bottom: 24),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFF333338), width: 1.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

              // 1. Delete Story Option (Red)
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB5757).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEB5757),
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Delete story',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEB5757),
                  ),
                ),
                subtitle: const Text(
                  'Remove this thought from your story',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                onTap: () {
                  Navigator.of(modalContext).pop(); // Close bottom sheet
                  Navigator.of(context).pop('delete'); // Pop viewer with delete action
                },
              ),

              const Divider(color: Color(0xFF2C2C32), height: 1, indent: 16, endIndent: 16),

              // 2. Save Story Option
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Save story',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.of(modalContext).pop();
                  if (mounted) {
                    _progressController.forward();
                  }
                },
              ),

              // 3. Story Settings
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Story settings',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.of(modalContext).pop();
                  if (mounted) {
                    _progressController.forward();
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
    ).then((_) {
      if (mounted && _progressController.status != AnimationStatus.completed) {
        _progressController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.story.backgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
              // Swipe up to view viewers
              _openViewersSheet();
            }
          },
          child: Column(
            children: [
              // 1. Top Story Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressController.value,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 2.5,
                      borderRadius: BorderRadius.circular(2),
                    );
                  },
                ),
              ),

              // 2. Top User Info Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.cloud_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Story',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.story.timestamp,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF9E9EA4),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // 3. Center Thought Balloon & Avatar
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Speech Balloon
                  CustomPaint(
                    painter: _ViewerBubblePainter(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 22),
                      constraints: const BoxConstraints(minWidth: 170, maxWidth: 280),
                      child: Text(
                        widget.story.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF141416),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),

                  if (widget.story.musicTrack != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222228),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF383842),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.music_note_rounded,
                            color: Color(0xFF56CCF2),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.story.musicTrack!.title} • ${widget.story.musicTrack!.artist}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Animated Audio Waveform next to song title
                          const _ViewerAudioWaveform(),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Cloud Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2F80ED).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.cloud_rounded, color: Colors.white, size: 48),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // 4. Bottom Viewers Indicator Button & Three Dots Options Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _openViewersSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.story.viewCount} views',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Three dots options button (opens delete sheet)
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
                      onPressed: _showStoryOptionsMenu,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewerBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final path = Path();
    const double radius = 18.0;
    const double arrowWidth = 14.0;
    const double arrowHeight = 8.0;
    final double bodyHeight = size.height - arrowHeight;

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, bodyHeight),
        const Radius.circular(radius),
      ),
    );

    final arrowPath = Path()
      ..moveTo(size.width / 2 - arrowWidth / 2, bodyHeight)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + arrowWidth / 2, bodyHeight)
      ..close();

    path.addPath(arrowPath, Offset.zero);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ViewerAudioWaveform extends StatefulWidget {
  const _ViewerAudioWaveform();

  @override
  State<_ViewerAudioWaveform> createState() => _ViewerAudioWaveformState();
}

class _ViewerAudioWaveformState extends State<_ViewerAudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final v = _waveController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 2.2,
              height: 4.0 + (v * 7),
              decoration: BoxDecoration(
                color: const Color(0xFF56CCF2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 2.0),
            Container(
              width: 2.2,
              height: 4.0 + ((1.0 - v) * 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2F80ED),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 2.0),
            Container(
              width: 2.2,
              height: 5.0 + (v * 5),
              decoration: BoxDecoration(
                color: const Color(0xFF56CCF2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        );
      },
    );
  }
}
