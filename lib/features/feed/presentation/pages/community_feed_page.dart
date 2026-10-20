import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/video_feed_model.dart';
import '../../data/models/video_model.dart';
import '../controllers/video_feed_manager.dart';
import 'video_feed_page.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage>
    with AutomaticKeepAliveClientMixin {
  final FeedRemoteDataSource _dataSource = FeedRemoteDataSource.instance;

  @override
  bool get wantKeepAlive => true;

  List<VideoModel> _videos = [];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    VideoFeedManager.instance.feedRefreshNotifier.addListener(_onFeedRefresh);
    _loadCommunityPosts();
  }

  @override
  void dispose() {
    VideoFeedManager.instance.feedRefreshNotifier.removeListener(_onFeedRefresh);
    super.dispose();
  }

  void _onFeedRefresh() {
    if (mounted) {
      _loadCommunityPosts();
    }
  }

  Future<void> _loadCommunityPosts() async {
    try {
      final videos = await _dataSource.getFeed(feedType: 'FOR_YOU', forceRefresh: true);
      if (!mounted) return;

      final mappedPosts = videos.asMap().entries.map((entry) {
        final i = entry.key;
        final VideoFeedModel v = entry.value;
        final heights = [220.0, 180.0, 250.0, 200.0, 240.0, 190.0];
        final height = heights[i % heights.length];

        final thumb = (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty)
            ? v.thumbnailUrl!
            : 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800';

        return {
          'imageUrl': thumb,
          'title': v.caption.isNotEmpty ? v.caption : 'Explore short clip on Vilo',
          'avatar': (v.avatarUrl != null && v.avatarUrl!.isNotEmpty)
              ? v.avatarUrl!
              : 'https://i.pravatar.cc/100?img=${(v.creatorId % 70) + 1}',
          'username': v.displayName.isNotEmpty ? v.displayName : v.username,
          'likes': v.likes,
          'height': height,
          'index': i,
        };
      }).toList();

      setState(() {
        _videos = videos;
        _posts = mappedPosts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _videos = [];
        _posts = [];
        _isLoading = false;
      });
    }
  }

  void _openVideoAt(int index) {
    if (_videos.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoFeedPage(
          initialVideos: _videos,
          initialIndex: index,
          feedType: 'COMMUNITY',
          isActive: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    if (_posts.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: Colors.white,
          backgroundColor: const Color(0xFF202024),
          onRefresh: _loadCommunityPosts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dashboard_outlined, color: Colors.white38, size: 56),
                      SizedBox(height: 12),
                      Text(
                        'No community posts yet.',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (int i = 0; i < _posts.length; i++) {
      final post = _posts[i];
      final card = _PostCard(
        data: post,
        onTap: () => _openVideoAt(i),
      );
      if (i % 2 == 0) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF202024),
        onRefresh: _loadCommunityPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          key: const PageStorageKey('community_feed_scroll_view'),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: leftColumn)),
              const SizedBox(width: 12),
              Expanded(child: Column(children: rightColumn)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _PostCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final height = (data['height'] as num?)?.toDouble() ?? 200.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                children: [
                  Image.network(
                    data['imageUrl'] as String,
                    height: height,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: height,
                      color: const Color(0xFF1E1E24),
                      child: const Center(
                        child: Icon(Icons.image_outlined, color: Colors.white24, size: 36),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              data['title'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Bottom Info Row
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundImage: NetworkImage(data['avatar'] as String),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data['username'] as String,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  data['likes'] as String,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
