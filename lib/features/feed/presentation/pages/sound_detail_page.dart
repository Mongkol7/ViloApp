import 'package:flutter/material.dart';

class SoundDetailPage extends StatelessWidget {
  const SoundDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for videos using this sound
    final List<String> mockVideos = [
      'https://picsum.photos/seed/s1/400/600',
      'https://picsum.photos/seed/s2/400/600',
      'https://picsum.photos/seed/s3/400/600',
      'https://picsum.photos/seed/s4/400/600',
      'https://picsum.photos/seed/s5/400/600',
      'https://picsum.photos/seed/s6/400/600',
      'https://picsum.photos/seed/s7/400/600',
      'https://picsum.photos/seed/s8/400/600',
      'https://picsum.photos/seed/s9/400/600',
      'https://picsum.photos/seed/s10/400/600',
      'https://picsum.photos/seed/s11/400/600',
      'https://picsum.photos/seed/s12/400/600',
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                backgroundColor: Colors.black,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white54, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Always',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              // Header Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Sound Icon with gradient border
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.cyanAccent, Colors.blueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(3), // Border width
                            child: const CircleAvatar(
                              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'), // Monkey image mock
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Sound Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Seven7 Team',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 10,
                                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'DanielCaesar',
                                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle, color: Colors.blueAccent, size: 14),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '+ Follow',
                                      style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Stats Row
                      Row(
                        children: [
                          const Icon(Icons.play_circle_outline, color: Colors.white54, size: 16),
                          const SizedBox(width: 4),
                          const Text('15s', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 12, color: Colors.white24),
                          const SizedBox(width: 12),
                          const Text('Original sound by:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          const Spacer(),
                          const Text('5.7M posts', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Add to music app', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bookmark_border, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Add to Favourites', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Grid of Videos
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1.5,
                  crossAxisSpacing: 1.5,
                  childAspectRatio: 0.75, // Slightly taller than square
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          mockVideos[index],
                          fit: BoxFit.cover,
                        ),
                        // Add tags for first few videos
                        if (index == 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: Colors.pinkAccent,
                              child: const Text('Original', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (index == 1)
                          const Positioned(
                            top: 8,
                            left: 8,
                            child: Text('Template', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                          ),
                      ],
                    );
                  },
                  childCount: mockVideos.length,
                ),
              ),
              
              // Extra space for bottom floating buttons
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Bottom Floating Buttons
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add to Story
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'),
                      ),
                      SizedBox(width: 8),
                      Text('Add to Story', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Use Sound
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.videocam, color: Colors.black, size: 20),
                      SizedBox(width: 8),
                      Text('Use sound', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
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
