import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/core/theme/app_theme.dart';
import 'package:viloapp/features/bottom_nav/presentation/widgets/vilo_floating_bottom_bar.dart';
import 'package:viloapp/features/inbox_activity/data/datasources/chat_manager.dart';
import 'package:viloapp/features/inbox_activity/data/datasources/thought_story_manager.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/inbox_screen.dart';
import 'package:viloapp/features/profile/presentation/pages/people_screen.dart';
import 'package:viloapp/features/profile/presentation/screens/profile_screen.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() {
    ThoughtStoryManager.instance.deleteStory();
    ChatManager.instance.reset();
    ChatManager.immediateRepliesForTesting = true;
  });

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

  testWidgets('ProfileScreen Share Mind: Share thought from Profile and verify shared state synchronization', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const ProfileScreen()));

    // Verify initial "Share a thought..." balloon on ProfileScreen
    expect(find.text('Share a thought...'), findsOneWidget);

    // Tap thought balloon on ProfileScreen to open ShareThoughtScreen
    await tester.tap(find.text('Share a thought...'));
    await tester.pumpAndSettle();

    // Tap "Your Story" button to share story and return
    await tester.tap(find.text('Your Story'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify ProfileScreen now displays shared thought message
    expect(find.text("Today's vibe..."), findsOneWidget);

    // Verify ThoughtStoryManager state is populated
    expect(ThoughtStoryManager.instance.currentStory, isNotNull);
    expect(ThoughtStoryManager.instance.currentStory!.message, "Today's vibe...");

    // Tap thought on ProfileScreen to view story
    await tester.tap(find.text("Today's vibe..."));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify StoryViewerScreen is displayed
    expect(find.text('418 views'), findsOneWidget);

    // Tap delete from StoryViewerScreen
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Delete story'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify story was removed from ProfileScreen and ThoughtStoryManager
    expect(find.text('Share a thought...'), findsOneWidget);
    expect(ThoughtStoryManager.instance.currentStory, isNull);
  });

  testWidgets('Interactive Chat: Send message in ChatDetailScreen and verify thread persistence', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const InboxScreen()));

    // Tap FashionHub message thread
    await tester.tap(find.text('FashionHub'));
    await tester.pumpAndSettle();

    // Enter message
    final inputFinder = find.byType(TextField);
    expect(inputFinder, findsOneWidget);
    await tester.enterText(inputFinder, 'Is shipping to California available?');
    await tester.pump();

    // Tap send button
    final sendButtonFinder = find.byTooltip('Send');
    expect(sendButtonFinder, findsOneWidget);
    await tester.tap(sendButtonFinder);
    await tester.pumpAndSettle();

    // Verify sent bubble appears
    expect(find.text('Is shipping to California available?'), findsOneWidget);

    // Verify message was recorded in ChatManager
    expect(
      ChatManager.instance.getMessages('t0').any((m) => m.text == 'Is shipping to California available?'),
      isTrue,
    );

    // Pop back to Inbox
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // Verify back on Inbox and thread exists
    expect(find.text('FashionHub'), findsOneWidget);
    expect(find.text('MESSAGES'), findsOneWidget);
  });

  testWidgets('View Another Post/Story: Tap other user story from stories tray and verify viewer and reactions', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const InboxScreen()));

    // Tap another user's story in the tray (.uzi07)
    final otherStoryFinder = find.text('.uzi07');
    expect(otherStoryFinder, findsOneWidget);
    await tester.tap(otherStoryFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify StoryViewerScreen opens with author name and thought message
    expect(find.text('.uzi07'), findsAtLeastNWidgets(1));
    expect(find.text('Late night studio sessions 🎧🎹'), findsOneWidget);
    expect(find.text('Starboy • The Weeknd'), findsOneWidget);
    expect(find.text('Reply to .uzi07...'), findsOneWidget);

    // Tap heart reaction in StoryViewerScreen
    await tester.tap(find.byIcon(Icons.favorite_rounded).last);
    await tester.pump();

    // Close story viewer
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Verify back on Inbox
    expect(find.text('Inbox'), findsOneWidget);
  });

  testWidgets('Sequential Story Navigation: Tap right screen to advance story A -> B -> C and tap left to go back', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const InboxScreen()));

    // Tap first story in tray: "On this day" (Story A)
    await tester.tap(find.text('On this day'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify we are on Story A
    expect(find.text('1 year ago today in Tokyo! 🗼🌸'), findsOneWidget);
    expect(find.text('Memories • Maroon 5'), findsOneWidget);

    // Tap on right screen area to advance to Story B (.uzi07)
    final rightTapZone = find.byKey(const Key('story_right_tap_zone'));
    expect(rightTapZone, findsOneWidget);
    await tester.tap(rightTapZone);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify we advanced to Story B
    expect(find.text('Late night studio sessions 🎧🎹'), findsOneWidget);
    expect(find.text('Starboy • The Weeknd'), findsOneWidget);

    // Tap on right screen area again to advance to Story C (Tin)
    await tester.tap(rightTapZone);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify we advanced to Story C
    expect(find.text('Weekend coffee run ☕🥐'), findsOneWidget);
    expect(find.text('Espresso • Sabrina Carpenter'), findsOneWidget);

    // Tap on left screen area to navigate back to Story B (.uzi07)
    final leftTapZone = find.byKey(const Key('story_left_tap_zone'));
    expect(leftTapZone, findsOneWidget);
    await tester.tap(leftTapZone);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify we returned to Story B
    expect(find.text('Late night studio sessions 🎧🎹'), findsOneWidget);
    expect(find.text('Starboy • The Weeknd'), findsOneWidget);

    // Close story viewer
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Verify back on Inbox
    expect(find.text('Inbox'), findsOneWidget);
  });

  testWidgets('Notifications Hub: Tap New followers, Activity, and System notifications to open dedicated views and clear badges', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const InboxScreen()));

    // 1. Test New followers navigation & interaction
    expect(find.text('New followers'), findsOneWidget);
    await tester.tap(find.text('New followers'));
    await tester.pumpAndSettle();

    // Verify NewFollowersScreen is open
    expect(find.text('13 new followers this week'), findsOneWidget);
    expect(find.text('R.DRR'), findsOneWidget);
    expect(find.text('@rdrr_official'), findsOneWidget);

    // Tap "Follow back" button on first follower
    final followBackFinder = find.text('Follow back').first;
    await tester.tap(followBackFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify button state toggled to "Following"
    expect(find.text('Following'), findsAtLeastNWidgets(1));

    // Pop back to Inbox
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // 2. Test Activity navigation & filter chips
    expect(find.text('Activity'), findsOneWidget);
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    // Verify ActivityScreen is open
    expect(find.text('Activity'), findsOneWidget);
    expect(find.textContaining('Junta'), findsOneWidget);
    expect(find.textContaining('liked your photos.'), findsOneWidget);
    expect(find.text('Likes ❤️'), findsOneWidget);
    expect(find.text('Comments 💬'), findsOneWidget);

    // Filter by Comments
    await tester.tap(find.text('Comments 💬'));
    await tester.pump();

    // Verify comment activity item is shown
    expect(find.textContaining('Sarah Jenkins'), findsOneWidget);

    // Pop back to Inbox
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // 3. Test System notifications navigation
    expect(find.text('System notifications'), findsOneWidget);
    await tester.tap(find.text('System notifications'));
    await tester.pumpAndSettle();

    // Verify SystemNotificationsScreen is open
    expect(find.text('Weekly Screen Time Report'), findsOneWidget);
    expect(find.text('Security Alert: New Login'), findsOneWidget);

    // Tap weekly screen time to inspect chart modal
    await tester.tap(find.text('Weekly Screen Time Report'));
    await tester.pumpAndSettle();

    // Verify chart modal
    expect(find.text('Weekly Screen Time'), findsAtLeastNWidgets(1));
    expect(find.text('Daily average: 2h 15m (Within healthy goal)'), findsOneWidget);

    // Close modal
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    // Pop back to Inbox
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // Verify back on Inbox
    expect(find.text('Inbox'), findsOneWidget);
  });
}
