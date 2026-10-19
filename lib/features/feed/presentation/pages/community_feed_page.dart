import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Mock data for the staggered grid
    final List<Map<String, dynamic>> mockPosts = [
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
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=600&auto=format&fit=crop&q=80',
        'title': 'Delicious homemade pasta recipe 🍝',
        'avatar': 'https://i.pravatar.cc/100?img=9',
        'username': 'ChefMario',
        'likes': '1,432',
        'height': 250.0,
      },
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=600&auto=format&fit=crop&q=80',
        'title': 'Road trip through the canyon',
        'avatar': 'https://i.pravatar.cc/100?img=10',
        'username': 'Wanderlust',
        'likes': '3,540',
        'height': 200.0,
      },
    ];

    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (int i = 0; i < mockPosts.length; i++) {
      if (i % 2 == 0) {
        leftColumn.add(_PostCard(data: mockPosts[i]));
      } else {
        rightColumn.add(_PostCard(data: mockPosts[i]));
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

  const _PostCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Stack(
              children: [
                Image.network(
                  data['imageUrl'],
                  height: data['height'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (data['height'] > 200) // Mock logic for video icon
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            data['title'],
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
                backgroundImage: NetworkImage(data['avatar']),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['username'],
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
                data['likes'],
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
