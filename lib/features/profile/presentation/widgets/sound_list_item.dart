import 'package:flutter/material.dart';

import '../mock/profile_mock_data.dart';
import '../style/pulse_tokens.dart';

/// A single track row in the Sounds tab. Owns just its own expand/collapse
/// state for "N similar sounds" — no scroll behavior, it's a plain item
/// placed inside a SliverList by the parent.
class SoundListItem extends StatefulWidget {
  const SoundListItem({super.key, required this.sound});

  final SoundTrack sound;

  @override
  State<SoundListItem> createState() => _SoundListItemState();
}

class _SoundListItemState extends State<SoundListItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sound = widget.sound;
    return Container(
      margin: const EdgeInsets.only(bottom: PulseSpacing.stackGap),
      padding: const EdgeInsets.all(PulseSpacing.containerPadding),
      decoration: BoxDecoration(
        color: PulseColors.surface,
        borderRadius: BorderRadius.circular(PulseRadius.cardRadius),
        border: Border.all(color: PulseColors.surfaceStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(PulseRadius.sm),
                child: Image.network(
                  sound.coverUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: PulseColors.surfaceContainer,
                  ),
                ),
              ),
              const SizedBox(width: PulseSpacing.inlineGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.title,
                      style: PulseTypography.bodyLg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Used by ${sound.usedByLabel} videos',
                      style: PulseTypography.bodyMd,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.play_circle_outline,
                  color: PulseColors.onSurface,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_border_rounded,
                  color: PulseColors.onSurface,
                ),
                onPressed: () {},
              ),
            ],
          ),
          if (sound.similarCount > 0)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: PulseSpacing.inlineGap),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${sound.similarCount} similar sounds',
                      style: PulseTypography.bodyMd,
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: PulseColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: PulseSpacing.inlineGap),
              child: Text(
                'Similar sound previews go here (static placeholder).',
                style: PulseTypography.bodyMd,
              ),
            ),
        ],
      ),
    );
  }
}
