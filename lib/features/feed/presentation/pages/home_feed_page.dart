import 'package:flutter/material.dart';
import '../../../search_discover/presentation/pages/search_screen.dart';
import '../../../shop/presentation/pages/shop_page.dart';
import 'community_feed_page.dart';
import 'video_feed_page.dart';

class HomeFeedPage extends StatefulWidget {
  final bool isActive;

  const HomeFeedPage({super.key, this.isActive = true});

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // We have 4 tabs: Community, Following, For You, Shop
    _tabController = TabController(length: 4, vsync: this, initialIndex: 2); // default to For You
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background as per screenshots
      body: Stack(
        children: [
          // Tab Bar View content
          TabBarView(
            controller: _tabController,
            children: [
              const CommunityFeedPage(),
              VideoFeedPage(isActive: widget.isActive && _tabController.index == 1), // Following
              VideoFeedPage(isActive: widget.isActive && _tabController.index == 2), // For You
              const ShopPage(),
            ],
          ),

          // Custom Top App Bar overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                      dividerColor: Colors.transparent, // Remove default divider
                      tabs: const [
                        Tab(text: 'Community'),
                        Tab(text: 'Following'),
                        Tab(text: 'For You'),
                        Tab(text: 'Shop'),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SearchScreen(),
                        ),
                      );
                    },
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
