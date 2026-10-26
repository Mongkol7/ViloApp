import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/shop/data/models/category_model.dart';
import 'package:viloapp/features/shop/data/models/product_model.dart';
import 'package:viloapp/features/shop/data/models/cart_item_model.dart';
import 'package:viloapp/features/shop/data/models/cart_model.dart';
import 'package:viloapp/features/shop/data/models/order_model.dart';

void main() {
  group('Sok Rithysak E-Commerce & Orders Module Tests', () {
    test('CategoryModel and ProductModel serialization and formatted getters', () {
      final categoryJson = {
        'id': 1,
        'name': 'Sneakers',
        'slug': 'sneakers',
        'iconUrl': 'https://example.com/icon.png',
      };
      final category = CategoryModel.fromJson(categoryJson);
      expect(category.id, 1);
      expect(category.name, 'Sneakers');

      final productJson = {
        'id': 101,
        'title': "Nike Air Force 1 '07 Pro",
        'description': 'Classic sneakers',
        'price': 129.99,
        'originalPrice': 189.99,
        'discountPercentage': 32,
        'stock': 150,
        'rating': 4.9,
        'reviewCount': 340,
        'salesCount': 1200,
        'category': categoryJson,
        'images': ['https://example.com/shoe1.png', 'https://example.com/shoe2.png'],
        'videoIds': [1, 2],
      };

      final product = ProductModel.fromJson(productJson);
      expect(product.id, 101);
      expect(product.title, "Nike Air Force 1 '07 Pro");
      expect(product.formattedPrice, '\$129.99');
      expect(product.formattedOriginalPrice, '\$189.99');
      expect(product.discountPercentage, 32);
      expect(product.primaryImage, 'https://example.com/shoe1.png');
      expect(product.videoIds, [1, 2]);
      expect(product.stock, 150);
    });

    test('CartItemModel and CartModel calculations', () {
      final item1Json = {
        'id': 10,
        'productId': 101,
        'productTitle': 'Sneakers',
        'productImage': 'https://example.com/shoe.png',
        'price': 120.0,
        'originalPrice': 150.0,
        'quantity': 2,
        'subtotal': 240.0,
        'stock': 50,
        'variant': 'Size 42',
      };

      final item1 = CartItemModel.fromJson(item1Json);
      expect(item1.formattedPrice, '\$120.00');
      expect(item1.formattedSubtotal, '\$240.00');
      expect(item1.quantity, 2);

      final cartJson = {
        'items': [item1Json],
        'itemCount': 2,
        'totalAmount': 240.0,
        'originalTotalAmount': 300.0,
        'totalSavings': 60.0,
      };

      final cart = CartModel.fromJson(cartJson);
      expect(cart.items.length, 1);
      expect(cart.itemCount, 2);
      expect(cart.formattedTotal, '\$240.00');
      expect(cart.formattedSavings, '\$60.00');
    });

    test('OrderModel serialization and status handling', () {
      final orderJson = {
        'id': 501,
        'orderNumber': 'ORD-20261019-AB12',
        'totalAmount': 240.0,
        'status': 'PAID',
        'shippingAddress': 'Street 271, Phnom Penh',
        'paymentMethod': 'KHQR_ABA',
        'notes': 'Please call before delivery',
        'items': [
          {
            'id': 1,
            'productId': 101,
            'productTitle': 'Sneakers',
            'productImageUrl': 'https://example.com/shoe.png',
            'price': 120.0,
            'quantity': 2,
            'subtotal': 240.0,
            'variant': 'Size 42',
          }
        ],
        'itemCount': 2,
        'createdAt': '2026-10-19T13:00:00Z',
      };

      final order = OrderModel.fromJson(orderJson);
      expect(order.orderNumber, 'ORD-20261019-AB12');
      expect(order.status, 'PAID');
      expect(order.formattedTotal, '\$240.00');
      expect(order.items.length, 1);
      expect(order.items.first.productTitle, 'Sneakers');
    });
  });
}
