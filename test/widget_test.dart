import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/app/app.dart';

void main() {
  testWidgets('ViloFloatingBottomBar renders tabs and plus button', (WidgetTester tester) async {
    await tester.pumpWidget(const ViloApp());
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
