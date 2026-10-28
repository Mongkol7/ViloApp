import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/cart_item_model.dart';
import '../controllers/cart_controller.dart';
import 'order_history_page.dart';
import '../../data/datasources/shop_remote_data_source.dart';
import '../../../inbox_activity/data/datasources/inbox_message_manager.dart';
import '../../../inbox_activity/domain/entities/inbox_item.dart';
import '../../../inbox_activity/presentation/pages/chat_detail_screen.dart';
import '../../models/product.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../auth/data/datasources/token_storage.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  static const Color _accentBlue = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([CartController.instance, Product.stockUpdateNotifier]),
          builder: (context, _) {
            final cartCtrl = CartController.instance;
            final cart = cartCtrl.cart;

            return Column(
              children: [
                // ── Top Bar ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Shopping Cart (${cart.itemCount})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: ShopRemoteDataSource.instance.pendingOrdersCountNotifier,
                        builder: (context, pendingCount, _) {
                          return Badge(
                            isLabelVisible: pendingCount > 0,
                            label: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            offset: const Offset(-2, 2),
                            child: IconButton(
                              tooltip: 'My Orders',
                              icon: const Icon(Icons.receipt_long_outlined, color: Colors.white70, size: 22),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
                              ),
                            ),
                          );
                        },
                      ),
                      if (cart.items.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear Cart',
                          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white54, size: 22),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1C1C1E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Clear Cart', style: TextStyle(color: Colors.white)),
                                content: const Text(
                                  'Are you sure you want to remove all items from your shopping cart?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      cartCtrl.clearCart();
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Clear All', style: TextStyle(color: Color(0xFFEF4444))),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                    ],
                  ),
                ),

                // ── Cart Items List / Empty View Grouped by Company ─
                Expanded(
                  child: cart.items.isEmpty
                      ? _buildEmptyCart(context)
                      : Builder(
                          builder: (context) {
                            final sellerGroups = _groupItemsBySeller(cart.items);

                            return ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              children: [
                                for (final entry in sellerGroups.entries) ...[
                                  _buildSellerOrderSection(context, entry.key, entry.value, cartCtrl),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            );
                          },
                        ),
                ),

                // ── Bottom Summary with Send Message (No Checkout) ─────
                if (cart.items.isNotEmpty) _buildBottomBar(context, cartCtrl),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<String, List<CartItemModel>> _groupItemsBySeller(List<CartItemModel> items) {
    final Map<String, List<CartItemModel>> groups = {};
    for (final item in items) {
      final seller = item.chatHandle.isNotEmpty
          ? item.chatHandle
          : (item.sellerName?.trim().isNotEmpty == true
              ? item.sellerName!.trim()
              : 'TechHorizon Global');
      groups.putIfAbsent(seller, () => []).add(item);
    }
    return groups;
  }

  Widget _buildSellerOrderSection(
    BuildContext context,
    String sellerName,
    List<CartItemModel> items,
    CartController ctrl,
  ) {
    final displayHandle = sellerName.startsWith('@') ? sellerName : '@$sellerName';
    final sectionTotal = items.fold<double>(0.0, (sum, i) => sum + i.subtotal);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Company / Store Header ───────────────────────────
          Row(
            children: [
              _buildStoreAvatar(sellerName),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayHandle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified_rounded, color: _accentBlue, size: 15),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Items for this Company ───────────────────────────
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildCartItemTile(context, items[i], ctrl),
          ],

          const SizedBox(height: 12),

          // ── Company Subtotal Row ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Company Subtotal',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Text(
                  '\$${sectionTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _accentBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Full-width "Send Message" to THIS company (Matching Photo 2) ──
          _buildUnderOrderSendMessageButton(
            context,
            ctrl,
            sellerName: sellerName,
            items: items,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreAvatar(String sellerName, {double radius = 16}) {
    final clean = sellerName.replaceAll('@', '').trim();
    final initial = clean.isNotEmpty ? clean[0].toUpperCase() : 'S';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildUnderOrderSendMessageButton(
    BuildContext context,
    CartController ctrl, {
    required String sellerName,
    required List<CartItemModel> items,
  }) {
    return GestureDetector(
      onTap: () => _openOrderInquirySheet(
        context,
        ctrl,
        sellerName: sellerName,
        items: items,
      ),
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2026),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'Send Message',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 54),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Cart is Empty',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore top tech, sneakers, and fashion deals.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            child: const Text('Discover Products', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(),
      );
    }
    return _imageFallback();
  }

  Widget _imageFallback() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.white10,
      child: const Icon(Icons.image_outlined, color: Colors.white24),
    );
  }

  Widget _buildCartItemTile(BuildContext context, CartItemModel item, CartController ctrl) {
    final effectiveStock = Product.getEffectiveStock(
      item.productStringId ?? item.productId.toString(),
      item.stock,
      productName: item.productTitle,
    );
    final isOutOfStock = effectiveStock <= 0;

    return Opacity(
      opacity: isOutOfStock ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildThumbnail(item.productImage),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        item.formattedPrice,
                        style: const TextStyle(
                          color: _accentBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
                      if (item.originalPrice != null && item.originalPrice! > item.price)
                        Text(
                          '\$${item.originalPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  if (item.variant != null && item.variant!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.variant!,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                  if (isOutOfStock)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Quantity Stepper
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                  onPressed: () => ctrl.removeItem(item.id),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (item.quantity > 1) {
                            ctrl.updateQuantity(item.id, item.quantity - 1);
                          } else {
                            ctrl.removeItem(item.id, restoreStock: false);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Icon(Icons.remove, color: Colors.white70, size: 14),
                        ),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      InkWell(
                        onTap: (isOutOfStock || effectiveStock <= 0)
                            ? null
                            : () => ctrl.updateQuantity(item.id, item.quantity + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Icon(
                            Icons.add,
                            color: (isOutOfStock || effectiveStock <= 0) ? Colors.white24 : Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartController ctrl) {
    final cart = ctrl.cart;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Estimated Total', style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                cart.formattedTotal,
                style: const TextStyle(color: _accentBlue, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          const Spacer(),
          // Dark glassmorphic "Send Message" action button (Matching original design)
          GestureDetector(
            key: const Key('cart_bottom_global_send_btn'),
            onTap: () => _handleGlobalSendMessage(context, ctrl),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2026),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Send Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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

  void _handleGlobalSendMessage(BuildContext context, CartController ctrl) {
    final cart = ctrl.cart;
    if (cart.items.isEmpty) return;

    final hasOutOfStock = cart.items.any((item) =>
        Product.getEffectiveStock(
          item.productStringId ?? item.productId.toString(),
          item.stock,
          productName: item.productTitle,
        ) <= 0);
    if (hasOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E1E22),
          content: Text('Some products in your cart are out of stock. Please remove them before proceeding.'),
        ),
      );
      return;
    }

    final sellerGroups = _groupItemsBySeller(cart.items);
    if (sellerGroups.isEmpty) return;

    // Deduct stock & increment sold count in real time
    for (final item in cart.items) {
      Product.deductStock(
        item.productStringId ?? item.productId.toString(),
        item.quantity,
        initialStock: item.stock,
        productName: item.productTitle,
      );
      Product.incrementSoldCount(
        item.productStringId ?? item.productId.toString(),
        item.quantity,
        productName: item.productTitle,
      );
    }

    final buyerUser = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
    final rawBuyerHandle = (buyerUser?.username != null && buyerUser!.username.trim().isNotEmpty)
        ? buyerUser.username.trim()
        : ProfileSyncService.instance.currentUsername;
    final buyerHandle = rawBuyerHandle.startsWith('@') ? rawBuyerHandle : '@$rawBuyerHandle';
    final buyerAvatar = buyerUser?.avatarUrl ?? ProfileSyncService.instance.currentUserAvatar;

    // Identify first product added to cart and its merchant
    final firstItem = cart.items.first;
    final firstSellerName = firstItem.chatHandle.isNotEmpty
        ? firstItem.chatHandle
        : (firstItem.sellerName?.trim().isNotEmpty == true
            ? firstItem.sellerName!.trim()
            : 'TechHorizon Global');
    final firstSellerHandle = firstSellerName.startsWith('@') ? firstSellerName : '@$firstSellerName';
    final firstSellerThreadId = InboxMessageManager.buildThreadId(buyerHandle, firstSellerHandle);

    // 1. Dispatch order inquiries for ALL distinct merchants & register in Inbox
    DirectMessageThread? firstRegisteredThread;

    for (final entry in sellerGroups.entries) {
      final seller = entry.key;
      final items = entry.value;
      final handle = seller.startsWith('@') ? seller : '@$seller';
      final subtotal = items.fold<double>(0.0, (s, i) => s + i.subtotal);
      final itemsSummary = items.map((e) => '${e.productTitle} (x${e.quantity})').join('\n- ');
      final msg = 'Hi! I would like to order ${items.length} item(s) (Total: \$${subtotal.toStringAsFixed(2)}) from $handle:\n- $itemsSummary\nAre these ready to ship?';

      final createdOrder = ShopRemoteDataSource.instance.createOrderFromCartItems(
        sellerName: seller,
        items: items,
        customNote: msg,
      );
      ShopRemoteDataSource.instance.addOrder(createdOrder);

      final itemImages = items
          .map((e) => e.productImage)
          .where((img) => img.trim().isNotEmpty)
          .toList();

      final threadId = InboxMessageManager.buildThreadId(buyerHandle, handle);
      final sellerAvatar = InboxMessageManager.resolveUserAvatar(
        handle,
        candidateAvatar: items.first.sellerAvatar,
      );

      final thread = DirectMessageThread(
        id: threadId,
        username: handle,
        avatarUrl: sellerAvatar,
        senderHandle: buyerHandle,
        senderAvatar: buyerAvatar,
        recipientHandle: handle,
        recipientAvatar: sellerAvatar,
        lastMessage: msg,
        timeAgo: 'Just now',
        isVerified: true,
        followersCount: '48.2k',
        messages: [
          ChatMessage(
            id: 'order_${createdOrder.orderNumber}',
            text: msg,
            isMe: true,
            senderHandle: buyerHandle,
            timestamp: 'Just now',
            status: 'Sent',
            imageUrl: itemImages.isNotEmpty ? itemImages.first : null,
            imageUrls: itemImages,
            isOrder: true,
            orderCreatedAtMs: DateTime.now().millisecondsSinceEpoch,
            orderStatus: 'Active',
            orderProductId: items.first.productStringId ?? items.first.productId.toString(),
            orderProductTitle: items.first.productTitle,
            orderReference: createdOrder.orderNumber,
            orderQuantity: items.fold<int>(0, (sum, i) => sum + i.quantity),
            orderItems: items
                .map((i) => {
                      'id': i.productStringId ?? i.productId.toString(),
                      'title': i.productTitle,
                      'quantity': i.quantity,
                    })
                .toList(),
          ),
        ],
      );



      final registered = InboxMessageManager.instance.addOrUpdateThread(thread);
      if (seller == firstSellerName || entry.key == sellerGroups.entries.first.key) {
        firstRegisteredThread = registered;
      }
    }

    // Always deterministically resolve the thread belonging to the first product added to the cart
    final targetThread = InboxMessageManager.instance.getThread(firstSellerThreadId) ??
        InboxMessageManager.instance.getThreadByUsername(firstSellerHandle) ??
        firstRegisteredThread ??
        (InboxMessageManager.instance.threads.isNotEmpty ? InboxMessageManager.instance.threads.first : null);

    if (targetThread == null) {
      return;
    }

    // 2. SnackBar Notification (Inquiries sent across all merchants, no orders created)
    final count = sellerGroups.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.white12),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count > 1
                    ? 'Sent order inquiries to $count merchants! Redirecting to first product\'s chat...'
                    : 'Order inquiry sent to ${targetThread.username}! Redirecting to chat...',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    // 3. Clear all items from cart upon sending inquiries for all products
    ctrl.clearCart(restoreStock: false);

    // 4. Navigate directly to the first product's chat page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(thread: targetThread),
      ),
    );
  }

  void _sendOrderForCompany({
    required BuildContext context,
    required CartController ctrl,
    required String sellerName,
    required List<CartItemModel> items,
    String? customNote,
  }) {
    final hasOutOfStock = items.any((item) =>
        Product.getEffectiveStock(
          item.productStringId ?? item.productId.toString(),
          item.stock,
          productName: item.productTitle,
        ) <= 0);
    if (hasOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E1E22),
          content: Text('Some products in this order are out of stock. Please remove them before proceeding.'),
        ),
      );
      return;
    }

    final buyerUser = ProfileSyncService.instance.cachedMyProfile ?? TokenStorage.instance.getUserModel();
    final rawBuyerHandle = (buyerUser?.username != null && buyerUser!.username.trim().isNotEmpty)
        ? buyerUser.username.trim()
        : ProfileSyncService.instance.currentUsername;
    final buyerHandle = rawBuyerHandle.startsWith('@') ? rawBuyerHandle : '@$rawBuyerHandle';
    final buyerAvatar = buyerUser?.avatarUrl ?? ProfileSyncService.instance.currentUserAvatar;

    final displayHandle = sellerName.startsWith('@') ? sellerName : '@$sellerName';
    final companySubtotal = items.fold<double>(0.0, (s, i) => s + i.subtotal);
    final itemsSummary = items.map((e) => '${e.productTitle} (x${e.quantity})').join('\n- ');
    final defaultNote = 'Hi! I would like to order ${items.length} item(s) (Total: \$${companySubtotal.toStringAsFixed(2)}) from $displayHandle:\n- $itemsSummary\nAre these ready to ship?';
    final messageText = (customNote != null && customNote.trim().isNotEmpty) ? customNote.trim() : defaultNote;

    // Create the local order before the chat message so both sides can refer
    // to this exact order instead of matching cancellations by product title.
    final createdOrder = ShopRemoteDataSource.instance.createOrderFromCartItems(
      sellerName: sellerName,
      items: items,
      customNote: messageText,
    );
    ShopRemoteDataSource.instance.addOrder(createdOrder);

    final itemImages = items
        .map((e) => e.productImage)
        .where((img) => img.trim().isNotEmpty)
        .toList();

    final threadId = InboxMessageManager.buildThreadId(buyerHandle, displayHandle);
    final sellerAvatar = InboxMessageManager.resolveUserAvatar(
      displayHandle,
      candidateAvatar: items.isNotEmpty ? items.first.sellerAvatar : null,
    );

    // 1. Construct and register DirectMessageThread with InboxMessageManager
    final thread = DirectMessageThread(
      id: threadId,
      username: displayHandle,
      avatarUrl: sellerAvatar,
      senderHandle: buyerHandle,
      senderAvatar: buyerAvatar,
      recipientHandle: displayHandle,
      recipientAvatar: sellerAvatar,
      lastMessage: messageText,
      timeAgo: 'Just now',
      isVerified: true,
      followersCount: '48.2k',
      messages: [
        ChatMessage(
          id: 'order_${createdOrder.orderNumber}',
          text: messageText,
          isMe: true,
          senderHandle: buyerHandle,
          timestamp: 'Just now',
          status: 'Sent',
          imageUrl: itemImages.isNotEmpty ? itemImages.first : null,
          imageUrls: itemImages,
          isOrder: true,
          orderCreatedAtMs: DateTime.now().millisecondsSinceEpoch,
          orderStatus: 'Active',
          orderProductId: items.isNotEmpty ? (items.first.productStringId ?? items.first.productId.toString()) : null,
          orderProductTitle: items.isNotEmpty ? items.first.productTitle : null,
          orderReference: createdOrder.orderNumber,
          orderQuantity: items.fold<int>(0, (sum, i) => sum + i.quantity),
          orderItems: items
              .map((i) => {
                    'id': i.productStringId ?? i.productId.toString(),
                    'title': i.productTitle,
                    'quantity': i.quantity,
                  })
              .toList(),
        ),
      ],
    );

    // Deduct stock & increment sold count in real time
    for (final item in items) {
      Product.deductStock(
        item.productStringId ?? item.productId.toString(),
        item.quantity,
        initialStock: item.stock,
        productName: item.productTitle,
      );
      Product.incrementSoldCount(
        item.productStringId ?? item.productId.toString(),
        item.quantity,
        productName: item.productTitle,
      );
    }

    final registeredThread = InboxMessageManager.instance.addOrUpdateThread(thread);

    // 2. SnackBar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1E22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.white12),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Order inquiry sent to $displayHandle! Redirecting to chat...',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    // 3. Clear only the sent merchant's products from cart
    for (final item in items) {
      ctrl.removeItem(item.id, restoreStock: false);
    }

    // 4. Navigate to ChatDetailScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(thread: registeredThread),
      ),
    );
  }

  void _openOrderInquirySheet(
    BuildContext context,
    CartController ctrl, {
    String? sellerName,
    List<CartItemModel>? items,
    CartItemModel? specificItem,
  }) {
    HapticFeedback.mediumImpact();
    final cart = ctrl.cart;
    final activeSeller = sellerName ??
        specificItem?.chatHandle ??
        specificItem?.sellerName ??
        (cart.items.isNotEmpty
            ? (cart.items.first.chatHandle.isNotEmpty
                ? cart.items.first.chatHandle
                : (cart.items.first.sellerName ?? 'TechHorizon Global'))
            : 'TechHorizon Global');
    final displayHandle = activeSeller.startsWith('@') ? activeSeller : '@$activeSeller';

    final orderItems = items ?? (specificItem != null ? [specificItem] : cart.items);

    final hasOutOfStock = orderItems.any((item) =>
        Product.getEffectiveStock(item.productId.toString(), item.stock) <= 0);
    if (hasOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E1E22),
          content: Text('This product is out of stock and cannot be ordered.'),
        ),
      );
      return;
    }
    final totalAmount = orderItems.fold<double>(0.0, (sum, i) => sum + i.subtotal);
    final formattedTotal = '\$${totalAmount.toStringAsFixed(2)}';

    final itemsSummary = orderItems.map((e) => '${e.productTitle} (x${e.quantity})').join('\n- ');
    final TextEditingController controller = TextEditingController(
      text: specificItem != null
          ? 'Hi! I would like to order ${specificItem.productTitle} (${specificItem.formattedPrice}) from $displayHandle. Is this ready to ship?'
          : 'Hi! I would like to order ${orderItems.length} item(s) (Total: $formattedTotal) from $displayHandle:\n- $itemsSummary\nAre these ready to ship?',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        color: const Color(0xFF161618),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Merchant / Store Profile Header
                Row(
                  children: [
                    _buildStoreAvatar(activeSeller, radius: 19),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayHandle,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.verified_rounded, color: _accentBlue, size: 15),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Direct Creator Channel • Inquire about cart order',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order Preview Container for this Company
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111215),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < orderItems.length && i < 3; i++) ...[
                        if (i > 0) const Divider(color: Colors.white10, height: 16),
                        _buildInquiryItemRow(orderItems[i]),
                      ],
                      if (orderItems.length > 3) ...[
                        const SizedBox(height: 6),
                        Text(
                          '+ ${orderItems.length - 3} more items',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                      const Divider(color: Colors.white12, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Company Order (${orderItems.length} items)',
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          ),
                          Text(
                            formattedTotal,
                            style: const TextStyle(
                              color: _accentBlue,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Quick Inquiry Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInquiryChip('I\'d like to place this order', controller),
                    _buildInquiryChip('Are items ready to ship?', controller),
                    _buildInquiryChip('What payment options do you support?', controller),
                    _buildInquiryChip('Do you offer delivery discounts?', controller),
                  ],
                ),
                const SizedBox(height: 14),

                // Message Text Field
                TextField(
                  controller: controller,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Message $displayHandle about this order...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF111215),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _accentBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Send Message Action Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      Navigator.pop(ctx);
                      _sendOrderForCompany(
                        context: context,
                        ctrl: ctrl,
                        sellerName: activeSeller,
                        items: orderItems,
                        customNote: text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.send_rounded, color: Colors.black, size: 16),
                        SizedBox(width: 8),
                        Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInquiryItemRow(CartItemModel item) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildInquiryThumbnail(item.productImage),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'Qty: ${item.quantity} • ${item.formattedPrice}',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          item.formattedSubtotal,
          style: const TextStyle(color: _accentBlue, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildInquiryThumbnail(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _inquiryFallback(),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _inquiryFallback(),
      );
    }
    return _inquiryFallback();
  }

  Widget _inquiryFallback() {
    return Container(
      width: 38,
      height: 38,
      color: Colors.white10,
      child: const Icon(Icons.image_outlined, color: Colors.white24, size: 18),
    );
  }

  Widget _buildInquiryChip(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () {
        controller.text = label;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF24262E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
        ),
      ),
    );
  }
}


