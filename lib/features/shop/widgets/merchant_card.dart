import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/creator_merchant.dart';
import '../models/product.dart';
import '../presentation/controllers/cart_controller.dart';
import '../presentation/pages/cart_page.dart';
import '../../inbox_activity/data/datasources/inbox_message_manager.dart';
import '../../inbox_activity/domain/entities/inbox_item.dart';
import '../../inbox_activity/presentation/pages/chat_detail_screen.dart';

/// Creator Merchant Card component matching Vilo's Obsidian Dark Canvas aesthetic (#141416 / #16171B).
/// Strictly adheres to image_54f91d.png:
/// - Tapping any product item row or thumbnail adds the item directly to CartManager and CartController.
/// - NO "Buy Now" buttons.
/// - Single-product cards include a square chat bubble button on the right to message the creator.
/// - Multi-product cards include a full-width "Send Message" button at the bottom.
class MerchantCard extends StatelessWidget {
  final CreatorMerchant merchant;
  final VoidCallback? onMessagePressed;

  const MerchantCard({
    super.key,
    required this.merchant,
    this.onMessagePressed,
  });

  static const Color _cardSurface = Color(0xFF1E1F24);
  static const Color _nestedSurface = Color(0xFF111215);
  static const Color _surfaceStroke = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color _accentBlue = Color(0xFF38BDF8); // Electric blue from design
  static const Color _textDim = Color(0xFF9CA3AF);

  void _handleAddToCart(BuildContext context, MerchantProductItem item) {
    HapticFeedback.mediumImpact();

    final product = Product(
      id: item.id,
      name: item.title,
      categoryId: '1',
      price: item.price,
      originalPrice: item.originalPrice,
      rating: item.rating,
      soldCount: item.soldCount,
      description: item.specs,
      imageUrl: item.imageUrl,
      seller: merchant.name,
    );

    // Add directly via CartController (which also synchronizes with CartManager)
    CartController.instance.addProduct(product, quantity: 1);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF18181B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.white12),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0x2610B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Added to Cart',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    item.title,
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
              },
              child: const Text('View Cart', style: TextStyle(color: _accentBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: const Color(0xFF18181B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded, color: Colors.white),
                title: Text('View ${merchant.handle} Profile', style: const TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF242426),
                      content: Text('Opening ${merchant.handle} store profile...'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('Share Store', style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF242426),
                      content: Text('Store link copied to clipboard!'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                title: const Text('Report Store', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatInquirySheet(BuildContext context, {MerchantProductItem? specificProduct}) {
    HapticFeedback.mediumImpact();
    final TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        color: const Color(0xFF161618),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
              // Merchant Profile Header
              Row(
                children: [
                  _buildAvatar(radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              merchant.handle,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (merchant.isVerified) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.verified_rounded, color: _accentBlue, size: 15),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Direct Creator Channel • Ask about items or purchase',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final threadId = 'merchant_chat_${merchant.handle.hashCode.abs()}';
                      var existingThread = InboxMessageManager.instance.getThread(threadId) ??
                          InboxMessageManager.instance.getThreadByUsername(merchant.handle);
                      final resolvedThread = existingThread ??
                          InboxMessageManager.instance.addOrUpdateThread(
                            DirectMessageThread(
                              id: threadId,
                              username: merchant.handle,
                              avatarUrl: merchant.avatarUrl,
                              lastMessage: 'Chat with ${merchant.handle}',
                              timeAgo: 'Just now',
                              isVerified: merchant.isVerified,
                              followersCount: merchant.followers,
                              messages: [
                                ChatMessage(
                                  id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
                                  text: 'Hi ${merchant.handle}! I am exploring your store.',
                                  isMe: true,
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
                    },
                    icon: const Icon(Icons.chat_outlined, size: 14, color: _accentBlue),
                    label: const Text('Open Chat',
                        style: TextStyle(
                            color: _accentBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      backgroundColor: _accentBlue.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Specific Inquired Product Preview
              if (specificProduct != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _nestedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          specificProduct.imageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 44,
                            height: 44,
                            color: Colors.white12,
                            child: const Icon(Icons.image_outlined, color: Colors.white24, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              specificProduct.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              specificProduct.formattedPrice,
                              style: const TextStyle(color: _accentBlue, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white38, size: 18),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // Quick Inquiry Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickInquiryChip(
                    'Is this in stock?',
                    controller,
                  ),
                  _buildQuickInquiryChip(
                    'How can I purchase this?',
                    controller,
                  ),
                  _buildQuickInquiryChip(
                    'Do you ship worldwide?',
                    controller,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Text Field
              TextField(
                controller: controller,
                autofocus: false,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Message ${merchant.handle} to discuss or buy...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: _nestedSurface,
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
                    final messageText = text.isNotEmpty
                        ? text
                        : (specificProduct != null
                            ? 'Hi ${merchant.handle}, I am interested in ${specificProduct.title} (Price: ${specificProduct.formattedPrice}/unit). Is it available?'
                            : 'Hi ${merchant.handle}, I would like to inquire about items from your store!');
                    final threadId = 'merchant_chat_${merchant.handle.hashCode.abs()}';
                    final thread = DirectMessageThread(
                      id: threadId,
                      username: merchant.handle,
                      avatarUrl: merchant.avatarUrl,
                      lastMessage: messageText,
                      timeAgo: 'Just now',
                      isVerified: merchant.isVerified,
                      followersCount: merchant.followers,
                      messages: [
                        ChatMessage(
                          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
                          text: messageText,
                          isMe: true,
                          timestamp: 'Just now',
                          status: 'Sent',
                        ),
                      ],
                    );
                    final registeredThread =
                        InboxMessageManager.instance.addOrUpdateThread(thread);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1E1E22),
                        content: Text('Message sent to ${merchant.handle}! Opening chat...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(thread: registeredThread),
                      ),
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
    );
  }

  Widget _buildQuickInquiryChip(String label, TextEditingController controller) {
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

  Widget _buildAvatar({double radius = 17}) {
    // Solid vibrant blue/cyan circular avatar matching image_54f91d.png
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _surfaceStroke),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Creator Header Row ───────────────────────────────────
          Row(
            children: [
              _buildAvatar(radius: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        merchant.handle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (merchant.isVerified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded, color: _accentBlue, size: 15),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showOptionsModal(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: const Center(
                    child: Icon(Icons.more_horiz_rounded, color: Colors.white54, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Product Item Container ───────────────────────────────
          if (merchant.isSingleProduct)
            _buildSingleProductContainer(context, merchant.products.first)
          else
            _buildMultiProductContainer(context, merchant.products),
        ],
      ),
    );
  }

  Widget _buildSingleProductContainer(BuildContext context, MerchantProductItem item) {
    return Container(
      decoration: BoxDecoration(
        color: _nestedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Product Thumbnail (Tapping adds directly to cart)
          GestureDetector(
            onTap: () => _handleAddToCart(context, item),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                item.imageUrl,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 68,
                  height: 68,
                  color: const Color(0xFF242426),
                  child: const Icon(Icons.keyboard_outlined, color: Colors.white24, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product Details (Tapping adds directly to cart)
          Expanded(
            child: GestureDetector(
              onTap: () => _handleAddToCart(context, item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.formattedPrice,
                    style: const TextStyle(
                      color: _accentBlue, // Bright electric blue matching image_54f91d.png
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.specs,
                    style: const TextStyle(
                      color: _textDim,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Square Rounded Chat Bubble Button
          GestureDetector(
            onTap: () => _showChatInquirySheet(context, specificProduct: item),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF26282E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Center(
                child: Icon(
                  Icons.chat_bubble_rounded, // Solid chat bubble matching image_54f91d.png
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiProductContainer(BuildContext context, List<MerchantProductItem> products) {
    return Column(
      children: [
        // Inner Container holding product items separated by a subtle divider
        Container(
          decoration: BoxDecoration(
            color: _nestedSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white10,
              height: 18,
              thickness: 0.8,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () => _handleAddToCart(context, product),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        product.imageUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 54,
                          height: 54,
                          color: const Color(0xFF242426),
                          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            product.formattedPrice,
                            style: const TextStyle(
                              color: _accentBlue, // Bright electric blue matching image_54f91d.png
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Full-width "Send Message" Action Button matching image_54f91d.png
        GestureDetector(
          onTap: () => _showChatInquirySheet(context),
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
        ),
      ],
    );
  }
}
