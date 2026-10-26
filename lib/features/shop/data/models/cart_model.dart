import 'cart_item_model.dart';

class CartModel {
  final List<CartItemModel> items;
  final int itemCount;
  final double totalAmount;
  final double originalTotalAmount;
  final double totalSavings;

  const CartModel({
    this.items = const [],
    this.itemCount = 0,
    this.totalAmount = 0.0,
    this.originalTotalAmount = 0.0,
    this.totalSavings = 0.0,
  });

  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';
  String get formattedSavings => '\$${totalSavings.toStringAsFixed(2)}';

  factory CartModel.fromJson(Map<String, dynamic> json) {
    List<CartItemModel> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return CartModel(
      items: parsedItems,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? parsedItems.length,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      originalTotalAmount: (json['originalTotalAmount'] as num?)?.toDouble() ?? 0.0,
      totalSavings: (json['totalSavings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
