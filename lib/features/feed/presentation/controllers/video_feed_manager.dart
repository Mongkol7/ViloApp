import 'package:flutter/foundation.dart';
import '../../data/models/video_model.dart';

/// Centralized in-memory manager for real-time video feed updates.
///
/// Ensures real-time state synchronization when new videos are uploaded,
/// instantly prepending them to [VideoFeedPage] and triggering refresh in [CommunityFeedPage].
class VideoFeedManager {
  VideoFeedManager._internal();
  static final VideoFeedManager instance = VideoFeedManager._internal();

  /// Emits the latest uploaded [VideoModel] to prepend to active feed lists.
  final ValueNotifier<VideoModel?> latestUploadedVideoNotifier =
      ValueNotifier<VideoModel?>(null);

  /// Emits incremental counter when community feed should reload.
  final ValueNotifier<int> feedRefreshNotifier = ValueNotifier<int>(0);

  /// Prepend a newly created video to the feed and notify all listeners.
  void prependVideo(VideoModel video) {
    latestUploadedVideoNotifier.value = video;
    feedRefreshNotifier.value++;
  }

  /// Reset / clear state (useful for tests or logout).
  void clear() {
    latestUploadedVideoNotifier.value = null;
    feedRefreshNotifier.value = 0;
  }
}
