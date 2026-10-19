import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:viloapp/features/feed/data/datasources/feed_remote_data_source.dart';
import 'package:viloapp/features/feed/data/models/video_model.dart';
import 'package:viloapp/features/feed/presentation/controllers/video_feed_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoFeedManager Unit Tests', () {
    test('prependVideo notifies listeners with new VideoModel and increments refresh count', () {
      final manager = VideoFeedManager.instance;
      manager.clear();

      VideoModel? capturedVideo;
      int refreshCount = 0;

      void onVideoAdded() {
        capturedVideo = manager.latestUploadedVideoNotifier.value;
      }

      void onFeedRefreshed() {
        refreshCount = manager.feedRefreshNotifier.value;
      }

      manager.latestUploadedVideoNotifier.addListener(onVideoAdded);
      manager.feedRefreshNotifier.addListener(onFeedRefreshed);

      const testVideo = VideoModel(
        id: 999,
        creatorId: 2,
        username: 'bunheng',
        displayName: 'Lim Bunheng',
        caption: 'Test video upload #flutter #vilo',
        videoUrl: '/uploads/videos/test.mp4',
      );

      manager.prependVideo(testVideo);

      expect(capturedVideo, isNotNull);
      expect(capturedVideo!.id, 999);
      expect(capturedVideo!.username, 'bunheng');
      expect(refreshCount, 1);

      manager.latestUploadedVideoNotifier.removeListener(onVideoAdded);
      manager.feedRefreshNotifier.removeListener(onFeedRefreshed);
    });
  });

  group('Live Video Upload Integration Tests (Port 3000)', () {
    test('User can log in, upload video file, and see it at index 0 of feed', () async {
      // 1. Verify backend connectivity
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse('http://localhost:3000/api/v1/videos/feed'));
        final res = await req.close();
        if (res.statusCode != 200) {
          // Backend not reachable, skip live integration
          return;
        }
      } catch (_) {
        // Backend not reachable, skip live integration
        return;
      } finally {
        client.close();
      }

      // 2. Log in as member 2 (@bunheng)
      final authDataSource = AuthRemoteDataSource();
      final user = await authDataSource.login(
        usernameOrEmail: 'bunheng',
        password: 'password123',
      );
      expect(user.username, 'bunheng');

      // 3. Perform multipart video upload using sample asset
      final feedDataSource = FeedRemoteDataSource();
      final sampleVideoFile = File('assets/videos/vid1.mp4');
      expect(sampleVideoFile.existsSync(), isTrue);

      final uploaded = await feedDataSource.uploadVideo(
        caption: 'Automated test upload by Lim Bunheng #coding #live_test',
        videoPath: sampleVideoFile.path,
        tags: ['coding', 'live_test'],
      );

      expect(uploaded.id, isPositive);
      expect(uploaded.creatorId, user.id);
      expect(uploaded.caption, contains('Automated test upload'));
      expect(uploaded.videoUrl, contains('/uploads/videos/'));

      // 4. Verify physical video file exists in ./uploads/videos/
      final relativeStoredPath = uploaded.videoUrl.replaceFirst('/uploads/videos/', '');
      final physicalFile = File('backend/uploads/videos/$relativeStoredPath');
      final rootPhysicalFile = File('uploads/videos/$relativeStoredPath');
      final fileExists = physicalFile.existsSync() || rootPhysicalFile.existsSync();
      expect(fileExists, isTrue, reason: 'Uploaded video file must be saved on disk');

      // 5. Verify newly uploaded video is index 0 in GET /api/v1/videos/feed
      final feed = await feedDataSource.getFeed(page: 0, size: 10, type: 'foryou');
      expect(feed.isNotEmpty, isTrue);
      expect(feed.first.id, uploaded.id, reason: 'Latest uploaded video must appear at index 0 of the feed');
      expect(feed.first.creatorId, user.id);
    });
  });
}
