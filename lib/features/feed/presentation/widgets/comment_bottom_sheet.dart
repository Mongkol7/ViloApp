import 'package:flutter/material.dart';

class CommentBottomSheet extends StatelessWidget {
  const CommentBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Comments Data based on screenshot
    final List<Map<String, dynamic>> comments = [
      {
        'name': 'Ractz',
        'avatar': 'https://i.pravatar.cc/150?img=14',
        'text': 'លេងអន់ចឹងលុប game ចោលទៅ ah bot',
        'time': '9m',
        'likes': 0,
        'replies': 0,
      },
      {
        'name': 'Hengg',
        'avatar': 'https://i.pravatar.cc/150?img=11',
        'text': 'Your Product so good😘',
        'time': '32m',
        'likes': 0,
        'replies': 0,
      },
      {
        'name': 'សំពៀន',
        'avatar': 'https://i.pravatar.cc/150?img=15',
        'text': 'មុខភ័យសង្ឃឹមជួយ',
        'time': '45m',
        'likes': 5,
        'replies': 1,
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Take 75% of screen height
      decoration: const BoxDecoration(
        color: Colors.black, // Dark background
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '53 comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.sort, color: Colors.white70, size: 24),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white70, size: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          
          // Comments List
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                return _CommentItem(data: comments[index]);
              },
            ),
          ),
          
          // Bottom Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=50'),
                  backgroundColor: Colors.blueAccent, // Just for border effect if needed
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Input Field (Mocked as Container for UI)
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Add comment...',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ),
                        Icon(Icons.emoji_emotions_outlined, color: Colors.white.withValues(alpha: 0.8), size: 20),
                        const SizedBox(width: 12),
                        Text('//', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Post Button
                const Text(
                  'Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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

class _CommentItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CommentItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(data['avatar']),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Text(
                  data['name'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Comment Text
                Text(
                  data['text'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Bottom Row (Time, Reply)
                Row(
                  children: [
                    Text(
                      data['time'],
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Reply',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                // View Replies
                if (data['replies'] > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 1,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'View ${data['replies']} reply',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Like Heart
          Column(
            children: [
              const Icon(Icons.favorite_border, color: Colors.white54, size: 18),
              if (data['likes'] > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${data['likes']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
