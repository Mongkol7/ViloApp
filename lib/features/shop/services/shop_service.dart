import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/data/datasources/token_storage.dart';
import '../models/product.dart';

class ShopService {
  static final ShopService instance = ShopService();

  final ValueNotifier<Product?> publishedProductNotifier = ValueNotifier(null);
  final http.Client _client;
  final Future<String?> Function() _tokenProvider;
  String baseUrl;

  ShopService({
    http.Client? client,
    String? baseUrl,
    Future<String?> Function()? tokenProvider,
  })  : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider ?? TokenStorage.instance.getAccessToken,
        baseUrl = baseUrl ?? _defaultBaseUrl;

  static String get _defaultBaseUrl {
    // If running in Android emulator, use 10.0.2.2. Otherwise, use localhost.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1/products';
    }
    return 'http://localhost:3000/api/v1/products';
  }

  static const String _storageKey = 'vilo_user_added_products';

  /// Loads cached products from persistent SharedPreferences storage
  Future<void> _loadPersistentProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonString);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final p = Product.fromJson(item);
            Product.addCreatorProduct(p);
          }
        }
      }
    } catch (e) {
      debugPrint('[ShopService] Error loading persistent products: $e');
    }
  }

  /// Saves current local products to SharedPreferences
  Future<void> _savePersistentProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = Product.userAddedProducts.map((p) => p.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[ShopService] Error saving persistent products: $e');
    }
  }

  /// Fetches products from the backend with robust error handling and fallback mock data.
  Future<List<Product>> getProducts({String? category, String? query}) async {
    await _loadPersistentProducts();
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          'size': '100',
        },
      );

      final response = await _client
          .get(uri, headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          })
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> rawList = _extractProductList(decoded);

        if (rawList.isNotEmpty) {
          final remoteProducts = rawList
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList();

          final existingIds = remoteProducts.map((p) => p.id).toSet();
          final userProducts = Product.userAddedProducts
              .where((p) => !existingIds.contains(p.id))
              .toList();
          final mergedProducts = [...userProducts, ...remoteProducts];

          return _filterLocallyIfNeeded(mergedProducts, category: category, query: query);
        }
      }
      debugPrint('[ShopService] Non-200 or empty response (${response.statusCode}). Using fallback catalog.');
      return _getFallbackProducts(category: category, query: query);
    } catch (e) {
      debugPrint('[ShopService] Backend connection failed: $e. Using resilient mock catalog.');
      return _getFallbackProducts(category: category, query: query);
    }
  }

  /// Extracts the list of products from various Spring Boot JSON formats:
  /// - { "data": { "content": [...] } } (Spring Data Page)
  /// - { "data": [...] } (ApiResponse wrapper)
  /// - [ ... ] (Raw JSON Array)
  List<dynamic> _extractProductList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map<String, dynamic> && decoded['data']['content'] is List) {
        return decoded['data']['content'] as List<dynamic>;
      }
      if (decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
      if (decoded['content'] is List) {
        return decoded['content'] as List<dynamic>;
      }
    }
    return [];
  }

  /// Fetches top seller promotional items
  Future<List<Product>> getTopSellers() async {
    try {
      final topSellerUri = Uri.parse('$baseUrl/top-sellers');
      final response = await _client
          .get(topSellerUri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> rawList = _extractProductList(decoded);
        if (rawList.isNotEmpty) {
          return rawList
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Backend top-sellers unavailable, use curated screenshot top sellers
    }
    return Product.screenshotTopSellers;
  }

  /// Fetches single product details
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/$id'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = (decoded is Map<String, dynamic> && decoded['data'] != null)
            ? decoded['data']
            : decoded;
        if (data is Map<String, dynamic>) {
          return Product.fromJson(data);
        }
      }
    } catch (_) {
      // Return from fallback if available
    }

    final all = [
      ...Product.userAddedProducts,
      ...Product.screenshotFeedProducts,
      ...Product.screenshotTopSellers,
      ...Product.creatorProducts,
    ];
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Publishes a product to the server catalog with resilient local fallback.
  Future<Product> addProduct(Product product) async {
    try {
      final token = await _tokenProvider();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: headers,
            body: jsonEncode({
              'title': product.name,
              'description': product.description,
              'price': product.price,
              'originalPrice': product.originalPrice,
              'stock': product.stock,
              'categoryName': product.category ?? product.categoryId,
              'imageUrl': product.imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        final dynamic data =
            decoded is Map<String, dynamic> && decoded.containsKey('data')
                ? decoded['data']
                : decoded;
        if (data is Map<String, dynamic>) {
          final publishedProduct = Product.fromJson(data);
          Product.addCreatorProduct(publishedProduct);
          await _savePersistentProducts();
          publishedProductNotifier.value = publishedProduct;
          return publishedProduct;
        }
      } else {
        debugPrint(
          '[ShopService] Server returned ${response.statusCode}: ${response.body}. Using resilient catalog fallback.',
        );
      }
    } catch (e) {
      debugPrint('[ShopService] Remote addProduct failed ($e). Using resilient catalog fallback.');
    }

    // Always ensure product is added and live in creator catalog
    Product.addCreatorProduct(product);
    await _savePersistentProducts();
    publishedProductNotifier.value = product;
    return product;
  }

  /// Keeps a product available in the local offline catalog.
  void cacheProduct(Product product) {
    Product.addCreatorProduct(product);
  }

  /// Applies category and query filtering locally if needed
  List<Product> _filterLocallyIfNeeded(
    List<Product> products, {
    String? category,
    String? query,
  }) {
    var filtered = products;

    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      final selCat = category.toLowerCase().trim();
      filtered = filtered.where((p) {
        final pCat = (p.category ?? p.categoryId).toLowerCase().trim();
        final pCatId = p.categoryId.toLowerCase().trim();
        return pCat == selCat ||
            pCat.contains(selCat) ||
            selCat.contains(pCat) ||
            pCatId == selCat;
      }).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            (p.seller?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return filtered;
  }

  /// High-fidelity offline fallback catalog matching exact design screenshot
  List<Product> _getFallbackProducts({String? category, String? query}) {
    final List<Product> catalog = [
      ...Product.userAddedProducts,
      ...Product.screenshotFeedProducts,
      ...Product.creatorProducts,
    ];

    return _filterLocallyIfNeeded(catalog, category: category, query: query);
  }
}
