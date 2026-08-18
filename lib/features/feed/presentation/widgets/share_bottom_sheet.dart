import 'package:flutter/material.dart';

class ShareBottomSheet extends StatelessWidget {
  const ShareBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Users
    final List<Map<String, dynamic>> users = [
      {'name': 's.k.liza', 'avatar': 'https://i.pravatar.cc/150?img=1', 'badge': '5'},
      {'name': 'Hengg', 'avatar': 'https://i.pravatar.cc/150?img=11', 'badge': '29'},
      {'name': 'T.S.MK', 'avatar': 'https://i.pravatar.cc/150?img=12', 'badge': '523'},
      {'name': 'Jinx Mo', 'avatar': 'https://i.pravatar.cc/150?img=13', 'badge': '208'},
      {'name': 'Ractz', 'avatar': 'https://i.pravatar.cc/150?img=14', 'badge': '349'},
    ];

    // Mock Share Actions
    final List<Map<String, dynamic>> shareActions = [
      {'icon': Icons.repeat, 'label': 'Repost', 'color': Colors.amber},
      {'icon': Icons.link, 'label': 'Copy link', 'color': Colors.blue},
      {'icon': Icons.chat_bubble, 'label': 'Messenger', 'color': Colors.lightBlue},
      {'icon': Icons.facebook, 'label': 'Facebook', 'color': Colors.blueAccent},
      {'icon': Icons.send, 'label': 'Telegram', 'color': Colors.lightBlueAccent},
    ];

    // Mock Other Actions
    final List<Map<String, dynamic>> otherActions = [
      {'icon': Icons.flag, 'label': 'Report'},
      {'icon': Icons.heart_broken, 'label': 'Not interested'},
      {'icon': Icons.add_circle_outline, 'label': 'Add to Story'},
      {'icon': Icons.download, 'label': 'Download'},
      {'icon': Icons.local_fire_department, 'label': 'Promote'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: const BoxDecoration(
        color: Color(0xFF2E2E2E), // Dark grey background matching screenshot
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.search, color: Colors.white, size: 28),
                const Text(
                  'Send to',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Users List
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _UserItem(data: users[index]);
              },
            ),
          ),
          
          const Divider(color: Colors.white24, height: 24, thickness: 1),
          
          // Share Actions
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: shareActions.length,
              itemBuilder: (context, index) {
                return _ActionItem(
                  data: shareActions[index],
                  isSquare: true,
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Other Actions
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: otherActions.length,
              itemBuilder: (context, index) {
                return _ActionItem(
                  data: otherActions[index],
                  isSquare: false,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _UserItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _UserItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(data['avatar']),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2E2E2E), width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.blueAccent, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        data['badge'],
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data['name'],
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSquare;

  const _ActionItem({required this.data, required this.isSquare});

  @override
  Widget build(BuildContext context) {
    final bgColor = data['color'] ?? const Color(0xFF3F3F3F);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(isSquare ? 16 : 28),
            ),
            child: Icon(data['icon'], color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              data['label'],
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
