import 'package:flutter/foundation.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/data/models/video_model.dart';

class FollowChangeEvent {
  final int targetUserId;
  final bool isFollowing;
  final int delta; // +1 if now following, -1 if unfollowed

  const FollowChangeEvent({
    required this.targetUserId,
    required this.isFollowing,
    required this.delta,
  });
}

class VideoInteractionEvent {
  final int videoId;
  final bool? isLiked;
  final int? likeCount;
  final bool? isSaved;
  final int? saveCount;
  final int? commentCount;
  final VideoModel? video;

  const VideoInteractionEvent({
    required this.videoId,
    this.isLiked,
    this.likeCount,
    this.isSaved,
    this.saveCount,
    this.commentCount,
    this.video,
  });
}

/// Global profile and follow sync service that broadcasts real-time follow/unfollow
/// and video interaction changes across ProfileScreen, PublicProfileScreen, and VideoFeedPage.
class ProfileSyncService {
  ProfileSyncService._();
  static final ProfileSyncService instance = ProfileSyncService._();

  /// Emits whenever follow state changes anywhere in the app
  final ValueNotifier<FollowChangeEvent?> followEvents = ValueNotifier<FollowChangeEvent?>(null);

  /// Emits whenever a new video or photo is uploaded by the current user
  final ValueNotifier<VideoModel?> videoUploadedEvents = ValueNotifier<VideoModel?>(null);

  /// Emits whenever like, save, or comment count changes on any video in the app
  final ValueNotifier<VideoInteractionEvent?> videoInteractionEvents = ValueNotifier<VideoInteractionEvent?>(null);

  /// Emits whenever a video is deleted
  final ValueNotifier<int?> videoDeletedEvents = ValueNotifier<int?>(null);

  void notifyVideoUploaded(VideoModel video) {
    videoUploadedEvents.value = video;
  }

  void notifyVideoDeleted(int videoId) {
    FeedRemoteDataSource.instance.removeCachedVideo(videoId);
    videoDeletedEvents.value = videoId;
  }

  void notifyVideoInteraction(VideoInteractionEvent event) {
    videoInteractionEvents.value = event;
    FeedRemoteDataSource.instance.updateCachedVideo(
      videoId: event.videoId,
      isLiked: event.isLiked,
      likeCount: event.likeCount,
      isSaved: event.isSaved,
      saveCount: event.saveCount,
      commentCount: event.commentCount,
    );
  }

  /// Cached user profile for immediate optimistic updates across screens
  UserModel? _cachedMyProfile;
  UserModel? get cachedMyProfile {
    if (_cachedMyProfile != null) return _cachedMyProfile;
    final stored = TokenStorage.instance.getUserModel();
    if (stored != null) {
      _cachedMyProfile = stored;
      return _cachedMyProfile;
    }
    return null;
  }

  set cachedMyProfile(UserModel? user) {
    _cachedMyProfile = user;
  }

  void clear() {
    _cachedMyProfile = null;
    cachedFollowers = null;
    cachedFollowing = null;
    mockFollowersCount = 0;
    mockFollowingCount = 0;
    followEvents.value = null;
    videoUploadedEvents.value = null;
    videoInteractionEvents.value = null;
    videoDeletedEvents.value = null;
  }

  /// In-memory cache of followers and following for instant zero-latency listing
  List<UserModel>? cachedFollowers;
  List<UserModel>? cachedFollowing;

  int mockFollowersCount = 0;
  int mockFollowingCount = 0;

  void setCurrentUser(UserModel user) {
    cachedMyProfile = user;
    mockFollowingCount = user.followingCount;
    mockFollowersCount = user.followersCount;
    cachedFollowers = null;
    cachedFollowing = null;
  }

  void clearSession() {
    cachedMyProfile = null;
    cachedFollowers = null;
    cachedFollowing = null;
    mockFollowingCount = 0;
    mockFollowersCount = 0;
  }

  /// Returns the current active user's avatar URL
  String get currentUserAvatar {
    final cached = cachedMyProfile?.avatarUrl;
    if (cached != null && cached.trim().isNotEmpty) {
      return cached.trim();
    }
    return 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';
  }

  /// Returns the current active user's display name
  String get currentUserDisplayName {
    final cached = cachedMyProfile?.displayName;
    if (cached != null && cached.trim().isNotEmpty) {
      return cached.trim();
    }
    final stored = TokenStorage.instance.currentDisplayNameSync;
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    final username = cachedMyProfile?.username ?? TokenStorage.instance.currentUsernameSync;
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    return 'User';
  }

  /// Returns the current active user's clean username (without @)
  String get currentUsername {
    final raw = (cachedMyProfile?.username != null && cachedMyProfile!.username.trim().isNotEmpty)
        ? cachedMyProfile!.username
        : (TokenStorage.instance.currentUsernameSync ?? '');
    return raw.trim().toLowerCase().replaceAll('@', '');
  }

  /// Returns true if the given username or ID belongs to the current user.
  /// Matches ONLY the active authenticated session — no hardcoded fallbacks.
  bool isCurrentUser({String? username, String? id}) {
    if (id != null && id.isNotEmpty && id != '0') {
      if (cachedMyProfile != null && cachedMyProfile!.id.toString() == id) return true;
      final storedId = TokenStorage.instance.currentUserIdSync;
      if (storedId != null && storedId.toString() == id) return true;
    }

    if (username != null && username.isNotEmpty) {
      final clean = username.trim().toLowerCase().replaceAll('@', '');
      final myUser = currentUsername;
      if (myUser.isNotEmpty && clean == myUser) return true;
    }

    return false;
  }

  void notifyFollowChanged({required int targetUserId, required bool isFollowing, UserModel? targetUser}) {
    final delta = isFollowing ? 1 : -1;
    mockFollowingCount = (mockFollowingCount + delta).clamp(0, 999999999);
    if (cachedMyProfile != null) {
      final updatedFollowing = (cachedMyProfile!.followingCount + delta).clamp(0, 999999999);
      cachedMyProfile = cachedMyProfile!.copyWith(followingCount: updatedFollowing);
    }

    // Update cachedFollowing in place if available
    if (cachedFollowing != null) {
      if (isFollowing) {
        final existingIndex = cachedFollowing!.indexWhere((u) => u.id == targetUserId);
        if (existingIndex != -1) {
          cachedFollowing![existingIndex] = cachedFollowing![existingIndex].copyWith(isFollowing: true);
        } else if (targetUser != null) {
          cachedFollowing!.insert(0, targetUser.copyWith(isFollowing: true));
        }
      } else {
        cachedFollowing!.removeWhere((u) => u.id == targetUserId);
      }
    }

    // Update cachedFollowers if this user appears in followers
    if (cachedFollowers != null) {
      final fIndex = cachedFollowers!.indexWhere((u) => u.id == targetUserId);
      if (fIndex != -1) {
        cachedFollowers![fIndex] = cachedFollowers![fIndex].copyWith(isFollowing: isFollowing);
      }
    }

    followEvents.value = FollowChangeEvent(
      targetUserId: targetUserId,
      isFollowing: isFollowing,
      delta: delta,
    );
  }
}
