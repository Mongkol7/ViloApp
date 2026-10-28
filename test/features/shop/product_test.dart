import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/shop/models/product.dart';
import 'package:viloapp/features/profile/presentation/widgets/shop_product_card.dart';
import 'package:viloapp/features/shop/presentation/controllers/cart_controller.dart';

void main() {
  group('Product Model & Creator Catalog Tests', () {
    test('Product JSON serialization and deserialization integrity', () {
      final product = Product(
        id: 'prod-test-01',
        name: 'Vilo Studio Pro Mic',
        categoryId: 'cat-audio',
        price: 49.99,
        description: 'Broadcast dynamic podcast microphone',
        imageUrl: 'https://example.com/mic.png',
      );

      final json = product.toJson();
      expect(json['id'], 'prod-test-01');
      expect(json['name'], 'Vilo Studio Pro Mic');
      expect(json['categoryId'], 'cat-audio');
      expect(json['price'], 49.99);
      expect(json['description'], 'Broadcast dynamic podcast microphone');
      expect(json['imageUrl'], 'https://example.com/mic.png');

      final reconstructed = Product.fromJson(json);
      expect(reconstructed.id, product.id);
      expect(reconstructed.name, product.name);
      expect(reconstructed.categoryId, product.categoryId);
      expect(reconstructed.price, product.price);
      expect(reconstructed.description, product.description);
      expect(reconstructed.imageUrl, product.imageUrl);
      expect(reconstructed.formattedPrice, '\$49.99');
    });

    test('Verify all 10 creator products data integrity and exact pricing', () {
      final catalog = Product.creatorProducts;
      expect(catalog.length, 10, reason: 'Must contain exactly 10 creator catalog products');

      // 1. Vilo Creator Ring Light Pro (Studio Equipment) – $34.99
      final p1 = catalog.firstWhere((p) => p.name == 'Vilo Creator Ring Light Pro');
      expect(p1.categoryId, 'cat-studio');
      expect(p1.price, 34.99);
      expect(p1.formattedPrice, '\$34.99');
      expect(p1.imageUrl.isNotEmpty, true);

      // 2. Wireless Lavalier Microphone (Audio & Tech) – $29.99
      final p2 = catalog.firstWhere((p) => p.name == 'Wireless Lavalier Microphone');
      expect(p2.categoryId, 'cat-audio');
      expect(p2.price, 29.99);
      expect(p2.formattedPrice, '\$29.99');

      // 3. Obsidian Pulse Oversized Hoodie (Apparel) – $55.00
      final p3 = catalog.firstWhere((p) => p.name == 'Obsidian Pulse Oversized Hoodie');
      expect(p3.categoryId, 'cat-apparel');
      expect(p3.price, 55.00);
      expect(p3.formattedPrice, '\$55.00');

      // 4. MagSafe Magnetic Desktop Phone Mount (Accessories) – $19.99
      final p4 = catalog.firstWhere((p) => p.name == 'MagSafe Magnetic Desktop Phone Mount');
      expect(p4.categoryId, 'cat-acc');
      expect(p4.price, 19.99);
      expect(p4.formattedPrice, '\$19.99');

      // 5. RGB Music-Sync Ambient Desk Light Bars (Studio Equipment) – $39.99
      final p5 = catalog.firstWhere((p) => p.name == 'RGB Music-Sync Ambient Desk Light Bars');
      expect(p5.categoryId, 'cat-studio');
      expect(p5.price, 39.99);
      expect(p5.formattedPrice, '\$39.99');

      // 6. Vilo Signature Canvas Tote Bag (Lifestyle) – $24.99
      final p6 = catalog.firstWhere((p) => p.name == 'Vilo Signature Canvas Tote Bag');
      expect(p6.categoryId, 'cat-life');
      expect(p6.price, 24.99);
      expect(p6.formattedPrice, '\$24.99');

      // 7. Flexible Octopus Tripod Stand (Accessories) – $15.99
      final p7 = catalog.firstWhere((p) => p.name == 'Flexible Octopus Tripod Stand');
      expect(p7.categoryId, 'cat-acc');
      expect(p7.price, 15.99);
      expect(p7.formattedPrice, '\$15.99');

      // 8. Minimalist Metal Phone Grip & Stand (Accessories) – $12.99
      final p8 = catalog.firstWhere((p) => p.name == 'Minimalist Metal Phone Grip & Stand');
      expect(p8.categoryId, 'cat-acc');
      expect(p8.price, 12.99);
      expect(p8.formattedPrice, '\$12.99');

      // 9. Portable LED Pocket Fill Light (Studio Equipment) – $22.99
      final p9 = catalog.firstWhere((p) => p.name == 'Portable LED Pocket Fill Light');
      expect(p9.categoryId, 'cat-studio');
      expect(p9.price, 22.99);
      expect(p9.formattedPrice, '\$22.99');

      // 10. Vilo Creator Vinyl Sticker Pack (Merchandise) – $8.99
      final p10 = catalog.firstWhere((p) => p.name == 'Vilo Creator Vinyl Sticker Pack');
      expect(p10.categoryId, 'cat-merch');
      expect(p10.price, 8.99);
      expect(p10.formattedPrice, '\$8.99');

      // Check round-trip serialization for all 10 products
      for (final p in catalog) {
        final serialized = p.toJson();
        final deserialized = Product.fromJson(serialized);
        expect(deserialized.id, p.id);
        expect(deserialized.name, p.name);
        expect(deserialized.price, p.price);
        expect(deserialized.categoryId, p.categoryId);
        expect(deserialized.description, p.description);
        expect(deserialized.imageUrl, p.imageUrl);
      }
    });

    test('Real-time stock deduction decrements stock and notifies listeners', () {
      Product.resetStockOverrides();
      final product = Product(
        id: 'stock-test-01',
        name: 'Test Mechanical Keyboard',
        categoryId: 'cat-tech',
        price: 99.0,
        stock: 5,
        description: 'Test keyboard',
        imageUrl: 'https://example.com/kb.png',
      );

      expect(Product.getEffectiveStock(product.id, product.stock), 5);
      expect(product.isOutOfStock, isFalse);

      int notifyCount = 0;
      void listener() => notifyCount++;
      Product.stockUpdateNotifier.addListener(listener);

      // Deduct 2 units
      Product.deductStock(product.id, 2, initialStock: product.stock);
      expect(Product.getEffectiveStock(product.id, product.stock), 3);
      expect(notifyCount, 1);
      expect(product.isOutOfStock, isFalse);

      // Deduct remaining 3 units -> drops to 0
      Product.deductStock(product.id, 3, initialStock: product.stock);
      expect(Product.getEffectiveStock(product.id, product.stock), 0);
      expect(notifyCount, 2);
      expect(product.isOutOfStock, isTrue);

      Product.stockUpdateNotifier.removeListener(listener);
      Product.resetStockOverrides();
    });

    testWidgets('ShopProductCard renders stock badge and displays Out of Stock tag when stock reaches 0', (tester) async {
      Product.resetStockOverrides();
      final product = Product(
        id: 'stock-card-01',
        name: 'Mechanical Gaming Keyboard',
        categoryId: 'cat-tech',
        price: 150.0,
        stock: 2,
        description: 'RGB mechanical switches',
        imageUrl: 'https://example.com/kb.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShopProductCard(
              product: product,
              sellerUsername: 'mongkol',
            ),
          ),
        ),
      );

      // Should show '2 in stock' initially
      expect(find.text('2 in stock'), findsOneWidget);
      expect(find.text('Out of Stock'), findsNothing);

      // Deduct all stock in real-time
      Product.deductStock(product.id, 2, initialStock: product.stock);
      await tester.pump();

      // Card must reactively update without full rebuild of parent
      expect(find.text('0 in stock'), findsOneWidget);
      expect(find.text('Out of Stock'), findsWidgets);
      expect(find.text('OUT OF STOCK'), findsOneWidget);

      Product.resetStockOverrides();
    });

    testWidgets('Adding product to cart deducts stock in real time and removing restores stock', (tester) async {
      Product.resetStockOverrides();
      final product = Product(
        id: 'cart-stock-01',
        name: '4K Creator Camera',
        categoryId: 'cat-tech',
        price: 899.0,
        stock: 5,
        description: 'Vlog camera',
        imageUrl: 'https://example.com/cam.png',
      );

      expect(Product.getEffectiveStock(product.id, product.stock), 5);

      // 1. Add to cart -> stock deducts in real time immediately
      await CartController.instance.addProduct(product, quantity: 2);
      expect(Product.getEffectiveStock(product.id, product.stock), 3);

      // 2. Add 1 more of same product -> stock deducts to 2
      await CartController.instance.addProduct(product, quantity: 1);
      expect(Product.getEffectiveStock(product.id, product.stock), 2);

      // 3. Clear cart with restoreStock -> stock returns to 5
      await CartController.instance.clearCart(restoreStock: true);
      expect(Product.getEffectiveStock(product.id, product.stock), 5);

      Product.resetStockOverrides();
    });

    testWidgets('Tapping Send Message in ShopProductCard deducts stock in real time', (tester) async {
      Product.resetStockOverrides();
      final product = Product(
        id: 'msg-stock-01',
        name: 'Studio Wireless Headphones',
        categoryId: 'cat-audio',
        price: 199.0,
        stock: 3,
        description: 'Noise cancelling',
        imageUrl: 'https://example.com/hp.png',
        seller: 'audio_pro',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShopProductCard(
              product: product,
              sellerUsername: 'audio_pro',
            ),
          ),
        ),
      );

      expect(find.text('3 in stock'), findsOneWidget);
      expect(find.text('Send Message'), findsOneWidget);

      // Tap Send Message
      await tester.tap(find.text('Send Message'));
      await tester.pump();

      // Stock must be deducted from 3 to 2 in real time!
      expect(Product.getEffectiveStock(product.id, product.stock), 2);
      expect(find.text('2 in stock'), findsOneWidget);

      Product.resetStockOverrides();
    });
  });
}
