import 'package:flutter/foundation.dart';
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  }) : assert(quantity > 0, 'Quantity must be at least 1');

  double get subtotal => product.price * quantity;
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && runtimeType == other.runtimeType && product.id == other.product.id;

  @override
  int get hashCode => product.id.hashCode;
}

/// Dynamic Cart State Manager following Clean Architecture
class CartManager extends ChangeNotifier {
  static CartManager? _instance;
  static CartManager get instance => _instance ??= CartManager();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';

  CartItem? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  void addItem(Product product, [int quantity = 1]) {
    if (quantity <= 0) return;

    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    final existingIndex = _items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    final existingIndex = _items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity--;
      } else {
        _items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
