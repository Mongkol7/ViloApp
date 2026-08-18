import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/app/app.dart';

void main() {
  testWidgets('ViloFloatingBottomBar renders navigation icons and action plus button', (WidgetTester tester) async {
    await tester.pumpWidget(const ViloApp());
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget); // Active tab
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Tapping search icon opens SearchScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const ViloApp());
    
    // Tap search icon on top bar
    final searchIconFinder = find.byIcon(Icons.search_rounded);
    expect(searchIconFinder, findsOneWidget);
    await tester.tap(searchIconFinder);
    await tester.pumpAndSettle();

    // Verify SearchScreen is displayed with top search bar and Trending Results
    expect(find.text('Trending Results'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Tapping Chat tab navigates to InboxScreen and opens ChatDetailScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const ViloApp());

    // Tap Chat tab (index 2) on floating navigation bar
    final chatTabFinder = find.byIcon(Icons.chat_bubble_outline_rounded);
    expect(chatTabFinder, findsOneWidget);
    await tester.tap(chatTabFinder);
    await tester.pumpAndSettle();

    // Verify InboxScreen components
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Share a thought...'), findsOneWidget);
    expect(find.text('New followers'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('System notifications'), findsOneWidget);
    expect(find.text('MESSAGES'), findsOneWidget);

    // Tap FashionHub message thread
    final fashionHubFinder = find.text('FashionHub');
    expect(fashionHubFinder, findsOneWidget);
    await tester.tap(fashionHubFinder);
    await tester.pumpAndSettle();

    // Verify ChatDetailScreen is displayed
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('120k followers'), findsOneWidget);
    expect(find.text('Hi! I saw the new collection, do you have the floral dress in size M?'), findsOneWidget);
    expect(find.text('Start a message...'), findsOneWidget);
  });

  testWidgets('Full Story lifecycle: Share thought with music wave, inspect viewers, delete story', (WidgetTester tester) async {
    await tester.pumpWidget(const ViloApp());

    // Switch to Inbox
    await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
    await tester.pumpAndSettle();

    // Tap thought bubble to open ShareThoughtScreen
    await tester.tap(find.text('Share a thought...'));
    await tester.pumpAndSettle();

    // Tap music note icon
    await tester.tap(find.byIcon(Icons.music_note_outlined));
    await tester.pumpAndSettle();

    // Select 'petal' track
    await tester.tap(find.text('petal').first);
    await tester.pumpAndSettle();

    // Confirm trim in MusicTrimmerBottomSheet
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify music badge is displayed
    expect(find.text('petal • Ariana Grande'), findsOneWidget);

    // Tap "Your Story" button to share story and return to Inbox
    await tester.tap(find.text('Your Story'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Inbox now reflects active story
    expect(find.text('Your story'), findsOneWidget);
    expect(find.text("Today's vibe..."), findsOneWidget);

    // Tap active story to open StoryViewerScreen
    await tester.tap(find.text('Your story'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify StoryViewerScreen is displayed
    expect(find.text('418 views'), findsOneWidget);

    // Tap bottom right three dots icon to open Story Options Menu
    final optionsIconFinder = find.byIcon(Icons.more_vert_rounded);
    expect(optionsIconFinder, findsOneWidget);
    await tester.tap(optionsIconFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify "Delete story" option is available
    expect(find.text('Delete story'), findsOneWidget);

    // Tap "Delete story"
    await tester.tap(find.text('Delete story'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify story was removed and reverted back to "Share a thought..."
    expect(find.text('Share a thought...'), findsOneWidget);
  });
}
