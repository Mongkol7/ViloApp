import 'package:flutter/foundation.dart';
import '../../data/datasources/shop_remote_data_source.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/product_model.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';

class CartController extends ChangeNotifier {
  static CartController? _instance;
  static CartController get instance => _instance ??= CartController._();

  final ShopRemoteDataSource _dataSource;
  final List<CartItemModel> _inMemoryItems = [];

  CartModel _cart = const CartModel();
  bool _isLoading = false;
  String? _errorMessage;

  CartController._([ShopRemoteDataSource? dataSource])
      : _dataSource = dataSource ?? ShopRemoteDataSource.instance {
    loadCart();
  }

  @visibleForTesting
  CartController.forTesting([ShopRemoteDataSource? dataSource])
      : _dataSource = dataSource ?? ShopRemoteDataSource.instance;

  @visibleForTesting
  static void setMockInstance(CartController mock) {
    _instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  CartModel get cart => _cart;
  List<CartItemModel> get items => _cart.items;
  int get itemCount => _cart.itemCount;
  double get totalAmount => _cart.totalAmount;
  double get totalSavings => _cart.totalSavings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _recalculateCart() {
    final totalCount = _inMemoryItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalAmount = _inMemoryItems.fold<double>(0.0, (sum, item) => sum + item.subtotal);
    final originalTotal = _inMemoryItems.fold<double>(
      0.0,
      (sum, item) => sum + ((item.originalPrice ?? item.price) * item.quantity),
    );
    final totalSavings = (originalTotal > totalAmount) ? (originalTotal - totalAmount) : 0.0;

    _cart = CartModel(
      items: List.unmodifiable(_inMemoryItems),
      itemCount: totalCount,
      totalAmount: totalAmount,
      originalTotalAmount: originalTotal,
      totalSavings: totalSavings,
    );
  }

  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteCart = await _dataSource.getCart();
      if (remoteCart.items.isNotEmpty) {
        _inMemoryItems.clear();
        _inMemoryItems.addAll(remoteCart.items);
        _cart = remoteCart;
      } else if (_inMemoryItems.isNotEmpty) {
        _recalculateCart();
      } else {
        _cart = remoteCart;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (_inMemoryItems.isNotEmpty) {
        _recalculateCart();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(ProductModel product, {int quantity = 1, String? variant, String? productStringId}) async {
    if (quantity <= 0) return false;

    final effectiveStock = Product.getEffectiveStock(
      product.id.toString(),
      product.stock,
    );
    if (effectiveStock <= 0) return false;

    final targetId = productStringId ?? product.id.toString();

    // 1. Optimistically update local in-memory cart
    final existingIndex = _inMemoryItems.indexWhere(
      (item) => item.productId == product.id && item.variant == variant,
    );

    int actualAddedQty = 0;
    if (existingIndex >= 0) {
      final existing = _inMemoryItems[existingIndex];
      if (effectiveStock <= 0) return false;
      final newQuantity = existing.quantity + quantity;
      actualAddedQty = quantity;
      _inMemoryItems[existingIndex] = CartItemModel(
        id: existing.id,
        productId: existing.productId,
        productStringId: existing.productStringId ?? targetId,
        productTitle: existing.productTitle,
        productImage: existing.productImage,
        price: existing.price,
        originalPrice: existing.originalPrice,
        quantity: newQuantity,
        subtotal: existing.price * newQuantity,
        stock: effectiveStock,
        variant: existing.variant,
        createdAt: existing.createdAt,
        sellerName: existing.sellerName ?? product.sellerName,
        sellerUsername: existing.sellerUsername ?? product.sellerUsername ?? product.sellerName,
        sellerAvatar: existing.sellerAvatar ?? product.sellerAvatar,
        sellerId: existing.sellerId ?? product.sellerId,
      );
    } else {
      final img = product.images.isNotEmpty ? product.images.first : product.primaryImage;
      final clampedQty = quantity;
      actualAddedQty = clampedQty;
      final newItem = CartItemModel(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + _inMemoryItems.length,
        productId: product.id,
        productStringId: targetId,
        productTitle: product.title,
        productImage: img,
        price: product.price,
        originalPrice: product.originalPrice,
        quantity: clampedQty,
        subtotal: product.price * clampedQty,
        stock: effectiveStock,
        variant: variant,
        createdAt: DateTime.now().toIso8601String(),
        sellerName: product.sellerName ?? 'TechHorizon Global',
        sellerUsername: product.sellerUsername ?? product.sellerName,
        sellerAvatar: product.sellerAvatar,
        sellerId: product.sellerId,
      );
      _inMemoryItems.add(newItem);
    }

    // Deduct stock in real time upon adding product to cart
    if (actualAddedQty > 0) {
      Product.deductStock(
        targetId,
        actualAddedQty,
        initialStock: product.stock,
        productName: product.title,
      );
    }

    _recalculateCart();
    notifyListeners();

    // 2. Also sync to legacy CartManager
    try {
      CartManager.instance.addItem(
        Product(
          id: product.id.toString(),
          name: product.title,
          categoryId: product.category?.id.toString() ?? '1',
          price: product.price,
          originalPrice: product.originalPrice,
          rating: product.rating,
          soldCount: product.salesCount,
          description: product.description,
          imageUrl: product.primaryImage,
          seller: product.sellerUsername ?? product.sellerName,
          sellerAvatar: product.sellerAvatar,
          sellerId: product.sellerId?.toString(),
          stock: product.stock,
        ),
        quantity,
      );
    } catch (_) {}

    // 3. Asynchronously attempt remote sync
    try {
      await _dataSource.addToCart(
        productId: product.id,
        quantity: quantity,
        variant: variant,
      );
    } catch (e) {
      debugPrint('Cart remote sync deferred (offline/guest): $e');
    }

    return true;
  }

  Future<bool> addProduct(Product product, {int quantity = 1, String? variant}) async {
    final int prodId = int.tryParse(product.id) ?? product.id.hashCode.abs();
    final model = ProductModel(
      id: prodId,
      title: product.name,
      description: product.description,
      price: product.price,
      originalPrice: product.originalPrice,
      stock: product.stock,
      rating: product.rating,
      reviewCount: 100,
      salesCount: product.soldCount,
      sellerName: product.seller ?? 'TechHorizon Global',
      sellerUsername: product.seller,
      sellerAvatar: product.sellerAvatar,
      images: [product.imageUrl],
    );
    return addToCart(model, quantity: quantity, variant: variant, productStringId: product.id);
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(itemId);
      return;
    }

    final index = _inMemoryItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final existing = _inMemoryItems[index];
      final targetId = existing.productStringId ?? existing.productId.toString();
      final effectiveStock = Product.getEffectiveStock(
        targetId,
        existing.stock,
        productName: existing.productTitle,
      );

      // Adjust stock in real time when quantity changes
      if (quantity > existing.quantity) {
        final diff = quantity - existing.quantity;
        if (effectiveStock < diff && effectiveStock > 0) {
          quantity = existing.quantity + effectiveStock;
        }
        final actualDeduct = quantity - existing.quantity;
        if (actualDeduct > 0) {
          Product.deductStock(
            targetId,
            actualDeduct,
            initialStock: existing.stock,
            productName: existing.productTitle,
          );
        }
      } else if (quantity < existing.quantity) {
        final diff = existing.quantity - quantity;
        Product.restoreStock(
          targetId,
          diff,
          initialStock: existing.stock,
          productName: existing.productTitle,
        );
      }

      _inMemoryItems[index] = CartItemModel(
        id: existing.id,
        productId: existing.productId,
        productStringId: existing.productStringId,
        productTitle: existing.productTitle,
        productImage: existing.productImage,
        price: existing.price,
        originalPrice: existing.originalPrice,
        quantity: quantity,
        subtotal: existing.price * quantity,
        stock: existing.stock,
        variant: existing.variant,
        createdAt: existing.createdAt,
        sellerName: existing.sellerName,
        sellerUsername: existing.sellerUsername,
        sellerAvatar: existing.sellerAvatar,
      );
      _recalculateCart();
      notifyListeners();

      // Legacy sync
      try {
        final legacyItem = CartManager.instance.getItem(existing.productId.toString());
        if (legacyItem != null) {
          legacyItem.quantity = quantity;
        }
      } catch (_) {}
    }

    try {
      await _dataSource.updateCartItem(itemId: itemId, quantity: quantity);
    } catch (e) {
      debugPrint('Update cart item remote sync deferred: $e');
    }
  }

  Future<void> removeItem(int itemId, {bool restoreStock = true}) async {
    final index = _inMemoryItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final removed = _inMemoryItems.removeAt(index);
      if (restoreStock) {
        Product.restoreStock(
          removed.productStringId ?? removed.productId.toString(),
          removed.quantity,
          initialStock: removed.stock,
          productName: removed.productTitle,
        );
      }
      _recalculateCart();
      notifyListeners();

      try {
        CartManager.instance.removeItem(removed.productId.toString());
      } catch (_) {}
    }

    try {
      await _dataSource.removeCartItem(itemId);
    } catch (e) {
      debugPrint('Remove cart item remote sync deferred: $e');
    }
  }

  Future<void> clearCart({bool restoreStock = false}) async {
    if (restoreStock) {
      for (final item in _inMemoryItems) {
        Product.restoreStock(
          item.productStringId ?? item.productId.toString(),
          item.quantity,
          initialStock: item.stock,
          productName: item.productTitle,
        );
      }
    }
    _inMemoryItems.clear();
    _recalculateCart();
    notifyListeners();

    try {
      CartManager.instance.clear();
    } catch (_) {}

    try {
      await _dataSource.clearCart();
    } catch (e) {
      debugPrint('Clear cart remote sync deferred: $e');
    }
  }
}
