import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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

  bool _isAutoLoggingIn = false;

  Future<void> autoLoginDefaultUser() async {
    if (_isAutoLoggingIn) return;
    _isAutoLoggingIn = true;
    try {
      final base = Platform.isAndroid ? 'http://10.0.2.2:3000/api/v1' : 'http://localhost:3000/api/v1';
      final res = await http.post(
        Uri.parse('$base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': 'mongkol',
          'password': 'password123',
        }),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          _accessToken = data['accessToken'] as String?;
          _refreshToken = data['refreshToken'] as String?;
          final user = data['user'] as Map<String, dynamic>?;
          if (user != null) {
            _userId = user['id'] as int?;
            _username = user['username'] as String?;
            _displayName = user['displayName'] as String?;
          }
          _persist();
        }
      }
    } catch (_) {
      _userId ??= 1;
      _username ??= 'mongkol';
      _displayName ??= 'Thoeung Sereymongkol';
    } finally {
      _isAutoLoggingIn = false;
    }
  }

  Future<String?> getAccessToken() async {
    _load();
    if (_accessToken == null || _accessToken!.isEmpty) {
      await autoLoginDefaultUser();
    }
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    _load();
    return _refreshToken;
  }

  String? get currentAccessTokenSync {
    _load();
    return _accessToken;
  }

  int? get currentUserIdSync {
    _load();
    return _userId;
  }

  String? get currentUsernameSync {
    _load();
    return _username;
  }

  String? get currentDisplayNameSync {
    _load();
    return _displayName;
  }

  bool get isDemoUserSync {
    _load();
    if (_userId == null) return true;
    return _userId == 1 && (_username == 'mongkol' || _username == null);
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
