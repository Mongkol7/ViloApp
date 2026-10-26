import 'cart_item.dart';

class ShopOrder {
  final String orderId;
  final List<CartItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String? shippingAddress;
  final String? paymentMethod;

  const ShopOrder({
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.shippingAddress,
    this.paymentMethod,
  });

  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Convenient factory to create an order payload directly from cart items
  factory ShopOrder.create({
    required String orderId,
    required List<CartItem> items,
    String status = 'PENDING',
    DateTime? createdAt,
    String? shippingAddress,
    String? paymentMethod,
  }) {
    final computedTotal = items.fold(0.0, (sum, item) => sum + item.subtotal);

    return ShopOrder(
      orderId: orderId,
      items: List.unmodifiable(items),
      totalAmount: computedTotal,
      status: status,
      createdAt: createdAt ?? DateTime.now(),
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
    );
  }

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    List<CartItem> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return ShopOrder(
      orderId: json['orderId'] as String? ?? '',
      items: parsedItems,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      shippingAddress: json['shippingAddress'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };
  }

  ShopOrder copyWith({
    String? orderId,
    List<CartItem>? items,
    double? totalAmount,
    String? status,
    DateTime? createdAt,
    String? shippingAddress,
    String? paymentMethod,
  }) {
    return ShopOrder(
      orderId: orderId ?? this.orderId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopOrder && runtimeType == other.runtimeType && orderId == other.orderId;

  @override
  int get hashCode => orderId.hashCode;
}
