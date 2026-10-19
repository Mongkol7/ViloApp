import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';

/// Cross-platform persistent storage for JWT tokens and user session data
/// Runs purely in Dart with zero native Android C++/JNI dependencies
class TokenStorage {
  static TokenStorage? _instance;
  static TokenStorage get instance => _instance ??= TokenStorage._();

  TokenStorage._();

  String? _accessToken;
  String? _refreshToken;
  int? _userId;
  String? _username;
  String? _displayName;
  String? _avatarUrl;
  String? _email;
  bool _initialized = false;

  File? _getFile() {
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
      }
    } catch (_) {}
  }

  void _persist() {
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
        };
        file.writeAsStringSync(jsonEncode(data));
      }
    } catch (_) {}
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
  }) async {
    _userId = id;
    _username = username;
    _displayName = displayName;
    if (avatarUrl != null) _avatarUrl = avatarUrl;
    if (email != null) _email = email;
    _persist();
  }

  Future<String?> getAccessToken() async {
    _load();
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    _load();
    return _refreshToken;
  }

  Future<String?> getUsername() async {
    _load();
    return _username;
  }

  Future<String?> getDisplayName() async {
    _load();
    return _displayName;
  }

  Future<String?> getAvatarUrl() async {
    _load();
    return _avatarUrl;
  }

  Future<int?> getUserId() async {
    _load();
    return _userId;
  }

  UserModel? getUserModel() {
    _load();
    if (_userId == null && (_username == null || _username!.isEmpty)) return null;
    return UserModel(
      id: _userId ?? 0,
      username: _username ?? '',
      displayName: _displayName ?? (_username ?? ''),
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
    try {
      final file = _getFile();
      if (file != null && file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }
}
