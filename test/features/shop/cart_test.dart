import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/shop/models/cart_item.dart';
import 'package:viloapp/features/shop/models/product.dart';

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
}
