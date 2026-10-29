import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../core/network/media_url.dart';

import '../data/models/product_model.dart';
import '../models/product.dart';
import '../presentation/controllers/cart_controller.dart';
import '../presentation/pages/cart_page.dart';
import 'shop_search_results_screen.dart';
import '../../inbox_activity/data/datasources/inbox_message_manager.dart';
import '../../inbox_activity/domain/entities/inbox_item.dart';
import '../../inbox_activity/presentation/pages/chat_detail_screen.dart';
import '../../profile/data/datasources/profile_sync_service.dart';
import '../../auth/data/datasources/token_storage.dart';
import '../../profile/data/datasources/profile_remote_data_source.dart';
import '../../profile/presentation/screens/public_profile_screen.dart';

/// Product Detail Screen matching Vilo's Obsidian Dark Canvas aesthetic (#080808 / #141416).
class ProductDetailScreen extends StatefulWidget {
  final ProductModel? productModel;
  final Product? product;
  final String? id;
  final String? title;
  final String? price;
  final String? imageUrl;
  final String? seller;
  final String? sellerAvatar;
  final String? sellerId;
  final double? rating;
  final int? soldCount;
  final String? description;
  final int? stock;
  final String? category;
  final double? originalPrice;

  const ProductDetailScreen({
    super.key,
    this.productModel,
    this.product,
    this.id,
    this.title,
    this.price,
    this.imageUrl,
    this.seller,
    this.sellerAvatar,
    this.sellerId,
    this.rating,
    this.soldCount,
    this.description,
    this.stock,
    this.category,
    this.originalPrice,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _imagePageController = PageController();

  // Section Keys for top tab bar smooth scrolling
  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _descriptionKey = GlobalKey();
  final GlobalKey _reviewsKey = GlobalKey();
  final GlobalKey _recommendationsKey = GlobalKey();

  // Interactive UI state
  int _currentImageIndex = 0;
  int _selectedTopTab = 0; // 0: Overview, 1: Reviews, 2: Description, 3: Recommendations
  bool _isWishlisted = false;
  bool _isFollowingStore = false;
  bool _isVoucherClaimed = false;
  bool _isAddingToCart = false;
  String _selectedReviewFilter = 'All (1.2k)';

  // Design tokens for Obsidian Dark Canvas
  static const Color _bgVoid = Color(0xFF080808);
  static const Color _bgSurface = Color(0xFF141416);
  static const Color _bgSurfaceElevated = Color(0xFF1C1C1E);
  static const Color _surfaceStroke = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color _accentBlue = Color(0xFF38BDF8);
  static const Color _accentGold = Color(0xFFF59E0B);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentRed = Color(0xFFEF4444);

  // Resolved metadata
  late final String _resolvedTitle;
  late final String _resolvedPrice;
  late final String _resolvedOriginalPrice;
  late final String _resolvedDiscount;
  late final String _resolvedSeller;
  late final String? _resolvedSellerAvatar;
  late final String? _resolvedSellerId;
  late final bool _isOwner;
  late final double _resolvedRating;
  late final String _resolvedReviewsCount;
  late final String _resolvedSoldCount;
  late final List<String> _carouselImages;

  @override
  void initState() {
    super.initState();
    _initProductData();
  }

  void _navigateToSellerProfile() {
    final cleanSeller = _resolvedSeller.startsWith('@') ? _resolvedSeller : '@$_resolvedSeller';
    final rawUsername = cleanSeller.replaceAll('@', '').trim();
    final avatar = InboxMessageManager.resolveSellerAvatar(
      candidateAvatar: _resolvedSellerAvatar,
      sellerHandle: cleanSeller,
    );
    final targetUid = int.tryParse(_resolvedSellerId ?? '');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: targetUid,
          username: rawUsername,
          displayName: _resolvedSeller,
          avatarUrl: avatar,
          isFollowing: _isFollowingStore,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isFollowingStore = ProfileSyncService.instance.isFollowingUser(
            username: _resolvedSeller,
            userId: targetUid,
          );
        });
      }
    });
  }

  void _initProductData() {
    _resolvedTitle = widget.productModel?.title ??
        widget.product?.name ??
        widget.title ??
        'iPhone 17 Pro Max Titanium (256GB)';

    if (widget.productModel != null) {
      _resolvedPrice = widget.productModel!.formattedPrice;
      _resolvedOriginalPrice = widget.productModel!.formattedOriginalPrice ?? '\$1,399.00';
      _resolvedDiscount = widget.productModel!.discountPercentage != null
          ? '-${widget.productModel!.discountPercentage}% OFF'
          : '-15% OFF';
    } else if (widget.product != null) {
      _resolvedPrice = widget.product!.formattedPrice;
      _resolvedOriginalPrice = widget.product!.formattedOriginalPrice ?? '\$1,399.00';
      _resolvedDiscount = widget.product!.discountPercentage != null
          ? '-${widget.product!.discountPercentage}% OFF'
          : '-15% OFF';
    } else {
      _resolvedPrice = widget.price ?? '\$1,199.00';
      _resolvedOriginalPrice = '\$1,399.00';
      _resolvedDiscount = '-15% OFF';
    }

    _resolvedSeller = widget.productModel?.sellerUsername ??
        widget.productModel?.sellerName ??
        widget.product?.seller ??
        widget.seller ??
        'TechHorizon Global';
    _resolvedSellerAvatar = widget.productModel?.sellerAvatar ??
        widget.product?.sellerAvatar ??
        widget.sellerAvatar;
    _resolvedSellerId = widget.productModel?.sellerId?.toString() ??
        widget.product?.sellerId ??
        widget.sellerId;
    _isOwner = ProfileSyncService.instance.isCurrentUser(
      username: _resolvedSeller,
      id: _resolvedSellerId,
    );
    final targetUid = int.tryParse(_resolvedSellerId ?? '');
    _isFollowingStore = ProfileSyncService.instance.isFollowingUser(
      username: _resolvedSeller,
      userId: targetUid,
    );

    _resolvedRating = widget.productModel?.rating ?? widget.product?.rating ?? widget.rating ?? 4.8;
    _resolvedReviewsCount = '1.2k';
    _resolvedSoldCount = '4.3k';

    final primaryImg = widget.imageUrl ??
        (widget.productModel?.images.isNotEmpty == true
            ? widget.productModel!.images.first
            : widget.product?.imageUrl);

    _carouselImages = [
      if (primaryImg != null && primaryImg.isNotEmpty) primaryImg,
      'assets/images/iphone_17_pro_max_case.jpg',
      'assets/images/iphone_deal.jpg',
      'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=1000',
      'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=1000',
      'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=1000',
      'https://images.unsplash.com/photo-1580910051074-3eb694886505?w=1000',
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=1000',
    ];

    while (_carouselImages.length < 8) {
      _carouselImages.add('assets/images/iphone_17_pro_max_case.jpg');
    }
    if (_carouselImages.length > 8) {
      _carouselImages.removeRange(8, _carouselImages.length);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key, int tabIndex) {
    setState(() => _selectedTopTab = tabIndex);
    final currentContext = key.currentContext;
    if (currentContext != null) {
      Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );
    }
  }

  Future<void> _handleAddToCart() async {
    HapticFeedback.mediumImpact();
    setState(() => _isAddingToCart = true);

    ProductModel productToAdd;
    if (widget.productModel != null) {
      productToAdd = widget.productModel!;
    } else {
      final clean = _resolvedPrice.replaceAll(RegExp(r'[^0-9.]'), '');
      final pVal = double.tryParse(clean) ?? 1199.0;
      final int prodId = widget.productModel?.id ??
          (widget.product != null
              ? (int.tryParse(widget.product!.id) ?? widget.product!.id.hashCode.abs())
              : (widget.id != null
                  ? (int.tryParse(widget.id!) ?? widget.id!.hashCode.abs())
                  : (_resolvedTitle.isNotEmpty ? _resolvedTitle.hashCode.abs() : 1701)));

      productToAdd = ProductModel(
        id: prodId,
        title: _resolvedTitle,
        description: 'iPhone 17 Pro Max Titanium (256GB). Grade 5 aerospace titanium design.',
        price: pVal,
        originalPrice: 1399.0,
        discountPercentage: 15,
        stock: 45,
        rating: _resolvedRating,
        reviewCount: 1200,
        salesCount: 4300,
        sellerName: _resolvedSeller,
        images: _carouselImages,
      );
    }

    final success = await CartController.instance.addToCart(productToAdd);
    if (!mounted) return;
    setState(() => _isAddingToCart = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF18181B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.white12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0x2610B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: _accentGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Added to Bag',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      _resolvedTitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
                },
                child: const Text('View Cart', style: TextStyle(color: _accentBlue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _openSellerChatDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildSellerChatSheet(ctx),
    );
  }

  void _openVideoPreviewSheet(String title, String creator, String videoAsset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _VideoPlayerModal(
        title: title,
        creator: creator,
        videoAsset: videoAsset,
        onAddToCart: _handleAddToCart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgVoid,
      body: Stack(
        children: [
          // Scrollable Body
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 94),
              ),
              SliverToBoxAdapter(
                key: _overviewKey,
                child: _buildImageCarousel(),
              ),
              SliverToBoxAdapter(
                child: _buildProductMetaSection(),
              ),
              SliverToBoxAdapter(
                child: _buildStoreProfileSection(),
              ),
              SliverToBoxAdapter(
                key: _descriptionKey,
                child: _buildDescriptionSection(),
              ),
              SliverToBoxAdapter(
                child: _buildCreatorVideoShowcase(),
              ),
              SliverToBoxAdapter(
                key: _reviewsKey,
                child: _buildUserReviewsSection(),
              ),
              SliverToBoxAdapter(
                child: _buildWelcomeVoucherCard(),
              ),
              SliverToBoxAdapter(
                key: _recommendationsKey,
                child: _buildRecommendationsSection(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),

          // Sticky Top Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStickyTopHeader(),
          ),

          // Sticky Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStickyBottomBar(),
          ),
        ],
      ),
    );
  }

  // 1. TOP HEADER & NAVIGATION BAR
  Widget _buildStickyTopHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    final tabs = ['Overview', 'Reviews', 'Description', 'Recommendations'];

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _bgVoid.withValues(alpha: 0.85),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _bgSurfaceElevated.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: _surfaceStroke),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShopSearchResultsScreen(initialQuery: _resolvedTitle),
                          ),
                        );
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _bgSurfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _surfaceStroke),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _resolvedTitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const Icon(Icons.mic_none_rounded, color: Colors.white38, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
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
                                color: _bgSurfaceElevated.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                border: Border.all(color: _surfaceStroke),
                              ),
                              child: const Center(
                                child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 19),
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _accentRed,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _bgVoid, width: 1.5),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: tabs.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedTopTab == index;
                    return GestureDetector(
                      onTap: () {
                        if (index == 0) _scrollToSection(_overviewKey, 0);
                        if (index == 1) _scrollToSection(_reviewsKey, 1);
                        if (index == 2) _scrollToSection(_descriptionKey, 2);
                        if (index == 3) _scrollToSection(_recommendationsKey, 3);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tabs[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white38,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 22 : 0,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. MULTI-PHOTO IMAGE CAROUSEL
  Widget _buildImageCarousel() {
    return Container(
      height: 400,
      width: double.infinity,
      color: const Color(0xFF0F0F11),
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            itemCount: _carouselImages.length,
            onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
            itemBuilder: (context, idx) {
              final path = _carouselImages[idx];
              return _buildCarouselImageWidget(path);
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 90,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_bgVoid, Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isWishlisted = !_isWishlisted);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Icon(
                        _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isWishlisted ? _accentRed : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildOverlayBadge(Icons.assignment_return_outlined, 'Free 6-day Returns', Colors.white),
                _buildOverlayBadge(Icons.verified_outlined, 'Store Seal', _accentBlue),
                _buildOverlayBadge(Icons.local_shipping_outlined, 'Free Shipping', _accentGreen),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${_carouselImages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayBadge(IconData icon, String text, Color accent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 12),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselImageWidget(String path) {
    final resolvedPath = resolveBackendMediaUrl(path);
    if (resolvedPath.startsWith('assets/')) {
      return Image.asset(
        resolvedPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }
    return Image.network(
      resolvedPath,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _buildImagePlaceholder(loading: true);
      },
      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder({bool loading = false}) {
    return Container(
      color: const Color(0xFF141416),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
              )
            : const Icon(Icons.phone_iphone_rounded, color: Colors.white12, size: 64),
      ),
    );
  }

  // 3. PRODUCT META & SHIPPING INFO
  Widget _buildProductMetaSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      _resolvedPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _resolvedOriginalPrice,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.white38,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accentRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _accentRed.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _resolvedDiscount,
                        style: const TextStyle(
                          color: _accentRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _bgSurfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: _surfaceStroke),
                ),
                child: const Icon(Icons.share_outlined, color: Colors.white70, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _resolvedTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => const Icon(Icons.star_rounded, color: _accentGold, size: 16),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_resolvedRating',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 4),
              Text(
                '($_resolvedReviewsCount)',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 12, color: Colors.white24),
              const SizedBox(width: 12),
              Text(
                '$_resolvedSoldCount sold',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _surfaceStroke),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accentBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_shipping_outlined, color: _accentBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Standard Delivery • FREE (was \$15.00)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Estimated arrival: 2-3 business days with tracking',
                            style: TextStyle(color: Colors.white60, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTrustFeature(Icons.security_rounded, '1-Year Warranty'),
                    _buildTrustFeature(Icons.verified_user_outlined, '100% Genuine'),
                    _buildTrustFeature(Icons.published_with_changes_rounded, '6-Day Return'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustFeature(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // 4. STORE PROFILE & ACTION BAR
  Widget _buildStoreProfileSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _surfaceStroke),
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _navigateToSellerProfile,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: ClipOval(
                      child: () {
                        final storeAvatar = _resolvedSellerAvatar;
                        if (storeAvatar != null && storeAvatar.isNotEmpty) {
                          final resolvedStoreAvatar =
                              resolveBackendMediaUrl(storeAvatar);
                          if (resolvedStoreAvatar.startsWith('http://') ||
                              resolvedStoreAvatar.startsWith('https://')) {
                            return Image.network(
                              resolvedStoreAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                            );
                          } else {
                            return Image.asset(
                              storeAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                            );
                          }
                        }
                        return const Center(
                          child: Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                        );
                      }(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToSellerProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _resolvedSeller,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _accentBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _accentBlue.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified_rounded, color: _accentBlue, size: 11),
                                  SizedBox(width: 3),
                                  Text(
                                    'Official Store',
                                    style: TextStyle(
                                      color: _accentBlue,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '99.4% Positive Feedback • 128k Followers',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                _isOwner
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222226),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          'Your Store',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final newFollowState = !_isFollowingStore;
                          setState(() => _isFollowingStore = newFollowState);
                          final targetUid = int.tryParse(_resolvedSellerId ?? '') ?? _resolvedSeller.hashCode.abs();
                          ProfileSyncService.instance.notifyFollowChanged(
                            targetUserId: targetUid,
                            isFollowing: newFollowState,
                          );
                          try {
                            if (newFollowState) {
                              await ProfileRemoteDataSource.instance.toggleFollow(targetUid);
                            } else {
                              await ProfileRemoteDataSource.instance.unfollow(targetUid);
                            }
                          } catch (_) {}
                          if (mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1E1E22),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                                content: Text(newFollowState ? 'Following $_resolvedSeller' : 'Unfollowed $_resolvedSeller'),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _isFollowingStore ? Colors.transparent : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isFollowingStore ? Colors.white38 : Colors.white,
                            ),
                          ),
                          child: Text(
                            _isFollowingStore ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: _isFollowingStore ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _bgSurfaceElevated.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openSellerChatDialog,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: const Text('Send Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isAddingToCart ? null : _handleAddToCart,
                          icon: _isAddingToCart
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Icon(Icons.add_shopping_cart_rounded, size: 16),
                          label: Text(_isAddingToCart ? 'Adding...' : 'Add to cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. PRODUCT DESCRIPTION SECTION
  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _surfaceStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Description',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Engineered with an ultra-lightweight grade 5 aerospace titanium band and contoured edges. Features the revolutionary A18 Pro chip, next-generation 48MP fusion camera system with 5x optical telephoto zoom, and unprecedented battery endurance.\n\n• Display: 6.9-inch Super Retina XDR with ProMotion 120Hz\n• Capacity: 256GB High-Speed NVMe Storage\n• Material: Natural Titanium chassis with Ceramic Shield front\n• Connectivity: USB-C 3.0 up to 10Gbps, Wi-Fi 7, 5G NR',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSpecTag('A18 Pro Silicon'),
                _buildSpecTag('5x Telephoto Zoom'),
                _buildSpecTag('Action Button'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bgSurfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  // 6. CREATOR VIDEO SHOWCASE SECTION
  Widget _buildCreatorVideoShowcase() {
    final List<Map<String, String>> creatorVideos = [
      {
        'title': 'iPhone 17 Pro Max Camera Test & Vlog',
        'creator': '@alex_tech',
        'views': '142.5K',
        'thumbnail': 'assets/images/iphone_17_pro_max_case.jpg',
        'videoAsset': 'assets/videos/vid1.mp4',
      },
      {
        'title': 'Natural Titanium Unboxing & 48h Impressions',
        'creator': '@unbox_studio',
        'views': '98.2K',
        'thumbnail': 'assets/images/iphone_deal.jpg',
        'videoAsset': 'assets/videos/vid2.mp4',
      },
      {
        'title': 'Durability & Action Button Creator Setup',
        'creator': '@gadgetreview',
        'views': '235.1K',
        'thumbnail': 'assets/images/v_watch_ultra.jpg',
        'videoAsset': 'assets/videos/vid3.mp4',
      },
      {
        'title': 'Cinematic 4K ProRes Recording Secrets',
        'creator': '@mkbhd_style',
        'views': '64.8K',
        'thumbnail': 'assets/images/ring_light.jpg',
        'videoAsset': 'assets/videos/vid4.mp4',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Videos from creators',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '30+',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Text('See all', style: TextStyle(color: _accentBlue, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: creatorVideos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = creatorVideos[index];
                return GestureDetector(
                  onTap: () => _openVideoPreviewSheet(
                    item['title']!,
                    item['creator']!,
                    item['videoAsset']!,
                  ),
                  child: Container(
                    width: 126,
                    decoration: BoxDecoration(
                      color: _bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _surfaceStroke),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            item['thumbnail']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: _bgSurfaceElevated),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white38),
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item['creator']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.remove_red_eye_outlined, color: Colors.white54, size: 10),
                                    const SizedBox(width: 3),
                                    Text(
                                      item['views']!,
                                      style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 7. USER REVIEWS SECTION
  Widget _buildUserReviewsSection() {
    final filterOptions = ['All (1.2k)', 'With Photos (450)', '5 Star (980)', '4 Star (180)'];

    final allReviews = [
      {
        'user': 'kevin_techlover',
        'rating': 5,
        'date': '2 days ago',
        'spec': 'Natural Titanium · 256GB',
        'comment':
            'The grade 5 titanium finish is astonishingly lightweight compared to previous models. Super fast shipping from TechHorizon Global, arrived sealed with verified Apple warranty!',
        'photos': [
          'assets/images/iphone_17_pro_max_case.jpg',
          'assets/images/iphone_deal.jpg',
        ],
        'likes': 64,
      },
      {
        'user': 'sarah_creatives',
        'rating': 5,
        'date': 'Yesterday',
        'spec': 'Desert Titanium · 256GB',
        'comment':
            'Color is subtle and luxurious in person. Battery life easily lasts 2 full days of creator filming. Highly recommend this store.',
        'photos': [
          'assets/images/magsafe_mount.jpg',
        ],
        'likes': 41,
      },
      {
        'user': 'dara_cambodia',
        'rating': 5,
        'date': '3 days ago',
        'spec': 'Black Titanium · 256GB',
        'comment':
            'Arrived in Phnom Penh within 48 hours in pristine condition. Official seal was intact. 10/10 shopping experience on Vilo.',
        'photos': <String>[],
        'likes': 19,
      },
      {
        'user': 'alex_m',
        'rating': 4,
        'date': '5 days ago',
        'spec': 'White Titanium · 256GB',
        'comment':
            'Phone is a complete beast. Only deducted one star because delivery courier called 30 mins before delivery window, but package was 100% secure.',
        'photos': [
          'assets/images/pocket_fill_light.jpg',
        ],
        'likes': 12,
      },
    ];

    final filteredReviews = allReviews.where((r) {
      if (_selectedReviewFilter == 'With Photos (450)') {
        return (r['photos'] as List).isNotEmpty;
      }
      if (_selectedReviewFilter == '5 Star (980)') {
        return r['rating'] == 5;
      }
      if (_selectedReviewFilter == '4 Star (180)') {
        return r['rating'] == 4;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'User Reviews',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('($_resolvedReviewsCount)', style: const TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: _accentGold, size: 16),
                  const SizedBox(width: 3),
                  Text('$_resolvedRating / 5.0',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: filterOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = filterOptions[index];
                final isSelected = _selectedReviewFilter == option;

                return GestureDetector(
                  onTap: () => setState(() => _selectedReviewFilter = option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : _bgSurface,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: isSelected ? Colors.white : Colors.white12),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredReviews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = filteredReviews[index];
              return _buildReviewCard(review);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final photos = review['photos'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _surfaceStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _bgSurfaceElevated,
                child: Text(
                  (review['user'] as String).substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${review['user']}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    Text(
                      '${review['spec']} • ${review['date']}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  review['rating'] as int,
                  (starIndex) => const Icon(Icons.star_rounded, color: _accentGold, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'] as String,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.45),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: photos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, pIndex) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      photos[pIndex],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(width: 60, height: 60, color: _bgSurfaceElevated),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.thumb_up_outlined, color: Colors.white38, size: 13),
              const SizedBox(width: 4),
              Text(
                'Helpful (${review['likes']})',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. PROMOTIONAL VOUCHER CARD
  Widget _buildWelcomeVoucherCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.4,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF111827),
            ],
          ),
          border: Border.all(color: _accentBlue.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentBlue.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.confirmation_number_outlined, color: _accentBlue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Welcome Voucher \$10 OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Min. spend \$50 • Valid for first-time buyers',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isVoucherClaimed
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      setState(() => _isVoucherClaimed = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: _bgSurfaceElevated,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          content: const Text(
                            '\$10 Welcome Voucher applied to your account!',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isVoucherClaimed ? const Color(0x2610B981) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isVoucherClaimed ? _accentGreen : Colors.white,
                  ),
                ),
                child: Text(
                  _isVoucherClaimed ? 'Claimed ✓' : 'Claim',
                  style: TextStyle(
                    color: _isVoucherClaimed ? _accentGreen : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 9. RECOMMENDATIONS SECTION
  Widget _buildRecommendationsSection() {
    final recommendations = [
      {
        'title': 'MagSafe Desktop Phone Mount',
        'price': '\$19.99',
        'image': 'assets/images/magsafe_mount.jpg',
      },
      {
        'title': 'V-Series Wireless Headphones',
        'price': '\$215.00',
        'image': 'assets/images/v_series_headphones.jpg',
      },
      {
        'title': 'RGB Music-Sync Desk Light Bars',
        'price': '\$39.99',
        'image': 'assets/images/rgb_light_bars.jpg',
      },
      {
        'title': 'Portable LED Pocket Fill Light',
        'price': '\$22.99',
        'image': 'assets/images/pocket_fill_light.jpg',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You May Also Like',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recommendations.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = recommendations[index];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          title: item['title'],
                          price: item['price'],
                          imageUrl: item['image'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: _bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _surfaceStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.asset(
                              item['image']!,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: _bgSurfaceElevated),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']!,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['price']!,
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 10. STICKY GLASSMORPHIC BOTTOM ACTION BAR
  Widget _buildStickyBottomBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _bgVoid.withValues(alpha: 0.88),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding > 0 ? bottomPadding : 14),
          child: Row(
            children: [
              // 1. Shopping Bag Quick Button with Real-Time Badge
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
                },
                child: AnimatedBuilder(
                  animation: CartController.instance,
                  builder: (context, childWidget) {
                    final count = CartController.instance.itemCount;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _surfaceStroke),
                          ),
                          child: const Center(
                            child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accentRed,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _bgVoid, width: 1.5),
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),

              // 2. Send Message Button (#141416 dark glassmorphic container with chat icon)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _openSellerChatDialog,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 16),
                    label: const Text('Send Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _bgSurface,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Add to Cart Button (Primary CTA)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isAddingToCart ? null : _handleAddToCart,
                    icon: _isAddingToCart
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded, color: Colors.black, size: 16),
                    label: Text(_isAddingToCart ? 'Adding...' : 'Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInquiryThumbnail() {
    final img = _carouselImages.isNotEmpty ? _carouselImages.first : (widget.imageUrl ?? '');
    final resolvedImg = resolveBackendMediaUrl(img);
    if (resolvedImg.startsWith('http://') || resolvedImg.startsWith('https://')) {
      return Image.network(
        resolvedImg,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 44,
          height: 44,
          color: const Color(0xFF242428),
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 20),
        ),
      );
    }
    return Image.asset(
      img.isNotEmpty ? img : 'assets/images/iphone_17_pro_max_case.jpg',
      width: 44,
      height: 44,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: 44,
        height: 44,
        color: const Color(0xFF242428),
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 20),
      ),
    );
  }

  void _handleSendSellerInquiry(BuildContext ctx, String rawText) {
    final text = rawText.trim();
    final messageText = text.isNotEmpty
        ? text
        : 'Hi $_resolvedSeller, I have an inquiry about $_resolvedTitle ($_resolvedPrice). Is it currently available?';

    final buyerUser = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
    final rawBuyerHandle = (buyerUser?.username != null && buyerUser!.username.trim().isNotEmpty)
        ? buyerUser.username.trim()
        : ProfileSyncService.instance.currentUsername;
    final buyerHandle = rawBuyerHandle.startsWith('@') ? rawBuyerHandle : '@$rawBuyerHandle';
    final buyerAvatar = buyerUser?.avatarUrl ?? ProfileSyncService.instance.currentUserAvatar;

    final handle = _resolvedSeller.startsWith('@')
        ? _resolvedSeller
        : '@${_resolvedSeller.replaceAll(' ', '_').toLowerCase()}';
    final threadId = InboxMessageManager.buildThreadId(buyerHandle, handle);
    final sellerAvatar = InboxMessageManager.resolveUserAvatar(handle, candidateAvatar: widget.sellerAvatar);

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: messageText,
      isMe: true,
      senderHandle: buyerHandle,
      timestamp: 'Just now',
      status: 'Sent',
      imageUrl: widget.imageUrl,
      imageUrls: widget.imageUrl != null && widget.imageUrl!.isNotEmpty ? [widget.imageUrl!] : null,
    );

    final existingThread = InboxMessageManager.instance.getThread(threadId) ??
        InboxMessageManager.instance.getThreadByUsername(handle);

    final DirectMessageThread threadToRegister;
    if (existingThread != null) {
      threadToRegister = existingThread.copyWith(
        lastMessage: messageText,
        timeAgo: 'Just now',
        messages: [...existingThread.messages, newMsg],
      );
    } else {
      threadToRegister = DirectMessageThread(
        id: threadId,
        username: handle,
        avatarUrl: sellerAvatar,
        senderHandle: buyerHandle,
        senderAvatar: buyerAvatar,
        recipientHandle: handle,
        recipientAvatar: sellerAvatar,
        lastMessage: messageText,
        timeAgo: 'Just now',
        isVerified: true,
        followersCount: '128k',
        messages: [newMsg],
      );
    }

    final registeredThread = InboxMessageManager.instance.addOrUpdateThread(threadToRegister);

    Navigator.pop(ctx);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _bgSurfaceElevated,
        content: Text('Message sent to $_resolvedSeller! Opening chat...'),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(thread: registeredThread),
      ),
    );
  }

  void _handleOpenSellerChatDirectly(BuildContext ctx) {
    final buyerUser = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
    final rawBuyerHandle = (buyerUser?.username != null && buyerUser!.username.trim().isNotEmpty)
        ? buyerUser.username.trim()
        : ProfileSyncService.instance.currentUsername;
    final buyerHandle = rawBuyerHandle.startsWith('@') ? rawBuyerHandle : '@$rawBuyerHandle';
    final buyerAvatar = buyerUser?.avatarUrl ?? ProfileSyncService.instance.currentUserAvatar;

    final handle = _resolvedSeller.startsWith('@')
        ? _resolvedSeller
        : '@${_resolvedSeller.replaceAll(' ', '_').toLowerCase()}';
    final threadId = InboxMessageManager.buildThreadId(buyerHandle, handle);
    final sellerAvatar = InboxMessageManager.resolveUserAvatar(handle, candidateAvatar: widget.sellerAvatar);

    var existingThread = InboxMessageManager.instance.getThread(threadId) ??
        InboxMessageManager.instance.getThreadByUsername(handle);

    final resolvedThread = existingThread ??
        InboxMessageManager.instance.addOrUpdateThread(
          DirectMessageThread(
            id: threadId,
            username: handle,
            avatarUrl: sellerAvatar,
            senderHandle: buyerHandle,
            senderAvatar: buyerAvatar,
            recipientHandle: handle,
            recipientAvatar: sellerAvatar,
            lastMessage: 'Viewing $_resolvedTitle',
            timeAgo: 'Just now',
            isVerified: true,
            followersCount: '128k',
            messages: [
              ChatMessage(
                id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
                text: 'Hi $_resolvedSeller! I am inquiring about $_resolvedTitle ($_resolvedPrice).',
                isMe: true,
                senderHandle: buyerHandle,
                timestamp: 'Just now',
                status: 'Sent',
              ),
            ],
          ),
        );

    Navigator.pop(ctx);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(thread: resolvedThread),
      ),
    );
  }

  Widget _buildQuickInquiryChip(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () {
        controller.text = label;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: _bgSurfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildSellerChatSheet(BuildContext ctx) {
    final TextEditingController msgController = TextEditingController();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: _bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFF1F2937),
                  child: Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resolvedSeller,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Text(
                        'Typically replies in under 5 minutes',
                        style: TextStyle(color: _accentGreen, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _handleOpenSellerChatDirectly(ctx),
                  icon: const Icon(Icons.chat_outlined, size: 14, color: _accentBlue),
                  label: const Text('Open Chat', style: TextStyle(color: _accentBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: _accentBlue.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bgSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildProductInquiryThumbnail(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inquiring about: $_resolvedTitle ($_resolvedPrice)',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap below to send inquiry or chat directly',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildQuickInquiryChip('Is this in stock?', msgController),
                  const SizedBox(width: 6),
                  _buildQuickInquiryChip('Can you ship today?', msgController),
                  const SizedBox(width: 6),
                  _buildQuickInquiryChip('Is price negotiable?', msgController),
                  const SizedBox(width: 6),
                  _buildQuickInquiryChip('Warranty details?', msgController),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Type your question to $_resolvedSeller...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: _bgSurfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _handleSendSellerInquiry(ctx, msgController.text),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Inquiry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Creator Video Player Bottom Sheet
class _VideoPlayerModal extends StatefulWidget {
  final String title;
  final String creator;
  final String videoAsset;
  final VoidCallback onAddToCart;

  const _VideoPlayerModal({
    required this.title,
    required this.creator,
    required this.videoAsset,
    required this.onAddToCart,
  });

  @override
  State<_VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<_VideoPlayerModal> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((result) {
        if (!mounted) return;
        setState(() => _isInitialized = true);
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E10),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isInitialized)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white24),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: !_controller.value.isPlaying && _isInitialized
                        ? const Center(
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.creator,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(widget.title,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onAddToCart();
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
