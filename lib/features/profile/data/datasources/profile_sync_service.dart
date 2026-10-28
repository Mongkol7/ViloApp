import 'package:flutter/foundation.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/data/models/video_model.dart';
import '../../../shop/models/product.dart';
import '../../presentation/mock/profile_mock_data.dart';

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

  /// Emits whenever a sound track is uploaded
  final ValueNotifier<SoundTrack?> soundUploadedEvents = ValueNotifier<SoundTrack?>(null);

  /// Emits whenever a sound track is deleted
  final ValueNotifier<int?> soundDeletedEvents = ValueNotifier<int?>(null);

  /// Emits whenever the current user's profile is updated (name, bio, avatar)
  final ValueNotifier<UserModel?> profileUpdatedEvents = ValueNotifier<UserModel?>(null);

  /// Emits whenever a product is uploaded/published by the current user
  final ValueNotifier<Product?> productUploadedEvents = ValueNotifier<Product?>(null);

  void notifyVideoUploaded(VideoModel video) {
    videoUploadedEvents.value = video;
  }

  void notifyVideoDeleted(int videoId) {
    FeedRemoteDataSource.instance.removeCachedVideo(videoId);
    videoDeletedEvents.value = videoId;
  }

  void notifySoundUploaded(SoundTrack sound) {
    soundUploadedEvents.value = sound;
    notifyInteraction();
  }

  void notifySoundDeleted(int soundId) {
    soundDeletedEvents.value = soundId;
    notifyInteraction();
  }

  void notifyProfileUpdated(UserModel user) {
    cachedMyProfile = user;
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
    notifyInteraction();
  }

  /// Emits whenever video interaction (like, save, upload) happens so Profile tabs automatically refresh
  final ValueNotifier<int> interactionEvents = ValueNotifier<int>(0);

  void notifyInteraction() {
    interactionEvents.value = interactionEvents.value + 1;
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
    if (user != null) {
      TokenStorage.instance.saveUserData(
        id: user.id,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        email: user.email,
        bio: user.bio,
      );
      profileUpdatedEvents.value = user;
    }
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
    soundUploadedEvents.value = null;
    soundDeletedEvents.value = null;
    profileUpdatedEvents.value = null;
    productUploadedEvents.value = null;
  }

  /// In-memory cache of followers and following for instant zero-latency listing
  List<UserModel>? cachedFollowers;
  List<UserModel>? cachedFollowing;

  int mockFollowersCount = 0;
  int mockFollowingCount = 0;

  /// Returns the current active user's avatar URL
  String get currentUserAvatar {
    final cached = cachedMyProfile?.avatarUrl;
    if (cached != null && cached.trim().isNotEmpty) {
      return cached.trim();
    }
    return ProfileMockData.avatarUrl;
  }

  /// Returns the current active user's display name
  String get currentUserDisplayName {
    final cached = cachedMyProfile?.displayName;
    if (cached != null && cached.trim().isNotEmpty) {
      return cached.trim();
    }
    final username = cachedMyProfile?.username;
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    return ProfileMockData.name;
  }

  /// Returns the current active user's clean username (without @)
  String get currentUsername {
    final raw = (cachedMyProfile?.username != null && cachedMyProfile!.username.trim().isNotEmpty)
        ? cachedMyProfile!.username
        : ProfileMockData.username;
    return raw.trim().toLowerCase().replaceAll('@', '');
  }

  /// Returns true if the given username or ID belongs to the current user.
  bool isCurrentUser({String? username, String? id}) {
    // 1. Resolve current user identity
    final currentProfile = cachedMyProfile ?? TokenStorage.instance.getUserModel();
    final int? myId = currentProfile?.id;
    final String? myRawUsername = currentProfile?.username;
    final String myUsername = (myRawUsername != null && myRawUsername.trim().isNotEmpty)
        ? myRawUsername.trim().toLowerCase().replaceAll('@', '')
        : '';

    // Clean and validate candidate input
    final cleanUsername = username?.trim().toLowerCase().replaceAll('@', '') ?? '';
    final cleanId = (id != null && id.trim().isNotEmpty && id.trim() != '0') ? id.trim() : null;

    if (cleanUsername == 'seller' || (cleanUsername.isEmpty && cleanId == null)) {
      return false;
    }

    // 2. If valid ID is provided, compare with current user's ID
    if (cleanId != null && myId != null && myId > 0) {
      if (myId.toString() == cleanId) {
        return true;
      }
      // If both IDs exist and do not match, they are different accounts
      return false;
    }

    // 3. If username is provided, compare with current user's username
    if (cleanUsername.isNotEmpty && myUsername.isNotEmpty) {
      return cleanUsername == myUsername;
    }

    // 4. Fallback only if app is unauthenticated (no token and no cached profile)
    if (myId == null && myUsername.isEmpty) {
      final fallback = ProfileMockData.username.trim().toLowerCase().replaceAll('@', '');
      return cleanUsername.isNotEmpty && cleanUsername == fallback;
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

  bool isFollowingUser({String? username, int? userId}) {
    if (cachedFollowing == null) return false;
    final clean = username?.replaceAll('@', '').trim().toLowerCase() ?? '';
    return cachedFollowing!.any((u) {
      if (userId != null && u.id == userId) return true;
      if (clean.isNotEmpty && u.username.toLowerCase() == clean) return true;
      return false;
    });
  }
}
