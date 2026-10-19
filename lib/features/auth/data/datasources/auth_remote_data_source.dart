import '../../../../core/network/api_client.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../models/user_model.dart';
import 'token_storage.dart';

class AuthRemoteDataSource {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  AuthRemoteDataSource({ApiClient? client, TokenStorage? tokenStorage})
      : _client = client ?? ApiClient.instance,
        _tokenStorage = tokenStorage ?? TokenStorage.instance;

  Future<UserModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      body: {
        'usernameOrEmail': usernameOrEmail.trim(),
        'password': password,
      },
      requireAuth: false,
    );

    final accessToken = response['accessToken'] as String;
    final refreshToken = response['refreshToken'] as String;
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _tokenStorage.saveUserData(
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      email: user.email,
    );

    // Sync globally so identity immediately reflects active user
    ProfileSyncService.instance.cachedMyProfile = user;
    ProfileRemoteDataSource.instance.cacheUser(user);

    return user;
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _client.post(
      '/auth/register',
      body: {
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
        'displayName': displayName?.trim(),
      },
      requireAuth: false,
    );

    final accessToken = response['accessToken'] as String;
    final refreshToken = response['refreshToken'] as String;
    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _tokenStorage.saveUserData(
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      email: user.email,
    );

    // Sync globally so identity immediately reflects active user
    ProfileSyncService.instance.cachedMyProfile = user;
    ProfileRemoteDataSource.instance.cacheUser(user);

    return user;
  }

  Future<UserModel> getMe() async {
    final response = await _client.get('/users/me', requireAuth: true);
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    ProfileSyncService.instance.cachedMyProfile = user;
    ProfileRemoteDataSource.instance.cacheUser(user);
    return user;
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    try {
      await _client.post(
        '/auth/logout',
        body: refreshToken != null ? {'refreshToken': refreshToken} : null,
        requireAuth: true,
      );
    } catch (_) {}
    await _tokenStorage.clear();
    ProfileSyncService.instance.clear();
    ProfileRemoteDataSource.instance.clearCache();
    FeedRemoteDataSource.instance.clearCache();
  }
}
