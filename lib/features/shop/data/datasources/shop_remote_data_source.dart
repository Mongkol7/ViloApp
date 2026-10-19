import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

class ShopRemoteDataSource {
  static ShopRemoteDataSource? _instance;
  static ShopRemoteDataSource get instance => _instance ??= ShopRemoteDataSource._();

  final ApiClient _client;

  ShopRemoteDataSource._([ApiClient? client]) : _client = client ?? ApiClient.instance;

  Future<List<CategoryModel>> getCategories() async {
    try {
      final data = await _client.get('/categories', requireAuth: false);
      if (data is List) {
        return data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<ProductModel>> getProducts({
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? query,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String>[
        'page=$page',
        'size=$size',
      ];
      if (categoryId != null) queryParams.add('categoryId=$categoryId');
      if (minPrice != null) queryParams.add('minPrice=$minPrice');
      if (maxPrice != null) queryParams.add('maxPrice=$maxPrice');
      if (query != null && query.trim().isNotEmpty) {
        queryParams.add('query=${Uri.encodeComponent(query.trim())}');
      }

      final endpoint = '/products?${queryParams.join('&')}';
      final data = await _client.get(endpoint, requireAuth: false);

      List rawList = [];
      if (data is Map && data['content'] is List) {
        rawList = data['content'] as List;
      } else if (data is List) {
        rawList = data;
      }

      return rawList.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ProductModel> getProductById(int id) async {
    final data = await _client.get('/products/$id', requireAuth: false);
    return ProductModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ProductModel>> getProductsByVideo(int videoId) async {
    try {
      final data = await _client.get('/products/by-video/$videoId', requireAuth: false);
      if (data is List) {
        return data.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<ProductModel>> getProductsBySeller(int sellerId) async {
    try {
      final data = await _client.get('/products/by-seller/$sellerId', requireAuth: false);
      if (data is List) {
        return data.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<CartModel> getCart() async {
    try {
      final data = await _client.get('/cart', requireAuth: true);
      if (data is Map<String, dynamic>) {
        return CartModel.fromJson(data);
      }
      return const CartModel();
    } catch (_) {
      return const CartModel();
    }
  }

  Future<CartItemModel> addToCart({
    required int productId,
    int quantity = 1,
    String? variant,
  }) async {
    final body = <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
      'variant': ?variant,
    };
    final data = await _client.post('/cart/items', body: body, requireAuth: true);
    return CartItemModel.fromJson(data as Map<String, dynamic>);
  }

  Future<CartItemModel?> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    final data = await _client.put(
      '/cart/items/$itemId',
      body: {'quantity': quantity},
      requireAuth: true,
    );
    if (data is Map<String, dynamic>) {
      return CartItemModel.fromJson(data);
    }
    return null;
  }

  Future<void> removeCartItem(int itemId) async {
    await _client.delete('/cart/items/$itemId', requireAuth: true);
  }

  Future<void> clearCart() async {
    await _client.delete('/cart', requireAuth: true);
  }

  Future<OrderModel> checkout({
    required String shippingAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    final body = {
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final data = await _client.post('/orders/checkout', body: body, requireAuth: true);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<OrderModel>> getOrderHistory() async {
    try {
      final data = await _client.get('/orders/history', requireAuth: true);
      if (data is List) {
        return data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<OrderModel> getOrderById(int orderId) async {
    final data = await _client.get('/orders/$orderId', requireAuth: true);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }
}
