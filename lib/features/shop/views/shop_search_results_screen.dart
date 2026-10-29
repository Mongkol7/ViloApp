import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/creator_merchant.dart';
import '../presentation/controllers/cart_controller.dart';
import '../presentation/pages/cart_page.dart';
import '../widgets/merchant_card.dart';

/// Shop Search & Creator Merchant List Screen matching Vilo's Obsidian Dark Canvas aesthetic (#080808 / #141416).
/// Matches the reference design in image_54091e.png.
class ShopSearchResultsScreen extends StatefulWidget {
  final String initialQuery;

  const ShopSearchResultsScreen({super.key, this.initialQuery = 'Keyboard'});

  @override
  State<ShopSearchResultsScreen> createState() =>
      _ShopSearchResultsScreenState();
}

class _ShopSearchResultsScreenState extends State<ShopSearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TabController _topTabController;

  static const Color _bgVoid = Color(0xFF080808);
  static const Color _bgSurfaceElevated = Color(0xFF1C1C1E);
  static const Color _surfaceStroke = Color(
    0x14FFFFFF,
  ); // rgba(255, 255, 255, 0.08)

  final List<String> _topTabs = ['Community', 'Following', 'For You', 'Shop'];
  late String _currentQuery;

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery;
    _searchController = TextEditingController(text: _currentQuery);
    // 4 tabs, index 3 is 'Shop'
    _topTabController = TabController(
      length: _topTabs.length,
      vsync: this,
      initialIndex: 3,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _topTabController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentQuery = query.trim();
    });
  }

  void _onClearQuery() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
    });
  }

  List<CreatorMerchant> get _filteredMerchants {
    if (_currentQuery.isEmpty) {
      return CreatorMerchant.mockMerchants;
    }
    final q = _currentQuery.toLowerCase();
    return CreatorMerchant.mockMerchants.where((m) {
      final matchesHandle = m.handle.toLowerCase().contains(q);
      final matchesName = m.name.toLowerCase().contains(q);
      final matchesProduct = m.products.any(
        (p) =>
            p.title.toLowerCase().contains(q) ||
            p.specs.toLowerCase().contains(q),
      );
      return matchesHandle || matchesName || matchesProduct;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final merchants = _filteredMerchants;

    return Scaffold(
      backgroundColor: _bgVoid,
      body: Stack(
        children: [
          // ── Scrollable Results Body ──────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Offset for top tabs and search bar header
              SliverToBoxAdapter(child: SizedBox(height: topPadding + 112)),

              // Filter Results Meta Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Row(
                    children: [
                      Text(
                        _currentQuery.isNotEmpty
                            ? 'Results for "$_currentQuery"'
                            : 'All Creator Merchants',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _surfaceStroke),
                        ),
                        child: Text(
                          '${merchants.length} stores',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Merchant Cards List
              if (merchants.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: MerchantCard(merchant: merchants[index]),
                      );
                    }, childCount: merchants.length),
                  ),
                )
              else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                ),
            ],
          ),

          // ── Sticky Top Bar & Navigation ──────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStickyTopHeader(topPadding),
          ),
        ],
      ),
    );
  }

  // ── Top Bar with Tab Navigation and Active Search Bar ────────────
  Widget _buildStickyTopHeader(double topPadding) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _bgVoid.withValues(alpha: 0.88),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          padding: EdgeInsets.fromLTRB(16, topPadding + 4, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Top Tab Navigation (Community, Following, For You, Shop) + Magnifier icon
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TabBar(
                        controller: _topTabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: Colors.white,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorWeight: 2.5,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white38,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                        dividerColor: Colors.transparent,
                        onTap: (index) {
                          if (index != 3 && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        tabs: _topTabs
                            .map((title) => Tab(text: title))
                            .toList(),
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _bgSurfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: _surfaceStroke),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Search Bar + Search Button + Shopping Cart Icon Badge
              Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _bgSurfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: _surfaceStroke),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Search Bar Container
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: _bgSurfaceElevated,
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: _surfaceStroke),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: Colors.white54,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _onSearchSubmitted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search products or creators...',
                                hintStyle: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: _onClearQuery,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white38,
                                  size: 17,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          // High-contrast pure white "Search" button
                          GestureDetector(
                            onTap: () =>
                                _onSearchSubmitted(_searchController.text),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Search',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Shopping Cart with Notification Badge
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartPage(),
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: CartController.instance,
                      builder: (context, childWidget) {
                        final count = CartController.instance.itemCount;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _bgSurfaceElevated,
                                shape: BoxShape.circle,
                                border: Border.all(color: _surfaceStroke),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _bgVoid,
                                      width: 1.2,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      count > 99 ? '99+' : count.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                      ),
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final suggested = [
      'Keyboard',
      'Gaming Mouse',
      'Desk Light',
      'Microphone',
      'V-Watch',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _bgSurfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: _surfaceStroke),
              ),
              child: const Center(
                child: Icon(
                  Icons.search_off_rounded,
                  color: Colors.white30,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No stores or products found for "$_currentQuery"',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching with different keywords or explore suggested creator gear below.',
              style: TextStyle(color: Colors.white38, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggested.map((tag) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = tag;
                    _onSearchSubmitted(tag);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _bgSurfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _surfaceStroke),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
