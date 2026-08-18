import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/music_track.dart';
import '../../domain/entities/shared_thought_story.dart';
import '../widgets/music_picker_bottom_sheet.dart';

class ShareThoughtScreen extends StatefulWidget {
  const ShareThoughtScreen({super.key});

  @override
  State<ShareThoughtScreen> createState() => _ShareThoughtScreenState();
}

class _ShareThoughtScreenState extends State<ShareThoughtScreen> {
  final TextEditingController _thoughtController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  MusicTrack? _selectedTrack;

  // Instagram-style background color themes
  final List<Color> _backgroundThemes = const [
    Color(0xFF141416), // Obsidian Dark (Default)
    Color(0xFF1B102E), // Midnight Violet
    Color(0xFF2C0F22), // Crimson Dusk
    Color(0xFF08222C), // Cyber Blue
    Color(0xFF0D281C), // Deep Emerald
    Color(0xFF281C0E), // Espresso Amber
  ];
  int _themeIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cycleBackgroundColor() {
    setState(() {
      _themeIndex = (_themeIndex + 1) % _backgroundThemes.length;
    });
  }

  Future<void> _openMusicPicker() async {
    _focusNode.unfocus();
    final track = await MusicPickerBottomSheet.show(context);
    if (track != null) {
      setState(() {
        _selectedTrack = track;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _backgroundThemes[_themeIndex];

    return Scaffold(
      backgroundColor: currentColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        color: currentColor,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Your Thoughts are visible for 24 hours',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF9E9EA4),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    // Right side quick actions
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {},
                        ),
                        // Palette Icon - Tap to cycle background themes
                        IconButton(
                          icon: Icon(
                            Icons.palette_outlined,
                            color: _themeIndex != 0
                                ? const Color(0xFF56CCF2)
                                : Colors.white,
                            size: 24,
                          ),
                          onPressed: _cycleBackgroundColor,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.music_note_outlined,
                            color: _selectedTrack != null
                                ? const Color(0xFF56CCF2)
                                : Colors.white,
                            size: 24,
                          ),
                          onPressed: _openMusicPicker,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Upper Spacer (Balanced to position avatar comfortably in upper-middle)
              const Spacer(flex: 2),

              // 2. Middle Thought Bubble & Cloud Avatar
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Speech Bubble with Downward Arrow Pointer
                  CustomPaint(
                    painter: _SpeechBubblePainter(),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(28, 14, 28, 22),
                      constraints: const BoxConstraints(minWidth: 170, maxWidth: 260),
                      child: IntrinsicWidth(
                        child: TextField(
                          controller: _thoughtController,
                          focusNode: _focusNode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF141416),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'On your mind...',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8E8E93),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),

                  if (_selectedTrack != null) ...[
                    const SizedBox(height: 8),
                    // Selected Music Track Badge with Audio Waveform animation next to title
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            '${_selectedTrack!.title} • ${_selectedTrack!.artist}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Audio Waveform Animation next to music title
                          const _ShareAudioWaveform(),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTrack = null;
                              });
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF9E9EA4),
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Cloud Profile Avatar (Positioned in the middle)
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                      ),
                      border: Border.all(
                        color: const Color(0xFF2F80ED),
                        width: 2.5,
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
                      child: Icon(
                        Icons.cloud_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ),
                ],
              ),

              // Lower Spacer
              const Spacer(flex: 3),

              // 3. Share Button Dock
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: GestureDetector(
                  onTap: () {
                    final story = SharedThoughtStory(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      message: _thoughtController.text.trim().isNotEmpty
                          ? _thoughtController.text.trim()
                          : "Today's vibe...",
                      musicTrack: _selectedTrack,
                      backgroundColor: currentColor,
                      timestamp: 'Just now',
                      viewCount: 418,
                    );
                    Navigator.of(context).pop(story);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222226),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: AppColors.surfaceStroke,
                        width: 1.0,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_circle_up_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Your Story',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareAudioWaveform extends StatefulWidget {
  const _ShareAudioWaveform();

  @override
  State<_ShareAudioWaveform> createState() => _ShareAudioWaveformState();
}

class _ShareAudioWaveformState extends State<_ShareAudioWaveform>
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

class _SpeechBubblePainter extends CustomPainter {
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

    // Rounded rectangle body
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, bodyHeight),
        const Radius.circular(radius),
      ),
    );

    // Downward arrow pointer
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
