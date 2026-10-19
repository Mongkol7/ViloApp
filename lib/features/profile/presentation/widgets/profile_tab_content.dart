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
List<Widget> buildProfileTabSlivers(int selectedIndex, {bool isCleanSlate = false}) {
  if (isCleanSlate) {
    IconData icon;
    String title;
    String subtitle;

    switch (selectedIndex) {
      case 0:
        icon = Icons.music_note_outlined;
        title = 'No sounds yet';
        subtitle = 'Original sounds created will appear here';
        break;
      case 2:
        icon = Icons.shopping_bag_outlined;
        title = 'No products showcase';
        subtitle = 'Products tagged or showcased will appear here';
        break;
      case 3:
        icon = Icons.bookmark_border_rounded;
        title = 'No saved videos yet';
        subtitle = 'Only you can see your saved videos';
        break;
      case 4:
        icon = Icons.favorite_border_rounded;
        title = 'No liked videos yet';
        subtitle = 'Videos you like will appear here';
        break;
      case 1:
      default:
        icon = Icons.videocam_outlined;
        title = 'No videos yet';
        subtitle = 'Upload your first video to share with friends';
        break;
    }

    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: const Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

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

    case 1: // Grid / Postings
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
              childCount: 12,
            ),
          ),
        ),
      ];

    case 3: // Saved
      final savedThumbnails = ProfileMockData.savedThumbnails;
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
                thumbnailUrl: savedThumbnails[i % savedThumbnails.length],
              ),
              childCount: 12,
            ),
          ),
        ),
      ];

    case 4: // Liked
    default:
      final likedThumbnails = ProfileMockData.likedThumbnails;
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
                thumbnailUrl: likedThumbnails[i % likedThumbnails.length],
              ),
              childCount: 12,
            ),
          ),
        ),
      ];
  }
}
