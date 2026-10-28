import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';
import 'profile_sync_service.dart';

class ProfileRemoteDataSource {
  final ApiClient _client;

  ProfileRemoteDataSource({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final ProfileRemoteDataSource instance = ProfileRemoteDataSource();

  final Map<String, UserModel> _userCache = {};

  void clearCache() {
    _userCache.clear();
  }

  UserModel? getCachedUser(dynamic idOrUsername) {
    if (idOrUsername == null) return null;
    final identifier = idOrUsername.toString().trim().replaceAll('@', '').toLowerCase();
    return _userCache[identifier];
  }

  void cacheUser(UserModel user) {
    final usernameClean = user.username.trim().replaceAll('@', '').toLowerCase();
    _userCache[usernameClean] = user;
    if (user.id > 0) {
      _userCache[user.id.toString()] = user;
    }
    final displayClean = user.displayName.trim().replaceAll('@', '').toLowerCase();
    if (displayClean.isNotEmpty) {
      _userCache[displayClean] = user;
      _userCache[displayClean.replaceAll(' ', '_')] = user;
      _userCache[displayClean.replaceAll('_', ' ')] = user;
    }
  }

  /// Retrieve authenticated user profile (GET /api/v1/users/me)
  Future<UserModel> getMyProfile() async {
    final response = await _client.get('/users/me', requireAuth: true);
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    cacheUser(user);
    ProfileSyncService.instance.cachedMyProfile = user;
    return user;
  }

  /// Retrieve public profile by user ID or username (GET /api/v1/users/{identifier})
  Future<UserModel> getUser(dynamic idOrUsername) async {
    final identifier = idOrUsername.toString().trim();
    final clean = identifier.startsWith('@') ? identifier.substring(1) : identifier;
    final cleanKey = clean.toLowerCase();

    try {
      final response = await _client.get('/users/$clean', requireAuth: false);
      final user = UserModel.fromJson(response as Map<String, dynamic>);
      cacheUser(user);
      return user;
    } catch (e) {
      if (_userCache.containsKey(cleanKey)) {
        return _userCache[cleanKey]!;
      }
      rethrow;
    }
  }

  /// Retrieve public profile by user ID (GET /api/v1/users/{id})
  Future<UserModel> getUserById(int id) => getUser(id);

  /// Update user profile details & avatar (PUT /api/v1/users/me)
  Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName.trim();
    if (bio != null) body['bio'] = bio.trim();
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl.trim();

    final response = await _client.put(
      '/users/me',
      body: body,
      requireAuth: true,
    );
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    cacheUser(user);
    ProfileSyncService.instance.cachedMyProfile = user;
    return user;
  }

  /// Follow target user idempotently (PUT /api/v1/users/{id}/follow).
  /// Calling this when already followed leaves the relationship unchanged.
  Future<bool> toggleFollow(int id) async {
    final response = await _client.put(
      '/users/$id/follow',
      requireAuth: true,
    );
    if (response is Map<String, dynamic> && response.containsKey('following')) {
      return response['following'] as bool;
    }
    return true;
  }

  /// Unfollow target user (DELETE /api/v1/users/{id}/follow)
  Future<bool> unfollow(int id) async {
    final response = await _client.delete(
      '/users/$id/follow',
      requireAuth: true,
    );
    if (response is Map<String, dynamic> && response.containsKey('following')) {
      return response['following'] as bool;
    }
    return false;
  }

  /// List followers of a user (GET /api/v1/users/{id}/followers)
  Future<List<UserModel>> getFollowers(int userId) async {
    final response = await _client.get('/users/$userId/followers', requireAuth: true);
    if (response is List) {
      final list = response.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
      for (final u in list) {
        cacheUser(u);
      }
      return list;
    }
    return [];
  }

  /// List accounts followed by a user (GET /api/v1/users/{id}/following)
  Future<List<UserModel>> getFollowing(int userId) async {
    final response = await _client.get('/users/$userId/following', requireAuth: true);
    if (response is List) {
      final list = response.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
      for (final u in list) {
        cacheUser(u);
      }
      return list;
    }
    return [];
  }

  /// List suggested users / real accounts in DB for Friends screen (GET /api/v1/users/suggestions)
  Future<List<UserModel>> getSuggestedUsers() async {
    final response = await _client.get('/users/suggestions', requireAuth: true);
    if (response is List) {
      final list = response.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
      for (final u in list) {
        cacheUser(u);
      }
      return list;
    }
    return [];
  }
}
