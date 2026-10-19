import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/shop/models/cart_item.dart';
import 'package:viloapp/features/shop/presentation/controllers/cart_controller.dart';
import 'package:viloapp/features/shop/views/shop_search_results_screen.dart';

void main() {
  group('ShopSearchResultsScreen & MerchantCard UI Tests (image_54f91d.png)', () {
    setUp(() async {
      CartManager.instance.clear();
      await CartController.instance.clearCart();
    });

    tearDown(() async {
      CartManager.instance.clear();
      await CartController.instance.clearCart();
    });

    testWidgets('renders top tabs, search icon, search pill, and creator merchant cards matching image_54f91d.png',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopSearchResultsScreen(initialQuery: ''),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Top Tabs & Search Magnifier icon
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsWidgets);

      // 2. Verify Search Bar and Search button
      expect(find.text('Search'), findsOneWidget);

      // 3. Verify Shopping Cart Bag Icon and badge (4)
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // 4. Verify All 4 Merchant Handles matching image_54f91d.png
      expect(find.text('@techgear_official'), findsOneWidget);
      expect(find.text('@god_gear_official'), findsOneWidget);
      expect(find.text('@master_tech'), findsOneWidget);
      expect(find.text('@keyboard_collector'), findsOneWidget);

      // 5. Verify Products and Electric Blue Prices ($149.00, $89.00, $29.00)
      expect(find.text('Stealth TKL Keyboard'), findsWidgets);
      expect(find.text('\$149.00'), findsWidgets);
      expect(find.text('Gaming Mouse'), findsWidgets);
      expect(find.text('\$89.00'), findsWidgets);
      expect(find.text('Mouse Pad'), findsWidgets);
      expect(find.text('\$29.00'), findsWidgets);

      // 6. Verify NO "Buy Now" buttons on these merchant cards
      expect(find.text('Buy Now'), findsNothing);

      // 7. Verify Chat bubble buttons and full-width "Send Message" buttons
      expect(find.byIcon(Icons.chat_bubble_rounded), findsWidgets);
      expect(find.text('Send Message'), findsWidgets);
    });

    testWidgets('tapping product item row directly adds to CartManager and updates count without navigating away',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopSearchResultsScreen(initialQuery: ''),
        ),
      );
      await tester.pumpAndSettle();

      expect(CartManager.instance.totalItemCount, 0);

      // Tap the first Stealth TKL Keyboard product row
      final keyboardFinder = find.text('Stealth TKL Keyboard').first;
      await tester.tap(keyboardFinder);
      await tester.pumpAndSettle();

      // Verify item was directly added to CartManager
      expect(CartManager.instance.totalItemCount, 1);
      expect(CartManager.instance.items.first.product.name, 'Stealth TKL Keyboard');
      expect(CartManager.instance.items.first.product.price, 149.00);

      // Verify SnackBar feedback with 'Added to Cart' and 'View Cart'
      expect(find.text('Added to Cart'), findsOneWidget);
      expect(find.text('View Cart'), findsOneWidget);
    });

    testWidgets('tapping square chat bubble button opens direct message conversation sheet with creator',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopSearchResultsScreen(initialQuery: ''),
        ),
      );
      await tester.pumpAndSettle();

      // Find the first square chat button on @techgear_official card
      final chatButtons = find.byIcon(Icons.chat_bubble_rounded);
      expect(chatButtons, findsWidgets);

      await tester.tap(chatButtons.first);
      await tester.pumpAndSettle();

      // Verify direct message bottom sheet opened with creator handle and options
      expect(find.text('Direct Creator Channel • Ask about items or purchase'), findsOneWidget);
      expect(find.text('Message @techgear_official to discuss or buy...'), findsOneWidget);
      expect(find.text('How can I purchase this?'), findsOneWidget);
      expect(find.text('Is this in stock?'), findsOneWidget);
    });

    testWidgets('dynamic search filters creator merchants list and shows empty state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopSearchResultsScreen(initialQuery: 'NonExistentProductXYZ'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty state is rendered
      expect(find.text('No stores or products found for "NonExistentProductXYZ"'), findsOneWidget);
      expect(find.text('0 stores'), findsOneWidget);
    });
  });
}
