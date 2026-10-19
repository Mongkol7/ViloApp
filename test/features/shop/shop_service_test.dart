import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:viloapp/features/shop/services/shop_service.dart';

void main() {
  group('ShopService Network & Fallback Tests', () {
    test('getProducts decodes Spring Boot Page ApiResponse successfully', () async {
      final mockPayload = {
        'success': true,
        'message': 'Products retrieved',
        'data': {
          'content': [
            {
              'id': 101,
              'title': 'Spring Boot Wireless Earbuds',
              'description': 'Active noise cancelling wireless earbuds',
              'price': 49.99,
              'originalPrice': 99.99,
              'rating': 4.9,
              'salesCount': 1500,
              'category': {'id': 2, 'name': 'Tech & Gadgets'},
              'seller': {'displayName': 'AudioStore'},
              'images': ['https://example.com/earbuds.png'],
            }
          ]
        }
      };

      final client = MockClient((request) async {
        return http.Response(jsonEncode(mockPayload), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final service = ShopService(client: client, baseUrl: 'http://localhost:8080/api/products');
      final products = await service.getProducts();

      expect(products.length, 1);
      final p = products.first;
      expect(p.id, '101');
      expect(p.name, 'Spring Boot Wireless Earbuds');
      expect(p.price, 49.99);
      expect(p.originalPrice, 99.99);
      expect(p.rating, 4.9);
      expect(p.soldCount, 1500);
      expect(p.category, 'Tech & Gadgets');
      expect(p.seller, 'AudioStore');
      expect(p.imageUrl, 'https://example.com/earbuds.png');
    });

    test('getProducts gracefully falls back to mock catalog on connection error', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final service = ShopService(client: client, baseUrl: 'http://invalid-host:8080/api/products');
      final products = await service.getProducts();

      // Must not crash or return empty list; must provide high-fidelity catalog
      expect(products.isNotEmpty, true);
      expect(products.any((p) => p.name.contains('Flagship') || p.name.contains('Ring Light')), true);
    });

    test('getTopSellers returns 4 deals matching screenshot layout', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ShopService(client: client);
      final topSellers = await service.getTopSellers();

      expect(topSellers.length, 4);
      expect(topSellers[0].price, 1.01);
      expect(topSellers[0].badge, '-99%');
      expect(topSellers[0].seller, '@vilo_deals');
      expect(topSellers[1].price, 0.01);
    });

    test('Filtering by category Beauty returns correct serum', () async {
      final service = ShopService(
        client: MockClient((request) async => http.Response('Error', 500)),
      );

      final beautyProducts = await service.getProducts(category: 'Beauty');
      expect(beautyProducts.isNotEmpty, true);
      expect(beautyProducts.any((p) => p.name.contains('Hydration Serum')), true);
    });
  });
}
