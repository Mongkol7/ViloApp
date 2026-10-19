class CartItemModel {
  final int id;
  final int productId;
  final String productTitle;
  final String productImage;
  final double price;
  final double? originalPrice;
  final int quantity;
  final double subtotal;
  final int stock;
  final String? variant;
  final String? createdAt;
  final String? sellerName;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.price,
    this.originalPrice,
    required this.quantity,
    required this.subtotal,
    required this.stock,
    this.variant,
    this.createdAt,
    this.sellerName,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      productTitle: json['productTitle'] as String? ?? '',
      productImage: json['productImage'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      variant: json['variant'] as String?,
      createdAt: json['createdAt'] as String?,
      sellerName: json['sellerName'] as String? ?? json['seller'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'price': price,
      'originalPrice': originalPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'stock': stock,
      'variant': variant,
      'createdAt': createdAt,
      'sellerName': sellerName,
    };
  }
}

