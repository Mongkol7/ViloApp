import 'package:flutter/material.dart';
import '../../views/shop_feed_screen.dart';

/// Shop storefront page displayed inside the Vilo home feed navigation tabs.
/// Delegates directly to [ShopFeedScreen] to render the full Obsidian Dark storefront,
/// Top Sellers row, promotional mega sale banner, and 2-column Masonry product feed.
class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShopFeedScreen();
  }
}
