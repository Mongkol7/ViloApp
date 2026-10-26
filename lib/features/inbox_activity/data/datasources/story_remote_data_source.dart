import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import '../../../auth/data/datasources/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/entities/music_track.dart';
import '../../domain/entities/shared_thought_story.dart';
import 'static_inbox_data.dart';
import 'thought_story_manager.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';

class StoryRemoteDataSource {
  StoryRemoteDataSource._();
  static final StoryRemoteDataSource instance = StoryRemoteDataSource._();

  String _resolveMediaUrl(String? rawUrl) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty ||
        value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('assets/')) {
      return value;
    }
    if (value.startsWith('/'))
      return '${ApiClient.baseUrl.replaceFirst('/api/v1', '')}$value';
    return '${ApiClient.baseUrl.replaceFirst('/api/v1', '')}/$value';
  }

  String _timeAgo(dynamic rawCreatedAt, {String fallback = 'Just now'}) {
    final value = rawCreatedAt?.toString();
    if (value == null || value.isEmpty) return fallback;
    final createdAt = DateTime.tryParse(value)?.toLocal();
    if (createdAt == null) return fallback;
    final elapsed = DateTime.now().difference(createdAt);
    if (elapsed.inSeconds < 60) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
    return '${(elapsed.inDays / 7).floor()}w ago';
  }

  Future<List<StoryItem>> getActiveStories() async {
    try {
      final response = await ApiClient.instance.get('/stories/active');
      if (response is List) {
        final List<StoryItem> items = [
          const StoryItem(
            id: 'create_story',
            title: 'Share a thought...',
            imageUrl: '',
            isCreate: true,
          ),
        ];

        SharedThoughtStory? myActiveStory;

        for (final item in response) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            final username = item['displayName'] ?? item['username'] ?? 'User';
            final uname = item['username'] ?? 'user';
            final avatarUrl =
                item['avatarUrl'] ??
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';
            final isMy =
                item['isMyStory'] == true ||
                ProfileSyncService.instance.isCurrentUser(
                  username: uname,
                  id: item['userId']?.toString(),
                );
            final message = item['message'] as String? ?? '';
            final mediaUrl = _resolveMediaUrl(item['mediaUrl'] as String?);
            final mediaType = item['mediaType'] as String? ?? 'TEXT';
            final privacy = item['privacy'] as String? ?? 'PUBLIC';
            final musicTitle = item['musicTitle'] as String?;
            final musicArtist = item['musicArtist'] as String?;
            final viewCount = item['viewCount'] as int? ?? 0;
            final timeAgo = _timeAgo(item['createdAt']);

            final story = SharedThoughtStory(
              id: id,
              message: message,
              mediaUrl: mediaUrl,
              mediaType: mediaType,
              privacy: privacy,
              musicTrack: musicTitle != null
                  ? MusicTrack(
                      id: item['musicTrackId']?.toString() ?? 'm_$id',
                      title: musicTitle,
                      artist: musicArtist ?? 'Unknown',
                      albumArtUrl: item['musicAlbumArt'] ?? avatarUrl,
                      duration: '0:30',
                    )
                  : null,
              backgroundColor: const Color(0xFF141416),
              timestamp: timeAgo,
              viewCount: viewCount,
              authorName: username,
              authorAvatarUrl: avatarUrl,
              authorUsername: uname,
              isOwner: isMy,
            );

            if (isMy) {
              myActiveStory ??= story;
              items.add(
                StoryItem(
                  id: id,
                  title: username,
                  imageUrl: avatarUrl,
                  isCreate: false,
                  message: message,
                  mediaUrl: mediaUrl,
                  mediaType: mediaType,
                  privacy: privacy,
                  musicTitle: musicTitle,
                  musicArtist: musicArtist,
                  timestamp: timeAgo,
                  viewCount: viewCount,
                  isMyStory: true,
                  authorUsername: uname,
                  authorId: int.tryParse(item['userId']?.toString() ?? ''),
                  createdAt: item['createdAt']?.toString(),
                ),
              );
            } else {
              items.add(
                StoryItem(
                  id: id,
                  title: username,
                  imageUrl: avatarUrl,
                  isCreate: false,
                  message: message,
                  mediaUrl: mediaUrl,
                  mediaType: mediaType,
                  privacy: privacy,
                  musicTitle: musicTitle,
                  musicArtist: musicArtist,
                  timestamp: timeAgo,
                  viewCount: viewCount,
                  isMyStory: false,
                  authorUsername: uname,
                  authorId: int.tryParse(item['userId']?.toString() ?? ''),
                  createdAt: item['createdAt']?.toString(),
                ),
              );
            }
          }
        }

        if (myActiveStory != null) {
          ThoughtStoryManager.instance.setStory(myActiveStory);
        }
        return items;
      }
    } catch (_) {}

    final isDemoUser = TokenStorage.instance.isDemoUserSync;
    if (isDemoUser) {
      return StaticInboxData.stories;
    }
    return const [
      StoryItem(
        id: 'create_story',
        title: 'Share a thought...',
        imageUrl: '',
        isCreate: true,
      ),
    ];
  }

  Future<SharedThoughtStory?> createStory({
    String? message,
    String? mediaUrl,
    String mediaType = 'TEXT',
    String privacy = 'PUBLIC',
    MusicTrack? musicTrack,
    String? backgroundGradient,
    int expiresInHours = 24,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/stories',
        body: {
          'message': message ?? '',
          if (mediaUrl != null && mediaUrl.isNotEmpty) 'mediaUrl': mediaUrl,
          'mediaType': mediaType,
          'privacy': privacy,
          if (musicTrack != null) ...{
            'musicTrackId': musicTrack.id,
            'musicTitle': musicTrack.title,
            'musicArtist': musicTrack.artist,
            'musicAlbumArt': musicTrack.albumArtUrl,
            'musicDuration': 30,
          },
          'backgroundGradient': backgroundGradient ?? 'sunset',
          'expiresInHours': expiresInHours,
        },
      );

      if (response is Map) {
        final story = SharedThoughtStory(
          id:
              response['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          message: response['message'] ?? (message ?? ''),
          mediaUrl: _resolveMediaUrl(response['mediaUrl'] ?? mediaUrl),
          mediaType: response['mediaType'] ?? mediaType,
          privacy: response['privacy'] ?? privacy,
          musicTrack: musicTrack,
          backgroundColor: const Color(0xFF141416),
          timestamp: _timeAgo(response['createdAt']),
          viewCount: response['viewCount'] ?? 0,
          isOwner: true,
          authorAvatarUrl:
              response['avatarUrl'] ??
              ProfileSyncService.instance.currentUserAvatar,
          authorName:
              response['displayName'] ??
              ProfileSyncService.instance.currentUserDisplayName,
          authorUsername:
              response['username'] ??
              ProfileSyncService.instance.currentUsername,
        );
        ThoughtStoryManager.instance.setStory(story);
        return story;
      }
    } catch (_) {}

    final fallbackStory = SharedThoughtStory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message ?? '',
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      privacy: privacy,
      musicTrack: musicTrack,
      backgroundColor: const Color(0xFF141416),
      timestamp: 'Just now',
      viewCount: 0,
      isOwner: true,
      authorAvatarUrl: ProfileSyncService.instance.currentUserAvatar,
      authorName: ProfileSyncService.instance.currentUserDisplayName,
      authorUsername: ProfileSyncService.instance.currentUsername,
    );
    ThoughtStoryManager.instance.setStory(fallbackStory);
    return fallbackStory;
  }

  Future<SharedThoughtStory?> uploadMediaStory({
    required String filePath,
    required String message,
    required String mediaType,
    required String privacy,
    MusicTrack? musicTrack,
    int expiresInHours = 24,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/stories/upload'),
    );
    final token = await TokenStorage.instance.getAccessToken();
    if (token != null && token.isNotEmpty)
      request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({
      'message': message,
      'mediaType': mediaType,
      'privacy': privacy,
      'expiresInHours': expiresInHours.toString(),
    });
    if (musicTrack != null) {
      request.fields.addAll({
        'musicTrackId': musicTrack.id,
        'musicTitle': musicTrack.title,
        'musicArtist': musicTrack.artist,
      });
    }
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    final body = jsonDecode(await response.stream.bytesToString());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiResponseException(
        body is Map
            ? body['message']?.toString() ?? 'Story upload failed'
            : 'Story upload failed',
        response.statusCode,
      );
    }
    final data = body is Map && body['data'] is Map
        ? body['data'] as Map
        : body as Map;
    final story = SharedThoughtStory(
      id:
          data['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      message: data['message']?.toString() ?? message,
      mediaUrl: _resolveMediaUrl(data['mediaUrl']?.toString()),
      mediaType: data['mediaType']?.toString() ?? mediaType,
      privacy: data['privacy']?.toString() ?? privacy,
      musicTrack: musicTrack,
      backgroundColor: const Color(0xFF141416),
      timestamp: _timeAgo(data['createdAt']),
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      isOwner: true,
      authorAvatarUrl:
          data['avatarUrl']?.toString() ??
          ProfileSyncService.instance.currentUserAvatar,
      authorName:
          data['displayName']?.toString() ??
          ProfileSyncService.instance.currentUserDisplayName,
      authorUsername:
          data['username']?.toString() ??
          ProfileSyncService.instance.currentUsername,
    );
    ThoughtStoryManager.instance.setStory(story);
    return story;
  }

  Future<void> recordView(String storyId) async {
    final id = int.tryParse(storyId);
    if (id == null) return;
    try {
      await ApiClient.instance.post('/stories/$id/view');
    } catch (_) {}
  }

  Future<List<StoryViewer>> getStoryViewers(String storyId) async {
    final id = int.tryParse(storyId);
    if (id != null) {
      try {
        final response = await ApiClient.instance.get('/stories/$id/viewers');
        if (response is List) {
          final myUid = TokenStorage.instance.currentUserIdSync?.toString();
          final myUsername = TokenStorage.instance.currentUsernameSync
              ?.toLowerCase();
          final List<StoryViewer> viewers = [];

          for (final item in response) {
            if (item is! Map) continue;
            final viewerId =
                item['userId']?.toString() ?? item['id']?.toString() ?? '';
            final username = item['username']?.toString() ?? 'viewer';
            final cleanUser = username.replaceAll('@', '').toLowerCase();

            // Exclude own account from viewing list
            if (myUid != null && viewerId == myUid) continue;
            if (myUsername != null &&
                (cleanUser == myUsername ||
                    cleanUser == 'me' ||
                    cleanUser == 'you'))
              continue;

            final fullName = item['displayName'] ?? username;
            final avatarUrl =
                (item['avatarUrl'] != null &&
                    item['avatarUrl'].toString().isNotEmpty)
                ? item['avatarUrl']
                : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';

            viewers.add(
              StoryViewer(
                id: viewerId,
                username: '@$username',
                fullName: fullName,
                avatarUrl: avatarUrl,
                hasStoryRing: true,
                actionType: 'following',
                timeAgo: 'Recently',
              ),
            );
          }
          return viewers;
        }
      } catch (_) {}
    }
    return [];
  }

  Future<void> deleteStory(String storyId) async {
    final id = int.tryParse(storyId);
    if (id == null) return;
    try {
      await ApiClient.instance.delete('/stories/$id');
    } catch (_) {}
  }
}
