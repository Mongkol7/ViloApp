import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/inbox_activity/data/datasources/inbox_message_manager.dart';
import 'package:viloapp/features/inbox_activity/domain/entities/inbox_item.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/chat_detail_screen.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/inbox_screen.dart';

void main() {
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

      // Initially FashionHub is top message
      expect(find.text('FashionHub'), findsOneWidget);

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
  });
}
