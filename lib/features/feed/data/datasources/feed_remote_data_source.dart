import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../models/comment_model.dart';
import '../models/video_model.dart';

class FeedRemoteDataSource {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  FeedRemoteDataSource({ApiClient? client, TokenStorage? tokenStorage})
      : _client = client ?? ApiClient.instance,
        _tokenStorage = tokenStorage ?? TokenStorage.instance;

  /// Fetch paginated feed (foryou or following)
  Future<List<VideoModel>> getFeed({
    int page = 0,
    int size = 10,
    String type = 'foryou',
  }) async {
    final response = await _client.get(
      '/videos/feed?page=$page&size=$size&type=$type',
      requireAuth: true,
    );

    if (response is Map && response['videos'] is List) {
      return (response['videos'] as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => VideoModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetch single video by ID
  Future<VideoModel> getVideoById(int id) async {
    final response = await _client.get(
      '/videos/$id',
      requireAuth: true,
    );
    return VideoModel.fromJson(response as Map<String, dynamic>);
  }

  /// Toggle like status
  Future<Map<String, dynamic>> toggleLike(
    int videoId, {
    required bool currentlyLiked,
  }) async {
    final endpoint = '/videos/$videoId/like';
    final dynamic response;
    if (currentlyLiked) {
      response = await _client.delete(endpoint, requireAuth: true);
    } else {
      response = await _client.post(endpoint, requireAuth: true);
    }
    return {
      'isLiked': response['isLiked'] ?? !currentlyLiked,
      'likeCount': (response['likeCount'] as num?)?.toInt() ?? 0,
    };
  }

  /// Toggle save/bookmark status
  Future<Map<String, dynamic>> toggleSave(
    int videoId, {
    required bool currentlySaved,
  }) async {
    final endpoint = '/videos/$videoId/save';
    final dynamic response;
    if (currentlySaved) {
      response = await _client.delete(endpoint, requireAuth: true);
    } else {
      response = await _client.post(endpoint, requireAuth: true);
    }
    return {
      'isSaved': response['isSaved'] ?? !currentlySaved,
      'saveCount': (response['saveCount'] as num?)?.toInt() ?? 0,
    };
  }

  /// Increment view count asynchronously
  Future<int> incrementView(int videoId) async {
    try {
      final response = await _client.post(
        '/videos/$videoId/view',
        requireAuth: false,
      );
      if (response is Map && response['viewCount'] != null) {
        return (response['viewCount'] as num).toInt();
      }
    } catch (_) {}
    return 0;
  }

  /// Fetch paginated comments for a video
  Future<List<CommentModel>> getComments(
    int videoId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      '/videos/$videoId/comments?page=$page&size=$size',
      requireAuth: false,
    );

    if (response is Map && response['comments'] is List) {
      return (response['comments'] as List)
          .whereType<Map<String, dynamic>>()
          .map((json) => CommentModel.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Post a new comment or reply
  Future<CommentModel> postComment(
    int videoId,
    String content, {
    int? parentId,
  }) async {
    final body = <String, dynamic>{
      'content': content.trim(),
    };
    if (parentId != null) {
      body['parentId'] = parentId;
    }

    final response = await _client.post(
      '/videos/$videoId/comments',
      body: body,
      requireAuth: true,
    );

    return CommentModel.fromJson(response as Map<String, dynamic>);
  }

  /// Multipart video upload
  Future<VideoModel> uploadVideo({
    required String caption,
    String? videoPath,
    List<int>? videoBytes,
    String videoFilename = 'upload.mp4',
    String? thumbnailPath,
    List<int>? thumbnailBytes,
    String thumbnailFilename = 'thumbnail.jpg',
    List<String>? tags,
  }) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/videos/upload');
    final request = http.MultipartRequest('POST', uri);

    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['caption'] = caption;

    // Handle tags (normalize, strip leading #, join by comma)
    final tagsList = <String>[];
    if (tags != null) {
      tagsList.addAll(
        tags
            .map((t) => t.replaceAll('#', '').trim())
            .where((t) => t.isNotEmpty),
      );
    }
    if (tagsList.isEmpty) {
      final matches = RegExp(r'#(\w+)').allMatches(caption);
      for (final m in matches) {
        final t = m.group(1);
        if (t != null && t.isNotEmpty && !tagsList.contains(t)) {
          tagsList.add(t);
        }
      }
    }
    if (tagsList.isNotEmpty) {
      request.fields['tags'] = tagsList.join(',');
    }

    // Video payload (either multipart file or direct videoPath reference)
    if (videoBytes != null && videoBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'videoFile',
          videoBytes,
          filename: videoFilename,
        ),
      );
      if (videoPath != null && videoPath.trim().isNotEmpty) {
        request.fields['videoPath'] = videoPath.trim();
      }
    } else if (videoPath != null && videoPath.trim().isNotEmpty) {
      final trimmedPath = videoPath.trim();
      request.fields['videoPath'] = trimmedPath;

      // Also attach file bytes if physical file exists on disk or in assets
      final fileOnDisk = File(trimmedPath);
      if (fileOnDisk.existsSync()) {
        try {
          request.files.add(await http.MultipartFile.fromPath('videoFile', trimmedPath));
        } catch (_) {}
      } else if (trimmedPath.startsWith('assets/')) {
        try {
          final byteData = await rootBundle.load(trimmedPath);
          final bytes = byteData.buffer.asUint8List();
          final name = trimmedPath.split('/').last;
          request.files.add(
            http.MultipartFile.fromBytes(
              'videoFile',
              bytes,
              filename: name.isNotEmpty ? name : videoFilename,
            ),
          );
        } catch (_) {}
      }
    } else {
      throw ApiResponseException('A video path or video file must be provided', 400);
    }

    // Thumbnail payload (optional)
    if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'thumbnailFile',
          thumbnailBytes,
          filename: thumbnailFilename,
        ),
      );
    } else if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      final thumbOnDisk = File(thumbnailPath);
      if (thumbOnDisk.existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('thumbnailFile', thumbnailPath));
      } else if (thumbnailPath.startsWith('assets/')) {
        final byteData = await rootBundle.load(thumbnailPath);
        final bytes = byteData.buffer.asUint8List();
        final name = thumbnailPath.split('/').last;
        request.files.add(
          http.MultipartFile.fromBytes(
            'thumbnailFile',
            bytes,
            filename: name.isNotEmpty ? name : thumbnailFilename,
          ),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('thumbnailFile', thumbnailPath));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final data = json['data'] ?? json;
      return VideoModel.fromJson(data as Map<String, dynamic>);
    } else {
      String errorMessage = 'Failed to upload video (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['message'] != null) {
          errorMessage = errJson['message'];
        }
      } catch (_) {}
      throw ApiResponseException(errorMessage, response.statusCode);
    }
  }
}
