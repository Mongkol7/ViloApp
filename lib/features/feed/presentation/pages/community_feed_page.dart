import 'package:flutter/material.dart';
import '../../../../core/network/media_url.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/video_feed_model.dart';
import '../../data/models/video_model.dart';
import '../controllers/video_feed_manager.dart';
import 'video_feed_page.dart';

class CommunityFeedPage extends StatefulWidget {
  final int refreshToken;

  const CommunityFeedPage({super.key, this.refreshToken = 0});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage>
    with AutomaticKeepAliveClientMixin {
  final FeedRemoteDataSource _dataSource = FeedRemoteDataSource.instance;

  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _posts = [];
  List<VideoModel> _communityVideos = [];
  bool _isLoading = true;

  static final List<Map<String, dynamic>> _fallbackPosts = [
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&auto=format&fit=crop&q=80',
      'title': 'Beautiful rustic coffee shop atmosphere in the morning',
      'avatar': 'https://i.pravatar.cc/100?img=1',
      'username': 'Linaa',
      'likes': '474',
      'height': 220.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&auto=format&fit=crop&q=80',
      'title': 'Exclusive handmade furniture collection for your home',
      'avatar': 'https://i.pravatar.cc/100?img=2',
      'username': 'Khmer Furniture',
      'likes': '132',
      'height': 180.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&auto=format&fit=crop&q=80',
      'title': 'Find your calm as the day comes to an end.',
      'avatar': 'https://i.pravatar.cc/100?img=3',
      'username': 'Mariko Matcha',
      'likes': '1,026',
      'height': 250.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=600&auto=format&fit=crop&q=80',
      'title': 'New arrivals! Stylish outfit sets available now',
      'avatar': 'https://i.pravatar.cc/100?img=4',
      'username': 'SHINE\'s Store',
      'likes': '2,955',
      'height': 200.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop&q=80',
      'title': 'Exploring ancient temples in the jungle',
      'avatar': 'https://i.pravatar.cc/100?img=5',
      'username': 'Traveler',
      'likes': '890',
      'height': 240.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&auto=format&fit=crop&q=80',
      'title': 'A fresh cup of coffee to start the day right',
      'avatar': 'https://i.pravatar.cc/100?img=6',
      'username': 'CafeLover',
      'likes': '342',
      'height': 190.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&auto=format&fit=crop&q=80',
      'title': 'Winter fashion guide for the upcoming cold season',
      'avatar': 'https://i.pravatar.cc/100?img=7',
      'username': 'StyleInspo',
      'likes': '2,104',
      'height': 230.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=600&auto=format&fit=crop&q=80',
      'title': 'Minimalist workspace setup for productivity',
      'avatar': 'https://i.pravatar.cc/100?img=8',
      'username': 'TechGeek',
      'likes': '890',
      'height': 180.0,
    },
  ];

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

  @override
  void didUpdateWidget(covariant CommunityFeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadCommunityPosts(forceRefresh: true);
    }
  }

  void _onFeedRefresh() {
    if (mounted) {
      _loadCommunityPosts();
    }
  }

  Future<void> _loadCommunityPosts({bool forceRefresh = false}) async {
    if (forceRefresh && mounted && _posts.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final videos = await _dataSource.getFeed(
        feedType: 'COMMUNITY',
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      if (videos.isNotEmpty) {
        _communityVideos = videos;
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
            'video': v,
            'videoIndex': i,
          };
        }).toList();

        // Blend with fallback posts to ensure full grid depth
        setState(() {
          _posts = [...mappedPosts, ..._fallbackPosts];
          _isLoading = false;
        });
      } else {
        setState(() {
          _posts = List.from(_fallbackPosts);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _posts = List.from(_fallbackPosts);
        _isLoading = false;
      });
    }
  }

  void _openVideo(Map<String, dynamic> data) {
    final v = data['video'] as VideoModel?;
    if (v == null) return;
    final index = (data['videoIndex'] as int?) ?? 0;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoFeedPage(
          initialVideos: _communityVideos.isNotEmpty ? _communityVideos : [v],
          initialIndex: index,
          isActive: true,
          canDelete: false,
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

    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (int i = 0; i < _posts.length; i++) {
      final post = _posts[i];
      final card = _PostCard(
        data: post,
        onTap: post['video'] != null ? () => _openVideo(post) : null,
      );
      if (i % 2 == 0) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
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
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _PostCard({required this.data, this.onTap});

  Widget _buildImage(String url, double height) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorPlaceholder(height),
      );
    }
    return Image.network(
      resolveBackendMediaUrl(url),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _errorPlaceholder(height),
    );
  }

  Widget _errorPlaceholder(double height) {
    return Container(
      height: height,
      color: const Color(0xFF1E1E24),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white24, size: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = (data['height'] as num?)?.toDouble() ?? 200.0;
    final imageUrl = (data['imageUrl'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                children: [
                  _buildImage(imageUrl, height),
                  if (height > 200 || data['video'] != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
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
                  backgroundImage: NetworkImage(
                    resolveBackendMediaUrl(data['avatar'] as String),
                  ),
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
