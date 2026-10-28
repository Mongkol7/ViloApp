import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viloapp/features/auth/data/datasources/token_storage.dart';
import 'package:viloapp/features/auth/data/models/user_model.dart';
import 'package:viloapp/features/profile/data/datasources/profile_sync_service.dart';
import 'package:viloapp/features/inbox_activity/data/datasources/inbox_message_manager.dart';
import 'package:viloapp/features/inbox_activity/domain/entities/inbox_item.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/chat_detail_screen.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/inbox_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sent messages and drafts persist separately for each account', () async {
    SharedPreferences.setMockInitialValues({});
    await TokenStorage.instance.clear();
    ProfileSyncService.instance.clear();
    final manager = InboxMessageManager.instance;
    manager.resetToDefault();
    const userId = 907001;
    await manager.loadForUser(userId);

    const testThread = DirectMessageThread(
      id: 'thread_user_test',
      username: '@TestShop',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      lastMessage: 'Hello',
      timeAgo: 'Just now',
      isVerified: true,
      messages: [],
    );
    manager.addOrUpdateThread(testThread);

    const draft = 'Please hold the blue one for me';
    await manager.saveDraft('thread_user_test', draft);
    await manager.addMessageToThread(
      'thread_user_test',
      const ChatMessage(
        id: 'persisted-message',
        text: 'Is this still available?',
        isMe: true,
        timestamp: 'Just now',
      ),
    );

    await manager.reloadForUser(userId);
    expect(manager.getDraft('thread_user_test'), draft);
    expect(
      manager.getThread('thread_user_test')!.messages.any((message) => message.id == 'persisted-message'),
      isTrue,
    );

    await manager.loadForUser(907002);
    expect(manager.getDraft('thread_user_test'), isNull);
    expect(
      manager.getThread('thread_user_test'),
      isNull,
    );
  });

  group('InboxMessageManager Unit & State Tests', () {
    setUp(() {
      InboxMessageManager.instance.resetToDefault();
    });

    test('addOrUpdateThread inserts new thread at top index 0', () {
      const newThread = DirectMessageThread(
        id: 'thread_vilo_test',
        username: '@Vilo Lifestyle',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        lastMessage: 'Hi! Order inquiry for Tote Bag',
        timeAgo: 'Just now',
        isVerified: true,
      );

      InboxMessageManager.instance.addOrUpdateThread(newThread);

      final threads = InboxMessageManager.instance.threads;
      expect(threads.first.username, '@Vilo Lifestyle');
      expect(threads.first.lastMessage, 'Hi! Order inquiry for Tote Bag');
    });

    test('addMessageToThread appends message and promotes thread to index 0', () {
      const thread = DirectMessageThread(
        id: 'test_thread_123',
        username: '@AeroMount Studio',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        lastMessage: 'First inquiry',
        timeAgo: '10m',
        messages: [
          ChatMessage(id: 'm1', text: 'First inquiry', isMe: true, timestamp: '10m'),
        ],
      );

      InboxMessageManager.instance.addOrUpdateThread(thread);

      final reply = ChatMessage(
        id: 'm2',
        text: 'Yes, this is in stock and ready to ship!',
        isMe: false,
        timestamp: 'Just now',
      );

      InboxMessageManager.instance.addMessageToThread('test_thread_123', reply);

      final topThread = InboxMessageManager.instance.threads.first;
      expect(topThread.username, '@AeroMount Studio');
      expect(topThread.lastMessage, 'Yes, this is in stock and ready to ship!');
      expect(topThread.messages.length, 2);
    });
  });

  group('InboxScreen Dynamic Thread Sync Widget Tests', () {
    setUp(() {
      InboxMessageManager.instance.resetToDefault();
    });

    testWidgets('InboxScreen displays newly registered merchant threads at the top of MESSAGES', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InboxScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially inbox has no messages
      expect(find.text('No messages yet'), findsOneWidget);

      // Now dispatch an order inquiry thread (as CartPage does)
      const orderThread = DirectMessageThread(
        id: 'order_vilo_lifestyle',
        username: '@Vilo Lifestyle',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        lastMessage: 'Hi! I would like to order 1 item(s) from @Vilo Lifestyle',
        timeAgo: 'Just now',
        isVerified: true,
      );

      InboxMessageManager.instance.addOrUpdateThread(orderThread);
      await tester.pumpAndSettle();

      // @Vilo Lifestyle must now be visible in InboxScreen MESSAGES
      expect(find.text('@Vilo Lifestyle'), findsOneWidget);
      expect(find.textContaining('Hi! I would like to order 1 item(s)'), findsOneWidget);

      // Tapping on the merchant thread opens ChatDetailScreen
      await tester.tap(find.text('@Vilo Lifestyle'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('@Vilo Lifestyle'), findsWidgets);
    });

    testWidgets('ChatDetailScreen renders message with product image attachment', (tester) async {
      const imageThread = DirectMessageThread(
        id: 'order_chat_titan',
        username: '@Titan Monitoring',
        avatarUrl: 'assets/images/v_watch_ultra.jpg',
        lastMessage: 'Hi! I would like to order 1 item(s)',
        timeAgo: 'Just now',
        isVerified: true,
        messages: [
          ChatMessage(
            id: 'msg_order_1',
            text: 'Hi! I would like to order 1 item(s) from @Titan Monitoring:\n- V-Watch Ultra Rugged Titanium Smartwatch (x1)\nAre these ready to ship?',
            isMe: true,
            timestamp: 'Just now',
            imageUrl: 'assets/images/v_watch_ultra.jpg',
            imageUrls: ['assets/images/v_watch_ultra.jpg'],
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatDetailScreen(thread: imageThread),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify text is displayed
      expect(find.textContaining('V-Watch Ultra Rugged Titanium Smartwatch'), findsOneWidget);

      // 2. Verify image widget is rendered
      expect(find.byType(Image), findsWidgets);
      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
    });
  });

  group('ChatMessage Image Model Unit Tests', () {
    test('ChatMessage correctly identifies single and multiple image attachments', () {
      const textOnly = ChatMessage(
        id: '1',
        text: 'Hello',
        isMe: true,
        timestamp: 'now',
      );
      expect(textOnly.hasImages, false);
      expect(textOnly.allImages, isEmpty);

      const singleImg = ChatMessage(
        id: '2',
        text: 'Order 1 item',
        isMe: true,
        timestamp: 'now',
        imageUrl: 'assets/images/v_watch_ultra.jpg',
      );
      expect(singleImg.hasImages, true);
      expect(singleImg.allImages, ['assets/images/v_watch_ultra.jpg']);

      const multiImg = ChatMessage(
        id: '3',
        text: 'Order 2 items',
        isMe: true,
        timestamp: 'now',
        imageUrls: ['assets/images/v_watch_ultra.jpg', 'assets/images/canvas_tote.jpg'],
      );
      expect(multiImg.hasImages, true);
      expect(multiImg.allImages.length, 2);
    });

    test('InboxMessageManager collapses duplicate threads for the same peer into a single thread', () async {
      await InboxMessageManager.instance.clearAllMessages();
      ProfileSyncService.instance.cachedMyProfile = UserModel(
        id: 3,
        username: 'admin',
        email: 'admin@vilo.app',
        displayName: 'Vilo Admin',
        isVerified: true,
        followersCount: 10,
        followingCount: 5,
      );

      // Thread 1: legacy chat_mongkol
      final thread1 = DirectMessageThread(
        id: 'chat_mongkol',
        username: '@mongkol',
        avatarUrl: 'https://example.com/avatar1.jpg',
        recipientHandle: '@mongkol',
        senderHandle: 'admin',
        lastMessage: 'Legacy message',
        timeAgo: 'Yesterday',
        messages: const [
          ChatMessage(id: 'm1', text: 'Legacy message', isMe: true, timestamp: 'Yesterday'),
        ],
      );

      // Thread 2: modern dm_admin_mongkol
      final thread2 = DirectMessageThread(
        id: 'dm_admin_mongkol',
        username: '@mongkol',
        avatarUrl: 'https://example.com/avatar2.jpg',
        recipientHandle: '@mongkol',
        senderHandle: 'admin',
        lastMessage: 'Modern message',
        timeAgo: 'Just now',
        messages: const [
          ChatMessage(id: 'm2', text: 'Modern message', isMe: true, timestamp: 'Just now'),
        ],
      );

      InboxMessageManager.instance.addOrUpdateThread(thread1);
      InboxMessageManager.instance.addOrUpdateThread(thread2);

      final threads = InboxMessageManager.instance.threads;
      // Must collapse to EXACTLY ONE thread for @mongkol
      expect(threads.where((t) => t.username == '@mongkol').length, 1);
      final singleThread = threads.firstWhere((t) => t.username == '@mongkol');
      expect(singleThread.messages.length, 2);
      expect(singleThread.id, 'dm_admin_mongkol');
    });

    test('ChatMessage preserves and exposes multiple ordered product images from comma-separated string', () {
      final String rawRemoteImageUrl = 'https://example.com/p1.png,https://example.com/p2.png';
      final List<String> parsedImages = rawRemoteImageUrl.contains(',')
          ? rawRemoteImageUrl.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : [rawRemoteImageUrl.trim()];

      final msg = ChatMessage(
        id: 'msg_multi',
        text: 'Order 2 items',
        isMe: true,
        timestamp: 'Just now',
        imageUrl: parsedImages.isNotEmpty ? parsedImages.first : null,
        imageUrls: parsedImages.isNotEmpty ? parsedImages : null,
      );

      expect(msg.hasImages, isTrue);
      expect(msg.allImages.length, 2);
      expect(msg.allImages[0], 'https://example.com/p1.png');
      expect(msg.allImages[1], 'https://example.com/p2.png');
    });
  });
}
