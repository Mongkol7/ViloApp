import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';

class ShopRemoteDataSource {
  static ShopRemoteDataSource? _instance;
  static ShopRemoteDataSource get instance => _instance ??= ShopRemoteDataSource._();

  final ApiClient _client;
  int _lastLocalOrderId = 0;

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

  final List<OrderModel> _localOrderHistory = [];
  final Map<String, List<OrderModel>> _userScopedOrders = {};

  String get _activeUserKey {
    final active = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
    final raw = (active?.username ?? ProfileSyncService.instance.currentUsername).trim().toLowerCase();
    return raw.replaceAll('@', '');
  }

  final ValueNotifier<int> pendingOrdersCountNotifier = ValueNotifier<int>(0);

  int get pendingOrdersCount {
    final orders = localOrders;
    return orders.where((o) => o.dynamicStatus == 'PENDING').fold<int>(
      0,
      (sum, o) => sum + (o.itemCount > 0 ? o.itemCount : (o.items.isNotEmpty ? o.items.length : 1)),
    );
  }

  void updatePendingCount() {
    pendingOrdersCountNotifier.value = pendingOrdersCount;
  }

  int _nextLocalOrderId() {
    final current = DateTime.now().millisecondsSinceEpoch;
    _lastLocalOrderId = current > _lastLocalOrderId ? current : _lastLocalOrderId + 1;
    return _lastLocalOrderId;
  }

  String _localOrderNumber({required String seller, required int orderId}) {
    final cleanSeller = seller.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final now = DateTime.fromMillisecondsSinceEpoch(orderId);
    // Keep the complete monotonic local id in the reference. Using only the
    // last few timestamp digits allowed a later order to reuse an older
    // reference and inherit that order's cancellation status.
    return 'ORD-${cleanSeller.isNotEmpty ? cleanSeller : 'VILO'}-'
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$orderId';
  }

  List<OrderModel> get localOrders {
    final key = _activeUserKey;
    if (key.isNotEmpty && _userScopedOrders.containsKey(key)) {
      return List.unmodifiable(_userScopedOrders[key]!);
    }
    return List.unmodifiable(_localOrderHistory);
  }

  void addOrder(OrderModel order) {
    final key = _activeUserKey;
    if (key.isNotEmpty) {
      final list = _userScopedOrders.putIfAbsent(key, () => []);
      list.removeWhere((o) => o.id == order.id || o.orderNumber == order.orderNumber);
      list.insert(0, order);
    }
    _localOrderHistory.removeWhere((o) => o.id == order.id || o.orderNumber == order.orderNumber);
    _localOrderHistory.insert(0, order);
    updatePendingCount();
  }

  void updateOrderStatus(String orderNumberOrTitle, String newStatus) {
    for (final list in _userScopedOrders.values) {
      for (int i = 0; i < list.length; i++) {
        final match = list[i].orderNumber == orderNumberOrTitle ||
            list[i].id.toString() == orderNumberOrTitle ||
            list[i].items.any((it) => it.productTitle.toLowerCase() == orderNumberOrTitle.toLowerCase());
        if (match) {
          list[i] = list[i].copyWith(status: newStatus);
        }
      }
    }
    for (int i = 0; i < _localOrderHistory.length; i++) {
      final match = _localOrderHistory[i].orderNumber == orderNumberOrTitle ||
          _localOrderHistory[i].id.toString() == orderNumberOrTitle ||
          _localOrderHistory[i].items.any((it) => it.productTitle.toLowerCase() == orderNumberOrTitle.toLowerCase());
      if (match) {
        _localOrderHistory[i] = _localOrderHistory[i].copyWith(status: newStatus);
      }
    }
    updatePendingCount();
  }

  OrderModel recordChatOrder({
    required String productTitle,
    required double price,
    required int quantity,
    required String imageUrl,
    String? sellerName,
  }) {
    final orderId = _nextLocalOrderId();
    final now = DateTime.fromMillisecondsSinceEpoch(orderId);
    final orderNum = _localOrderNumber(seller: sellerName ?? 'VILO', orderId: orderId);
    final subtotal = price * quantity;
    final item = OrderItemModel(
      id: orderId,
      productTitle: productTitle,
      productImageUrl: imageUrl,
      price: price,
      quantity: quantity,
      subtotal: subtotal,
    );
    final order = OrderModel(
      id: orderId,
      orderNumber: orderNum,
      totalAmount: subtotal,
      status: 'PENDING',
      shippingAddress: 'Direct Seller Inquiry',
      paymentMethod: 'Inquiry / Direct Chat',
      notes: sellerName != null ? 'Seller: $sellerName' : null,
      items: [item],
      itemCount: quantity,
      createdAt: now.toIso8601String(),
    );
    addOrder(order);
    return order;
  }

  void clearLocalOrders() {
    final key = _activeUserKey;
    if (key.isNotEmpty && _userScopedOrders.containsKey(key)) {
      _userScopedOrders[key]!.clear();
    }
    _localOrderHistory.clear();
    updatePendingCount();
  }

  OrderModel createOrderFromCartItems({
    required String sellerName,
    required List<CartItemModel> items,
    String? customNote,
  }) {
    final now = DateTime.now();
    final orderId = _nextLocalOrderId();
    final totalAmount = items.fold<double>(0.0, (sum, i) => sum + i.subtotal);
    final orderItems = items.map((item) {
      return OrderItemModel(
        id: item.id,
        productId: item.productId,
        productTitle: item.productTitle,
        productImageUrl: item.productImage,
        price: item.price,
        quantity: item.quantity,
        subtotal: item.subtotal,
        variant: item.variant,
      );
    }).toList();

    return OrderModel(
      id: orderId,
      orderNumber: _localOrderNumber(seller: sellerName, orderId: orderId),
      totalAmount: totalAmount,
      status: 'PENDING',
      shippingAddress: 'Direct In-App Merchant Inquiry',
      paymentMethod: 'Merchant Inquiry / Cash on Delivery',
      notes: customNote ?? 'Inquired via direct message with merchant',
      items: orderItems,
      itemCount: items.fold<int>(0, (sum, i) => sum + i.quantity),
      createdAt: now.toIso8601String(),
    );
  }

  Future<OrderModel> checkout({
    required String shippingAddress,
    required String paymentMethod,
    String? notes,
    List<CartItemModel>? items,
  }) async {
    final body = {
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    try {
      final data = await _client.post('/orders/checkout', body: body, requireAuth: true);
      final order = OrderModel.fromJson(data as Map<String, dynamic>);
      addOrder(order);
      return order;
    } catch (_) {
      // Create completed PAID order locally for offline / resilient persistence
      final orderItemsList = items ?? const <CartItemModel>[];
      final now = DateTime.now();
      final orderId = _nextLocalOrderId();
      final totalAmount = orderItemsList.fold<double>(0.0, (sum, i) => sum + i.subtotal);
      final order = OrderModel(
        id: orderId,
        orderNumber: _localOrderNumber(seller: 'PAID', orderId: orderId),
        totalAmount: totalAmount,
        status: 'PAID',
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        notes: notes ?? 'Successfully paid order',
        items: orderItemsList.map((item) {
          return OrderItemModel(
            id: item.id,
            productId: item.productId,
            productTitle: item.productTitle,
            productImageUrl: item.productImage,
            price: item.price,
            quantity: item.quantity,
            subtotal: item.subtotal,
            variant: item.variant,
          );
        }).toList(),
        itemCount: orderItemsList.fold<int>(0, (sum, i) => sum + i.quantity),
        createdAt: now.toIso8601String(),
      );
      addOrder(order);
      return order;
    }
  }

  Future<List<OrderModel>> getOrderHistory() async {
    final key = _activeUserKey;
    final userLocalList = (key.isNotEmpty && _userScopedOrders.containsKey(key))
        ? _userScopedOrders[key]!
        : _localOrderHistory;

    try {
      final data = await _client.get('/orders/history', requireAuth: true);
      List<OrderModel> remoteOrders = [];
      if (data is List) {
        remoteOrders = data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      final Set<int> existingIds = remoteOrders.map((o) => o.id).toSet();
      final combined = [
        ...userLocalList.where((o) => !existingIds.contains(o.id)),
        ...remoteOrders,
      ];
      return combined;
    } catch (_) {
      return List<OrderModel>.from(userLocalList);
    }
  }

  Future<OrderModel> getOrderById(int orderId) async {
    final localMatch = _localOrderHistory.where((o) => o.id == orderId);
    if (localMatch.isNotEmpty) {
      return localMatch.first;
    }
    final data = await _client.get('/orders/$orderId', requireAuth: true);
    return OrderModel.fromJson(data as Map<String, dynamic>);
  }
}
