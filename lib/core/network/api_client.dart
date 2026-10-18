import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../features/auth/data/datasources/token_storage.dart';

class ApiResponseException implements Exception {
  final String message;
  final int statusCode;

  ApiResponseException(this.message, [this.statusCode = 400]);

  @override
  String toString() => message;
}

class ApiClient {
  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  ApiClient._();

  /// Automatically select localhost for Windows desktop / iOS / Web, and 10.0.2.2 for Android emulator
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://localhost:3000/api/v1';
  }

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await TokenStorage.instance.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await http.get(url, headers: headers);
    return _handleResponse(response, () => get(endpoint, requireAuth: requireAuth));
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, () => post(endpoint, body: body, requireAuth: requireAuth));
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await http.put(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, () => put(endpoint, body: body, requireAuth: requireAuth));
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    final response = await http.delete(url, headers: headers);
    return _handleResponse(response, () => delete(endpoint, requireAuth: requireAuth));
  }

  Future<dynamic> _handleResponse(
    http.Response response,
    Future<dynamic> Function() retryCall,
  ) async {
    final statusCode = response.statusCode;
    final responseBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (statusCode >= 200 && statusCode < 300) {
      if (responseBody is Map && responseBody.containsKey('data')) {
        return responseBody['data'];
      }
      return responseBody;
    }

    if (statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return retryCall();
      }
      await TokenStorage.instance.clear();
      throw ApiResponseException('Session expired. Please log in again.', 401);
    }

    final errorMessage = (responseBody is Map && responseBody['message'] != null)
        ? responseBody['message'].toString()
        : 'Request failed with status $statusCode';

    throw ApiResponseException(errorMessage, statusCode);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await TokenStorage.instance.getRefreshToken();
      if (refreshToken == null) return false;

      final url = Uri.parse('$baseUrl/auth/refresh');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        await TokenStorage.instance.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
    } catch (_) {}
    return false;
  }
}
