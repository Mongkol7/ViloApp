import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/inbox_activity/domain/entities/inbox_item.dart';
import 'package:viloapp/features/profile/presentation/widgets/shop_product_card.dart';
import 'package:viloapp/features/shop/models/product.dart';
import 'package:viloapp/features/shop/data/datasources/shop_remote_data_source.dart';
import 'package:viloapp/features/shop/data/models/order_model.dart';
import 'package:viloapp/features/shop/views/shop_feed_screen.dart';
import 'package:viloapp/features/shop/presentation/pages/cart_page.dart';

void main() {
  group('ShopProductCard Enhancements & Overflow Eradication Tests', () {
    testWidgets('renders without overflow on narrow width when out of stock with discount', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testProduct = Product(
        id: 'test-macbook-1',
        name: 'Mac Book Pro Super Retina XDR 16 Inch',
        categoryId: 'cat-tech',
        price: 1100.0,
        originalPrice: 1200.0,
        stock: 0,
        soldCount: 42,
        seller: '@other_seller',
        description: 'Mac Book laptop test item',
        imageUrl: '',
      );

      Product.deductStock('test-macbook-1', 10, initialStock: 0, productName: testProduct.name);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ShopProductCard(
                product: testProduct,
                sellerUsername: '@other_seller',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no layout overflow exception
      expect(tester.takeException(), isNull);

      // Verify sold count is rendered
      expect(find.textContaining('sold'), findsWidgets);

      // Verify out of stock badge is rendered
      expect(find.text('Out of Stock'), findsWidgets);

      // Verify other users cannot see three dots edit button
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);

      // Now verify that when viewing as product owner, three dots button is visible and layout has no overflow
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ShopProductCard(
                product: testProduct,
                sellerUsername: '@other_seller',
                isCurrentUser: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('three dots opens Edit Product modal and updates stock & title in real time', (tester) async {
      const testProduct = Product(
        id: 'test-edit-product-1',
        name: 'Test Gadget',
        categoryId: 'cat-tech',
        price: 99.0,
        originalPrice: 120.0,
        stock: 5,
        soldCount: 15,
        seller: '@other_seller',
        description: 'Test gadget description',
        imageUrl: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShopProductCard(
              product: testProduct,
              sellerUsername: '@mongkol',
              isCurrentUser: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap three dots button
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Modal bottom sheet should be open
      expect(find.text('Edit Product'), findsOneWidget);
      expect(find.text('Product Title'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Increase stock using '+' button in modal
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Effective stock should be updated to 6
      final updatedStock = Product.getEffectiveStock('test-edit-product-1', 5, productName: 'Test Gadget');
      expect(updatedStock, 6);
    });
  });

  group('Order Messages Countdown & Cancellation Tests', () {
    test('ChatMessage calculates 4-hour remaining cancellation countdown accurately', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final orderMessage = ChatMessage(
        id: 'order_1',
        text: 'Hi! I would like to order Mac Book (Price: \$1100.00/unit). Is it available to ship?',
        isMe: true,
        timestamp: 'Just now',
        isOrder: true,
        orderCreatedAtMs: now - (30 * 60 * 1000), // 30 minutes ago
        orderStatus: 'Active',
        orderProductId: 'test-prod-123',
        orderProductTitle: 'Mac Book',
        orderQuantity: 1,
      );

      expect(orderMessage.isOrderMessage, isTrue);
      expect(orderMessage.isCancelled, isFalse);
      expect(orderMessage.canCancel, isTrue);

      // Remaining seconds should be approximately 3.5 hours = 12600 seconds
      expect(orderMessage.cancelRemainingSeconds, inInclusiveRange(12590, 12600));
    });

    test('Normal message or message without order timestamp returns remaining 0 and cannot cancel', () {
      final normalMessage = ChatMessage(
        id: 'normal_1',
        text: 'Hello, how are you doing?',
        isMe: true,
        timestamp: '1 hour ago',
      );

      expect(normalMessage.isOrderMessage, isFalse);
      expect(normalMessage.orderCreatedAtMs, isNull);
      expect(normalMessage.cancelRemainingSeconds, 0);
      expect(normalMessage.canCancel, isFalse);
    });

    test('Expired order after 4 hours cannot be cancelled and returns 0 remaining seconds', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredOrder = ChatMessage(
        id: 'order_expired',
        text: 'Hi! I would like to order item',
        isMe: true,
        timestamp: '5 hours ago',
        isOrder: true,
        orderCreatedAtMs: now - (5 * 3600 * 1000), // 5 hours ago
        orderStatus: 'Active',
      );

      expect(expiredOrder.cancelRemainingSeconds, 0);
      expect(expiredOrder.canCancel, isFalse);
    });

    test('Order cancellation restores stock and deducts sold count in real time', () {
      const prodId = 'test-cancel-stock-1';
      const prodName = 'iPhone 18 Pro Max';

      // Initial state: stock 10, sold 0
      expect(Product.getEffectiveStock(prodId, 10, productName: prodName), 10);
      expect(Product.getEffectiveSoldCount(prodId, 0, productName: prodName), 0);

      // Order 2 units: stock becomes 8, sold becomes 2
      Product.deductStock(prodId, 2, initialStock: 10, productName: prodName);
      Product.incrementSoldCount(prodId, 2, initialSold: 0, productName: prodName);

      expect(Product.getEffectiveStock(prodId, 10, productName: prodName), 8);
      expect(Product.getEffectiveSoldCount(prodId, 0, productName: prodName), 2);

      // Cancellation: restore stock and deduct sold
      Product.restoreStock(prodId, 2, initialStock: 10, productName: prodName);
      Product.deductSoldCount(prodId, 2, initialSold: 2, productName: prodName);

      // State is fully restored
      expect(Product.getEffectiveStock(prodId, 10, productName: prodName), 10);
      expect(Product.getEffectiveSoldCount(prodId, 0, productName: prodName), 0);
    });

    test('Stock overwrite fix: Seller adds stock to 15, then buyer cancels 1 -> stock becomes 16, not 1', () {
      const prodId = 'test-seller-restock-item';
      const prodName = 'Seller Restocked Laptop';

      // 1. Initial product with 0 stock
      Product.deductStock(prodId, 10, initialStock: 0, productName: prodName);
      expect(Product.getEffectiveStock(prodId, 0, productName: prodName), 0);

      // 2. Seller edits product details and restocks to 15
      Product.updateProductDetails(prodId, name: prodName, stock: 15);
      expect(Product.getEffectiveStock(prodId, 0, productName: prodName), 15);

      // 3. Buyer cancels an order of 1 unit
      Product.restoreStock(prodId, 1, productName: prodName);

      // 4. Stock must now be 16 (15 + 1), NEVER overwritten to 1
      expect(Product.getEffectiveStock(prodId, 0, productName: prodName), 16);
    });
  });

  group('Order History Tests', () {
    test('Records chat order and updates status upon cancellation', () async {
      final remoteSource = ShopRemoteDataSource.instance;

      final recorded = remoteSource.recordChatOrder(
        productTitle: 'AirPods Max Titanium',
        price: 549.0,
        quantity: 1,
        imageUrl: '',
        sellerName: '@mongkol',
      );

      expect(recorded.status, 'PENDING');
      expect(recorded.totalAmount, 549.0);

      final orders = await remoteSource.getOrderHistory();
      expect(orders.any((o) => o.id == recorded.id), isTrue);

      // Update status to CANCELLED
      remoteSource.updateOrderStatus('AirPods Max Titanium', 'CANCELLED');

      final updatedOrders = await remoteSource.getOrderHistory();
      final updatedOrder = updatedOrders.firstWhere((o) => o.id == recorded.id);
      expect(updatedOrder.status, 'CANCELLED');
    });

    test('OrderModel dynamicStatus transitions correctly based on 4-hour window', () {
      final now = DateTime.now();

      final pendingOrder = OrderModel(
        id: 101,
        orderNumber: 'ORD-101',
        totalAmount: 1100.0,
        status: 'PENDING',
        paymentMethod: 'Cash on Delivery',
        createdAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
        shippingAddress: 'Phnom Penh',
      );
      expect(pendingOrder.dynamicStatus, 'PENDING');

      final successOrder = OrderModel(
        id: 102,
        orderNumber: 'ORD-102',
        totalAmount: 1100.0,
        status: 'PENDING',
        paymentMethod: 'Cash on Delivery',
        createdAt: now.subtract(const Duration(hours: 5)).toIso8601String(),
        shippingAddress: 'Phnom Penh',
      );
      expect(successOrder.dynamicStatus, 'SUCCESS');

      final cancelledOrder = OrderModel(
        id: 103,
        orderNumber: 'ORD-103',
        totalAmount: 1100.0,
        status: 'CANCELLED',
        paymentMethod: 'Cash on Delivery',
        createdAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
        shippingAddress: 'Phnom Penh',
      );
      expect(cancelledOrder.dynamicStatus, 'CANCELLED');
    });

    test('ChatMessage supports cancelledBy and cancellationTime in json serialization', () {
      final msg = ChatMessage(
        id: 'msg-cancel-1',
        text: 'Order Message',
        isMe: true,
        timestamp: '12:00 PM',
        status: 'Sent',
        isOrder: true,
        orderStatus: 'Cancelled',
        cancelledBy: 'Buyer',
        cancellationTime: '3:30 PM',
      );

      final json = msg.toJson();
      expect(json['cancelledBy'], 'Buyer');
      expect(json['cancellationTime'], '3:30 PM');

      final restored = ChatMessage.fromJson(json);
      expect(restored.cancelledBy, 'Buyer');
      expect(restored.cancellationTime, '3:30 PM');
      expect(restored.orderStatus, 'Cancelled');
    });
  });

  group('Cart & Shop Feed Overflow Layout Tests', () {
    testWidgets('CartPage renders without overflow on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: CartPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ShopFeedScreen renders Mega Sale banner without overflow on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(340, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopFeedScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Shop now'), findsOneWidget);
    });
  });
}
