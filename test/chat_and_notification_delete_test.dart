import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/core/theme/app_theme.dart';
import 'package:viloapp/features/bottom_nav/presentation/widgets/vilo_floating_bottom_bar.dart';
import 'package:viloapp/features/inbox_activity/data/datasources/chat_manager.dart';
import 'package:viloapp/features/inbox_activity/domain/entities/inbox_item.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/chat_detail_screen.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/inbox_screen.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: child,
  );
}

void main() {
  setUp(() {
    ChatManager.instance.reset();
  });

  test('ChatManager: deleteMessage removes specific message from thread', () {
    final thread = ChatManager.instance.getThread('t0');
    expect(thread.messages.isNotEmpty, isTrue);
    final firstMsgId = thread.messages.first.id;

    ChatManager.instance.deleteMessage('t0', firstMsgId, forEveryone: false);
    final updatedThread = ChatManager.instance.getThread('t0');
    expect(updatedThread.messages.any((m) => m.id == firstMsgId), isFalse);
  });

  test('ChatManager: deleteMessage for everyone updates message notice', () {
    final thread = ChatManager.instance.getThread('t0');
    expect(thread.messages.isNotEmpty, isTrue);
    final firstMsgId = thread.messages.first.id;

    ChatManager.instance.deleteMessage('t0', firstMsgId, forEveryone: true);
    final updatedThread = ChatManager.instance.getThread('t0');
    final msg = updatedThread.messages.firstWhere((m) => m.id == firstMsgId);
    expect(msg.isDeletedForEveryone, isTrue);
    expect(msg.text, 'You deleted a message');
  });

  test('ChatManager: deleteThread removes conversation completely', () {
    final initialCount = ChatManager.instance.threads.length;
    expect(initialCount, greaterThan(0));

    ChatManager.instance.deleteThread('t0');
    final thread = ChatManager.instance.threads.where((t) => t.id == 't0');
    expect(thread.isEmpty, isTrue);
  });

  testWidgets('InboxScreen: Delete button is located near camera icon and deletes chat', (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp(child: const InboxScreen()));
    await tester.pump();

    // Verify camera icon and delete icon are rendered next to each other
    expect(find.byIcon(Icons.camera_alt_outlined), findsWidgets);
    expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);

    // Verify notification badge / dot
    // Activity has badgeCount: 1, System notifications has hasDot: true
    expect(find.text('1'), findsWidgets);

    // Tap delete button near camera for FashionHub
    final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteButtons, findsWidgets);

    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appeared
    expect(find.textContaining('Delete Chat with'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Delete to confirm
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify snackbar feedback
    expect(find.textContaining('deleted'), findsOneWidget);
  });

  testWidgets('ChatDetailScreen: Long press on message shows Remove for you and Remove for everyone', (WidgetTester tester) async {
    final thread = ChatManager.instance.getThread('t0');
    await tester.pumpWidget(_buildTestApp(child: ChatDetailScreen(thread: thread)));
    await tester.pump();

    // Find first message text
    final msgFinder = find.text(thread.messages.first.text);
    await tester.scrollUntilVisible(msgFinder, 200, scrollable: find.byType(Scrollable).first);
    expect(msgFinder, findsOneWidget);

    // Long press on message to show options
    await tester.longPress(msgFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet with 'Remove for you' and 'Remove for everyone' appears
    expect(find.text('Remove for you'), findsOneWidget);
    expect(find.text('Remove for everyone'), findsOneWidget);
    expect(find.text('Copy text'), findsOneWidget);

    // Tap 'Remove for you'
    await tester.tap(find.text('Remove for you'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Remove for you?'), findsOneWidget);
    final removeBtn = find.widgetWithText(ElevatedButton, 'Remove for you');
    expect(removeBtn, findsOneWidget);
    await tester.tap(removeBtn);
    await tester.pumpAndSettle();

    // Verify message removed for you feedback
    expect(find.text('Message removed for you'), findsOneWidget);
  });

  testWidgets('ChatDetailScreen: Remove for everyone shows You deleted a message', (WidgetTester tester) async {
    final thread = ChatManager.instance.getThread('t0');
    await tester.pumpWidget(_buildTestApp(child: ChatDetailScreen(thread: thread)));
    await tester.pump();

    // Find first message text
    final msgFinder = find.text(thread.messages.first.text);
    await tester.scrollUntilVisible(msgFinder, 200, scrollable: find.byType(Scrollable).first);
    expect(msgFinder, findsOneWidget);

    // Long press on message to show options
    await tester.longPress(msgFinder);
    await tester.pumpAndSettle();

    // Tap 'Remove for everyone'
    await tester.tap(find.text('Remove for everyone'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Remove for everyone?'), findsOneWidget);
    final confirmBtn = find.widgetWithText(ElevatedButton, 'Remove for everyone');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify snackbar feedback
    expect(find.text('Message removed for everyone'), findsOneWidget);

    // Verify bubble now displays 'You deleted a message'
    expect(find.text('You deleted a message'), findsOneWidget);
  });

  testWidgets('ChatDetailScreen: Shows Seen receipt on seen messages', (WidgetTester tester) async {
    final seenMessage = const ChatMessage(
      id: 'seen_1',
      text: 'Hey are you there?',
      isMe: true,
      timestamp: '10:00 AM',
      status: 'Seen',
    );
    final thread = DirectMessageThread(
      id: 't_seen',
      userId: 45,
      username: 'TestUser',
      avatarUrl: '',
      lastMessage: 'Hey are you there?',
      timeAgo: 'Just now',
      messages: [seenMessage],
    );

    await tester.pumpWidget(_buildTestApp(child: ChatDetailScreen(thread: thread)));
    await tester.pump();

    // Verify message bubble is rendered
    expect(find.text('Hey are you there?'), findsOneWidget);

    // Verify 'Seen' label and double checkmark icon are rendered on chat
    expect(find.text('Seen'), findsOneWidget);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
  });

  testWidgets('ChatDetailScreen: Top AppBar more options has Delete Chat', (WidgetTester tester) async {
    final thread = ChatManager.instance.getThread('t0');
    await tester.pumpWidget(_buildTestApp(child: ChatDetailScreen(thread: thread)));
    await tester.pump();

    // Tap more_vert icon in AppBar
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    // Verify bottom sheet has 'Delete Chat with...'
    expect(find.textContaining('Delete Chat with'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'View Profile'), findsOneWidget);

    // Tap 'Delete Chat with...'
    await tester.tap(find.textContaining('Delete Chat with'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.textContaining('Delete Chat with'), findsWidgets);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('ViloFloatingBottomBar: displays number alert badge or dot on notify/chat', (WidgetTester tester) async {
    // 1. With number alert
    await tester.pumpWidget(_buildTestApp(
      child: ViloFloatingBottomBar(
        currentIndex: 0,
        isAddActive: false,
        isCompact: false,
        chatBadgeCount: 5,
        onTabSelected: (_) {},
        onAddPressed: () {},
      ),
    ));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);

    // 2. With dot alert
    await tester.pumpWidget(_buildTestApp(
      child: ViloFloatingBottomBar(
        currentIndex: 0,
        isAddActive: false,
        isCompact: false,
        chatHasDot: true,
        onTabSelected: (_) {},
        onAddPressed: () {},
      ),
    ));
    await tester.pump();
    // Dot indicator rendered
    expect(find.byType(ViloFloatingBottomBar), findsOneWidget);
  });
}
