import 'package:flutter/gestures.dart';
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

class _HomeFeedPageState extends State<HomeFeedPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final Map<int, int> _tabRefreshTokens = <int, int>{};
  int? _refreshingTab;
  int _refreshRequest = 0;

  @override
  bool get wantKeepAlive => true;

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

  void _refreshTopCategory(int index) {
    final request = ++_refreshRequest;
    setState(() {
      _refreshingTab = index;
      _tabRefreshTokens[index] = (_tabRefreshTokens[index] ?? 0) + 1;
    });

    // Keep the indicator visible even when the response is served from the
    // in-memory cache and returns immediately.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted || request != _refreshRequest) return;
      setState(() => _refreshingTab = null);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black, // Dark background as per screenshots
      body: Stack(
        children: [
          // Tab Bar View content
          TabBarView(
            controller: _tabController,
            children: [
              CommunityFeedPage(
                key: const PageStorageKey('tab_community'),
                refreshToken: _tabRefreshTokens[0] ?? 0,
              ),
              VideoFeedPage(
                key: const PageStorageKey('tab_following'),
                feedType: 'FOLLOWING',
                refreshToken: _tabRefreshTokens[1] ?? 0,
                isActive: widget.isActive && _tabController.index == 1,
              ),
              VideoFeedPage(
                key: const PageStorageKey('tab_for_you'),
                feedType: 'FOR_YOU',
                refreshToken: _tabRefreshTokens[2] ?? 0,
                isActive: widget.isActive && _tabController.index == 2,
              ),
              const ShopPage(key: PageStorageKey('tab_shop')),
            ],
          ),

          // Custom Top App Bar overlay with horizontal scrolling and edge fade
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.08, 0.92, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: TabBar(
                          controller: _tabController,
                          onTap: _refreshTopCategory,
                          isScrollable: true,
                          tabAlignment: TabAlignment.center,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                          indicatorColor: Colors.white,
                          indicatorSize: TabBarIndicatorSize.label,
                          indicatorWeight: 3,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white.withValues(alpha: 0.50),
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
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
          if (_refreshingTab != null)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
