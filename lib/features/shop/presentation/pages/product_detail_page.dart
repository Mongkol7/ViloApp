import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../models/product.dart';
import '../../views/product_detail_screen.dart';

/// Legacy page wrapper that seamlessly renders [ProductDetailScreen]
/// for all existing routes and views across the application.
class ProductDetailPage extends StatelessWidget {
  final dynamic product;
  final String? id;
  final String? imageUrl;
  final String? title;
  final String? price;
  final String? description;
  final String? seller;
  final String? sellerAvatar;
  final String? sellerId;
  final double? rating;
  final int? soldCount;
  final int? stock;
  final String? category;
  final double? originalPrice;

  const ProductDetailPage({
    super.key,
    this.product,
    this.id,
    this.imageUrl,
    this.title,
    this.price,
    this.description,
    this.seller,
    this.sellerAvatar,
    this.sellerId,
    this.rating,
    this.soldCount,
    this.stock,
    this.category,
    this.originalPrice,
  });

  @override
  Widget build(BuildContext context) {
    ProductModel? pModel;
    Product? pEntity;
    if (product is ProductModel) {
      pModel = product as ProductModel;
    } else if (product is Product) {
      pEntity = product as Product;
    }

    return ProductDetailScreen(
      productModel: pModel,
      product: pEntity,
      id: id ?? (pEntity?.id) ?? (pModel?.id.toString()),
      imageUrl: imageUrl ?? pEntity?.imageUrl ?? (pModel?.images.isNotEmpty == true ? pModel!.images.first : null),
      title: title ?? pEntity?.name ?? pModel?.title,
      price: price ?? pEntity?.formattedPrice ?? pModel?.formattedPrice,
      description: description ?? pEntity?.description ?? pModel?.description,
      seller: seller ?? pEntity?.seller ?? pModel?.sellerName,
      sellerAvatar: sellerAvatar ?? pEntity?.sellerAvatar ?? pModel?.sellerAvatar,
      sellerId: sellerId ?? pEntity?.sellerId ?? pModel?.sellerId?.toString(),
      rating: rating ?? pEntity?.rating ?? pModel?.rating,
      soldCount: soldCount ?? pEntity?.soldCount ?? pModel?.salesCount,
      stock: stock ?? pEntity?.stock ?? pModel?.stock,
      category: category ?? pEntity?.category ?? pModel?.category?.name,
      originalPrice: originalPrice ?? pEntity?.originalPrice ?? pModel?.originalPrice,
    );
  }
}

