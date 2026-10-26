import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Cross-platform persistent storage for JWT tokens and user session data.
/// - On native / unit tests: Uses synchronous JSON file storage with zero hanging.
/// - On Flutter Web: Uses browser persistent SharedPreferences (localStorage).
class TokenStorage {
  static TokenStorage? _instance;
  static TokenStorage get instance => _instance ??= TokenStorage._();

  TokenStorage._();

  static const String _keyAccessToken = 'vilo_auth_access_token';
  static const String _keyRefreshToken = 'vilo_auth_refresh_token';
  static const String _keyUserId = 'vilo_auth_user_id';
  static const String _keyUsername = 'vilo_auth_username';
  static const String _keyDisplayName = 'vilo_auth_display_name';
  static const String _keyAvatarUrl = 'vilo_auth_avatar_url';
  static const String _keyEmail = 'vilo_auth_email';
  static const String _keyBio = 'vilo_auth_bio';

  String? _accessToken;
  String? _refreshToken;
  int? _userId;
  String? _username;
  String? _displayName;
  String? _avatarUrl;
  String? _email;
  String? _bio;
  bool _initialized = false;

  File? _getFile() {
    if (kIsWeb) return null;
    try {
      if (Platform.isAndroid) {
        final dir = Directory('/data/user/0/com.example.viloapp/files');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        return File('${dir.path}/vilo_auth.json');
      }
      final dir = Directory.systemTemp;
      return File('${dir.path}/vilo_auth.json');
    } catch (_) {
      return null;
    }
  }

  void _load() {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) {
      try {
        final file = _getFile();
        if (file != null && file.existsSync()) {
          final content = file.readAsStringSync();
          final map = jsonDecode(content) as Map<String, dynamic>;
          _accessToken = map['accessToken'] as String?;
          _refreshToken = map['refreshToken'] as String?;
          _userId = map['userId'] as int?;
          _username = map['username'] as String?;
          _displayName = map['displayName'] as String?;
          _avatarUrl = map['avatarUrl'] as String?;
          _email = map['email'] as String?;
          _bio = map['bio'] as String?;
        }
      } catch (_) {}
    }
  }

  Future<void> _ensureWebLoaded() async {
    if (!kIsWeb) {
      _load();
      return;
    }
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_keyAccessToken);
      _refreshToken = prefs.getString(_keyRefreshToken);
      _userId = prefs.getInt(_keyUserId);
      _username = prefs.getString(_keyUsername);
      _displayName = prefs.getString(_keyDisplayName);
      _avatarUrl = prefs.getString(_keyAvatarUrl);
      _email = prefs.getString(_keyEmail);
      _bio = prefs.getString(_keyBio);
      _initialized = true;
    } catch (_) {}
  }

  void _persist() {
    if (!kIsWeb) {
      try {
        final file = _getFile();
        if (file != null) {
          final data = {
            'accessToken': _accessToken,
            'refreshToken': _refreshToken,
            'userId': _userId,
            'username': _username,
            'displayName': _displayName,
            'avatarUrl': _avatarUrl,
            'email': _email,
            'bio': _bio,
          };
          file.writeAsStringSync(jsonEncode(data));
        }
      } catch (_) {}
    } else {
      SharedPreferences.getInstance().then((prefs) {
        if (_accessToken != null) prefs.setString(_keyAccessToken, _accessToken!);
        if (_refreshToken != null) prefs.setString(_keyRefreshToken, _refreshToken!);
        if (_userId != null) prefs.setInt(_keyUserId, _userId!);
        if (_username != null) prefs.setString(_keyUsername, _username!);
        if (_displayName != null) prefs.setString(_keyDisplayName, _displayName!);
        if (_avatarUrl != null) prefs.setString(_keyAvatarUrl, _avatarUrl!);
        if (_email != null) prefs.setString(_keyEmail, _email!);
        if (_bio != null) prefs.setString(_keyBio, _bio!);
      }).catchError((_) {});
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _persist();
  }

  Future<void> saveUserData({
    required int id,
    required String username,
    required String displayName,
    String? avatarUrl,
    String? email,
    String? bio,
  }) async {
    _userId = id;
    _username = username;
    _displayName = displayName;
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    if (email != null) _email = email;
    if (bio != null) _bio = bio;
    _persist();
  }

  Future<void> updateProfileData({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    if (kIsWeb) await _ensureWebLoaded(); else _load();
    if (displayName != null) _displayName = displayName;
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    if (bio != null) _bio = bio;
    _persist();
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) await _ensureWebLoaded(); else _load();
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) await _ensureWebLoaded(); else _load();
    return _refreshToken;
  }

  Future<String?> getUsername() async {
    if (kIsWeb) await _ensureWebLoaded(); else _load();
    return _username;
  }

  Future<String?> getDisplayName() async {
    if (kIsWeb) await _ensureWebLoaded(); else _load();
    return _displayName;
  }

  Future<String?> getAvatarUrl() async {
    if (kIsWeb) await _ensureWebLoaded(); else _load();
    return _avatarUrl;
  }

  Future<String?> getBio() async {
    if (kIsWeb) await _ensureWebLoaded(); else _load();
    return _bio;
  }

  Future<int?> getUserId() async {
    if (kIsWeb) await _ensureWebLoaded(); else _load();
    return _userId;
  }

  UserModel? getUserModel() {
    _load();
    if (_userId == null && (_username == null || _username!.isEmpty)) return null;
    return UserModel(
      id: _userId ?? 0,
      username: _username ?? '',
      displayName: _displayName ?? (_username ?? ''),
      bio: _bio ?? '',
      avatarUrl: _avatarUrl,
      email: _email ?? '',
      isVerified: false,
      followersCount: 0,
      followingCount: 0,
    );
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    _username = null;
    _displayName = null;
    _avatarUrl = null;
    _email = null;
    _bio = null;

    if (!kIsWeb) {
      try {
        final file = _getFile();
        if (file != null && file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyAccessToken);
        await prefs.remove(_keyRefreshToken);
        await prefs.remove(_keyUserId);
        await prefs.remove(_keyUsername);
        await prefs.remove(_keyDisplayName);
        await prefs.remove(_keyAvatarUrl);
        await prefs.remove(_keyEmail);
        await prefs.remove(_keyBio);
      } catch (_) {}
    }
  }
}
