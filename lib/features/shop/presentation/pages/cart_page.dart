import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar (Search + Cart) ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
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
                        children: const [
                          Icon(Icons.search, color: Colors.white60, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Keyboard',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          Text(
                            'Search',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
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
                ],
              ),
            ),

            // ── Cart Items List ──────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // 1. Single Product Account
                  _buildSellerBlock(
                    sellerHandle: '@techgear_official',
                    isVerified: true,
                    products: [
                      _ProductData(
                        title: 'Stealth TKL Keyboard',
                        price: '\$149.00',
                        attrs: 'Black · Wireless',
                        imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83bac1?q=80&w=400',
                      ),
                    ],
                    showChatIcon: true,
                  ),

                  // 2. Multi Product Account
                  _buildSellerBlock(
                    sellerHandle: '@god_gear_official',
                    isVerified: true,
                    products: [
                      _ProductData(
                        title: 'Gaming Mouse',
                        price: '\$89.00',
                        attrs: 'RGB · 16k DPI',
                        imageUrl: 'https://images.unsplash.com/photo-1625842268584-8f3bf9ff16a0?q=80&w=400',
                      ),
                      _ProductData(
                        title: 'Mouse Pad',
                        price: '\$29.00',
                        attrs: 'Extra Large · Anti-slip',
                        imageUrl: 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?q=80&w=400',
                      ),
                    ],
                    showSendMessage: true,
                  ),

                  // 3. Multi Product Account (No verification)
                  _buildSellerBlock(
                    sellerHandle: '@master_tech',
                    isVerified: false,
                    products: [
                      _ProductData(
                        title: 'Gaming Mouse',
                        price: '\$89.00',
                        attrs: 'RGB · 16k DPI',
                        imageUrl: 'https://images.unsplash.com/photo-1625842268584-8f3bf9ff16a0?q=80&w=400',
                      ),
                      _ProductData(
                        title: 'Mouse Pad',
                        price: '\$29.00',
                        attrs: 'Extra Large · Anti-slip',
                        imageUrl: 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?q=80&w=400',
                      ),
                    ],
                    showSendMessage: true,
                  ),

                  // 4. Single Product Account (Bottom)
                  _buildSellerBlock(
                    sellerHandle: '@keyboard_collector',
                    isVerified: true,
                    products: [
                      _ProductData(
                        title: 'Stealth TKL Keyboard',
                        price: '\$149.00',
                        attrs: 'Black · Wireless',
                        imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83bac1?q=80&w=400',
                      ),
                    ],
                    showChatIcon: true,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerBlock({
    required String sellerHandle,
    required bool isVerified,
    required List<_ProductData> products,
    bool showChatIcon = false,
    bool showSendMessage = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                sellerHandle,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: Colors.blueAccent, size: 14),
              ],
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.white38, size: 20),
            ],
          ),
          const SizedBox(height: 16),

          // Product(s) Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ...products.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  return Column(
                    children: [
                      _buildProductRow(p, showChatIcon),
                      if (idx < products.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.white12, height: 1),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Send Message Button
          if (showSendMessage) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.chat_bubble, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Send Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductRow(_ProductData p, bool showChatIcon) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              p.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.white10,
                child: const Icon(Icons.image_outlined, color: Colors.white24),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 4),
              Text(p.price, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 2),
              Text(p.attrs, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        if (showChatIcon)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
          ),
      ],
    );
  }
}

class _ProductData {
  final String title;
  final String price;
  final String attrs;
  final String imageUrl;

  _ProductData({required this.title, required this.price, required this.attrs, required this.imageUrl});
}
