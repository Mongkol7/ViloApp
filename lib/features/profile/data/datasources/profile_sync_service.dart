import 'package:flutter/foundation.dart';
import '../../../auth/data/models/user_model.dart';

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

/// Global profile and follow sync service that broadcasts real-time follow/unfollow
/// state changes across ProfileScreen, PublicProfileScreen, and FollowersFollowingScreen.
class ProfileSyncService {
  ProfileSyncService._();
  static final ProfileSyncService instance = ProfileSyncService._();

  /// Emits whenever follow state changes anywhere in the app
  final ValueNotifier<FollowChangeEvent?> followEvents = ValueNotifier<FollowChangeEvent?>(null);

  /// Cached user profile for immediate optimistic updates across screens
  UserModel? cachedMyProfile;

  /// In-memory cache of followers and following for instant zero-latency listing
  List<UserModel>? cachedFollowers;
  List<UserModel>? cachedFollowing;

  int mockFollowersCount = 4;
  int mockFollowingCount = 3;

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
