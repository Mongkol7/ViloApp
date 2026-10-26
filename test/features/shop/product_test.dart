import 'package:flutter_test/flutter_test.dart';
import 'package:viloapp/features/shop/models/product.dart';

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
  });
}
