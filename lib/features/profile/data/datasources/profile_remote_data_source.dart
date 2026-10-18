import '../../../../core/network/api_client.dart';
import '../../../auth/data/models/user_model.dart';

class ProfileRemoteDataSource {
  final ApiClient _client;

  ProfileRemoteDataSource({ApiClient? client}) : _client = client ?? ApiClient.instance;

  static final ProfileRemoteDataSource instance = ProfileRemoteDataSource();

  /// Retrieve authenticated user profile (GET /api/v1/users/me)
  Future<UserModel> getMyProfile() async {
    final response = await _client.get('/users/me', requireAuth: true);
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  /// Retrieve public profile by user ID (GET /api/v1/users/{id})
  Future<UserModel> getUserById(int id) async {
    final response = await _client.get('/users/$id', requireAuth: true);
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

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
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  /// Toggle follow state on target user (POST /api/v1/users/{id}/follow)
  Future<bool> toggleFollow(int id) async {
    final response = await _client.post(
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
      return response.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// List accounts followed by a user (GET /api/v1/users/{id}/following)
  Future<List<UserModel>> getFollowing(int userId) async {
    final response = await _client.get('/users/$userId/following', requireAuth: true);
    if (response is List) {
      return response.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// List suggested users / real accounts in DB for Friends screen (GET /api/v1/users/suggestions)
  Future<List<UserModel>> getSuggestedUsers() async {
    final response = await _client.get('/users/suggestions', requireAuth: true);
    if (response is List) {
      return response.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
