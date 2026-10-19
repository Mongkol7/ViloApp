import 'package:flutter/foundation.dart';
import '../../data/datasources/shop_remote_data_source.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/cart_model.dart';
import '../../data/models/product_model.dart';

class CartController extends ChangeNotifier {
  static CartController? _instance;
  static CartController get instance => _instance ??= CartController._();

  final ShopRemoteDataSource _dataSource;

  CartModel _cart = const CartModel();
  bool _isLoading = false;
  String? _errorMessage;

  CartController._([ShopRemoteDataSource? dataSource])
      : _dataSource = dataSource ?? ShopRemoteDataSource.instance {
    loadCart();
  }

  CartModel get cart => _cart;
  List<CartItemModel> get items => _cart.items;
  int get itemCount => _cart.itemCount;
  double get totalAmount => _cart.totalAmount;
  double get totalSavings => _cart.totalSavings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cart = await _dataSource.getCart();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(ProductModel product, {int quantity = 1, String? variant}) async {
    try {
      await _dataSource.addToCart(
        productId: product.id,
        quantity: quantity,
        variant: variant,
      );
      await loadCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    try {
      await _dataSource.updateCartItem(itemId: itemId, quantity: quantity);
      await loadCart();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeItem(int itemId) async {
    try {
      await _dataSource.removeCartItem(itemId);
      await loadCart();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      await _dataSource.clearCart();
      await loadCart();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
