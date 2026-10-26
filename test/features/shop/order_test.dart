import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/shop/models/cart_item.dart';
import 'package:viloapp/features/shop/models/order.dart';
import 'package:viloapp/features/shop/models/product.dart';

void main() {
  group('ShopOrder Payload Structuring & Status Tracking Tests', () {
    final ringLight = Product(
      id: 'prod-001',
      name: 'Vilo Creator Ring Light Pro',
      categoryId: 'cat-studio',
      price: 34.99,
      description: 'Dimmable LED ring light',
      imageUrl: 'https://example.com/ringlight.png',
    );

    final hoodie = Product(
      id: 'prod-003',
      name: 'Obsidian Pulse Oversized Hoodie',
      categoryId: 'cat-apparel',
      price: 55.00,
      description: 'Heavyweight streetwear hoodie',
      imageUrl: 'https://example.com/hoodie.png',
    );

    test('ShopOrder.create structures payload and computes total automatically', () {
      final cartItems = [
        CartItem(product: ringLight, quantity: 2), // 34.99 * 2 = 69.98
        CartItem(product: hoodie, quantity: 1),    // 55.00 * 1 = 55.00
      ];

      final orderTime = DateTime(2026, 10, 19, 14, 0, 0);
      final order = ShopOrder.create(
        orderId: 'ORD-VILO-20261019-9941',
        items: cartItems,
        status: 'PENDING',
        createdAt: orderTime,
        shippingAddress: 'Street 271, Phnom Penh, Cambodia',
        paymentMethod: 'KHQR_ABA',
      );

      expect(order.orderId, 'ORD-VILO-20261019-9941');
      expect(order.status, 'PENDING');
      expect(order.totalItemCount, 3);
      expect(order.totalAmount, closeTo(124.98, 0.001));
      expect(order.formattedTotal, '\$124.98');
      expect(order.shippingAddress, 'Street 271, Phnom Penh, Cambodia');
      expect(order.paymentMethod, 'KHQR_ABA');
    });

    test('ShopOrder JSON serialization and deserialization integrity', () {
      final cartItems = [
        CartItem(product: ringLight, quantity: 1),
      ];

      final originalOrder = ShopOrder.create(
        orderId: 'ORD-7788',
        items: cartItems,
        status: 'PAID',
        createdAt: DateTime(2026, 10, 19, 12, 0, 0),
        shippingAddress: '123 Studio Way',
        paymentMethod: 'CARD',
      );

      final json = originalOrder.toJson();
      expect(json['orderId'], 'ORD-7788');
      expect(json['status'], 'PAID');
      expect(json['totalAmount'], closeTo(34.99, 0.001));
      expect(json['shippingAddress'], '123 Studio Way');
      expect(json['paymentMethod'], 'CARD');

      final reconstructed = ShopOrder.fromJson(json);
      expect(reconstructed.orderId, originalOrder.orderId);
      expect(reconstructed.status, originalOrder.status);
      expect(reconstructed.totalAmount, closeTo(originalOrder.totalAmount, 0.001));
      expect(reconstructed.shippingAddress, originalOrder.shippingAddress);
      expect(reconstructed.items.length, 1);
      expect(reconstructed.items.first.product.name, 'Vilo Creator Ring Light Pro');
    });

    test('ShopOrder status progression tracking', () {
      final order = ShopOrder.create(
        orderId: 'ORD-TRACK-01',
        items: [CartItem(product: ringLight, quantity: 1)],
        status: 'PENDING',
      );
      expect(order.status, 'PENDING');

      final paidOrder = order.copyWith(status: 'PAID');
      expect(paidOrder.status, 'PAID');

      final shippedOrder = paidOrder.copyWith(status: 'SHIPPED');
      expect(shippedOrder.status, 'SHIPPED');

      final deliveredOrder = shippedOrder.copyWith(status: 'DELIVERED');
      expect(deliveredOrder.status, 'DELIVERED');

      final cancelledOrder = order.copyWith(status: 'CANCELLED');
      expect(cancelledOrder.status, 'CANCELLED');
    });
  });
}
