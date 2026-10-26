import 'package:flutter/material.dart';

import '../mock/profile_mock_data.dart';
import '../style/pulse_tokens.dart';
import '../../../shop/presentation/pages/product_detail_page.dart';
import '../../../inbox_activity/data/datasources/inbox_message_manager.dart';
import '../../../inbox_activity/domain/entities/inbox_item.dart';
import '../../../inbox_activity/presentation/pages/chat_detail_screen.dart';

/// A single product row in the Shop tab. Pure display widget — placed
/// directly inside a SliverList by the parent, no scroll of its own.
class ShopProductCard extends StatelessWidget {
  const ShopProductCard({super.key, required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              id: product.name.hashCode.toString(),
              title: product.name,
              price: product.price,
              imageUrl: product.imageUrl,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(PulseRadius.cardRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: PulseSpacing.stackGap),
        padding: const EdgeInsets.all(PulseSpacing.containerPadding),
        decoration: BoxDecoration(
          color: PulseColors.surface,
          borderRadius: BorderRadius.circular(PulseRadius.cardRadius),
          border: Border.all(color: PulseColors.surfaceStroke),
        ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(PulseRadius.sm),
            child: Image.network(
              product.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 52,
                height: 52,
                color: PulseColors.surfaceContainer,
              ),
            ),
          ),
          const SizedBox(width: PulseSpacing.inlineGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: PulseTypography.bodyLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(product.price, style: PulseTypography.bodyMd),
              ],
            ),
          ),
          Material(
            color: PulseColors.actionSecondary,
            borderRadius: BorderRadius.circular(PulseRadius.full),
            child: InkWell(
              borderRadius: BorderRadius.circular(PulseRadius.full),
              onTap: () {
                final messageText =
                    'Hi! I am interested in ${product.name} (${product.price}). Is it still available?';
                final threadId = 'profile_product_chat_${product.name.hashCode.abs()}';
                final thread = DirectMessageThread(
                  id: threadId,
                  username: '@seller',
                  avatarUrl: product.imageUrl,
                  lastMessage: messageText,
                  timeAgo: 'Just now',
                  isVerified: true,
                  followersCount: '45k',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: PulseColors.surfaceContainer,
                    content: Text('Starting chat for ${product.name}...'),
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
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text('Send Message', style: PulseTypography.bodyMd),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
