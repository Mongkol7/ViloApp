import 'package:flutter/material.dart';

import '../../../feed/data/models/video_feed_model.dart';
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
List<Widget> buildProfileTabSlivers(
  int selectedIndex, {
  List<VideoFeedModel>? userVideos,
  bool isLoading = false,
}) {
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
      if (userVideos != null && userVideos.isNotEmpty) {
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
                (context, i) {
                  final video = userVideos[i];
                  final thumb = (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
                      ? video.thumbnailUrl!
                      : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500';
                  return VideoGridItem(
                    thumbnailUrl: thumb,
                    viewsLabel: video.likes,
                  );
                },
                childCount: userVideos.length,
              ),
            ),
          ),
        ];
      }

      if (isLoading && (userVideos == null || userVideos.isEmpty)) {
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
                (context, i) => Container(
                  decoration: BoxDecoration(
                    color: PulseColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(PulseRadius.sm),
                  ),
                ),
                childCount: 6,
              ),
            ),
          ),
        ];
      }

      if (!isLoading && userVideos != null && userVideos.isEmpty) {
        return [
          const SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 48),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_outlined, color: Colors.white24, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'No videos posted yet',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      }

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
