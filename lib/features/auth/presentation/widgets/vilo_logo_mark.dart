import 'package:flutter/material.dart';
import '../../../../core/theme/app_typography.dart';

/// Vilo cloud-style logo mark.
///
/// Renders a glossy blue circle with a cloud icon + "vi" label,
/// matching the design reference picture.
class ViloLogoMark extends StatelessWidget {
  const ViloLogoMark({
    super.key,
    this.size = 90,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF5DB8FF),
            Color(0xFF1A7FD4),
            Color(0xFF0B5EAE),
          ],
          stops: [0.0, 0.6, 1.0],
          center: Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A7FD4).withValues(alpha: 0.5),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_rounded,
            color: Colors.white.withValues(alpha: 0.95),
            size: size * 0.38,
          ),
          const SizedBox(height: 2),
          Text(
            'vi',
            style: AppTypography.headlineSm.copyWith(
              color: Colors.white,
              fontSize: size * 0.18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
