import 'dart:ui';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/entities/music_track.dart';
import '../../domain/entities/shared_thought_story.dart';
import 'static_inbox_data.dart';
import 'static_story_viewers_data.dart';

class StoryRemoteDataSource {
  StoryRemoteDataSource._();
  static final StoryRemoteDataSource instance = StoryRemoteDataSource._();

  Future<List<StoryItem>> getActiveStories() async {
    try {
      final response = await ApiClient.instance.get('/stories/active');
      if (response is List && response.isNotEmpty) {
        final List<StoryItem> items = [];

        // Always put create bubble first
        items.add(const StoryItem(
          id: 'create_story',
          title: 'Share a thought...',
          imageUrl: '',
          isCreate: true,
        ));

        for (final item in response) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            final username = item['displayName'] ?? item['username'] ?? 'User';
            final avatarUrl = item['avatarUrl'] ??
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';

            items.add(StoryItem(
              id: id,
              title: username,
              imageUrl: avatarUrl,
              isCreate: false,
            ));
          }
        }
        return items;
      }
    } catch (_) {}
    return StaticInboxData.stories;
  }

  Future<SharedThoughtStory?> createStory({
    required String message,
    MusicTrack? musicTrack,
    String? backgroundGradient,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/stories',
        body: {
          'message': message,
          if (musicTrack != null) ...{
            'musicTrackId': musicTrack.id,
            'musicTitle': musicTrack.title,
            'musicArtist': musicTrack.artist,
            'musicAlbumArt': musicTrack.albumArtUrl,
            'musicDuration': 30,
          },
          'backgroundGradient': backgroundGradient ?? 'sunset',
          'expiresInHours': 24,
        },
      );

      if (response is Map) {
        return SharedThoughtStory(
          id: response['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          message: response['message'] ?? message,
          musicTrack: musicTrack,
          backgroundColor: const Color(0xFF141416),
          timestamp: 'Just now',
          viewCount: response['viewCount'] ?? 0,
        );
      }
    } catch (_) {}

    return SharedThoughtStory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      musicTrack: musicTrack,
      backgroundColor: const Color(0xFF141416),
      timestamp: 'Just now',
      viewCount: 418,
    );
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
        if (response is List && response.isNotEmpty) {
          return response.map<StoryViewer>((item) {
            final viewerId = item['userId']?.toString() ?? item['id']?.toString() ?? '';
            final username = item['username'] ?? 'viewer';
            final fullName = item['displayName'] ?? username;
            final avatarUrl = item['avatarUrl'] ??
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500';

            return StoryViewer(
              id: viewerId,
              username: '@$username',
              fullName: fullName,
              avatarUrl: avatarUrl,
              hasStoryRing: true,
              actionType: 'following',
            );
          }).toList();
        }
      } catch (_) {}
    }
    return StaticStoryViewersData.viewers;
  }

  Future<void> deleteStory(String storyId) async {
    final id = int.tryParse(storyId);
    if (id == null) return;
    try {
      await ApiClient.instance.delete('/stories/$id');
    } catch (_) {}
  }
}
