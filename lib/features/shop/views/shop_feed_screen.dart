import 'package:flutter/material.dart';
import '../presentation/controllers/cart_controller.dart';
import '../models/product.dart';
import '../presentation/pages/cart_page.dart';
import '../presentation/pages/product_detail_page.dart';
import '../services/shop_service.dart';
import 'shop_search_results_screen.dart';

class ShopFeedScreen extends StatefulWidget {
  const ShopFeedScreen({super.key});

  @override
  State<ShopFeedScreen> createState() => _ShopFeedScreenState();
}

class _ShopFeedScreenState extends State<ShopFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ShopService _shopService = ShopService.instance;

  late Future<List<Product>> _productsFuture;
  late Future<List<Product>> _topSellersFuture;

  List<String> get _categoryTabs {
    const baseTabs = [
      'All',
      'Tech & Gadgets',
      'Fashion & Apparel',
      'Beauty & Care',
      'Studio Equipment',
      'Accessories',
      'Lifestyle',
      'Crazy Prices',
      'Mall',
      'Toys',
    ];
    final dynamicCategories = Product.userAddedProducts
        .map((p) => p.category ?? p.categoryId)
        .where((c) => c.isNotEmpty && !baseTabs.contains(c))
        .toSet();
    return [...baseTabs, ...dynamicCategories];
  }

  int _selectedCategoryIndex = 0;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _shopService.publishedProductNotifier.addListener(_onProductPublished);
    _loadData();
  }

  void _onProductPublished() {
    final newProduct = _shopService.publishedProductNotifier.value;
    if (newProduct != null) {
      final pCat = (newProduct.category ?? newProduct.categoryId).toLowerCase().trim();
      final tabs = _categoryTabs;
      final matchedIndex = tabs.indexWhere((tab) {
        final t = tab.toLowerCase().trim();
        return t == pCat || t.contains(pCat) || pCat.contains(t);
      });
      if (matchedIndex != -1) {
        _selectedCategoryIndex = matchedIndex;
      }
    }
    if (mounted) _loadData();
  }

  void _loadData() {
    final tabs = _categoryTabs;
    if (_selectedCategoryIndex >= tabs.length) {
      _selectedCategoryIndex = 0;
    }
    final selectedCategory = tabs[_selectedCategoryIndex];
    setState(() {
      _productsFuture = _shopService.getProducts(
        category: selectedCategory == 'All' ? null : selectedCategory,
        query: _currentQuery.isNotEmpty ? _currentQuery : null,
      );
      _topSellersFuture = _shopService.getTopSellers();
    });
  }

  @override
  void dispose() {
    _shopService.publishedProductNotifier.removeListener(_onProductPublished);
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(int index) {
    if (_selectedCategoryIndex == index) return;
    setState(() {
      _selectedCategoryIndex = index;
    });
    _loadData();
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShopSearchResultsScreen(initialQuery: trimmed),
        ),
      );
    } else {
      setState(() {
        _currentQuery = '';
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Offset for top tab bar (Community | Following | For You | Shop)
    final topPadding = MediaQuery.of(context).padding.top + 56;

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1C1C1E),
        onRefresh: () async {
          _loadData();
          await Future.wait([_productsFuture, _topSellersFuture]);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Top Bar Spacing ──────────────────────────────────────
            SliverToBoxAdapter(child: SizedBox(height: topPadding)),

            // ── Search Bar & Cart Button Header ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.white60, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: _onSearchSubmitted,
                                textInputAction: TextInputAction.search,
                                decoration: const InputDecoration(
                                  hintText: 'iPhone 17 promax',
                                  hintStyle: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _onSearchSubmitted('');
                                },
                                child: const Icon(Icons.close, color: Colors.white38, size: 18),
                              ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _onSearchSubmitted(_searchController.text),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'Search',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Shopping Cart with Badge "4"
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartPage()),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1C1C1E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: CartController.instance,
                            builder: (context, _) {
                              final count = CartController.instance.itemCount;
                              if (count <= 0) return const SizedBox.shrink();
                              return Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                  child: Center(
                                    child: Text(
                                      count > 99 ? '99+' : count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Mega Sale Promotional Banner ────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMegaSaleBanner(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Coupons & Perks Bar ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCouponsStrip(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Top Sellers (HOT) Section ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Top Sellers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'HOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Top Sellers Horizontal List ─────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: FutureBuilder<List<Product>>(
                  future: _topSellersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildTopSellersSkeleton();
                    }
                    final topSellers = snapshot.data ?? Product.screenshotTopSellers;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: topSellers.length,
                      itemBuilder: (context, index) {
                        return _buildTopSellerCard(topSellers[index]);
                      },
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Category Tabs Strip ─────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categoryTabs.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    final title = _categoryTabs[index];
                    return GestureDetector(
                      onTap: () => _onCategorySelected(index),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isSelected)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── 2-Column Product Grid ───────────────────────────────
            FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildGridSkeleton();
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Colors.white30, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'No products found',
                            style: TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _loadData,
                            child: const Text('Reload catalog'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildProductCard(products[index]);
                      },
                      childCount: products.length,
                    ),
                  ),
                );
              },
            ),

            // Bottom padding for scrolling comfort
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  // ── Mega Sale Promotional Banner ────────────────────────────────
  Widget _buildMegaSaleBanner() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const RadialGradient(
          center: Alignment(0.7, -0.2),
          radius: 1.2,
          colors: [
            Color(0xFF1E2638),
            Color(0xFF141416),
          ],
        ),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Stack(
        children: [
          // Banner Product Photography
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 150,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              child: _buildProductImage(
                'assets/images/mega_sale_banner.jpg',
                fallbackUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600',
              ),
            ),
          ),

          // Banner Left Text Content
          Positioned(
            left: 16,
            top: 14,
            bottom: 14,
            right: 155,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VILO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'VILO Shop | Mega\nSale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get A Free Gift | \$25 Min Spend',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    'Shop now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Indicator Dots at bottom center
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Coupons Strip ────────────────────────────────────────────────
  Widget _buildCouponsStrip() {
    return Row(
      children: [
        // Free shipping card
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Free shipping',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 2),
                Text(
                  'No min. spend',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // $15 off card
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '\$15 off',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 2),
                Text(
                  'No min. spend',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // New customer claim card
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'New customer',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Claim all gifts',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Claim',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Top Seller Card ──────────────────────────────────────────────
  Widget _buildTopSellerCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: product,
              id: product.id,
              title: product.name,
              price: product.formattedPrice,
              imageUrl: product.imageUrl,
              seller: product.seller,
              rating: product.rating,
              soldCount: product.soldCount,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with -99% badge
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: _buildProductImage(
                        product.imageUrl,
                        fallbackUrl: product.fallbackImageUrl,
                      ),
                    ),
                  ),
                  if (product.badge != null)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          product.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Price & seller tag
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    product.seller ?? '@vilo_deals',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2-Column Product Grid Card ───────────────────────────────────
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: product,
              id: product.id,
              title: product.name,
              price: product.formattedPrice,
              imageUrl: product.imageUrl,
              seller: product.seller,
              rating: product.rating,
              soldCount: product.soldCount,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with 👍 Badge
            Expanded(
              flex: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(
                    product.imageUrl,
                    fallbackUrl: product.fallbackImageUrl,
                  ),
                  if (product.badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Product Metadata
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Seller Badge / Branding
                    if (product.seller != null && product.seller!.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getSellerColor(product.seller!),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.seller!,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Title
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Price & Strikethrough
                    Row(
                      children: [
                        Text(
                          product.formattedPrice,
                          style: const TextStyle(
                            color: Color(0xFF38BDF8), // Cyan/Blue price accent
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.formattedOriginalPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            product.formattedOriginalPrice!,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Rating & Sold
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFBBF24), size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${product.rating.toStringAsFixed(1)} | ${product.formattedSoldCount}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSellerColor(String seller) {
    if (seller.toLowerCase().contains('glow') || seller.toLowerCase().contains('beauty')) {
      return const Color(0xFFEC4899);
    }
    if (seller.toLowerCase().contains('titan') || seller.toLowerCase().contains('tech')) {
      return const Color(0xFF3B82F6);
    }
    return const Color(0xFF6B7280);
  }

  /// Image loader that supports local assets with automatic network fallback
  Widget _buildProductImage(
    String imagePath, {
    String? fallbackUrl,
    BoxFit fit = BoxFit.cover,
  }) {
    final fallbackNetwork = fallbackUrl ??
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600';

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            fallbackNetwork,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1C1C1E),
              child: const Center(
                child: Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 28),
              ),
            ),
          );
        },
      );
    } else if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFF1C1C1E),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            fallbackNetwork,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1C1C1E),
              child: const Center(
                child: Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 28),
              ),
            ),
          );
        },
      );
    } else {
      return Image.network(
        fallbackNetwork,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1C1C1E),
          child: const Center(
            child: Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 28),
          ),
        ),
      );
    }
  }

  // ── Skeletons ───────────────────────────────────────────────────
  Widget _buildTopSellersSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          width: 100,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 40, color: Colors.white10),
                    const SizedBox(height: 4),
                    Container(height: 8, width: 60, color: Colors.white10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridSkeleton() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(height: 10, width: 60, color: Colors.white10),
                          Container(height: 12, width: double.infinity, color: Colors.white10),
                          Container(height: 12, width: 50, color: Colors.white10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: 4,
        ),
      ),
    );
  }
}
