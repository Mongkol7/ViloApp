import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/inbox_activity/data/datasources/inbox_message_manager.dart';
import 'package:viloapp/features/inbox_activity/presentation/pages/chat_detail_screen.dart';
import 'package:viloapp/features/shop/data/datasources/shop_remote_data_source.dart';
import 'package:viloapp/features/shop/data/models/product_model.dart';
import 'package:viloapp/features/shop/models/cart_item.dart';
import 'package:viloapp/features/shop/models/product.dart';
import 'package:viloapp/features/shop/presentation/controllers/cart_controller.dart';
import 'package:viloapp/features/shop/presentation/pages/cart_page.dart';
import 'package:viloapp/features/shop/presentation/pages/checkout_page.dart';
import 'package:viloapp/features/shop/presentation/pages/order_history_page.dart';

void main() {
  group('CartItem & CartManager Dynamic Logic Tests', () {
    late CartManager cartManager;

    final productA = Product(
      id: 'prod-001',
      name: 'Vilo Creator Ring Light Pro',
      categoryId: 'cat-studio',
      price: 34.99,
      description: 'Dimmable LED ring light',
      imageUrl: 'https://example.com/ringlight.png',
    );

    final productB = Product(
      id: 'prod-002',
      name: 'Wireless Lavalier Microphone',
      categoryId: 'cat-audio',
      price: 29.99,
      description: 'Wireless noise-cancelling lapel mic',
      imageUrl: 'https://example.com/mic.png',
    );

    setUp(() {
      cartManager = CartManager();
      cartManager.clear();
    });

    test('CartItem calculation and serialization', () {
      final item = CartItem(product: productA, quantity: 3);
      expect(item.subtotal, closeTo(34.99 * 3, 0.001));
      expect(item.formattedSubtotal, '\$104.97');

      final json = item.toJson();
      expect(json['quantity'], 3);
      expect(json['subtotal'], closeTo(104.97, 0.001));

      final restored = CartItem.fromJson(json);
      expect(restored.product.id, 'prod-001');
      expect(restored.quantity, 3);
      expect(restored.subtotal, closeTo(104.97, 0.001));
    });

    test('CartManager adds products and updates existing quantities', () {
      expect(cartManager.isEmpty, true);
      expect(cartManager.totalItemCount, 0);
      expect(cartManager.totalAmount, 0.0);

      // Add product A
      cartManager.addItem(productA, 1);
      expect(cartManager.items.length, 1);
      expect(cartManager.totalItemCount, 1);
      expect(cartManager.totalAmount, closeTo(34.99, 0.001));

      // Add product A again (should increment quantity rather than create duplicate entry)
      cartManager.addItem(productA, 2);
      expect(cartManager.items.length, 1);
      expect(cartManager.totalItemCount, 3);
      expect(cartManager.items.first.quantity, 3);
      expect(cartManager.totalAmount, closeTo(34.99 * 3, 0.001));

      // Add product B
      cartManager.addItem(productB, 1);
      expect(cartManager.items.length, 2);
      expect(cartManager.totalItemCount, 4);
      final expectedTotal = (34.99 * 3) + 29.99;
      expect(cartManager.totalAmount, closeTo(expectedTotal, 0.001));
      expect(cartManager.formattedTotal, '\$${expectedTotal.toStringAsFixed(2)}');
    });

    test('CartManager increment and decrement quantity logic with auto-removal', () {
      cartManager.addItem(productA, 2);

      // Increment product A
      cartManager.incrementQuantity('prod-001');
      expect(cartManager.getItem('prod-001')?.quantity, 3);

      // Decrement product A
      cartManager.decrementQuantity('prod-001');
      expect(cartManager.getItem('prod-001')?.quantity, 2);

      cartManager.decrementQuantity('prod-001');
      expect(cartManager.getItem('prod-001')?.quantity, 1);

      // Decrement when quantity is 1 should remove product from cart
      cartManager.decrementQuantity('prod-001');
      expect(cartManager.getItem('prod-001'), isNull);
      expect(cartManager.items.isEmpty, true);
      expect(cartManager.totalAmount, 0.0);
    });

    test('CartManager removes product and clears cart', () {
      cartManager.addItem(productA, 2);
      cartManager.addItem(productB, 1);
      expect(cartManager.items.length, 2);

      // Remove product A explicitly
      cartManager.removeItem('prod-001');
      expect(cartManager.items.length, 1);
      expect(cartManager.getItem('prod-001'), isNull);
      expect(cartManager.getItem('prod-002'), isNotNull);
      expect(cartManager.totalAmount, closeTo(29.99, 0.001));

      // Clear all items
      cartManager.clear();
      expect(cartManager.items.isEmpty, true);
      expect(cartManager.totalItemCount, 0);
      expect(cartManager.totalAmount, 0.0);
    });
  });

  group('CartController Optimistic In-Memory & Fallback Tests', () {
    late CartController cartCtrl;

    setUp(() async {
      cartCtrl = CartController.instance;
      await cartCtrl.clearCart();
    });

    tearDown(() async {
      await cartCtrl.clearCart();
    });

    test('addToCart optimistically updates items and totals immediately', () async {
      const product = ProductModel(
        id: 991,
        title: 'Cyberpunk Mechanical Keyboard',
        description: 'RGB mechanical gaming keyboard',
        price: 89.99,
        originalPrice: 119.99,
        stock: 25,
        rating: 4.9,
        reviewCount: 350,
        salesCount: 1200,
        images: ['https://example.com/keyboard.jpg'],
      );

      expect(cartCtrl.itemCount, 0);
      expect(cartCtrl.items.isEmpty, true);

      final success = await cartCtrl.addToCart(product, quantity: 2, variant: 'Blue Switch');
      expect(success, true);
      expect(cartCtrl.itemCount, 2);
      expect(cartCtrl.items.length, 1);
      expect(cartCtrl.items.first.productId, 991);
      expect(cartCtrl.items.first.productTitle, 'Cyberpunk Mechanical Keyboard');
      expect(cartCtrl.items.first.variant, 'Blue Switch');
      expect(cartCtrl.items.first.quantity, 2);
      expect(cartCtrl.items.first.subtotal, closeTo(89.99 * 2, 0.001));
      expect(cartCtrl.totalAmount, closeTo(89.99 * 2, 0.001));
    });

    test('addProduct helper bridges Product and ProductModel seamlessly', () async {
      final product = Product(
        id: '882',
        name: 'Vilo Studio Monitor Stand',
        categoryId: '1',
        price: 49.99,
        originalPrice: 59.99,
        rating: 4.7,
        soldCount: 85,
        description: 'Aluminum dual monitor mount',
        imageUrl: 'https://example.com/stand.jpg',
      );

      final success = await cartCtrl.addProduct(product, quantity: 1);
      expect(success, true);
      expect(cartCtrl.itemCount, 1);
      expect(cartCtrl.items.first.productTitle, 'Vilo Studio Monitor Stand');
      expect(cartCtrl.totalAmount, closeTo(49.99, 0.001));
    });

    test('updateQuantity and removeItem correctly modify cart state', () async {
      const product = ProductModel(
        id: 773,
        title: 'RGB Lightbar',
        description: 'Screen-mounted monitor lamp',
        price: 39.99,
        stock: 10,
        rating: 4.8,
        reviewCount: 50,
        salesCount: 300,
      );

      await cartCtrl.addToCart(product, quantity: 1);
      final itemId = cartCtrl.items.first.id;

      // Update quantity to 4
      await cartCtrl.updateQuantity(itemId, 4);
      expect(cartCtrl.itemCount, 4);
      expect(cartCtrl.totalAmount, closeTo(39.99 * 4, 0.001));

      // Remove item
      await cartCtrl.removeItem(itemId);
      expect(cartCtrl.itemCount, 0);
      expect(cartCtrl.items.isEmpty, true);
      expect(cartCtrl.totalAmount, 0.0);
    });
  });

  group('CartPage Widget & Badge Behavior Tests', () {
    setUp(() async {
      await CartController.instance.clearCart();
    });

    tearDown(() async {
      await CartController.instance.clearCart();
    });

    testWidgets('CartPage displays empty state when cart has no items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CartPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Cart is Empty'), findsOneWidget);
      expect(find.text('Shopping Cart (0)'), findsOneWidget);
      expect(find.text('Discover Products'), findsOneWidget);
    });

    testWidgets('CartPage displays items, updates quantity, and shows correct total', (tester) async {
      const testProduct = ProductModel(
        id: 404,
        title: 'Sony WH-1000XM5 Titanium',
        description: 'Noise cancelling headphones',
        price: 299.99,
        originalPrice: 399.99,
        stock: 15,
        rating: 4.9,
        reviewCount: 240,
        salesCount: 890,
        images: ['https://example.com/sony.jpg'],
      );

      // Add to cart before opening page
      await CartController.instance.addToCart(testProduct, quantity: 1, variant: 'Silver');

      await tester.pumpWidget(
        const MaterialApp(
          home: CartPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify item details rendered
      expect(find.text('Sony WH-1000XM5 Titanium'), findsOneWidget);
      expect(find.text('\$299.99'), findsWidgets);
      expect(find.text('Silver'), findsOneWidget);
      expect(find.text('Shopping Cart (1)'), findsOneWidget);
      expect(find.text('Checkout'), findsNothing);
      expect(find.text('Send Message'), findsWidgets);

      // Increment item quantity using '+' button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(CartController.instance.itemCount, 2);
      expect(find.text('Shopping Cart (2)'), findsOneWidget);
      expect(CartController.instance.totalAmount, closeTo(299.99 * 2, 0.001));

      // Tapping Send Message opens direct order inquiry sheet
      await tester.tap(find.text('Send Message').first);
      await tester.pumpAndSettle();

      expect(find.text('@TechHorizon Global'), findsWidgets);
      expect(find.text('Direct Creator Channel • Inquire about cart order'), findsOneWidget);
      expect(find.text('I\'d like to place this order'), findsOneWidget);
    });

    testWidgets('Adding second distinct product creates separate card without colliding IDs', (tester) async {
      await CartController.instance.clearCart();

      const prod1 = ProductModel(
        id: 701,
        title: 'Sony Headphones Pro',
        description: 'Noise cancelling',
        price: 199.0,
        stock: 10,
        rating: 4.8,
        reviewCount: 150,
        salesCount: 650,
        images: ['https://example.com/p1.jpg'],
        sellerName: 'Sony Store',
      );
      const prod2 = ProductModel(
        id: 702,
        title: 'Mechanical Keyboard RGB',
        description: 'Wireless TKL',
        price: 129.0,
        stock: 15,
        rating: 4.9,
        reviewCount: 220,
        salesCount: 890,
        images: ['https://example.com/p2.jpg'],
        sellerName: 'God Gear Official',
      );

      await CartController.instance.addToCart(prod1, quantity: 1);
      await CartController.instance.addToCart(prod2, quantity: 1);

      expect(CartController.instance.items.length, 2);
      expect(CartController.instance.itemCount, 2);

      await tester.pumpWidget(
        const MaterialApp(
          home: CartPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Both distinct products must be rendered
      expect(find.text('Sony Headphones Pro'), findsOneWidget);
      expect(find.text('Mechanical Keyboard RGB'), findsOneWidget);

      // Distinct company headers must be rendered
      expect(find.text('@Sony Store'), findsOneWidget);
      expect(find.text('@God Gear Official'), findsOneWidget);

      // Verify each company has its own Send Message button
      expect(find.text('Send Message'), findsWidgets);
    });

    testWidgets('Tapping bottom bar Send Message dispatches inquiries with images, keeps cart items intact, does not create orders, and redirects to first company ChatDetailScreen', (tester) async {
      await CartController.instance.clearCart();
      ShopRemoteDataSource.instance.clearLocalOrders();

      const prod1 = ProductModel(
        id: 801,
        title: 'Vilo Signature Canvas Tote Bag',
        description: 'Durable canvas tote',
        price: 24.99,
        stock: 50,
        rating: 4.8,
        reviewCount: 320,
        salesCount: 1200,
        images: ['assets/images/products/tote.png'],
        sellerName: 'Vilo Lifestyle',
      );
      const prod2 = ProductModel(
        id: 802,
        title: 'MagSafe Magnetic Phone Mount',
        description: 'Solid aluminum mount',
        price: 19.99,
        stock: 30,
        rating: 4.9,
        reviewCount: 150,
        salesCount: 650,
        images: ['https://example.com/mount.jpg'],
        sellerName: 'AeroMount Studio',
      );

      await CartController.instance.addToCart(prod1, quantity: 1);
      await CartController.instance.addToCart(prod2, quantity: 1);

      expect(CartController.instance.itemCount, 2);

      await tester.pumpWidget(
        const MaterialApp(
          home: CartPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the bottom bar Send Message button (with count badge '2')
      expect(find.text('Send Message'), findsWidgets);
      expect(find.text('2'), findsOneWidget);

      // Tap bottom bar Send Message
      final bottomSendButton = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.text('Send Message'),
      ).last;
      await tester.tap(bottomSendButton);
      await tester.pumpAndSettle();

      // 1. Should navigate to ChatDetailScreen for the first company (@Vilo Lifestyle)
      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('@Vilo Lifestyle'), findsWidgets);

      // 2. Cart items must be cleared upon sending all inquiries
      expect(CartController.instance.itemCount, 0);

      // 3. NO orders should be created in Order History from chat inquiry
      final orders = await ShopRemoteDataSource.instance.getOrderHistory();
      expect(orders.length, 0);

      // 4. Both threads must be registered in InboxMessageManager
      final threads = InboxMessageManager.instance.threads;
      expect(threads.any((t) => t.username == '@Vilo Lifestyle'), true);
      expect(threads.any((t) => t.username == '@AeroMount Studio'), true);

      // 5. Verify order ChatMessage contains product image attachment
      final viloThread = threads.firstWhere((t) => t.username == '@Vilo Lifestyle');
      expect(viloThread.messages.first.hasImages, true);
      expect(viloThread.messages.first.imageUrl, 'assets/images/products/tote.png');

      final aeroThread = threads.firstWhere((t) => t.username == '@AeroMount Studio');
      expect(aeroThread.messages.first.hasImages, true);
      expect(aeroThread.messages.first.imageUrl, 'https://example.com/mount.jpg');
    });

    testWidgets('Global Send Message deterministically redirects to first product added to cart and clears all cart items', (tester) async {
      await CartController.instance.clearCart();
      ShopRemoteDataSource.instance.clearLocalOrders();

      const prod1 = ProductModel(
        id: 801,
        title: 'Vilo Signature Canvas Tote Bag',
        description: 'Durable canvas tote',
        price: 24.99,
        stock: 50,
        rating: 4.8,
        reviewCount: 320,
        salesCount: 1200,
        images: ['assets/images/products/tote.png'],
        sellerName: 'Vilo Lifestyle',
      );
      const prod2 = ProductModel(
        id: 802,
        title: 'MagSafe Magnetic Phone Mount',
        description: 'Solid aluminum mount',
        price: 19.99,
        stock: 30,
        rating: 4.9,
        reviewCount: 150,
        salesCount: 650,
        images: ['https://example.com/mount.jpg'],
        sellerName: 'AeroMount Studio',
      );

      // Add prod2 (AeroMount Studio) FIRST
      await CartController.instance.addToCart(prod2, quantity: 1);
      // Add prod1 (Vilo Lifestyle) SECOND
      await CartController.instance.addToCart(prod1, quantity: 1);

      expect(CartController.instance.items.first.productTitle, 'MagSafe Magnetic Phone Mount');
      expect(CartController.instance.itemCount, 2);

      await tester.pumpWidget(
        const MaterialApp(
          home: CartPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap bottom bar Send Message
      final bottomSendButton = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.text('Send Message'),
      ).last;
      await tester.tap(bottomSendButton);
      await tester.pumpAndSettle();

      // Must navigate to ChatDetailScreen for the FIRST product's merchant (@AeroMount Studio)
      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('@AeroMount Studio'), findsWidgets);

      // Verify the active chat bubble contains prod2's image
      final aeroThread = InboxMessageManager.instance.getThreadByUsername('@AeroMount Studio');
      expect(aeroThread, isNotNull);
      expect(aeroThread!.messages.first.imageUrl, 'https://example.com/mount.jpg');

      // Cart should now be cleared
      expect(CartController.instance.itemCount, 0);
    });

    testWidgets('Tapping per-company Send Message clears only that company items from cart', (tester) async {
      await CartController.instance.clearCart();
      ShopRemoteDataSource.instance.clearLocalOrders();

      const prod1 = ProductModel(
        id: 801,
        title: 'Vilo Signature Canvas Tote Bag',
        description: 'Durable canvas tote',
        price: 24.99,
        stock: 50,
        rating: 4.8,
        reviewCount: 320,
        salesCount: 1200,
        images: ['assets/images/products/tote.png'],
        sellerName: 'Vilo Lifestyle',
      );
      const prod2 = ProductModel(
        id: 802,
        title: 'MagSafe Magnetic Phone Mount',
        description: 'Solid aluminum mount',
        price: 19.99,
        stock: 30,
        rating: 4.9,
        reviewCount: 150,
        salesCount: 650,
        images: ['https://example.com/mount.jpg'],
        sellerName: 'AeroMount Studio',
      );

      await CartController.instance.addToCart(prod1, quantity: 1);
      await CartController.instance.addToCart(prod2, quantity: 1);
      expect(CartController.instance.itemCount, 2);

      await tester.pumpWidget(
        const MaterialApp(
          home: CartPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Send Message button for Vilo Lifestyle
      final companySendBtn = find.text('Send Message').first;
      await tester.tap(companySendBtn);
      await tester.pumpAndSettle();

      // Tap the action button in the inquiry bottom sheet
      final sheetSendBtn = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Send Message'),
      );
      expect(sheetSendBtn, findsOneWidget);
      await tester.tap(sheetSendBtn);
      await tester.pumpAndSettle();

      // Should navigate to ChatDetailScreen for @Vilo Lifestyle
      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('@Vilo Lifestyle'), findsWidgets);

      // Vilo items removed, but AeroMount Studio item remains in cart!
      expect(CartController.instance.itemCount, 1);
      expect(CartController.instance.items.first.sellerName, 'AeroMount Studio');
    });

    testWidgets('CheckoutPage places order, clears cart, and records PAID order in My Orders', (tester) async {
      await CartController.instance.clearCart();
      ShopRemoteDataSource.instance.clearLocalOrders();

      const prod = ProductModel(
        id: 850,
        title: 'V-Watch Ultra Rugged Titanium Smartwatch',
        description: 'Titanium smartwatch',
        price: 89.90,
        stock: 20,
        rating: 4.9,
        reviewCount: 420,
        salesCount: 1500,
        images: ['assets/images/v_watch_ultra.jpg'],
        sellerName: 'Titan Monitoring',
      );

      await CartController.instance.addToCart(prod, quantity: 1);
      expect(CartController.instance.itemCount, 1);

      await tester.pumpWidget(
        const MaterialApp(
          home: CheckoutPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Place Order button
      final placeOrderButton = find.text('Place Order');
      expect(placeOrderButton, findsOneWidget);
      await tester.tap(placeOrderButton);
      await tester.pumpAndSettle();

      // Verify order success dialog appeared with PAID status
      expect(find.text('Order Placed!'), findsOneWidget);
      expect(find.text('Status: PAID'), findsOneWidget);

      // Verify cart is now cleared
      expect(CartController.instance.itemCount, 0);

      // Verify PAID order is recorded in ShopRemoteDataSource
      final orders = await ShopRemoteDataSource.instance.getOrderHistory();
      expect(orders.length, 1);
      expect(orders.first.status, 'PAID');
      expect(orders.first.items.first.productTitle, 'V-Watch Ultra Rugged Titanium Smartwatch');
    });

    testWidgets('OrderHistoryPage renders persisted orders with items and status', (tester) async {
      ShopRemoteDataSource.instance.clearLocalOrders();

      const prod = ProductModel(
        id: 901,
        title: 'Vilo Signature Canvas Tote Bag',
        description: 'Durable tote',
        price: 24.99,
        stock: 50,
        rating: 4.8,
        reviewCount: 300,
        salesCount: 1200,
        sellerName: 'Vilo Lifestyle',
        images: ['assets/images/products/tote.png'],
      );

      await CartController.instance.clearCart();
      await CartController.instance.addToCart(prod, quantity: 2);

      final order = ShopRemoteDataSource.instance.createOrderFromCartItems(
        sellerName: 'Vilo Lifestyle',
        items: CartController.instance.items,
      );
      ShopRemoteDataSource.instance.addOrder(order);

      await tester.pumpWidget(
        const MaterialApp(
          home: OrderHistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Vilo Signature Canvas Tote Bag'), findsOneWidget);
      expect(find.text('\$24.99 × 2'), findsOneWidget);
      expect(find.text('\$49.98'), findsWidgets);
    });
  });
}


