import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:viloapp/core/theme/app_theme.dart';
import 'package:viloapp/features/bottom_nav/presentation/pages/main_navigation_shell.dart';
import 'package:viloapp/features/feed/data/models/video_model.dart';
import 'package:viloapp/features/feed/presentation/widgets/create_action_sheet.dart';
import 'package:viloapp/features/feed/presentation/widgets/upload_video_sheet.dart';

class _FakeImagePicker extends Fake implements ImagePicker {
  final XFile? xFile;
  _FakeImagePicker(this.xFile);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return xFile;
  }
}

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

  testWidgets('Tapping + button in MainNavigationShell opens Split Action Modal and navigating to UploadVideoSheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: MainNavigationShell(initialIndex: 1),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Locate and tap the floating navigation bar '+' button
    final plusFinder = find.byWidgetPredicate(
      (widget) => widget is Icon && widget.icon == Icons.add && widget.size != 14.0,
    );
    expect(plusFinder, findsOneWidget);
    await tester.tap(plusFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 2. Verify Split Action Modal appears with Camera and Upload cards
    final cameraBtnFinder = find.byKey(const Key('create_camera_option_button'));
    final uploadBtnFinder = find.byKey(const Key('create_upload_option_button'));
    expect(cameraBtnFinder, findsOneWidget);
    expect(uploadBtnFinder, findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Take a photo to post directly'), findsOneWidget);
    expect(find.text('Upload Video or Photo'), findsOneWidget);
    expect(find.text('Choose media from your device files'), findsOneWidget);

    // 3. Tap "Upload Video or Photo" to open UploadVideoSheet
    await tester.tap(uploadBtnFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 4. Verify UploadVideoSheet header renders visibly with non-zero size
    final titleFinder = find.text('Upload Video');
    expect(titleFinder, findsOneWidget);
    final titleRenderBox = tester.renderObject<RenderBox>(titleFinder);
    expect(titleRenderBox.size.width, greaterThan(0));
    expect(titleRenderBox.size.height, greaterThan(0));

    // 5. Verify Native Media Picker Button renders visibly with non-zero size
    final pickButtonFinder = find.byKey(const Key('upload_pick_video_button'));
    expect(pickButtonFinder, findsOneWidget);
    final pickButtonRenderBox = tester.renderObject<RenderBox>(pickButtonFinder);
    expect(pickButtonRenderBox.size.width, greaterThan(0));
    expect(pickButtonRenderBox.size.height, greaterThan(0));
    expect(find.text('Choose Video or Photo'), findsOneWidget);
    expect(find.text('Pick an .mp4, .mov, .jpg, or .png from your device'), findsOneWidget);

    // 6. Verify Thumbnail Picker Button renders visibly with non-zero size
    final thumbButtonFinder = find.byKey(const Key('upload_pick_thumbnail_button'));
    expect(thumbButtonFinder, findsOneWidget);
    final thumbButtonRenderBox = tester.renderObject<RenderBox>(thumbButtonFinder);
    expect(thumbButtonRenderBox.size.width, greaterThan(0));
    expect(thumbButtonRenderBox.size.height, greaterThan(0));
    expect(find.text('Choose Thumbnail Image'), findsOneWidget);

    // 7. Verify Caption TextField renders visibly with non-zero size
    final captionFieldFinder = find.byKey(const Key('upload_caption_field'));
    expect(captionFieldFinder, findsOneWidget);
    final captionRenderBox = tester.renderObject<RenderBox>(captionFieldFinder);
    expect(captionRenderBox.size.width, greaterThan(0));
    expect(captionRenderBox.size.height, greaterThan(0));

    // 8. Verify Tags TextField renders visibly with non-zero size
    final tagsFieldFinder = find.byKey(const Key('upload_tags_field'));
    expect(tagsFieldFinder, findsOneWidget);
    final tagsRenderBox = tester.renderObject<RenderBox>(tagsFieldFinder);
    expect(tagsRenderBox.size.width, greaterThan(0));
    expect(tagsRenderBox.size.height, greaterThan(0));

    // 9. Verify Quick Hashtag chips render
    expect(find.text('#vilo'), findsOneWidget);
    expect(find.text('#trending'), findsOneWidget);

    // 10. Verify Post Video button renders visibly with non-zero size
    final postButtonFinder = find.byKey(const Key('upload_post_video_button'));
    expect(postButtonFinder, findsOneWidget);
    final postButtonRenderBox = tester.renderObject<RenderBox>(postButtonFinder);
    expect(postButtonRenderBox.size.width, greaterThan(0));
    expect(postButtonRenderBox.size.height, greaterThan(0));
  });

  testWidgets('UploadVideoSheet displays selected video and thumbnail preview tiles and validates required inputs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Case A: Unselected state validation
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: UploadVideoSheet(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final postBtn = find.byKey(const Key('upload_post_video_button'));
    expect(postBtn, findsOneWidget);

    // Tap "Post Video" without file -> verify selection validation error
    await tester.tap(postBtn);
    await tester.pump();
    expect(find.text('Please select a video or photo file.'), findsOneWidget);

    // Case B: Selected video & thumbnail state with preview tiles
    final fakeVideo = PlatformFile(
      name: 'test_clip.mp4',
      size: 1024 * 1024 * 2,
      path: 'test_clip.mp4',
    );
    final fakeThumbnail = PlatformFile(
      name: 'cover.jpg',
      size: 1024 * 50,
      path: 'cover.jpg',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: UploadVideoSheet(
            key: const ValueKey('sheet_with_video'),
            initialFile: fakeVideo,
            initialThumbnail: fakeThumbnail,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify video preview tile renders with video name and action buttons
    expect(find.byKey(const Key('upload_selected_video_tile')), findsOneWidget);
    expect(find.text('test_clip.mp4'), findsOneWidget);
    expect(find.byKey(const Key('upload_change_video_button')), findsOneWidget);
    expect(find.byKey(const Key('upload_remove_video_button')), findsOneWidget);

    // Verify thumbnail preview tile renders with thumbnail name and action buttons
    expect(find.byKey(const Key('upload_selected_thumbnail_tile')), findsOneWidget);
    expect(find.text('cover.jpg'), findsOneWidget);
    expect(find.byKey(const Key('upload_change_thumbnail_button')), findsOneWidget);
    expect(find.byKey(const Key('upload_remove_thumbnail_button')), findsOneWidget);

    final captionField = find.byKey(const Key('upload_caption_field'));
    final tagsField = find.byKey(const Key('upload_tags_field'));

    // Tap "Post Video" with empty caption -> verify caption error
    await tester.tap(find.byKey(const Key('upload_post_video_button')));
    await tester.pump();
    expect(find.text('Please enter a caption for your video.'), findsOneWidget);

    // Enter caption & tags
    await tester.enterText(captionField, 'My amazing travel clip #cambodia');
    await tester.enterText(tagsField, '#travel, #vilo');
    await tester.pump();

    expect(find.text('My amazing travel clip #cambodia'), findsOneWidget);
    expect(find.text('#travel, #vilo'), findsOneWidget);

    // Test remove thumbnail clears thumbnail preview tile and restores thumbnail picker button
    await tester.tap(find.byKey(const Key('upload_remove_thumbnail_button')));
    await tester.pump();
    expect(find.byKey(const Key('upload_selected_thumbnail_tile')), findsNothing);
    expect(find.byKey(const Key('upload_pick_thumbnail_button')), findsOneWidget);

    // Test remove video button clears preview tile and restores picker button
    await tester.tap(find.byKey(const Key('upload_remove_video_button')));
    await tester.pump();

    expect(find.byKey(const Key('upload_selected_video_tile')), findsNothing);
    expect(find.byKey(const Key('upload_pick_video_button')), findsOneWidget);
  });

  testWidgets('UploadVideoSheet hides thumbnail section when photo is selected as main post', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakePhoto = PlatformFile(
      name: 'scenery.jpg',
      size: 1024 * 400,
      path: 'scenery.jpg',
      bytes: Uint8List.fromList(_transparentImage),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: UploadVideoSheet(
            key: const ValueKey('sheet_with_photo'),
            initialFile: fakePhoto,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify main tile displays photo name
    expect(find.byKey(const Key('upload_selected_video_tile')), findsOneWidget);
    expect(find.text('scenery.jpg'), findsOneWidget);

    // Verify thumbnail picker section is completely hidden
    expect(find.byKey(const Key('upload_pick_thumbnail_button')), findsNothing);
    expect(find.byKey(const Key('upload_selected_thumbnail_tile')), findsNothing);
    expect(find.text('THUMBNAIL (OPTIONAL)'), findsNothing);

    // Verify button indicates posting photo
    expect(find.text('Post Photo'), findsOneWidget);
  });

  test('VideoModel isImagePost returns true for photo paths and auto-assigns thumbnailUrl', () {
    final photoModel = VideoModel.fromJson({
      'id': 10,
      'creatorId': 1,
      'caption': 'Sunset photo',
      'videoUrl': '/uploads/photos/sunset.jpg',
    });

    expect(photoModel.isImagePost, isTrue);
    expect(photoModel.thumbnailUrl, contains('/uploads/photos/sunset.jpg'));

    final videoModel = VideoModel.fromJson({
      'id': 11,
      'creatorId': 1,
      'caption': 'Sunset video',
      'videoUrl': '/uploads/videos/sunset.mp4',
    });

    expect(videoModel.isImagePost, isFalse);
    expect(videoModel.thumbnailUrl, isNull);
  });

  testWidgets('CreateActionSheet Camera handoff captures photo and pre-populates UploadVideoSheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeImagePicker = _FakeImagePicker(
      XFile.fromData(
        Uint8List.fromList(_transparentImage),
        name: 'camera_capture.jpg',
        path: 'camera_capture.jpg',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => CreateActionSheet.show(context, imagePicker: fakeImagePicker),
                child: const Text('Open Create'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Open Create'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Camera option in split chooser
    expect(find.byKey(const Key('create_camera_option_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('create_camera_option_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify UploadVideoSheet automatically opens with the captured camera photo pre-selected
    expect(find.byKey(const Key('upload_selected_video_tile')), findsOneWidget);
    expect(find.text('camera_capture.jpg'), findsOneWidget);

    // Verify thumbnail picker is hidden for photo post and post button reflects Photo
    expect(find.byKey(const Key('upload_pick_thumbnail_button')), findsNothing);
    expect(find.text('Post Photo'), findsOneWidget);
  });

  test('VideoModel multi-image carousel parses comma-separated URLs and sets isMultiImagePost', () {
    final carouselModel = VideoModel.fromJson({
      'id': 20,
      'creatorId': 1,
      'caption': 'Cambodia journey carousel',
      'videoUrl': '/uploads/photos/angkor1.jpg,/uploads/photos/angkor2.jpg,/uploads/photos/angkor3.jpg',
      'mediaUrls': [
        '/uploads/photos/angkor1.jpg',
        '/uploads/photos/angkor2.jpg',
        '/uploads/photos/angkor3.jpg',
      ],
    });

    expect(carouselModel.isImagePost, isTrue);
    expect(carouselModel.isMultiImagePost, isTrue);
    expect(carouselModel.resolvedMediaUrls.length, equals(3));
    expect(carouselModel.resolvedMediaUrls[0], contains('angkor1.jpg'));
    expect(carouselModel.resolvedMediaUrls[1], contains('angkor2.jpg'));
    expect(carouselModel.resolvedMediaUrls[2], contains('angkor3.jpg'));
    expect(carouselModel.thumbnailUrl, contains('angkor1.jpg'));
  });

  testWidgets('UploadVideoSheet displays multi-image carousel preview strip and updates CTA button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final files = [
      PlatformFile(name: 'photo1.jpg', size: 1024 * 100, path: 'photo1.jpg', bytes: Uint8List.fromList(_transparentImage)),
      PlatformFile(name: 'photo2.jpg', size: 1024 * 120, path: 'photo2.jpg', bytes: Uint8List.fromList(_transparentImage)),
      PlatformFile(name: 'photo3.jpg', size: 1024 * 150, path: 'photo3.jpg', bytes: Uint8List.fromList(_transparentImage)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: UploadVideoSheet(
            key: const ValueKey('sheet_with_carousel'),
            initialFiles: files,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify Carousel header badge is displayed
    expect(find.text('Photo Carousel (3/10)'), findsOneWidget);

    // 2. Verify CTA button states Post Carousel with count
    expect(find.text('Post Carousel (3 Photos)'), findsOneWidget);

    // 3. Verify thumbnail items render (badges 1, 2, 3)
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // 4. Tap delete icon on one photo to test reactive update
    await tester.tap(find.byKey(const Key('upload_carousel_remove_0')));
    await tester.pump();

    // Now 2 photos remain
    expect(find.text('Photo Carousel (2/10)'), findsOneWidget);
    expect(find.text('Post Carousel (2 Photos)'), findsOneWidget);
  });
}
