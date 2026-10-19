class Product {
  final String id;
  final String name;
  final String categoryId;
  final double price;
  final String description;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.description,
    required this.imageUrl,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? price,
    String? description,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// The 10 official creator catalog products for Vilo E-Commerce
  static const List<Product> creatorProducts = [
    Product(
      id: 'prod-001',
      name: 'Vilo Creator Ring Light Pro',
      categoryId: 'cat-studio',
      price: 34.99,
      description: '12-inch dimmable LED ring light with tripod stand and smartphone holder for crisp streaming.',
      imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
    ),
    Product(
      id: 'prod-002',
      name: 'Wireless Lavalier Microphone',
      categoryId: 'cat-audio',
      price: 29.99,
      description: 'Plug-and-play wireless lapel mic with active DSP noise reduction for mobile vlogging.',
      imageUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=800',
    ),
    Product(
      id: 'prod-003',
      name: 'Obsidian Pulse Oversized Hoodie',
      categoryId: 'cat-apparel',
      price: 55.00,
      description: '450 GSM French Terry cotton hoodie with custom drop-shoulder fit and Obsidian dark aesthetic.',
      imageUrl: 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800',
    ),
    Product(
      id: 'prod-004',
      name: 'MagSafe Magnetic Desktop Phone Mount',
      categoryId: 'cat-acc',
      price: 19.99,
      description: 'CNC machined aerospace aluminum magnetic stand with 360-degree rotation for hands-free live streams.',
      imageUrl: 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800',
    ),
    Product(
      id: 'prod-005',
      name: 'RGB Music-Sync Ambient Desk Light Bars',
      categoryId: 'cat-studio',
      price: 39.99,
      description: 'Smart ambient light bars with real-time sound sync, app control, and 16M color dynamics.',
      imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800',
    ),
    Product(
      id: 'prod-006',
      name: 'Vilo Signature Canvas Tote Bag',
      categoryId: 'cat-life',
      price: 24.99,
      description: 'Heavyweight organic canvas bag with internal laptop sleeve and reinforced stitching.',
      imageUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=800',
    ),
    Product(
      id: 'prod-007',
      name: 'Flexible Octopus Tripod Stand',
      categoryId: 'cat-acc',
      price: 15.99,
      description: 'Rubber-coated bendable legs that wrap around poles and uneven surfaces for outdoor shooting.',
      imageUrl: 'https://images.unsplash.com/photo-1526170315870-ef68ea653258?w=800',
    ),
    Product(
      id: 'prod-008',
      name: 'Minimalist Metal Phone Grip & Stand',
      categoryId: 'cat-acc',
      price: 12.99,
      description: 'Ultra-thin foldable zinc-alloy kickstand and finger grip with strong adhesive.',
      imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800',
    ),
    Product(
      id: 'prod-009',
      name: 'Portable LED Pocket Fill Light',
      categoryId: 'cat-studio',
      price: 22.99,
      description: 'Pocket-sized biometric LED panel with adjustable color temperature (2500K-9000K) and built-in battery.',
      imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800',
    ),
    Product(
      id: 'prod-010',
      name: 'Vilo Creator Vinyl Sticker Pack',
      categoryId: 'cat-merch',
      price: 8.99,
      description: 'Pack of 12 weatherproof, scratch-resistant vinyl stickers designed for creator setups and laptops.',
      imageUrl: 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=800',
    ),
  ];
}
