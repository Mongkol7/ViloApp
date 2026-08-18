import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CommunityFeedPage extends StatelessWidget {
  const CommunityFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for the staggered grid
    final List<Map<String, dynamic>> mockPosts = [
      {
        'imageUrl': 'https://picsum.photos/seed/c1/600/800',
        'title': 'Beautiful rustic coffee shop atmosphere in the morning',
        'avatar': 'https://i.pravatar.cc/100?img=1',
        'username': 'Linaa',
        'likes': '474',
        'height': 220.0,
      },
      {
        'imageUrl': 'https://picsum.photos/seed/c2/600/800',
        'title': 'Exclusive handmade furniture collection for your home',
        'avatar': 'https://i.pravatar.cc/100?img=2',
        'username': 'Khmer Furniture',
        'likes': '132',
        'height': 180.0,
      },
      {
        'imageUrl': 'https://picsum.photos/seed/c3/600/800',
        'title': 'Find your calm as the day comes to an end.',
        'avatar': 'https://i.pravatar.cc/100?img=3',
        'username': 'Mariko Matcha',
        'likes': '1,026',
        'height': 250.0,
      },
      {
        'imageUrl': 'https://picsum.photos/seed/c4/600/800',
        'title': 'New arrivals! Stylish outfit sets available now',
        'avatar': 'https://i.pravatar.cc/100?img=4',
        'username': 'SHINE\'s Store',
        'likes': '2,955',
        'height': 200.0,
      },
      {
        'imageUrl': 'https://picsum.photos/seed/c5/600/800',
        'title': 'Exploring ancient temples in the jungle',
        'avatar': 'https://i.pravatar.cc/100?img=5',
        'username': 'Traveler',
        'likes': '890',
        'height': 240.0,
      },
      {
        'imageUrl': 'https://picsum.photos/seed/c6/600/800',
        'title': 'A fresh cup of coffee to start the day right',
        'avatar': 'https://i.pravatar.cc/100?img=6',
        'username': 'CafeLover',
        'likes': '342',
        'height': 190.0,
      },
      {
        'imageUrl': 'https://picsum.photos/seed/c7/600/800',
        'title': 'Winter fashion guide for the upcoming cold season',
        'avatar': 'https://i.pravatar.cc/100?img=7',
        'username': 'StyleInspo',
        'likes': '2,104',
        'height': 230.0,
      },
      {
        'imageUrl': 'https://picsum.photos/seed/c8/600/800',
        'title': 'Minimalist workspace setup for productivity',
        'avatar': 'https://i.pravatar.cc/100?img=8',
        'username': 'TechGeek',
        'likes': '890',
        'height': 180.0,
      },
      {
        'imageUrl': 'https://picsum.photos/seed/c9/600/800',
        'title': 'Delicious homemade pasta recipe 🍝',
        'avatar': 'https://i.pravatar.cc/100?img=9',
        'username': 'ChefMario',
        'likes': '1,432',
        'height': 250.0,
      },
      {
        'imageUrl': 'https://picsum.photos/seed/c10/600/800',
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftColumn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: rightColumn,
              ),
            ),
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
