class Product {
  final String id;
  final String name;
  final String categoryId;
  final String? category;
  final double price;
  final double? originalPrice;
  final double rating;
  final int soldCount;
  final String? badge;
  final String? seller;
  final String description;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.category,
    required this.price,
    this.originalPrice,
    this.rating = 4.8,
    this.soldCount = 0,
    this.badge,
    this.seller,
    required this.description,
    required this.imageUrl,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  String? get formattedOriginalPrice =>
      originalPrice != null ? '\$${originalPrice!.toStringAsFixed(2)}' : null;

  int? get discountPercentage {
    if (originalPrice != null && originalPrice! > price && originalPrice! > 0) {
      return (((originalPrice! - price) / originalPrice!) * 100).round();
    }
    return null;
  }

  String get formattedSoldCount {
    if (soldCount >= 1000) {
      final double inK = soldCount / 1000.0;
      final formatted = inK.toStringAsFixed(1).replaceAll('.0', '');
      return '$formatted sold';
    }
    return '$soldCount sold';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Category mapping
    String catId = '';
    String? catName;
    if (json['category'] is Map) {
      final catMap = json['category'] as Map<String, dynamic>;
      catId = catMap['id']?.toString() ?? '';
      catName = catMap['name'] as String?;
    } else if (json['category'] is String) {
      catName = json['category'] as String;
    }
    if (catId.isEmpty && json['categoryId'] != null) {
      catId = json['categoryId'].toString();
    }

    // Seller mapping
    String? sellerName;
    if (json['seller'] is Map) {
      final sellerMap = json['seller'] as Map<String, dynamic>;
      sellerName = (sellerMap['displayName'] ?? sellerMap['username']) as String?;
    } else if (json['seller'] is String) {
      sellerName = json['seller'] as String;
    }

    // Image mapping
    String resolvedImage = '';
    if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      resolvedImage = json['imageUrl'].toString();
    } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      resolvedImage = (json['images'] as List).first.toString();
    }

    // Badge mapping
    String? badgeText = json['badge'] as String?;
    if (badgeText == null && json['discountPercentage'] != null) {
      badgeText = '-${json['discountPercentage']}%';
    }

    final double priceVal = (json['price'] as num?)?.toDouble() ?? 0.0;
    final double? origPriceVal = (json['originalPrice'] as num?)?.toDouble();

    return Product(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['title']) as String? ?? '',
      categoryId: catId,
      category: catName,
      price: priceVal,
      originalPrice: origPriceVal,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      soldCount: (json['soldCount'] as num?)?.toInt() ??
          (json['salesCount'] as num?)?.toInt() ??
          0,
      badge: badgeText,
      seller: sellerName,
      description: json['description'] as String? ?? '',
      imageUrl: resolvedImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'category': category,
      'price': price,
      'originalPrice': originalPrice,
      'rating': rating,
      'soldCount': soldCount,
      'badge': badge,
      'seller': seller,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? category,
    double? price,
    double? originalPrice,
    double? rating,
    int? soldCount,
    String? badge,
    String? seller,
    String? description,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      soldCount: soldCount ?? this.soldCount,
      badge: badge ?? this.badge,
      seller: seller ?? this.seller,
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

  String get fallbackImageUrl {
    switch (id) {
      case 'ts-1':
        return 'https://images.unsplash.com/photo-1544233726-9f1d2b27be8b?w=600';
      case 'ts-2':
        return 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=600';
      case 'ts-3':
        return 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600';
      case 'ts-4':
        return 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=600';
      case 'feed-1':
        return 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800';
      case 'feed-2':
        return 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800';
      case 'feed-3':
        return 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=800';
      case 'feed-4':
        return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800';
      case 'prod-001':
        return 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800';
      case 'prod-002':
        return 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=800';
      case 'prod-003':
        return 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800';
      case 'prod-004':
        return 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=800';
      case 'prod-005':
        return 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800';
      case 'prod-006':
        return 'https://images.unsplash.com/photo-1544816155-12df9643f363?w=800';
      case 'prod-007':
        return 'https://images.unsplash.com/photo-1526170315870-ef68ea653258?w=800';
      case 'prod-008':
        return 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800';
      case 'prod-009':
        return 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800';
      case 'prod-010':
        return 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=800';
      default:
        return 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600';
    }
  }

  /// Top Sellers matching exact mobile design screenshot
  static const List<Product> screenshotTopSellers = [
    Product(
      id: 'ts-1',
      name: 'Electric Multi-Cooker & Steamer',
      categoryId: 'cat-kitchen',
      category: 'Crazy Prices',
      price: 1.01,
      originalPrice: 101.00,
      badge: '-99%',
      seller: '@vilo_deals',
      rating: 4.9,
      soldCount: 12000,
      description: 'Smart fuzzy logic electric rice cooker and food steamer with non-stick ceramic pot.',
      imageUrl: 'assets/images/mini_rice_cooker.jpg',
    ),
    Product(
      id: 'ts-2',
      name: 'Ultra Slim Aluminum Power Bank 20000mAh',
      categoryId: 'cat-tech',
      category: 'Crazy Prices',
      price: 0.01,
      originalPrice: 49.99,
      badge: '-99%',
      seller: '@vilo_deals',
      rating: 4.8,
      soldCount: 8500,
      description: 'Anodized aluminum compact power bank with 65W fast charge USB-C PD.',
      imageUrl: 'assets/images/power_bank.jpg',
    ),
    Product(
      id: 'ts-3',
      name: 'Mechanical Keyboard 61-Key White Minimalist',
      categoryId: 'cat-tech',
      category: 'Crazy Prices',
      price: 0.01,
      originalPrice: 69.99,
      badge: '-99%',
      seller: '@vilo_deals',
      rating: 4.9,
      soldCount: 6700,
      description: 'Compact 60% RGB mechanical keyboard with smooth hot-swappable red switches.',
      imageUrl: 'assets/images/keyboard.jpg',
    ),
    Product(
      id: 'ts-4',
      name: 'Titanium Flagship Phone Retail Pack',
      categoryId: 'cat-tech',
      category: 'Crazy Prices',
      price: 0.01,
      originalPrice: 1099.00,
      badge: '-99%',
      seller: '@vilo_deals',
      rating: 5.0,
      soldCount: 4300,
      description: 'Brand new in box flagship smartphone with titanium finish and charger.',
      imageUrl: 'assets/images/iphone_deal.jpg',
    ),
  ];

  /// 2-Column Storefront Feed matching exact mobile design screenshot
  static const List<Product> screenshotFeedProducts = [
    Product(
      id: 'feed-1',
      name: 'iPhone 17 Pro Max Case & Flagship Titanium',
      categoryId: 'cat-tech',
      category: 'Mall',
      price: 124.50,
      originalPrice: 299.00,
      badge: '👍 3.2K',
      seller: 'TechPro Official',
      rating: 4.8,
      soldCount: 1400,
      description: 'Titanium flagship smartphone case and housing featuring Super Retina XDR display protection.',
      imageUrl: 'assets/images/iphone_17_pro_max_case.jpg',
    ),
    Product(
      id: 'feed-2',
      name: 'V-Watch Ultra Rugged Titanium Smartwatch',
      categoryId: 'cat-tech',
      category: 'Mall',
      price: 89.90,
      originalPrice: 149.00,
      badge: '👍 1.8K',
      seller: 'Titan Monitoring',
      rating: 4.9,
      soldCount: 4200,
      description: 'Outdoor titanium GPS smartwatch with sapphire glass, heart rate ECG, and dive-ready water resistance.',
      imageUrl: 'assets/images/v_watch_ultra.jpg',
    ),
    Product(
      id: 'feed-3',
      name: 'Midnight Hydration Serum with Pure Hyaluronic Acid',
      categoryId: 'cat-beauty',
      category: 'Beauty',
      price: 42.00,
      originalPrice: 85.00,
      badge: '👍 5.1K',
      seller: 'GLOW Beauty',
      rating: 4.7,
      soldCount: 12000,
      description: 'Intense overnight barrier repair serum formulated with multi-weight hyaluronic acid and niacinamide.',
      imageUrl: 'assets/images/midnight_hydration_serum.jpg',
    ),
    Product(
      id: 'feed-4',
      name: 'V-Series Wireless Headphones Active Noise Cancelling',
      categoryId: 'cat-audio',
      category: 'Mall',
      price: 215.00,
      originalPrice: 369.00,
      badge: '👍 2.4K',
      seller: 'AudioPro Official',
      rating: 5.0,
      soldCount: 850,
      description: 'Studio grade wireless headphones with high-res audio codec, plush memory foam, and hybrid ANC.',
      imageUrl: 'assets/images/v_series_headphones.jpg',
    ),
  ];

  /// The 10 official creator catalog products for Vilo E-Commerce
  static const List<Product> creatorProducts = [
    Product(
      id: 'prod-001',
      name: 'Vilo Creator Ring Light Pro',
      categoryId: 'cat-studio',
      category: 'Studio Equipment',
      price: 34.99,
      originalPrice: 49.99,
      rating: 4.9,
      soldCount: 2400,
      badge: '👍 2.8K',
      seller: 'Vilo Studio Pro',
      description: '12-inch dimmable LED ring light with tripod stand and smartphone holder for crisp streaming.',
      imageUrl: 'assets/images/ring_light.jpg',
    ),
    Product(
      id: 'prod-002',
      name: 'Wireless Lavalier Microphone',
      categoryId: 'cat-audio',
      category: 'Audio & Tech',
      price: 29.99,
      originalPrice: 45.00,
      rating: 4.8,
      soldCount: 3100,
      badge: '👍 1.5K',
      seller: 'AudioTech Lab',
      description: 'Plug-and-play wireless lapel mic with active DSP noise reduction for mobile vlogging.',
      imageUrl: 'assets/images/lavalier_mic.jpg',
    ),
    Product(
      id: 'prod-003',
      name: 'Obsidian Pulse Oversized Hoodie',
      categoryId: 'cat-apparel',
      category: 'Apparel',
      price: 55.00,
      originalPrice: 85.00,
      rating: 4.9,
      soldCount: 5200,
      badge: '👍 4.2K',
      seller: 'Obsidian Apparel',
      description: '450 GSM French Terry cotton hoodie with custom drop-shoulder fit and Obsidian dark aesthetic.',
      imageUrl: 'assets/images/obsidian_hoodie.jpg',
    ),
    Product(
      id: 'prod-004',
      name: 'MagSafe Magnetic Desktop Phone Mount',
      categoryId: 'cat-acc',
      category: 'Accessories',
      price: 19.99,
      originalPrice: 29.99,
      rating: 4.7,
      soldCount: 1800,
      badge: '👍 950',
      seller: 'AeroMount Studio',
      description: 'CNC machined aerospace aluminum magnetic stand with 360-degree rotation for hands-free live streams.',
      imageUrl: 'assets/images/magsafe_mount.jpg',
    ),
    Product(
      id: 'prod-005',
      name: 'RGB Music-Sync Ambient Desk Light Bars',
      categoryId: 'cat-studio',
      category: 'Studio Equipment',
      price: 39.99,
      originalPrice: 59.99,
      rating: 4.9,
      soldCount: 4100,
      badge: '👍 3.1K',
      seller: 'GlowRGB Lab',
      description: 'Smart ambient light bars with real-time sound sync, app control, and 16M color dynamics.',
      imageUrl: 'assets/images/rgb_light_bars.jpg',
    ),
    Product(
      id: 'prod-006',
      name: 'Vilo Signature Canvas Tote Bag',
      categoryId: 'cat-life',
      category: 'Lifestyle',
      price: 24.99,
      originalPrice: 35.00,
      rating: 4.8,
      soldCount: 2200,
      badge: '👍 1.1K',
      seller: 'Vilo Lifestyle',
      description: 'Heavyweight organic canvas bag with internal laptop sleeve and reinforced stitching.',
      imageUrl: 'assets/images/canvas_tote.jpg',
    ),
    Product(
      id: 'prod-007',
      name: 'Flexible Octopus Tripod Stand',
      categoryId: 'cat-acc',
      category: 'Accessories',
      price: 15.99,
      originalPrice: 24.99,
      rating: 4.6,
      soldCount: 1600,
      badge: '👍 820',
      seller: 'FlexiShoot',
      description: 'Rubber-coated bendable legs that wrap around poles and uneven surfaces for outdoor shooting.',
      imageUrl: 'assets/images/octopus_tripod.jpg',
    ),
    Product(
      id: 'prod-008',
      name: 'Minimalist Metal Phone Grip & Stand',
      categoryId: 'cat-acc',
      category: 'Accessories',
      price: 12.99,
      originalPrice: 19.99,
      rating: 4.7,
      soldCount: 2900,
      badge: '👍 1.4K',
      seller: 'UltraGrip Official',
      description: 'Ultra-thin foldable zinc-alloy kickstand and finger grip with strong adhesive.',
      imageUrl: 'assets/images/phone_grip.jpg',
    ),
    Product(
      id: 'prod-009',
      name: 'Portable LED Pocket Fill Light',
      categoryId: 'cat-studio',
      category: 'Studio Equipment',
      price: 22.99,
      originalPrice: 34.99,
      rating: 4.8,
      soldCount: 1750,
      badge: '👍 980',
      seller: 'LumiPocket Lab',
      description: 'Pocket-sized biometric LED panel with adjustable color temperature (2500K-9000K) and built-in battery.',
      imageUrl: 'assets/images/pocket_fill_light.jpg',
    ),
    Product(
      id: 'prod-010',
      name: 'Vilo Creator Vinyl Sticker Pack',
      categoryId: 'cat-merch',
      category: 'Merchandise',
      price: 8.99,
      originalPrice: 14.99,
      rating: 5.0,
      soldCount: 6400,
      badge: '👍 5.5K',
      seller: 'Vilo Merch',
      description: 'Pack of 12 weatherproof, scratch-resistant vinyl stickers designed for creator setups and laptops.',
      imageUrl: 'assets/images/sticker_pack.jpg',
    ),
  ];
}
