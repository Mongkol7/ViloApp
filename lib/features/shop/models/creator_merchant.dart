/// Model representing a creator-merchant in Vilo Creator Commerce
class CreatorMerchant {
  final String id;
  final String name;
  final String handle;
  final String avatarUrl;
  final bool isVerified;
  final double rating;
  final String followers;
  final List<MerchantProductItem> products;

  const CreatorMerchant({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    this.isVerified = true,
    this.rating = 4.9,
    this.followers = '48.2k',
    required this.products,
  });

  bool get isSingleProduct => products.length == 1;

  /// Default mock merchants matching image_54f91d.png and Vilo Creator E-commerce
  static const List<CreatorMerchant> mockMerchants = [
    CreatorMerchant(
      id: 'merchant-01',
      name: 'TechGear Official',
      handle: '@techgear_official',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
      isVerified: true,
      rating: 4.9,
      followers: '85.4k',
      products: [
        MerchantProductItem(
          id: 'prod-k1',
          title: 'Stealth TKL Keyboard',
          price: 149.00,
          originalPrice: 199.00,
          specs: 'Black · Wireless',
          imageUrl: 'assets/images/keyboard.jpg',
          rating: 4.9,
          soldCount: 3400,
        ),
      ],
    ),
    CreatorMerchant(
      id: 'merchant-02',
      name: 'God Gear Official',
      handle: '@god_gear_official',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
      isVerified: true,
      rating: 4.8,
      followers: '124.8k',
      products: [
        MerchantProductItem(
          id: 'prod-m1',
          title: 'Gaming Mouse',
          price: 89.00,
          originalPrice: 119.00,
          specs: 'Matte Black · 4K Polling',
          imageUrl: 'assets/images/magsafe_mount.jpg',
          rating: 4.8,
          soldCount: 2800,
        ),
        MerchantProductItem(
          id: 'prod-m2',
          title: 'Mouse Pad',
          price: 29.00,
          originalPrice: 45.00,
          specs: 'Speed Surface · Non-Slip Base',
          imageUrl: 'assets/images/rgb_light_bars.jpg',
          rating: 4.9,
          soldCount: 5100,
        ),
      ],
    ),
    CreatorMerchant(
      id: 'merchant-03',
      name: 'Master Tech',
      handle: '@master_tech',
      avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=200',
      isVerified: false,
      rating: 4.7,
      followers: '42.1k',
      products: [
        MerchantProductItem(
          id: 'prod-mt1',
          title: 'Gaming Mouse',
          price: 89.00,
          originalPrice: 119.00,
          specs: 'Matte Black · 4K Polling',
          imageUrl: 'assets/images/magsafe_mount.jpg',
          rating: 4.8,
          soldCount: 1900,
        ),
        MerchantProductItem(
          id: 'prod-mt2',
          title: 'Mouse Pad',
          price: 29.00,
          originalPrice: 45.00,
          specs: 'Speed Surface · Non-Slip Base',
          imageUrl: 'assets/images/rgb_light_bars.jpg',
          rating: 4.9,
          soldCount: 3800,
        ),
      ],
    ),
    CreatorMerchant(
      id: 'merchant-04',
      name: 'Keyboard Collector',
      handle: '@keyboard_collector',
      avatarUrl: 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=200',
      isVerified: true,
      rating: 4.9,
      followers: '92.1k',
      products: [
        MerchantProductItem(
          id: 'prod-kc1',
          title: 'Stealth TKL Keyboard',
          price: 149.00,
          originalPrice: 199.00,
          specs: 'Black · Wireless',
          imageUrl: 'assets/images/keyboard.jpg',
          rating: 4.9,
          soldCount: 4200,
        ),
      ],
    ),
  ];
}

/// Model representing a product item inside a merchant card
class MerchantProductItem {
  final String id;
  final String title;
  final double price;
  final double? originalPrice;
  final String specs;
  final String imageUrl;
  final double rating;
  final int soldCount;

  const MerchantProductItem({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice,
    required this.specs,
    required this.imageUrl,
    this.rating = 4.8,
    this.soldCount = 0,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String? get formattedOriginalPrice =>
      originalPrice != null ? '\$${originalPrice!.toStringAsFixed(2)}' : null;
}
