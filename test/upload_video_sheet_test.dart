import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/core/theme/app_theme.dart';
import 'package:viloapp/features/bottom_nav/presentation/pages/main_navigation_shell.dart';
import 'package:viloapp/features/feed/presentation/widgets/upload_video_sheet.dart';

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

  testWidgets('Tapping + button in MainNavigationShell opens simplified UploadVideoSheet with file picker box', (WidgetTester tester) async {
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

    // 2. Verify UploadVideoSheet header renders visibly with non-zero size
    final titleFinder = find.text('Upload Video');
    expect(titleFinder, findsOneWidget);
    final titleRenderBox = tester.renderObject<RenderBox>(titleFinder);
    expect(titleRenderBox.size.width, greaterThan(0));
    expect(titleRenderBox.size.height, greaterThan(0));

    // 3. Verify Choose Video File box renders visibly
    final chooseFileBoxFinder = find.text('Tap to Choose Video File');
    expect(chooseFileBoxFinder, findsOneWidget);
    final chooseFileBoxBox = tester.renderObject<RenderBox>(chooseFileBoxFinder);
    expect(chooseFileBoxBox.size.width, greaterThan(0));
    expect(chooseFileBoxBox.size.height, greaterThan(0));

    // 4. Verify Caption TextField renders visibly with non-zero size
    final captionFieldFinder = find.widgetWithText(TextField, 'Write a caption...');
    expect(captionFieldFinder, findsOneWidget);
    final captionRenderBox = tester.renderObject<RenderBox>(captionFieldFinder);
    expect(captionRenderBox.size.width, greaterThan(0));
    expect(captionRenderBox.size.height, greaterThan(0));

    // 5. Verify Tags TextField renders visibly with non-zero size
    final tagsFieldFinder = find.widgetWithText(TextField, '#vilo, #trending');
    expect(tagsFieldFinder, findsOneWidget);
    final tagsRenderBox = tester.renderObject<RenderBox>(tagsFieldFinder);
    expect(tagsRenderBox.size.width, greaterThan(0));
    expect(tagsRenderBox.size.height, greaterThan(0));

    // 6. Verify Quick Hashtag chips render
    expect(find.text('#vilo'), findsOneWidget);
    expect(find.text('#trending'), findsOneWidget);

    // 7. Verify Post Video button renders visibly with non-zero size
    final postButtonFinder = find.widgetWithText(ElevatedButton, 'Post Video');
    expect(postButtonFinder, findsOneWidget);
    final postButtonRenderBox = tester.renderObject<RenderBox>(postButtonFinder);
    expect(postButtonRenderBox.size.width, greaterThan(0));
    expect(postButtonRenderBox.size.height, greaterThan(0));
  });

  testWidgets('Direct UploadVideoSheet displays selected file details and handles validation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testPlatformFile = PlatformFile(
      name: 'spider_glass.mp4',
      size: 3900000,
      path: 'assets/videos/video1.mp4',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: UploadVideoSheet(initialFile: testPlatformFile),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify "Upload Video" title
    final titleFinder = find.text('Upload Video');
    expect(titleFinder, findsOneWidget);

    // 2. Verify selected file details are displayed
    expect(find.text('spider_glass.mp4'), findsOneWidget);
    expect(find.text('3.7 MB'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);

    // 3. Verify Caption field
    final captionField = find.widgetWithText(TextField, 'Write a caption...');
    expect(captionField, findsOneWidget);

    // 4. Verify Tags field
    final tagsField = find.widgetWithText(TextField, '#vilo, #trending');
    expect(tagsField, findsOneWidget);

    // 5. Verify Post Video button
    final postBtn = find.widgetWithText(ElevatedButton, 'Post Video');
    expect(postBtn, findsOneWidget);

    // 6. Tap "Post Video" without caption -> verify validation error message
    await tester.tap(postBtn);
    await tester.pump();
    expect(find.text('Please enter a caption for your video.'), findsOneWidget);

    // 7. Type caption in field
    await tester.enterText(captionField, 'My amazing spider glass clip! #spiderglass');
    await tester.pump();
    expect(find.text('My amazing spider glass clip! #spiderglass'), findsOneWidget);
  });
}
