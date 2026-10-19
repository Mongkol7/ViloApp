import 'package:flutter/material.dart';

import '../../../feed/data/models/video_model.dart';
import '../style/pulse_tokens.dart';

/// A single square thumbnail for the video grid (Videos / Saved / Liked tabs).
/// Pure display widget with optional tap support to open and view the video.
class VideoGridItem extends StatelessWidget {
  const VideoGridItem({
    super.key,
    required this.thumbnailUrl,
    this.viewsLabel,
    this.onTap,
  });

  final String thumbnailUrl;
  final String? viewsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final cleanUrl = thumbnailUrl.trim();

    if (cleanUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        cleanUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: PulseColors.surfaceContainer),
      );
    } else if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      imageWidget = Image.network(
        cleanUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: PulseColors.surfaceContainer),
      );
    } else if (cleanUrl.isNotEmpty) {
      final resolved = VideoModel.resolveMediaUrl(cleanUrl);
      imageWidget = Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: PulseColors.surfaceContainer),
      );
    } else {
      imageWidget = Container(
        color: PulseColors.surfaceContainer,
        child: const Center(
          child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PulseRadius.sm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: PulseColors.surfaceContainer),
            imageWidget,
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
      ),
    );
  }
}

