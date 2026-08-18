import 'package:flutter/material.dart';

import '../style/pulse_tokens.dart';

/// A single square thumbnail for the video grid (Videos / Saved / Liked tabs).
/// Pure display widget — no scrolling behavior of its own, it's placed
/// directly inside a SliverGrid by the parent.
class VideoGridItem extends StatelessWidget {
  const VideoGridItem({
    super.key,
    required this.thumbnailUrl,
    this.viewsLabel,
  });

  final String thumbnailUrl;
  final String? viewsLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(PulseRadius.sm),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: PulseColors.surfaceContainer),
          Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: PulseColors.surfaceContainer),
          ),
          if (viewsLabel != null)
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    viewsLabel!,
                    style: PulseTypography.labelCaps.copyWith(
                      color: Colors.white,
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
