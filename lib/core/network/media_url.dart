import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Resolves media paths returned by the backend without importing ApiClient.
/// Keeping this helper independent avoids a dependency cycle between the
/// authenticated user model, token storage, and the API client.
String resolveBackendMediaUrl(String? value) {
  if (value == null || value.trim().isEmpty) return '';

  final clean = value.trim();
  if (clean.startsWith('assets/')) {
    return clean;
  }

  const configuredHost = String.fromEnvironment('VILO_MEDIA_HOST');
  final host = configuredHost.trim().isNotEmpty
      ? configuredHost.trim().replaceFirst(RegExp(r'/$'), '')
      : (kIsWeb || !Platform.isAndroid
            ? 'http://localhost:3000'
            : 'http://10.0.2.2:3000');

  // Older records may contain an absolute localhost URL. On Android,
  // localhost points to the device rather than the development machine.
  final parsed = Uri.tryParse(clean);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
    final localHost = parsed.host == 'localhost' ||
        parsed.host == '127.0.0.1' ||
        parsed.host == '0.0.0.0';
    if (!localHost) return clean;

    final replacement = Uri.parse(host);
    return parsed
        .replace(
          scheme: replacement.scheme,
          host: replacement.host,
          port: replacement.hasPort ? replacement.port : parsed.port,
        )
        .toString();
  }

  return clean.startsWith('/') ? '$host$clean' : '$host/$clean';
}
