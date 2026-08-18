import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/core/theme/app_theme.dart';
import 'package:viloapp/features/bottom_nav/presentation/widgets/vilo_floating_bottom_bar.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/inbox_screen.dart';
import 'package:viloapp/features/profile/presentation/pages/people_screen.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('ViloFloatingBottomBar renders navigation icons and action plus button', (WidgetTester tester) async {
    int selectedIndex = 1;
    bool isAddActive = false;

    await tester.pumpWidget(
      _buildTestApp(
        child: ViloFloatingBottomBar(
          currentIndex: selectedIndex,
          isAddActive: isAddActive,
          isCompact: false,
          onTabSelected: (i) => selectedIndex = i,
          onAddPressed: () => isAddActive = !isAddActive,
        ),
      ),
    );

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget); // Active tab
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('PeopleScreen renders top search bar and creator cards', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const PeopleScreen()));

    // Verify search icon and title
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);

    // Tap search icon to open SearchScreen
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Trending Results'), findsOneWidget);
  });

  testWidgets('InboxScreen renders and navigates to ChatDetailScreen', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const InboxScreen()));

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
    await tester.pumpWidget(_buildTestApp(child: const InboxScreen()));

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
