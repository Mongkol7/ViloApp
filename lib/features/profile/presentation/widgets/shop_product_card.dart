import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../auth/data/datasources/token_storage.dart';
import '../mock/profile_mock_data.dart';
import '../style/pulse_tokens.dart';
import '../../data/datasources/profile_sync_service.dart';
import '../../../shop/models/product.dart';
import '../../../shop/data/datasources/shop_remote_data_source.dart';
import '../../../shop/presentation/pages/product_detail_page.dart';
import '../../../inbox_activity/data/datasources/inbox_message_manager.dart';
import '../../../inbox_activity/domain/entities/inbox_item.dart';

/// A single product row in the Shop tab. Pure display widget — placed
/// directly inside a SliverList by the parent, no scroll of its own.
class ShopProductCard extends StatelessWidget {
  final dynamic product;
  final String? sellerUsername;
  final String? sellerAvatarUrl;
  final bool isCurrentUser;

  const ShopProductCard({
    super.key,
    required this.product,
    this.sellerUsername,
    this.sellerAvatarUrl,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Product.stockUpdateNotifier,
      builder: (context, _, child) {
        final String name;
        final String price;
        final String imageUrl;
        final String description;
        final String seller;
        final String id;
        final String? originalPrice;
        final int? discountPercent;
        final String? sellerAvatar;
        final String? sellerId;
        Product? entity;

        final String cleanSellerUsername = (sellerUsername != null && sellerUsername!.trim().isNotEmpty)
            ? sellerUsername!.trim()
            : '';

        if (product is Product) {
          entity = product as Product;
          name = entity.name;
          price = entity.formattedPrice;
          originalPrice = entity.formattedOriginalPrice;
          discountPercent = entity.discountPercentage;
          imageUrl = entity.imageUrl;
          description = entity.description;
          final String rawSeller = cleanSellerUsername.isNotEmpty
              ? cleanSellerUsername
              : (entity.seller ?? '@seller');
          seller = rawSeller.startsWith('@') ? rawSeller : '@$rawSeller';
          sellerAvatar = sellerAvatarUrl ?? entity.sellerAvatar;
          sellerId = entity.sellerId;
          id = entity.id;
        } else if (product is ShopProduct) {
          final p = product as ShopProduct;
          name = p.name;
          price = p.price;
          originalPrice = null;
          discountPercent = null;
          imageUrl = p.imageUrl;
          description = 'Product listing by ${cleanSellerUsername.isNotEmpty ? cleanSellerUsername : 'seller'}';
          final String rawSeller = cleanSellerUsername.isNotEmpty ? cleanSellerUsername : '@seller';
          seller = rawSeller.startsWith('@') ? rawSeller : '@$rawSeller';
          sellerAvatar = sellerAvatarUrl;
          sellerId = null;
          id = p.name.hashCode.toString();
        } else {
          name = 'Product';
          price = r'$0.00';
          originalPrice = null;
          discountPercent = null;
          imageUrl = '';
          description = '';
          final String rawSeller = cleanSellerUsername.isNotEmpty ? cleanSellerUsername : '@seller';
          seller = rawSeller.startsWith('@') ? rawSeller : '@$rawSeller';
          sellerAvatar = sellerAvatarUrl;
          sellerId = null;
          id = '0';
        }

        final String resolvedSellerAvatar = InboxMessageManager.resolveUserAvatar(
          seller,
          candidateAvatar: sellerAvatar,
        );

        final overrides = Product.getProductDetailsOverride(id, productName: name);
        final String resolvedName = overrides?['name'] ?? name;
        final double resolvedPriceVal = overrides?['price'] ?? (entity?.price ?? double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0);
        final String resolvedPrice = '\$${resolvedPriceVal.toStringAsFixed(2)}';
        final double? resolvedOrigPriceVal = overrides?['originalPrice'] ?? entity?.originalPrice;
        final String? resolvedOriginalPrice = resolvedOrigPriceVal != null ? '\$${resolvedOrigPriceVal.toStringAsFixed(2)}' : originalPrice;
        final int? resolvedDiscountPercent = (resolvedOrigPriceVal != null && resolvedOrigPriceVal > resolvedPriceVal && resolvedOrigPriceVal > 0)
            ? (((resolvedOrigPriceVal - resolvedPriceVal) / resolvedOrigPriceVal) * 100).round()
            : discountPercent;
        final String resolvedDescription = overrides?['description'] ?? description;

        final int effectiveStock = Product.getEffectiveStock(id, entity?.stock ?? 10, productName: resolvedName);
        final bool isOutOfStock = effectiveStock <= 0;
        final int effectiveSold = Product.getEffectiveSoldCount(id, entity?.soldCount ?? 0, productName: resolvedName);

        final bool isOwner = isCurrentUser ||
            ProfileSyncService.instance.isCurrentUser(
              username: seller,
              id: sellerId,
            );

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailPage(
                  product: entity,
                  id: id,
                  title: resolvedName,
                  price: resolvedPrice,
                  imageUrl: imageUrl,
                  description: resolvedDescription,
                  seller: seller,
                  sellerAvatar: resolvedSellerAvatar,
                  sellerId: sellerId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(PulseRadius.cardRadius),
          child: Opacity(
            opacity: isOutOfStock ? 0.55 : 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: PulseSpacing.stackGap),
              padding: const EdgeInsets.all(PulseSpacing.containerPadding),
              decoration: BoxDecoration(
                color: PulseColors.surface,
                borderRadius: BorderRadius.circular(PulseRadius.cardRadius),
                border: Border.all(color: PulseColors.surfaceStroke),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(PulseRadius.sm),
                    child: _buildThumbnail(imageUrl, isOutOfStock: isOutOfStock),
                  ),
                  const SizedBox(width: PulseSpacing.inlineGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resolvedName,
                          style: PulseTypography.bodyLg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(resolvedPrice, style: PulseTypography.bodyMd),
                            if (resolvedOriginalPrice != null && resolvedOriginalPrice.isNotEmpty)
                              Text(
                                resolvedOriginalPrice,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            if (resolvedDiscountPercent != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-$resolvedDiscountPercent%',
                                  style: const TextStyle(
                                    color: Color(0xFFFF3B30),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (isOutOfStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              'By ${seller.startsWith('@') ? seller : '@$seller'}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '$effectiveSold sold',
                                style: const TextStyle(
                                  color: Color(0xFF60A5FA),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                    : const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isOutOfStock
                                      ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                                      : const Color(0xFF10B981).withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isOutOfStock ? '0 in stock' : '$effectiveStock in stock',
                                style: TextStyle(
                                  color: isOutOfStock ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isOwner) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showEditProductSheet(
                            context,
                            id: id,
                            currentName: resolvedName,
                            currentPrice: resolvedPriceVal,
                            currentOriginalPrice: resolvedOrigPriceVal,
                            currentStock: effectiveStock,
                            currentDescription: resolvedDescription,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (isOwner)
                        Material(
                          color: const Color(0xFF222226),
                          borderRadius: BorderRadius.circular(PulseRadius.full),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(PulseRadius.full),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF1E1E22),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.white12),
                                  ),
                                  content: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isOutOfStock
                                              ? 'This is your posted product (Currently Out of Stock).'
                                              : 'This is your posted product. You cannot send a message to yourself or add to cart.',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.inventory_2_outlined, color: Colors.white70, size: 13),
                                  SizedBox(width: 4),
                                  Text(
                                    'Your Product',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (isOutOfStock)
                        Material(
                          color: const Color(0xFF1E1E22),
                          borderRadius: BorderRadius.circular(PulseRadius.full),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(PulseRadius.full),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF1E1E22),
                                  behavior: SnackBarBehavior.floating,
                                  content: Text('This product is currently out of stock and cannot be ordered.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Material(
                          color: PulseColors.actionSecondary,
                          borderRadius: BorderRadius.circular(PulseRadius.full),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(PulseRadius.full),
                            onTap: () {
                              if (isOutOfStock) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Color(0xFF1E1E22),
                                    content: Text('This product is out of stock. Unable to send order message.'),
                                  ),
                                );
                                return;
                              }

                              final cleanSeller = seller.startsWith('@') ? seller : '@$seller';
                              final messageText =
                                  'Hi! I would like to order $resolvedName (Price: $resolvedPrice/unit). Is it available to ship?';

                              // This profile action creates an order inquiry. Keep its
                              // order reference unique so an older cancellation event
                              // cannot cancel this new inquiry by product title alone.
                              final createdOrder = ShopRemoteDataSource.instance.recordChatOrder(
                                productTitle: resolvedName,
                                price: resolvedPriceVal,
                                quantity: 1,
                                imageUrl: imageUrl,
                                sellerName: cleanSeller,
                              );

                              Product.deductStock(
                                id,
                                1,
                                initialStock: entity?.stock ?? 10,
                                productName: resolvedName,
                              );
                              Product.incrementSoldCount(
                                id,
                                1,
                                initialSold: entity?.soldCount ?? 0,
                                productName: resolvedName,
                              );

                              final buyerUser = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
                              final rawBuyerHandle = (buyerUser?.username != null && buyerUser!.username.trim().isNotEmpty)
                                  ? buyerUser.username.trim()
                                  : ProfileSyncService.instance.currentUsername;
                              final cleanBuyerHandle = rawBuyerHandle.startsWith('@') ? rawBuyerHandle : '@$rawBuyerHandle';
                              final buyerAvatar = InboxMessageManager.resolveUserAvatar(
                                cleanBuyerHandle,
                                candidateAvatar: buyerUser?.avatarUrl ?? ProfileSyncService.instance.currentUserAvatar,
                              );

                              final threadId = InboxMessageManager.buildThreadId(cleanBuyerHandle, cleanSeller);
                              final String finalSellerAvatar = resolvedSellerAvatar;
                              final resolvedImage = imageUrl.isNotEmpty ? imageUrl : null;

                              final orderMsg = ChatMessage(
                                id: 'order_${createdOrder.orderNumber}',
                                text: messageText,
                                isMe: true,
                                senderHandle: cleanBuyerHandle,
                                timestamp: 'Just now',
                                status: 'Sent',
                                imageUrl: resolvedImage,
                                imageUrls: resolvedImage != null ? [resolvedImage] : null,
                                isOrder: true,
                                orderCreatedAtMs: DateTime.now().millisecondsSinceEpoch,
                                orderStatus: 'Active',
                                orderProductId: id,
                                orderProductTitle: resolvedName,
                                orderReference: createdOrder.orderNumber,
                                orderQuantity: 1,
                              );

                              final existingThread = InboxMessageManager.instance.getThread(threadId) ??
                                  InboxMessageManager.instance.getThreadByUsername(cleanSeller);

                              final DirectMessageThread threadToRegister;
                              if (existingThread != null) {
                                threadToRegister = existingThread.copyWith(
                                  lastMessage: messageText,
                                  timeAgo: 'Just now',
                                  messages: [...existingThread.messages, orderMsg],
                                );
                              } else {
                                threadToRegister = DirectMessageThread(
                                  id: threadId,
                                  username: cleanSeller,
                                  avatarUrl: finalSellerAvatar,
                                  senderHandle: cleanBuyerHandle,
                                  senderAvatar: buyerAvatar,
                                  recipientHandle: cleanSeller,
                                  recipientAvatar: finalSellerAvatar,
                                  lastMessage: messageText,
                                  timeAgo: 'Just now',
                                  isVerified: true,
                                  followersCount: '45k',
                                  messages: [orderMsg],
                                );
                              }

                              InboxMessageManager.instance.addOrUpdateThread(threadToRegister);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: PulseColors.surfaceContainer,
                                  content: Text('Message sent successfully to $cleanSeller.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              child: Text('Send Message', style: TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditProductSheet(
    BuildContext context, {
    required String id,
    required String currentName,
    required double currentPrice,
    required double? currentOriginalPrice,
    required int currentStock,
    required String currentDescription,
  }) {
    final titleController = TextEditingController(text: currentName);
    final priceController = TextEditingController(text: currentPrice.toStringAsFixed(2));
    final origPriceController = TextEditingController(
      text: currentOriginalPrice != null ? currentOriginalPrice.toStringAsFixed(2) : '',
    );
    final stockController = TextEditingController(text: currentStock.toString());
    final descController = TextEditingController(text: currentDescription);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: Color(0xFF38BDF8), size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Edit Product',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Product Title',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. Mac Book Pro',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF1E1E22),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Price (\$)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '1100.00',
                                    hintStyle: const TextStyle(color: Colors.white24),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E22),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                                  ),
                                  validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Invalid price' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Original Price (\$)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: origPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '1200.00 (Optional)',
                                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E22),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Stock Quantity', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E1E22)),
                            icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
                            onPressed: () {
                              final cur = int.tryParse(stockController.text.trim()) ?? 0;
                              if (cur > 0) {
                                stockController.text = (cur - 1).toString();
                                setModalState(() {});
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF1E1E22),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                              ),
                              validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'Invalid stock' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E1E22)),
                            icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                            onPressed: () {
                              final cur = int.tryParse(stockController.text.trim()) ?? 0;
                              stockController.text = (cur + 1).toString();
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Description', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Product specifications and details...',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF1E1E22),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final newName = titleController.text.trim();
                            final newPrice = double.parse(priceController.text.trim());
                            final newOrigPrice = origPriceController.text.trim().isNotEmpty
                                ? double.tryParse(origPriceController.text.trim())
                                : null;
                            final newStock = int.parse(stockController.text.trim());
                            final newDesc = descController.text.trim();

                            Product.updateProductDetails(
                              id,
                              name: newName,
                              price: newPrice,
                              originalPrice: newOrigPrice,
                              stock: newStock,
                              description: newDesc,
                            );

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1E1E22),
                                content: Text('"$newName" updated successfully!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThumbnail(String url, {bool isOutOfStock = false}) {
    Widget img;
    if (url.startsWith('assets/')) {
      img = Image.asset(
        url,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 52,
          height: 52,
          color: PulseColors.surfaceContainer,
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 24),
        ),
      );
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      img = Image.network(
        url,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 52,
          height: 52,
          color: PulseColors.surfaceContainer,
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 24),
        ),
      );
    } else {
      img = Container(
        width: 52,
        height: 52,
        color: PulseColors.surfaceContainer,
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 24),
      );
    }

    if (isOutOfStock) {
      return Stack(
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
            child: img,
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'OUT OF STOCK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return img;
  }
}
