import 'package:flutter/material.dart';

/// Animated mini dancing music wave equalizer bars for thought balloons
class AnimatedMiniMusicWave extends StatefulWidget {
  const AnimatedMiniMusicWave({super.key});

  @override
  State<AnimatedMiniMusicWave> createState() => _AnimatedMiniMusicWaveState();
}

class _AnimatedMiniMusicWaveState extends State<AnimatedMiniMusicWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

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
              width: 2.0,
              height: 3.5 + (v * 7),
              decoration: BoxDecoration(
                color: const Color(0xFF2F80ED),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 1.5),
            Container(
              width: 2.0,
              height: 3.5 + ((1.0 - v) * 8),
              decoration: BoxDecoration(
                color: const Color(0xFF56CCF2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 1.5),
            Container(
              width: 2.0,
              height: 4.0 + (v * 5),
              decoration: BoxDecoration(
                color: const Color(0xFF9B51E0),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        );
      },
    );
  }
}
