import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ShopService {
  static final ShopService instance = ShopService();

  final http.Client _client;
  String baseUrl;

  ShopService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  static String get _defaultBaseUrl {
    // If running in Android emulator, use 10.0.2.2. Otherwise, use localhost.
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/products';
    }
    return 'http://localhost:8080/api/products';
  }

  /// Fetches products from the backend with robust error handling and fallback mock data.
  Future<List<Product>> getProducts({String? category, String? query}) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          if (category != null && category.isNotEmpty && category.toLowerCase() != 'all')
            'category': category,
          if (query != null && query.isNotEmpty) 'query': query,
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
          final products = rawList
              .map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList();

          return _filterLocallyIfNeeded(products, category: category, query: query);
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

  /// Adds a product listed by a creator/merchant to the active local catalog
  void addProduct(Product product) {
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
      filtered = filtered.where((p) {
        final pCat = (p.category ?? p.categoryId).toLowerCase();
        return pCat.contains(category.toLowerCase());
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
