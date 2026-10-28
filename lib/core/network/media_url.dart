import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Resolves media paths returned by the backend without importing ApiClient.
/// Keeping this helper independent avoids a dependency cycle between the
/// authenticated user model, token storage, and the API client.
String resolveBackendMediaUrl(String? value) {
  if (value == null || value.trim().isEmpty) return '';

  final clean = value.trim();
  if (clean.startsWith('assets/') ||
      clean.startsWith('http://') ||
      clean.startsWith('https://')) {
    return clean;
  }

  final host = kIsWeb || !Platform.isAndroid
      ? 'http://localhost:3000'
      : 'http://10.0.2.2:3000';
  return clean.startsWith('/') ? '$host$clean' : '$host/$clean';
}
