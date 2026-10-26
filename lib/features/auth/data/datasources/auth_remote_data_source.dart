import '../../../../core/network/api_client.dart';
import '../../../inbox_activity/data/datasources/inbox_message_manager.dart';
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
    );

    // Switch InboxMessageManager to this authenticated account and load its saved conversations
    await InboxMessageManager.instance.loadForUser(user.id);

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
    );

    // Switch InboxMessageManager to this authenticated account and load its saved conversations
    await InboxMessageManager.instance.loadForUser(user.id);

    return user;
  }

  Future<UserModel> getMe() async {
    final response = await _client.get('/users/me', requireAuth: true);
    return UserModel.fromJson(response as Map<String, dynamic>);
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
    // Switch InboxMessageManager back to guest mode
    await InboxMessageManager.instance.loadForCurrentUser();
  }
}
