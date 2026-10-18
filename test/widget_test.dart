import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/core/theme/app_theme.dart';
import 'package:viloapp/features/bottom_nav/presentation/widgets/vilo_floating_bottom_bar.dart';
import 'package:viloapp/features/creator/presentation/widgets/vilo_creation_speed_dial.dart';
import 'package:viloapp/features/inbox_activity/data/datasources/thought_story_manager.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/inbox_screen.dart';
import 'package:viloapp/features/profile/presentation/pages/people_screen.dart';
import 'package:viloapp/features/profile/presentation/pages/settings_and_privacy_screen.dart';
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

  testWidgets('SettingsAndPrivacyScreen: Log out button opens confirmation dialog and handles cancel/confirm', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_buildTestApp(child: const SettingsAndPrivacyScreen()));

    // Scroll to the bottom to find 'Log out' tile
    final logoutFinder = find.text('Log out');
    await tester.scrollUntilVisible(logoutFinder, 200, scrollable: find.byType(Scrollable));
    await tester.pumpAndSettle();
    expect(logoutFinder, findsOneWidget);

    // Tap 'Log out' tile
    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog is displayed
    expect(find.text('Log out of Vilo?'), findsOneWidget);
    expect(find.text('Are you sure you want to log out? You will need to log back in to access your profile and feed.'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap 'Cancel'
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify dialog was dismissed
    expect(find.text('Log out of Vilo?'), findsNothing);
    expect(logoutFinder, findsOneWidget);
  });

  testWidgets('+ Action Button reveals animated quick access Speed Dial and navigates to Camera studio', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool isAddActive = false;
    int currentIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Feed Area')),
                  ViloCreationSpeedDial(
                    isOpen: isAddActive,
                    onClose: () => setState(() => isAddActive = false),
                    bottomOffset: 80.0,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: ViloFloatingBottomBar(
                      currentIndex: currentIndex,
                      isAddActive: isAddActive,
                      isCompact: false,
                      onTabSelected: (i) => setState(() => currentIndex = i),
                      onAddPressed: () => setState(() => isAddActive = !isAddActive),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial state: Speed dial options are not visible
    expect(find.text('Camera'), findsNothing);
    expect(find.text('Photo'), findsNothing);
    expect(find.text('Upload'), findsNothing);
    expect(find.text('Story'), findsNothing);
    expect(find.text('Go LIVE'), findsNothing);

    // Tap the '+' action button on the bottom bar dock
    final plusFinder = find.byKey(const Key('vilo_floating_action_button'));
    expect(plusFinder, findsOneWidget);
    await tester.tap(plusFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify speed dial quick access buttons have smoothly animated into view
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
    expect(find.text('Go LIVE'), findsOneWidget);

    // Tap 'Camera' quick access option
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    // Verify ViloCameraScreen opened with interactive viewfinder controls
    expect(find.text('Add sound'), findsOneWidget);
    expect(find.text('Flip'), findsOneWidget);
    expect(find.text('Beauty'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('15s'), findsOneWidget);
    expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);

    // Tap Close icon in camera to dismiss viewfinder
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Verify return to shell
    expect(find.text('Feed Area'), findsOneWidget);
    expect(find.text('Camera'), findsNothing);

    // Tap '+' again to open speed dial
    await tester.tap(plusFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Go LIVE'), findsOneWidget);

    // Tap backdrop (outside the speed dial items) to dismiss
    await tester.tap(find.byKey(const Key('vilo_speed_dial_backdrop')));
    await tester.pumpAndSettle();
    expect(find.text('Go LIVE'), findsNothing);
  });

  testWidgets('+ Action Button Speed Dial opens Upload gallery sheet and selects media', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool isAddActive = false;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Home')),
                  ViloCreationSpeedDial(
                    isOpen: isAddActive,
                    onClose: () => setState(() => isAddActive = false),
                    bottomOffset: 80.0,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: ViloFloatingBottomBar(
                      currentIndex: 0,
                      isAddActive: isAddActive,
                      isCompact: false,
                      onTabSelected: (_) {},
                      onAddPressed: () => setState(() => isAddActive = !isAddActive),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap '+' action button
    await tester.tap(find.byKey(const Key('vilo_floating_action_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Tap 'Upload' option
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    // Verify ViloMediaPickerBottomSheet opened
    expect(find.text('All Media'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Next (0)'), findsOneWidget);

    // Tap close button in gallery sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('All Media'), findsNothing);
  });

  testWidgets('+ Action Button Speed Dial opens Go LIVE studio and toggles live broadcast', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bool isAddActive = false;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Home')),
                  ViloCreationSpeedDial(
                    isOpen: isAddActive,
                    onClose: () => setState(() => isAddActive = false),
                    bottomOffset: 80.0,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: ViloFloatingBottomBar(
                      currentIndex: 0,
                      isAddActive: isAddActive,
                      isCompact: false,
                      onTabSelected: (_) {},
                      onAddPressed: () => setState(() => isAddActive = !isAddActive),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap '+' action button
    await tester.tap(find.byKey(const Key('vilo_floating_action_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Tap 'Go LIVE' speed dial item
    await tester.tap(find.text('Go LIVE'));
    await tester.pumpAndSettle();

    // Verify ViloLiveScreen opened
    expect(find.text('Chilling & Connecting with the City 🌃'), findsOneWidget);
    expect(find.text('Chatting'), findsOneWidget);
    expect(find.text('Gaming'), findsOneWidget);
    expect(find.text('Go LIVE Now'), findsOneWidget);

    // Tap Go LIVE broadcast button to start broadcast
    await tester.tap(find.text('Go LIVE Now'));
    await tester.pumpAndSettle();

    // Verify live broadcast mode is active
    expect(find.text('LIVE • 142 viewers'), findsOneWidget);
    expect(find.text('End LIVE Broadcast'), findsOneWidget);

    // Tap Close to dismiss live broadcast
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}



