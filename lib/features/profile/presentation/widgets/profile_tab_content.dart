import 'package:flutter/material.dart';

import '../mock/profile_mock_data.dart';
import '../style/pulse_tokens.dart';
import 'shop_product_card.dart';
import 'sound_list_item.dart';
import 'video_grid_item.dart';

/// Builds the sliver(s) for whichever tab is selected.
///
/// IMPORTANT: this returns plain slivers (SliverList / SliverGrid), not a
/// scrollable widget. They get spread directly into the parent
/// CustomScrollView's `slivers` list, so the video grid / sounds list / shop
/// list scroll together with the header as ONE page scroll — there is no
/// nested/inner scroll view here.
List<Widget> buildProfileTabSlivers(int selectedIndex) {
  switch (selectedIndex) {
    case 0: // Sounds
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            PulseSpacing.edgeMargin,
            PulseSpacing.stackGap,
            PulseSpacing.edgeMargin,
            PulseSpacing.sectionMargin,
          ),
          sliver: SliverList.builder(
            itemCount: ProfileMockData.sounds.length,
            itemBuilder: (context, i) =>
                SoundListItem(sound: ProfileMockData.sounds[i]),
          ),
        ),
      ];

    case 2: // Shop
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            PulseSpacing.edgeMargin,
            PulseSpacing.stackGap,
            PulseSpacing.edgeMargin,
            PulseSpacing.sectionMargin,
          ),
          sliver: SliverList.builder(
            itemCount: ProfileMockData.products.length,
            itemBuilder: (context, i) =>
                ShopProductCard(product: ProfileMockData.products[i]),
          ),
        ),
      ];

    case 1: // Grid / Videos
    case 3: // Saved
    case 4: // Liked
    default:
      final thumbnails = ProfileMockData.videoThumbnails;
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            PulseSpacing.inlineGap,
            PulseSpacing.stackGap,
            PulseSpacing.inlineGap,
            PulseSpacing.sectionMargin,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => VideoGridItem(
                thumbnailUrl: thumbnails[i % thumbnails.length],
              ),
              // Static mock count — swap for real list length later.
              childCount: 12,
            ),
          ),
        ),
      ];
  }
}
