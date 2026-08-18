import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'product_detail_page.dart';
import 'cart_page.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 60; // Space for the top nav bar

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Top Spacing for Nav Bar ───────────────────────────
          SliverToBoxAdapter(child: SizedBox(height: topPadding)),

          // ── Search & Cart Header ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.white60, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'iPhone 17 promax',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Search',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartPage()),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Text('4', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Mega Sale Banner ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Opacity(
                          opacity: 0.6,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1546435770-a3e426bf472b?q=80&w=2065&auto=format&fit=crop',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.white12),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                            child: const Text('VILO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'VILO Shop | Mega\nSale',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1),
                          ),
                          const SizedBox(height: 8),
                          const Text('Get A Free Gift | \$25 Min Spend', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24)),
                            child: const Text('Shop now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Coupons & Claim Section ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildCouponCard('Free shipping', 'No min. spend')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildCouponCard('\$15 off', 'No min. speed')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New customer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Claim all gifts', style: TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18)),
                          child: const Text('Claim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Top Sellers ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Top Sellers', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: const Text('HOT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _buildTopSellerItem(),
                  ),
                ),
              ],
            ),
          ),

          // ── Tabs ──────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              Container(
                color: Colors.black,
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildTab('All', active: true),
                    _buildTab('Crazy Prices'),
                    _buildTab('Beauty'),
                    _buildTab('Mall'),
                    _buildTab('Toys'),
                  ],
                ),
              ),
            ),
          ),

          // ── Product Grid ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCard(context, index),
                childCount: 10,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCouponCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.blueAccent, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTopSellerItem() {
    // Top Seller images matching the design items (Crockpot, Powerbank, Keyboard, iPhone)
    final List<String> topSellerImages = [
      'https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?q=80&w=400', // Kitchen/Crockpot
      'https://images.unsplash.com/photo-1625842268584-8f3bf9ff16a0?q=80&w=400', // Powerbank
      'https://images.unsplash.com/photo-1587829741301-dc798b83bac1?q=80&w=400', // Keyboard
      'https://images.unsplash.com/photo-1616348436168-de43ad0db179?q=80&w=400', // iPhone
      'https://images.unsplash.com/photo-1546435770-a3e426bf472b?q=80&w=400', // Generic tech
    ];
    
    // We'll use the index if we had it, but for a simple mock we'll randomize or pick one
    final imageUrl = topSellerImages[math.Random().nextInt(topSellerImages.length)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 40),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: const Text('-99%', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('\$0.01', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const Text('@vilo.deals', style: TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildTab(String label, {bool active = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: active ? Colors.white : Colors.white38, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
            if (active) ...[
              const SizedBox(height: 4),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, int index) {
    final List<String> productImages = [
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=500', // Mobile
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=500', // Watch
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=500', // Headphones
      'https://images.unsplash.com/photo-1526170315870-ef68ea653258?q=80&w=500', // Camera
      'https://images.unsplash.com/photo-1572635196237-14b3f281503f?q=80&w=500', // Glasses
    ];
    final imageUrl = productImages[index % productImages.length];
    const productTitle = 'Premium Gadget Product Title...';
    const productPrice = '\$124.50';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              imageUrl: imageUrl,
              title: productTitle,
              price: productPrice,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFF2C2C2E), 
                    width: double.infinity, 
                    height: double.infinity,
                    child: Image.network(
                      imageUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_outlined, color: Colors.white12, size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: const [
                          Icon(Icons.thumb_up, color: Colors.orange, size: 10),
                          SizedBox(width: 4),
                          Text('1.2K', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(productTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Text(productPrice, style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(width: 4),
                      Text('\$299.00', style: TextStyle(color: Colors.white24, fontSize: 10, decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.star, color: Colors.orange, size: 10),
                      SizedBox(width: 2),
                      Text('4.8 | 1.5K sold', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._child);
  final Widget _child;

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
