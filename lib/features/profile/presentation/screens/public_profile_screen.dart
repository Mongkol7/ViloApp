import 'package:flutter/material.dart';
import '../../../bottom_nav/presentation/pages/main_navigation_shell.dart';
import '../mock/profile_mock_data.dart';
import '../style/pulse_tokens.dart';
import '../widgets/profile_tab_content.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseColors.background,
      appBar: AppBar(
        backgroundColor: PulseColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PulseColors.onSurface),
          onPressed: _handleBack,
        ),
        title: Text(ProfileMockData.username, style: PulseTypography.bodyLg),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: PulseColors.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(ProfileMockData.avatarUrl),
                    backgroundColor: PulseColors.surfaceContainer,
                  ),
                  const SizedBox(height: 12),
                  // Username
                  Text(ProfileMockData.username, style: PulseTypography.headlineSm),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem('Following', '284'),
                      _buildDivider(),
                      _buildStatItem('Followers', '12.8K'),
                      _buildDivider(),
                      _buildStatItem('Likes', '154K'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPillButton(
                        _isFollowing ? 'Following' : 'Follow', 
                        isPrimary: !_isFollowing,
                        onTap: () => setState(() => _isFollowing = !_isFollowing),
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton('Message', isPrimary: false, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bio
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      ProfileMockData.bio,
                      textAlign: TextAlign.center,
                      style: PulseTypography.bodyMd,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.music_note_rounded)), // Music
                    Tab(icon: Icon(Icons.grid_view_rounded)),  // Grid
                    Tab(icon: Icon(Icons.shopping_bag_outlined)), // Shop
                    Tab(icon: Icon(Icons.bookmark_border_rounded)), // Saved
                    Tab(icon: Icon(Icons.favorite_border_rounded)), // Liked
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            CustomScrollView(slivers: buildProfileTabSlivers(0)), // Music
            CustomScrollView(slivers: buildProfileTabSlivers(1)), // Grid
            CustomScrollView(slivers: buildProfileTabSlivers(2)), // Shop
            CustomScrollView(slivers: buildProfileTabSlivers(3)), // Saved
            CustomScrollView(slivers: buildProfileTabSlivers(4)), // Liked
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 15, width: 1, color: Colors.grey.withValues(alpha: 0.3));
  }

  Widget _buildPillButton(String label, {required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : PulseColors.actionSecondary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: PulseColors.background, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
