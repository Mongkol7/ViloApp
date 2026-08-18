import 'package:flutter/material.dart';

class TikTokStudioScreen extends StatelessWidget {
  const TikTokStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('TikTok Studio', style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
        actions: [
          const Icon(Icons.settings_outlined, color: Colors.white),
          const SizedBox(width: 16),
          const CircleAvatar(radius: 12, backgroundColor: Colors.blueAccent),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Analytics'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AnalyticsItem('POST VIEWS', '477', '+ 155% 7d', Colors.redAccent),
                  _AnalyticsItem('FOLLOWERS', '0', '0% 7d', Colors.grey),
                  _AnalyticsItem('LIKES', '49', '+ 390% 7d', Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Monetisation'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _MonetisationCard(
                    title: 'Service+',
                    desc: 'Build connections with potential clients while you\'re LIVE.',
                    color: Colors.cyanAccent,
                    buttonText: 'Join',
                  ),
                  const SizedBox(width: 12),
                  _MonetisationCard(
                    title: 'Subscriptions',
                    desc: 'Connect more deeply with viewers through exclusive content.',
                    color: Colors.pinkAccent,
                    buttonText: 'Learn more',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Inspiration'),
            _buildSectionHeader('More Tools'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _ToolCard(Icons.person_search, 'Account check'),
                  _ToolCard(Icons.campaign, 'Promote'),
                  _ToolCard(Icons.card_giftcard, 'Benefits'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Creator Academy'),
            const SizedBox(height: 100), // Space for button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Color(0xFF1C1C1E))),
        ),
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.video_call),
          label: const Text('Start creating'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

class _AnalyticsItem extends StatelessWidget {
  final String label, value, trend;
  final Color trendColor;
  const _AnalyticsItem(this.label, this.value, this.trend, this.trendColor);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(trend, style: TextStyle(color: trendColor, fontSize: 10)),
      ],
    );
  }
}

class _MonetisationCard extends StatelessWidget {
  final String title, desc, buttonText;
  final Color color;
  const _MonetisationCard({required this.title, required this.desc, required this.color, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 36),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ToolCard(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.pinkAccent, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
