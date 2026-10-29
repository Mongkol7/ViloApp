class OrderItemModel {
  final int id;
  final int? productId;
  final String productTitle;
  final String productImageUrl;
  final double price;
  final int quantity;
  final double subtotal;
  final String? variant;

  const OrderItemModel({
    required this.id,
    this.productId,
    required this.productTitle,
    required this.productImageUrl,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.variant,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num?)?.toInt(),
      productTitle: json['productTitle'] as String? ?? '',
      productImageUrl: json['productImageUrl'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      variant: json['variant'] as String?,
    );
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final String paymentMethod;
  final String? notes;
  final List<OrderItemModel> items;
  final int itemCount;
  final String? createdAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.notes,
    this.items = const [],
    this.itemCount = 0,
    this.createdAt,
  });

  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';

  String get dynamicStatus {
    final s = status.toUpperCase();
    if (s == 'CANCELLED' || s == 'CANCELED') {
      return 'CANCELLED';
    }

    DateTime? createdDate;
    if (createdAt != null && createdAt!.isNotEmpty) {
      createdDate = DateTime.tryParse(createdAt!);
    }
    if (createdDate == null && id > 1000000000000) {
      createdDate = DateTime.fromMillisecondsSinceEpoch(id);
    }

    // Only legacy in-memory inquiry orders use the local four-hour display
    // transition. Backend orders must keep their persisted status so a
    // pending order remains cancellable after an app restart.
    if (id > 1000000000000 && createdDate != null) {
      final elapsed = DateTime.now().difference(createdDate);
      if (elapsed.inSeconds >= 4 * 3600) {
        return 'SUCCESS';
      } else {
        return 'PENDING';
      }
    }

    return (status.toUpperCase() == 'DELIVERED' ||
            status.toUpperCase() == 'PAID')
        ? 'SUCCESS'
        : status;
  }

  OrderModel copyWith({
    int? id,
    String? orderNumber,
    double? totalAmount,
    String? status,
    String? shippingAddress,
    String? paymentMethod,
    String? notes,
    List<OrderItemModel>? items,
    int? itemCount,
    String? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: (json['id'] as num).toInt(),
      orderNumber: json['orderNumber'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      shippingAddress: json['shippingAddress'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      notes: json['notes'] as String?,
      items: parsedItems,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? parsedItems.length,
      createdAt: json['createdAt'] as String?,
    );
  }
}
