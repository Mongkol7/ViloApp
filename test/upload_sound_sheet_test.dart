import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/core/theme/app_theme.dart';
import 'package:viloapp/features/auth/data/datasources/token_storage.dart';
import 'package:viloapp/features/auth/data/models/user_model.dart';
import 'package:viloapp/features/feed/presentation/pages/sound_detail_page.dart';
import 'package:viloapp/features/feed/presentation/widgets/create_action_sheet.dart';
import 'package:viloapp/features/feed/presentation/widgets/upload_sound_sheet.dart';
import 'package:viloapp/features/profile/data/datasources/profile_sync_service.dart';
import 'package:viloapp/features/profile/presentation/mock/profile_mock_data.dart';
import 'package:viloapp/features/profile/presentation/widgets/sound_list_item.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() async {
    await TokenStorage.instance.clear();
    ProfileSyncService.instance.clear();
  });

  group('CreateActionSheet - Upload Music / Sound Option', () {
    testWidgets('renders Upload Music / Sound button and responds to tap', (WidgetTester tester) async {
      bool soundSelected = false;
      bool productSelected = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: CreateActionSheet(
            onCameraSelected: () {},
            onUploadSelected: () {},
            onUploadSoundSelected: () => soundSelected = true,
            onPostProductSelected: () => productSelected = true,
          ),
        ),
      );

      // Verify all 4 options are rendered
      expect(find.byKey(const Key('create_camera_option_button')), findsOneWidget);
      expect(find.byKey(const Key('create_upload_option_button')), findsOneWidget);
      expect(find.byKey(const Key('create_upload_sound_option_button')), findsOneWidget);
      expect(find.byKey(const Key('create_post_product_option_button')), findsOneWidget);

      expect(find.text('Upload Music / Sound'), findsOneWidget);
      expect(find.byIcon(Icons.library_music_rounded), findsOneWidget);
      expect(find.text('Post Product'), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('create_upload_sound_option_button')));
      await tester.pump();
      expect(soundSelected, isTrue);

      await tester.tap(find.byKey(const Key('create_post_product_option_button')));
      await tester.pump();
      expect(productSelected, isTrue);
    });
  });

  group('UploadSoundSheet', () {
    testWidgets('renders all required controls and validates audio selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const UploadSoundSheet(),
        ),
      );

      // Verify controls
      expect(find.text('Upload Music / Sound'), findsOneWidget);
      expect(find.byKey(const Key('upload_sound_pick_audio_button')), findsOneWidget);
      expect(find.text('Select Audio File *'), findsOneWidget);
      expect(find.byKey(const Key('upload_sound_title_field')), findsOneWidget);
      expect(find.byKey(const Key('upload_sound_pick_cover_button')), findsOneWidget);
      expect(find.byKey(const Key('upload_sound_submit_button')), findsOneWidget);

      // Tap Upload without picking audio file -> shows validation error
      await tester.tap(find.byKey(const Key('upload_sound_submit_button')));
      await tester.pump();

      expect(find.text('Please select an audio file (MP3, WAV, M4A, etc.)'), findsOneWidget);
    });
  });

  group('SoundListItem Owner-Only Delete & Edit Cover', () {
    final mySound = SoundTrack(
      id: 101,
      title: 'Neon Nights',
      artist: '@mongkol',
      creatorId: 1,
      creatorUsername: 'mongkol',
      coverUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500',
      audioUrl: '/uploads/music/neon.mp3',
      usedByLabel: '12',
    );

    final otherUserSound = SoundTrack(
      id: 202,
      title: 'Alien Sunset',
      artist: '@bunheng',
      creatorId: 2,
      creatorUsername: 'bunheng',
      coverUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500',
      audioUrl: '/uploads/music/sunset.mp3',
      usedByLabel: '5',
    );

    testWidgets('Owner sees Edit Cover and Delete button, tapping Delete opens confirmation dialog', (WidgetTester tester) async {
      // Mock active user as @mongkol (id: 1)
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 1,
        username: 'mongkol',
        email: 'mongkol@vilo.app',
        displayName: 'Mongkol',
        bio: '',
        isVerified: false,
        followersCount: 0,
        followingCount: 0,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: SoundListItem(
            sound: mySound,
            isCreator: true,
          ),
        ),
      );

      // Owner should see both Edit Cover and Delete
      expect(find.text('Edit Cover'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byKey(const Key('delete_sound_button')), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Tap Delete button -> shows confirmation dialog
      await tester.tap(find.byKey(const Key('delete_sound_button')));
      await tester.pumpAndSettle();

      expect(find.text('Delete Sound'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Neon Nights"? Existing videos using this sound will remain intact.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const Key('confirm_delete_sound_dialog_button')), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Sound'), findsNothing);
    });

    testWidgets('Non-owner does NOT see Edit Cover or Delete buttons', (WidgetTester tester) async {
      // Mock active user as @other (id: 99)
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 99,
        username: 'other_user',
        email: 'other@vilo.app',
        displayName: 'Other',
        bio: '',
        isVerified: false,
        followersCount: 0,
        followingCount: 0,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: SoundListItem(
            sound: otherUserSound,
            isCreator: false,
          ),
        ),
      );

      // Non-owner should not see Edit Cover or Delete
      expect(find.text('Edit Cover'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.byKey(const Key('delete_sound_button')), findsNothing);
    });
  });

  group('SoundDetailPage Owner-Only Delete & Edit Cover', () {
    testWidgets('Owner sees Edit Cover and Delete buttons on SoundDetailPage', (WidgetTester tester) async {
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 1,
        username: 'mongkol',
        email: 'mongkol@vilo.app',
        displayName: 'Mongkol',
        bio: '',
        isVerified: false,
        followersCount: 0,
        followingCount: 0,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const SoundDetailPage(
            soundId: '101',
            title: 'Owner Track',
            artist: '@mongkol',
            creatorId: 1,
            creatorUsername: 'mongkol',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sound_detail_edit_cover_button')), findsOneWidget);
      expect(find.byKey(const Key('sound_detail_delete_button')), findsOneWidget);
      expect(find.text('Use this sound'), findsOneWidget);
    });

    testWidgets('Non-owner sees Use this sound but NOT Edit Cover or Delete buttons', (WidgetTester tester) async {
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 1,
        username: 'mongkol',
        email: 'mongkol@vilo.app',
        displayName: 'Mongkol',
        bio: '',
        isVerified: false,
        followersCount: 0,
        followingCount: 0,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const SoundDetailPage(
            soundId: '999',
            title: 'Someone Else Track',
            artist: '@artist99',
            creatorId: 99,
            creatorUsername: 'artist99',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sound_detail_edit_cover_button')), findsNothing);
      expect(find.byKey(const Key('sound_detail_delete_button')), findsNothing);
      expect(find.text('Use this sound'), findsOneWidget);
    });
  });
}
