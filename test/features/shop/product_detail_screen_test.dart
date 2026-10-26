import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/shop/views/product_detail_screen.dart';

void main() {
  group('ProductDetailScreen UI & Interaction Tests', () {
    testWidgets('renders key UI sections and elements properly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header & Navigation items
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Recommendations'), findsOneWidget);

      // 2. Product Meta & Title
      expect(find.text('iPhone 17 Pro Max Titanium (256GB)'), findsWidgets);
      expect(find.text('\$1,199.00'), findsOneWidget);
      expect(find.text('\$1,399.00'), findsOneWidget);
      expect(find.text('-15% OFF'), findsOneWidget);

      // 3. Carousel Overlay Badges
      expect(find.text('Free 6-day Returns'), findsOneWidget);
      expect(find.text('Store Seal'), findsOneWidget);
      expect(find.text('Free Shipping'), findsOneWidget);

      // 4. Store Profile
      expect(find.text('TechHorizon Global'), findsOneWidget);
      expect(find.text('Official Store'), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);
      expect(find.text('Send Message'), findsWidgets);

      // 5. Creator Videos Section
      expect(find.text('Videos from creators'), findsOneWidget);
      expect(find.text('30+'), findsOneWidget);

      // 6. User Reviews & Filter chips
      expect(find.text('All (1.2k)'), findsOneWidget);
      expect(find.text('With Photos (450)'), findsOneWidget);
      expect(find.text('5 Star (980)'), findsOneWidget);
      expect(find.text('4 Star (180)'), findsOneWidget);

      // 7. Welcome Voucher Card
      expect(find.text('Welcome Voucher \$10 OFF'), findsOneWidget);
      expect(find.text('Claim'), findsOneWidget);

      // 8. Sticky Bottom Bar Buttons (Send Message & Add to Cart, no Buy Now)
      expect(find.text('Buy Now'), findsNothing);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Send Message'), findsWidgets);
    });

    testWidgets('tapping Send Message in bottom action bar opens direct messaging sheet', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Send Message button in the bottom bar
      final sendMessageFinder = find.widgetWithText(OutlinedButton, 'Send Message').last;
      await tester.tap(sendMessageFinder);
      await tester.pumpAndSettle();

      // Verify messaging modal with seller TechHorizon Global
      expect(find.text('TechHorizon Global'), findsWidgets);
      expect(find.text('Typically replies in under 5 minutes'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Voucher claim button toggles state to Claimed ✓', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final claimButtonFinder = find.text('Claim');
      await tester.ensureVisible(claimButtonFinder);
      await tester.pumpAndSettle();

      expect(claimButtonFinder, findsOneWidget);
      await tester.tap(claimButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Claimed ✓'), findsOneWidget);
    });

    testWidgets('Follow button toggles state to Following', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductDetailScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final followFinder = find.text('Follow');
      await tester.ensureVisible(followFinder);
      await tester.pumpAndSettle();

      expect(followFinder, findsOneWidget);
      await tester.tap(followFinder);
      await tester.pumpAndSettle();

      expect(find.text('Following'), findsOneWidget);
    });
  });
}
