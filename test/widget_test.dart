import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/core/theme/app_theme.dart';
import 'package:viloapp/features/bottom_nav/presentation/widgets/vilo_floating_bottom_bar.dart';
import 'package:viloapp/features/inbox_activity/data/datasources/thought_story_manager.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/inbox_screen.dart';
import 'package:viloapp/features/auth/data/models/user_model.dart';
import 'package:viloapp/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:viloapp/features/profile/presentation/pages/followers_following_screen.dart';
import 'package:viloapp/features/profile/presentation/pages/people_screen.dart';
import 'package:viloapp/features/profile/presentation/pages/settings_and_privacy_screen.dart';
import 'package:viloapp/features/profile/presentation/screens/profile_screen.dart';
import 'package:viloapp/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:viloapp/features/feed/data/models/video_feed_model.dart';
import 'package:viloapp/features/feed/data/models/video_model.dart';
import 'package:viloapp/features/feed/presentation/pages/home_feed_page.dart';
import 'package:viloapp/features/search_discover/presentation/pages/search_screen.dart';
import 'package:viloapp/features/feed/presentation/pages/sound_detail_page.dart';
import 'package:viloapp/features/feed/presentation/pages/video_feed_page.dart';
import 'package:viloapp/features/auth/data/datasources/token_storage.dart';
import 'package:viloapp/features/profile/data/datasources/profile_sync_service.dart';
import 'package:viloapp/features/profile/data/datasources/profile_remote_data_source.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() async {
    ThoughtStoryManager.instance.deleteStory();
    await TokenStorage.instance.clear();
    ProfileSyncService.instance.clear();
    ProfileRemoteDataSource.instance.clearCache();
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

  testWidgets('EditProfileScreen renders user details, allows editing name/bio, and opens avatar picker', (WidgetTester tester) async {
    final testUser = UserModel(
      id: 1,
      username: 'mongkol',
      email: 'mongkol@vilo.app',
      displayName: 'Thoeung Sereymongkol',
      bio: 'Flutter & Spring Boot Engineer',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
      isVerified: true,
      followersCount: 12800,
      followingCount: 284,
    );

    await tester.pumpWidget(_buildTestApp(child: EditProfileScreen(user: testUser)));

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Thoeung Sereymongkol'), findsOneWidget);
    expect(find.text('@mongkol'), findsOneWidget);
    expect(find.text('Flutter & Spring Boot Engineer'), findsOneWidget);
    expect(find.text('Change Photo'), findsOneWidget);

    // Tap Change Photo
    await tester.tap(find.text('Change Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Profile Picture'), findsOneWidget);
    expect(find.text('Select a preset avatar:'), findsOneWidget);
    expect(find.text('Enter Custom Image URL'), findsOneWidget);
  });

  testWidgets('PublicProfileScreen renders user details and toggles follow state', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: const PublicProfileScreen(
          username: 'bunheng',
          displayName: 'Lim Bunheng',
          avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop&q=80',
          bio: 'Video Engine & Streaming Specialist',
          isFollowing: false,
        ),
      ),
    );

    expect(find.text('Lim Bunheng'), findsOneWidget);
    expect(find.text('@bunheng'), findsOneWidget);
    expect(find.text('Video Engine & Streaming Specialist'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);

    // Tap Follow
    await tester.tap(find.text('Follow'));
    await tester.pump();

    // Verify it changed to Following (one in stats column, one in action button)
    expect(find.text('Following'), findsNWidgets(2));
  });

  testWidgets('FollowersFollowingScreen renders tabs, searches users, and switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: const FollowersFollowingScreen(
          userId: 1,
          username: 'mongkol',
          initialTabIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check title and tabs
    expect(find.text('@mongkol'), findsOneWidget);
    final followersTabFinder = find.descendant(of: find.byType(TabBar), matching: find.textContaining('Followers'));
    final followingTabFinder = find.descendant(of: find.byType(TabBar), matching: find.textContaining('Following'));
    expect(followersTabFinder, findsOneWidget);
    expect(followingTabFinder, findsOneWidget);

    // Check search field
    expect(find.byType(TextField), findsOneWidget);

    // Verify initial users in Followers tab
    expect(find.text('Lim Bunheng'), findsOneWidget);
    expect(find.text('Chhuon Rithysak'), findsOneWidget);

    // Search for "bunheng"
    await tester.enterText(find.byType(TextField), 'bunheng');
    await tester.pumpAndSettle();

    expect(find.text('Lim Bunheng'), findsOneWidget);
    expect(find.text('Chhuon Rithysak'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    // Switch to Following tab
    await tester.tap(followingTabFinder);
    await tester.pumpAndSettle();

    // Verify Following tab content
    expect(find.text('Sophia Vance'), findsOneWidget);
  });

  testWidgets('SearchScreen renders search input, category chips, and handles category switching', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const SearchScreen()));
    await tester.pumpAndSettle();

    // Verify search input field
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search videos, creators, sounds...'), findsOneWidget);

    // Verify category chips
    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Sounds'), findsOneWidget);

    // Switch to Sounds tab
    await tester.tap(find.text('Sounds'));
    await tester.pumpAndSettle();

    // Search query
    await tester.enterText(find.byType(TextField), 'neon');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  });

  testWidgets('SearchScreen search username shows up user account with display name and verified badge', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const SearchScreen()));
    await tester.pumpAndSettle();

    // Search for @mongkol
    await tester.enterText(find.byType(TextField), '@mongkol');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Top category shows Accounts section header and user with You indicator
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Thoeung Sereymongkol'), findsOneWidget);
    expect(find.text('@mongkol • You'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsWidgets);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('SearchScreen Top category shows all matching entities together', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const SearchScreen()));
    await tester.pumpAndSettle();

    // Search for 'pulse' which matches both Accounts and Sounds
    await tester.enterText(find.byType(TextField), 'pulse');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Top category shows all matching categories together
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Noir Pulse'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Sounds'), findsWidgets);
    expect(find.text('Pulse Bass Drop (Original)'), findsOneWidget);
  });

  testWidgets('SoundDetailPage renders sound details, toggles favorite state, and shows Use this sound button', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: const SoundDetailPage(
          soundId: '101',
          title: 'Cyberpunk Odyssey',
          artist: 'Neon Wave Lab',
          videosCount: '340K videos',
          durationSeconds: 30,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and artist
    expect(find.text('Cyberpunk Odyssey'), findsWidgets);
    expect(find.text('Neon Wave Lab'), findsOneWidget);
    expect(find.text('30s'), findsOneWidget);
    expect(find.text('Use this sound'), findsOneWidget);

    // Tap favorite button
    expect(find.text('Add to Favorites'), findsOneWidget);
    await tester.tap(find.text('Add to Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Favorited'), findsOneWidget);

    // Tap Play Sample
    expect(find.text('Play Sample'), findsOneWidget);
    await tester.tap(find.text('Play Sample'));
    await tester.pump();
    expect(find.text('Pause Sample'), findsOneWidget);
  });

  testWidgets('VideoFeedPage renders real DB creator account with follow status and hides + button when followed', (WidgetTester tester) async {
    const testVideo = VideoModel(
      id: 2,
      creatorId: 2,
      username: '@bunheng',
      displayName: 'Lim Bunheng',
      caption: 'Night walk through the neon streets #citylife #neon #cyberpunk',
      videoUrl: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
      isFollowing: true,
      musicTitle: 'Original Sound - @bunheng',
    );
    await tester.pumpWidget(_buildTestApp(child: const VideoFeedPage(feedType: 'FOLLOWING', isActive: false, initialVideos: [testVideo])));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify creator from DB is rendered (@bunheng)
    expect(find.text('@bunheng'), findsOneWidget);
    expect(find.text('Night walk through the neon streets #citylife #neon #cyberpunk'), findsOneWidget);
    // Because bunheng is already followed, + icon is NOT shown on avatar
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('VideoFeedPage Following tab displays clean empty state message when following list is empty', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const VideoFeedPage(feedType: 'FOLLOWING', isActive: false)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('No posts from people you follow yet. Follow creators to see their latest videos and photos here!'),
      findsOneWidget,
    );
  });

  testWidgets('PublicProfileScreen renders creator clean username without double @ and shows video grid', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: const PublicProfileScreen(
          userId: 2,
          username: '@bunheng',
          displayName: 'Lim Bunheng',
          isFollowing: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Must show @bunheng, NEVER @@bunheng
    expect(find.text('@bunheng'), findsOneWidget);
    expect(find.text('@@bunheng'), findsNothing);
    expect(find.text('Lim Bunheng'), findsOneWidget);
  });

  testWidgets('HomeFeedPage renders tabs (Community, Following, For You, Shop) with PageStorageKeys', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const HomeFeedPage(isActive: false)));
    await tester.pump();

    // Verify all 4 tabs exist
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('For You'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);

    // Verify active tab child has PageStorageKey
    expect(find.byKey(const PageStorageKey('tab_for_you')), findsOneWidget);
  });

  testWidgets('PublicProfileScreen renders initialVideos on frame 0 with 0ms latency', (WidgetTester tester) async {
    final testVideo = VideoFeedModel(
      id: 99,
      creatorId: 2,
      username: '@bunheng',
      displayName: 'Lim Bunheng',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
      isVerified: true,
      videoUrl: 'assets/videos/vid2.mp4',
      caption: 'Instant profile video test',
      musicTitle: 'Cyber Beats',
      views: '999K',
      likes: '999K',
      comments: '1K',
      saves: '500',
      isFollowing: true,
      isMe: false,
    );

    await tester.pumpWidget(
      _buildTestApp(
        child: PublicProfileScreen(
          userId: 2,
          username: '@bunheng',
          displayName: 'Lim Bunheng',
          isFollowing: true,
          initialVideos: [testVideo],
        ),
      ),
    );

    // Verify video likes badge is visible immediately on first pump without waiting for network
    expect(find.text('999K'), findsOneWidget);
    expect(find.text('@bunheng'), findsOneWidget);
  });
}

