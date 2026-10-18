import 'package:shared_preferences/shared_preferences.dart';

/// Secure / persistent local storage for JWT tokens and user session data
class TokenStorage {
  static const _keyAccessToken = 'vilo_access_token';
  static const _keyRefreshToken = 'vilo_refresh_token';
  static const _keyUserId = 'vilo_user_id';
  static const _keyUsername = 'vilo_username';
  static const _keyDisplayName = 'vilo_display_name';

  static TokenStorage? _instance;
  static TokenStorage get instance => _instance ??= TokenStorage._();

  TokenStorage._();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  Future<void> saveUserData({
    required int id,
    required String username,
    required String displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, id);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyDisplayName, displayName);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyDisplayName);
  }
}
