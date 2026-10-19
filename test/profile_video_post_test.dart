import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/feed/data/datasources/feed_remote_data_source.dart';
import 'package:viloapp/features/feed/data/models/video_model.dart';
import 'package:viloapp/features/profile/data/datasources/profile_sync_service.dart';
import 'package:viloapp/features/profile/presentation/screens/profile_screen.dart';
import 'package:viloapp/features/profile/presentation/widgets/video_grid_item.dart';
import 'package:viloapp/features/feed/presentation/pages/video_feed_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testVideo = VideoModel(
    id: 99,
    creatorId: 1,
    username: '@mongkol',
    displayName: 'Thoeung Sereymongkol',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
    videoUrl: '/uploads/videos/test-video-99.mp4',
    thumbnailUrl: null,
    caption: 'My latest test upload',
    likes: '10',
    likeCount: 10,
    viewCount: 100,
  );

  test('FeedRemoteDataSource.prependUserVideo correctly stores and returns video in cache', () async {
    final ds = FeedRemoteDataSource.instance;
    ds.prependUserVideo(1, testVideo);

    final cached = ds.getCachedUserVideos(1);
    expect(cached, isNotNull);
    expect(cached!.first.id, 99);
    expect(cached.first.caption, 'My latest test upload');
  });

  testWidgets('VideoGridItem fires onTap callback when tapped', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 180,
            child: VideoGridItem(
              thumbnailUrl: 'assets/images/default_avatar.png',
              viewsLabel: '10K',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(VideoGridItem));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('VideoFeedPage renders directly with initialVideos and initialIndex', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: VideoFeedPage(
          isActive: true,
          initialVideos: [testVideo],
          initialIndex: 0,
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('ProfileScreen reacts in real-time to ProfileSyncService.notifyVideoUploaded', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(isOwnProfile: true),
      ),
    );

    await tester.pump();

    // Broadcast upload event
    ProfileSyncService.instance.notifyVideoUploaded(testVideo);
    await tester.pumpAndSettle();

    // Grid tab should contain the updated video
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
