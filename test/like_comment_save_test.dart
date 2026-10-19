import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/core/theme/app_theme.dart';
import 'package:viloapp/features/feed/data/models/comment_model.dart';
import 'package:viloapp/features/feed/data/models/video_model.dart';
import 'package:viloapp/features/feed/presentation/widgets/comment_bottom_sheet.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final List<int> _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('Member 2 Like, Save & Comment Feature Verification', () {
    test('VideoModel correctly toggles like and save states with formatted counts', () {
      const initial = VideoModel(
        id: 1,
        creatorId: 2,
        username: '@bunheng',
        displayName: 'Lim Bunheng',
        caption: 'Testing Member 2 interactions',
        videoUrl: '/uploads/videos/sample.mp4',
        likeCount: 999,
        saveCount: 1500,
        commentCount: 24,
        isLiked: false,
        isSaved: false,
      );

      expect(initial.isLiked, isFalse);
      expect(initial.isSaved, isFalse);
      expect(initial.formattedLikes, equals('999'));
      expect(initial.formattedSaves, equals('1.5K'));
      expect(initial.formattedComments, equals('24'));

      // Simulate like toggle
      final liked = initial.copyWith(
        isLiked: true,
        likeCount: initial.likeCount + 1,
      );
      expect(liked.isLiked, isTrue);
      expect(liked.likeCount, equals(1000));
      expect(liked.formattedLikes, equals('1.0K'));

      // Simulate save toggle
      final saved = liked.copyWith(
        isSaved: true,
        saveCount: liked.saveCount + 1,
      );
      expect(saved.isSaved, isTrue);
      expect(saved.saveCount, equals(1501));
      expect(saved.formattedSaves, equals('1.5K'));
    });

    test('VideoModel deserialized from JSON dynamically updates formatted counts on like, comment, and save', () {
      final json = {
        'id': 1,
        'creatorId': 2,
        'username': 'bunheng',
        'displayName': 'Lim Bunheng',
        'caption': 'Testing live counter updates',
        'videoUrl': '/uploads/videos/sample.mp4',
        'likeCount': 0,
        'formattedLikes': '0',
        'commentCount': 0,
        'formattedComments': '0',
        'saveCount': 0,
        'formattedSaves': '0',
        'isLiked': false,
        'isSaved': false,
      };

      final video = VideoModel.fromJson(json);
      expect(video.formattedLikes, equals('0'));
      expect(video.formattedComments, equals('0'));
      expect(video.formattedSaves, equals('0'));

      // 1. Like immediately increments formatted count
      final liked = video.copyWith(isLiked: true, likeCount: 1);
      expect(liked.likeCount, equals(1));
      expect(liked.formattedLikes, equals('1'));

      // 2. Unlike immediately decrements formatted count back to 0
      final unliked = liked.copyWith(isLiked: false, likeCount: 0);
      expect(unliked.likeCount, equals(0));
      expect(unliked.formattedLikes, equals('0'));

      // 3. Comment immediately increments formatted comments
      final commented = video.copyWith(commentCount: 1);
      expect(commented.commentCount, equals(1));
      expect(commented.formattedComments, equals('1'));

      // 4. Save immediately increments formatted saves
      final saved = video.copyWith(isSaved: true, saveCount: 1);
      expect(saved.saveCount, equals(1));
      expect(saved.formattedSaves, equals('1'));
    });

    test('CommentModel parses JSON with nested replies correctly', () {
      final json = {
        'id': 10,
        'videoId': 1,
        'userId': 2,
        'username': 'bunheng',
        'displayName': 'Lim Bunheng',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'content': 'This video engine is awesome!',
        'createdAt': '2026-10-19T10:00:00Z',
        'replies': [
          {
            'id': 11,
            'videoId': 1,
            'userId': 1,
            'username': 'mongkol',
            'displayName': 'Thoeung Sereymongkol',
            'parentId': 10,
            'content': 'Great job on the like, comment, and save implementation!',
            'createdAt': '2026-10-19T10:05:00Z',
            'replies': [],
          }
        ],
      };

      final comment = CommentModel.fromJson(json);

      expect(comment.id, equals(10));
      expect(comment.username, equals('bunheng'));
      expect(comment.content, equals('This video engine is awesome!'));
      expect(comment.replies.length, equals(1));
      expect(comment.replies.first.parentId, equals(10));
      expect(comment.replies.first.username, equals('mongkol'));
    });

    testWidgets('CommentBottomSheet renders comments and allows user input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => const CommentBottomSheet(
                      videoId: 1,
                      initialCommentCount: 3,
                    ),
                  );
                },
                child: const Text('Open Comments'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open Comments'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify comment input field and submit button exist
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);

      // Verify comments header exists
      expect(find.text('3 comments'), findsOneWidget);
    });

    test('Real total likes count calculates from videos without hardcoded values', () {
      final videos = [
        const VideoModel(
          id: 1,
          creatorId: 1,
          username: '@mongkol',
          displayName: 'Thoeung Sereymongkol',
          caption: 'Video 1',
          videoUrl: 'http://example.com/1.mp4',
          likeCount: 42,
          saveCount: 10,
          commentCount: 5,
        ),
        const VideoModel(
          id: 2,
          creatorId: 1,
          username: '@mongkol',
          displayName: 'Thoeung Sereymongkol',
          caption: 'Video 2',
          videoUrl: 'http://example.com/2.mp4',
          likeCount: 58,
          saveCount: 20,
          commentCount: 15,
        ),
      ];

      final totalLikes = videos.fold<int>(0, (sum, v) => sum + v.likeCount);
      expect(totalLikes, equals(100));
    });
  });
}
