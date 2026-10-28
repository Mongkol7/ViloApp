import 'category_model.dart';
import '../../models/product.dart';

class ProductModel {
  final int id;
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final int? discountPercentage;
  final int stock;
  final double rating;
  final int reviewCount;
  final int salesCount;
  final CategoryModel? category;
  final int? sellerId;
  final String? sellerName;
  final String? sellerUsername;
  final String? sellerAvatar;
  final List<String> images;
  final List<int> videoIds;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discountPercentage,
    required this.stock,
    required this.rating,
    required this.reviewCount,
    required this.salesCount,
    this.category,
    this.sellerId,
    this.sellerName,
    this.sellerUsername,
    this.sellerAvatar,
    this.images = const [],
    this.videoIds = const [],
  });

  String get primaryImage =>
      images.isNotEmpty ? images.first : 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600';

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String? get formattedOriginalPrice =>
      originalPrice != null ? '\$${originalPrice!.toStringAsFixed(2)}' : null;

  int get effectiveStock => Product.getEffectiveStock(id.toString(), stock);
  bool get isOutOfStock => effectiveStock <= 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    }

    List<int> parsedVideoIds = [];
    if (json['videoIds'] is List) {
      parsedVideoIds = (json['videoIds'] as List).map((e) => (e as num).toInt()).toList();
    }

    Map<String, dynamic>? sellerJson = json['seller'] as Map<String, dynamic>?;

    return ProductModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toInt(),
      stock: json['stock'] != null ? (json['stock'] as num).toInt() : 10,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      sellerId: sellerJson != null ? (sellerJson['id'] as num?)?.toInt() : null,
      sellerUsername: sellerJson != null ? sellerJson['username'] as String? : null,
      sellerName: sellerJson != null
          ? (sellerJson['username'] ?? sellerJson['displayName']) as String?
          : null,
      sellerAvatar: sellerJson != null ? sellerJson['avatarUrl'] as String? : null,
      images: parsedImages,
      videoIds: parsedVideoIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'stock': stock,
      'rating': rating,
      'reviewCount': reviewCount,
      'salesCount': salesCount,
      'category': category?.toJson(),
      'images': images,
      'videoIds': videoIds,
    };
  }
}
