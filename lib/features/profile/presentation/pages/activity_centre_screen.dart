import 'package:flutter/material.dart';

class ActivityCentreScreen extends StatelessWidget {
  const ActivityCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity centre',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E), // Dark grey surface
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActivityTile(Icons.play_circle_outline, 'Watch history'),
              _buildActivityTile(Icons.chat_bubble_outline, 'Comment history'),
              _buildActivityTile(Icons.search, 'Search history'),
              _buildActivityTile(Icons.ads_click, 'Ads link history'),
              _buildActivityTile(Icons.alternate_email, 'Mention history'),
              _buildActivityTile(Icons.person_outline, 'Account history'),
              _buildActivityTile(Icons.access_time, 'Screen time'),
              _buildActivityTile(Icons.video_library_outlined, 'Reuse of content history', isLast: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(IconData icon, String title, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white, size: 22),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 20,
          ),
          onTap: () {},
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          visualDensity: const VisualDensity(vertical: -1),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 56.0),
            child: Divider(color: Colors.grey, height: 1, thickness: 0.1),
          ),
      ],
    );
  }
}
