import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../controllers/cart_controller.dart';
import 'cart_page.dart';
import 'checkout_page.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel? product;
  final String? imageUrl;
  final String? title;
  final String? price;

  const ProductDetailPage({
    super.key,
    this.product,
    this.imageUrl,
    this.title,
    this.price,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentImageIndex = 0;
  bool _isAdding = false;

  late ProductModel _resolvedProduct;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _resolvedProduct = widget.product!;
    } else {
      // Fallback wrapper for backward compatibility
      final cleanPrice = widget.price?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
      final parsedPrice = double.tryParse(cleanPrice) ?? 99.0;
      _resolvedProduct = ProductModel(
        id: 1,
        title: widget.title ?? 'Premium Product',
        description:
            'Experience exceptional quality and craftmanship with this product. Features state-of-the-art materials, ultra-comfortable ergonomics, and seamless durability.',
        price: parsedPrice,
        originalPrice: parsedPrice * 1.4,
        discountPercentage: 28,
        stock: 50,
        rating: 4.8,
        reviewCount: 312,
        salesCount: 1200,
        images: [
          if (widget.imageUrl != null) widget.imageUrl!,
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800',
        ],
      );
    }
  }

  Future<void> _handleAddToCart() async {
    setState(() => _isAdding = true);
    final success = await CartController.instance.addToCart(_resolvedProduct);
    if (!mounted) return;
    setState(() => _isAdding = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1C1C1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Added to shopping cart', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.blueAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleBuyNow() async {
    await CartController.instance.addToCart(_resolvedProduct);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _resolvedProduct.images.isNotEmpty
        ? _resolvedProduct.images
        : [widget.imageUrl ?? 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Main Content ──────────────────────────────────────
          CustomScrollView(
            slivers: [
              // Product Image Carousel
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      height: 420,
                      width: double.infinity,
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                        itemBuilder: (context, idx) {
                          return Image.network(
                            images[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1C1C1E),
                              child: const Icon(Icons.image_not_supported, color: Colors.white24, size: 60),
                            ),
                          );
                        },
                      ),
                    ),
                    // Image dots indicator
                    if (images.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (idx) {
                            final isActive = idx == _currentImageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white : Colors.white38,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Info Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price & Discount row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _resolvedProduct.formattedPrice,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_resolvedProduct.formattedOriginalPrice != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              _resolvedProduct.formattedOriginalPrice!,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (_resolvedProduct.discountPercentage != null &&
                              _resolvedProduct.discountPercentage! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '-${_resolvedProduct.discountPercentage}% OFF',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        _resolvedProduct.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Rating & Sales & Free shipping
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_resolvedProduct.rating}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${_resolvedProduct.reviewCount} reviews)',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_resolvedProduct.salesCount} sold',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Free Shipping',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 16),

                      // Seller / Store Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                _resolvedProduct.sellerAvatar ?? 'https://i.pravatar.cc/150?img=12',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _resolvedProduct.sellerName ?? 'Vilo Official Store',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, color: Colors.blueAccent, size: 14),
                                    ],
                                  ),
                                  const Text(
                                    'Verified Merchant · 99.4% Positive Feedback',
                                    style: TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'Product Overview',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _resolvedProduct.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.55),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 16),

                      // Customer Reviews Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Customer Reviews (${_resolvedProduct.reviewCount})',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const Text('View All', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // Reviews preview
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCommentItem(index),
                  childCount: 3,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // ── Top Navigation Overlay ───────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                  },
                  child: AnimatedBuilder(
                    animation: CartController.instance,
                    builder: (context, _) {
                      final count = CartController.instance.itemCount;
                      return Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                          ),
                          if (count > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Action Bar ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  // Add to Cart Button
                  InkWell(
                    onTap: _isAdding ? null : _handleAddToCart,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: _isAdding
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Buy Now Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleBuyNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Buy Now',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(int index) {
    final List<String> avatars = [
      'https://i.pravatar.cc/150?img=11',
      'https://i.pravatar.cc/150?img=12',
      'https://i.pravatar.cc/150?img=13',
    ];
    final List<String> names = ['Sarah K.', 'David Heng', 'Sophea V.'];
    final List<String> comments = [
      'Amazing authentic quality! Arrived within 2 days in Phnom Penh.',
      'Super comfortable and matches the photos in the video perfectly.',
      '10/10 recommendation. Great packaging and customer service.',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(avatars[index % avatars.length]),
              ),
              const SizedBox(width: 10),
              Text(
                names[index % names.length],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (starIndex) => const Icon(Icons.star, color: Colors.orange, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comments[index % comments.length],
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 6),
          const Text('2 days ago · Verified Purchase', style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }
}
