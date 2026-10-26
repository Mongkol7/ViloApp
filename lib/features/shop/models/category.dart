import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String name;
  final String iconName;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.iconName,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      iconName: json['iconName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
    };
  }

  ProductCategory copyWith({
    String? id,
    String? name,
    String? iconName,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
    );
  }

  /// Maps string icon identifier to high-fidelity Material icon
  IconData getIconData() {
    switch (iconName.toLowerCase()) {
      case 'studio':
      case 'lightbulb':
        return Icons.lightbulb_outline_rounded;
      case 'audio':
      case 'mic':
        return Icons.mic_external_on_rounded;
      case 'apparel':
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'accessories':
      case 'devices':
        return Icons.devices_other_rounded;
      case 'lifestyle':
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'merchandise':
      case 'style':
        return Icons.style_outlined;
      case 'all':
        return Icons.grid_view_rounded;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Default predefined creator categories
  static const List<ProductCategory> defaultCategories = [
    ProductCategory(id: 'cat-all', name: 'All', iconName: 'all'),
    ProductCategory(id: 'cat-studio', name: 'Studio Equipment', iconName: 'lightbulb'),
    ProductCategory(id: 'cat-audio', name: 'Audio & Tech', iconName: 'mic'),
    ProductCategory(id: 'cat-apparel', name: 'Apparel', iconName: 'checkroom'),
    ProductCategory(id: 'cat-acc', name: 'Accessories', iconName: 'devices'),
    ProductCategory(id: 'cat-life', name: 'Lifestyle', iconName: 'shopping_bag'),
    ProductCategory(id: 'cat-merch', name: 'Merchandise', iconName: 'style'),
  ];
}
