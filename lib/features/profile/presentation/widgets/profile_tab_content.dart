import 'package:flutter/material.dart';

import '../../../feed/data/models/video_feed_model.dart';
import '../mock/profile_mock_data.dart';
import '../style/pulse_tokens.dart';
import 'shop_product_card.dart';
import 'sound_list_item.dart';
import 'video_grid_item.dart';

/// Builds the sliver(s) for whichever tab is selected.
///
/// Tab 0: Sounds (user-specific uploaded/created sounds)
/// Tab 1: Postings (user-specific uploaded videos/photos)
/// Tab 2: Shop (untouched product showcase)
/// Tab 3: Saved (user's bookmarked videos)
/// Tab 4: Liked (user's liked videos)
List<Widget> buildProfileTabSlivers(
  int selectedIndex, {
  List<SoundTrack>? userSounds,
  List<VideoFeedModel>? userVideos,
  List<VideoFeedModel>? savedVideos,
  List<VideoFeedModel>? likedVideos,
  bool isLoading = false,
  bool isCurrentUser = true,
  void Function(VideoFeedModel video, int index)? onVideoTap,
  void Function(VideoFeedModel video, int index)? onVideoLongPress,
  void Function(VideoFeedModel video, int index)? onSavedVideoTap,
  void Function(VideoFeedModel video, int index)? onLikedVideoTap,
  void Function(SoundTrack updatedSound)? onSoundUpdated,
  void Function(SoundTrack deletedSound)? onSoundDeleted,
}) {
  switch (selectedIndex) {
    case 0: // Sounds
      if (userSounds != null && userSounds.isNotEmpty) {
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              PulseSpacing.edgeMargin,
              PulseSpacing.stackGap,
              PulseSpacing.edgeMargin,
              PulseSpacing.sectionMargin,
            ),
            sliver: SliverList.builder(
              itemCount: userSounds.length,
              itemBuilder: (context, i) =>
                  SoundListItem(
                    sound: userSounds[i],
                    isCreator: isCurrentUser,
                    onSoundUpdated: onSoundUpdated,
                    onSoundDeleted: onSoundDeleted,
                  ),
            ),
          ),
        ];
      }

      if (isLoading && (userSounds == null || userSounds.isEmpty)) {
        return [
          const SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 48),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                ),
              ),
            ),
          ),
        ];
      }

      return [
        const SliverPadding(
          padding: EdgeInsets.symmetric(vertical: 48),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note_outlined, color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No sounds uploaded yet',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];

    case 1: // Postings
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
                  String thumb;
                  if (video.thumbnailUrl != null && video.thumbnailUrl!.trim().isNotEmpty) {
                    thumb = video.thumbnailUrl!.trim();
                  } else if (video.isImagePost && video.videoUrl.trim().isNotEmpty) {
                    thumb = video.videoUrl.trim();
                  } else {
                    thumb = '';
                  }

                  return VideoGridItem(
                    thumbnailUrl: thumb,
                    viewsLabel: video.views,
                    onTap: onVideoTap != null ? () => onVideoTap(video, i) : null,
                    onLongPress: onVideoLongPress != null ? () => onVideoLongPress(video, i) : null,
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

    case 2: // Shop (Untouched)
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

    case 3: // Saved
      if (savedVideos != null && savedVideos.isNotEmpty) {
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
                  final video = savedVideos[i];
                  String thumb;
                  if (video.thumbnailUrl != null && video.thumbnailUrl!.trim().isNotEmpty) {
                    thumb = video.thumbnailUrl!.trim();
                  } else if (video.isImagePost && video.videoUrl.trim().isNotEmpty) {
                    thumb = video.videoUrl.trim();
                  } else {
                    thumb = '';
                  }

                  return VideoGridItem(
                    thumbnailUrl: thumb,
                    viewsLabel: video.views,
                    onTap: onSavedVideoTap != null
                        ? () => onSavedVideoTap(video, i)
                        : (onVideoTap != null ? () => onVideoTap(video, i) : null),
                  );
                },
                childCount: savedVideos.length,
              ),
            ),
          ),
        ];
      }

      if (isLoading && (savedVideos == null || savedVideos.isEmpty)) {
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

      if (!isCurrentUser) {
        return [
          const SliverPadding(
            padding: EdgeInsets.symmetric(vertical: 48),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 48),
                    SizedBox(height: 12),
                    Text(
                      "This user's saved videos are private",
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Saved videos and collections are only visible to their creator',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ];
      }

      return [
        const SliverPadding(
          padding: EdgeInsets.symmetric(vertical: 48),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border_rounded, color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No saved videos yet',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];

    case 4: // Liked
      if (likedVideos != null && likedVideos.isNotEmpty) {
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
                  final video = likedVideos[i];
                  String thumb;
                  if (video.thumbnailUrl != null && video.thumbnailUrl!.trim().isNotEmpty) {
                    thumb = video.thumbnailUrl!.trim();
                  } else if (video.isImagePost && video.videoUrl.trim().isNotEmpty) {
                    thumb = video.videoUrl.trim();
                  } else {
                    thumb = '';
                  }

                  return VideoGridItem(
                    thumbnailUrl: thumb,
                    viewsLabel: video.views,
                    onTap: onLikedVideoTap != null
                        ? () => onLikedVideoTap(video, i)
                        : (onVideoTap != null ? () => onVideoTap(video, i) : null),
                  );
                },
                childCount: likedVideos.length,
              ),
            ),
          ),
        ];
      }

      if (isLoading && (likedVideos == null || likedVideos.isEmpty)) {
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

      return [
        const SliverPadding(
          padding: EdgeInsets.symmetric(vertical: 48),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded, color: Colors.white24, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No liked videos yet',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];

    default:
      return [
        const SliverToBoxAdapter(child: SizedBox.shrink()),
      ];
  }
}
