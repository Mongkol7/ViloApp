import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viloapp/features/bottom_nav/presentation/widgets/vilo_floating_bottom_bar.dart';
import 'package:viloapp/features/shop/models/product.dart';
import 'package:viloapp/features/shop/presentation/pages/add_product_screen.dart';
import 'package:viloapp/features/shop/services/shop_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Product.clearUserAddedProducts();
  });

  tearDown(() {
    Product.clearUserAddedProducts();
  });

  group('AddProductScreen Widget & Form Validation Tests', () {
    testWidgets('renders all required form controls, chips, and image URL input field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddProductScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sell Product'), findsOneWidget);
      expect(find.text('List New Product to Sell'), findsOneWidget);
      expect(find.text('Product Title *'), findsOneWidget);
      expect(find.text('Category *'), findsOneWidget);
      expect(find.text('Price (\$) *'), findsOneWidget);
      expect(find.text('Original Price (\$)'), findsOneWidget);
      expect(find.text('Stock Quantity *'), findsOneWidget);
      expect(find.text('Seller Name *'), findsOneWidget);
      expect(find.text('Product Image *'), findsOneWidget);
      expect(find.byKey(const Key('add_product_image_url_field')), findsOneWidget);
      expect(find.text('Product Description *'), findsOneWidget);
      expect(find.text('Publish Product to Sell'), findsOneWidget);

      // Verify category chips exist
      expect(find.text('Tech & Gadgets'), findsOneWidget);
      expect(find.text('Fashion & Apparel'), findsOneWidget);
      expect(find.text('Beauty & Care'), findsOneWidget);
    });

    testWidgets('triggers validation errors when required fields are empty or invalid', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AddProductScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap publish without filling title or price or image URL
      final publishBtn = find.byKey(const Key('add_product_publish_btn'));
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      expect(find.text('Product title is required'), findsOneWidget);
      expect(find.text('Price required'), findsOneWidget);
      expect(find.text('Product image URL is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);

      // Verify no product was added
      expect(Product.userAddedProducts.isEmpty, true);
    });

    testWidgets('successfully validates, creates Product, adds to ShopService, and pops screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Product? returnedProduct;
      const productResponse = {
        'id': 7001,
        'title': 'Obsidian Wireless Earbuds Pro',
        'description': 'High resolution spatial audio',
        'price': 89.5,
        'stock': 10,
        'rating': 0,
        'reviewCount': 0,
        'salesCount': 0,
        'category': {'id': 2, 'name': 'Tech & Gadgets'},
        'seller': {'displayName': '@ViloCreator'},
        'images': ['assets/images/v_watch_ultra.jpg'],
      };
      final shopService = ShopService(
        baseUrl: 'http://localhost:3000/api/v1/products',
        tokenProvider: () async => 'test-token',
        client: MockClient((request) async {
          if (request.method == 'POST') {
            expect(request.headers['Authorization'], 'Bearer test-token');
            final postedProduct = jsonDecode(request.body) as Map<String, dynamic>;
            expect(postedProduct['categoryName'], 'Tech & Gadgets');
            expect(postedProduct['stock'], 10);
            return http.Response(
              jsonEncode({'success': true, 'data': productResponse}),
              201,
            );
          }
          if (request.url.path.endsWith('/7001')) {
            return http.Response(
              jsonEncode({'success': true, 'data': productResponse}),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'content': [productResponse]},
            }),
            200,
          );
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  returnedProduct = await Navigator.push<Product>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(shopService: shopService),
                    ),
                  );
                },
                child: const Text('Open Sell Page'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open screen
      await tester.tap(find.text('Open Sell Page'));
      await tester.pumpAndSettle();

      expect(find.text('Sell Product'), findsOneWidget);

      // Fill in required fields
      final titleField = find.byKey(const Key('add_product_title_field'));
      await tester.ensureVisible(titleField);
      await tester.enterText(
        titleField,
        'Obsidian Wireless Earbuds Pro',
      );

      // Price
      final priceField = find.byKey(const Key('add_product_price_field'));
      await tester.ensureVisible(priceField);
      await tester.enterText(
        priceField,
        '89.50',
      );

      // Image URL
      final imageField = find.byKey(const Key('add_product_image_url_field'));
      await tester.ensureVisible(imageField);
      await tester.enterText(
        imageField,
        'assets/images/v_watch_ultra.jpg',
      );

      // Description
      final descField = find.byKey(const Key('add_product_desc_field'));
      await tester.ensureVisible(descField);
      await tester.enterText(
        descField,
        'High resolution spatial audio with active noise cancellation and 30hr battery life.',
      );

      // Tap Publish
      final publishBtn = find.byKey(const Key('add_product_publish_btn'));
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      // Verify returned product
      expect(returnedProduct, isNotNull);
      expect(returnedProduct!.name, 'Obsidian Wireless Earbuds Pro');
      expect(returnedProduct!.price, 89.50);
      expect(returnedProduct!.category, 'Tech & Gadgets');
      expect(returnedProduct!.seller, '@ViloCreator');
      expect(returnedProduct!.id, '7001');
      expect(returnedProduct!.stock, 10);
      expect(returnedProduct!.imageUrl, 'assets/images/v_watch_ultra.jpg');

      // Verify added to ShopService catalog
      final products = await shopService.getProducts();
      expect(products.any((p) => p.name == 'Obsidian Wireless Earbuds Pro'), true);

      // Verify lookup by id
      final lookedUp = await shopService.getProductById(returnedProduct!.id);
      expect(lookedUp, isNotNull);
      expect(lookedUp!.name, 'Obsidian Wireless Earbuds Pro');
    });

    testWidgets('tapping plus button in ViloFloatingBottomBar invokes onAddPressed and opens AddProductScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              bottomNavigationBar: ViloFloatingBottomBar(
                currentIndex: 0,
                onTabSelected: (_) {},
                onAddPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddProductScreen()),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final addBtn = find.byIcon(Icons.add);
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AddProductScreen), findsOneWidget);
      expect(find.text('Sell Product'), findsOneWidget);
    });
  });
}
