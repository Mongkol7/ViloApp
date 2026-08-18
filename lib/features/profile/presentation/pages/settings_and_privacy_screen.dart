import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsAndPrivacyScreen extends StatelessWidget {
  const SettingsAndPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings and privacy',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSection('Activity', [
            _buildTile(Icons.grid_view, 'Manage posts'),
            _buildTile(Icons.play_circle_outline, 'Content preferences'),
            _buildTile(Icons.sensors, 'LIVE'),
            _buildTile(Icons.notifications_none, 'Notifications'),
            _buildTile(Icons.timer_outlined, 'Time and well-being'),
            _buildTile(Icons.people_outline, 'Family Pairing'),
          ]),
          _buildSection('Account', [
            _buildTile(Icons.person_outline, 'Account'),
            _buildTile(Icons.security, 'Security and permissions'),
            _buildTile(Icons.share_outlined, 'Share profile'),
          ]),
          _buildSection('Visibility', [
            _buildToggleTile(Icons.lock_outline, 'Private account', true),
            _buildTile(Icons.block_flipped, 'Blocked accounts'),
          ]),
          _buildSection('Interactions', [
            _buildTile(Icons.chat_bubble_outline, 'Comments'),
            _buildTile(Icons.alternate_email, 'Mentions'),
            _buildTile(Icons.send_outlined, 'Direct messages'),
            _buildTile(Icons.loop, 'Reuse of content'),
            _buildTile(Icons.download_outlined, 'Downloads', trailingText: 'On'),
            _buildTile(Icons.list_alt, 'Following list', trailingText: 'Only you'),
            _buildTile(Icons.favorite_border, 'Liked videos', trailingText: 'Only you'),
            _buildTile(Icons.visibility_outlined, 'Viewers', trailingText: 'On'),
          ]),
          _buildSection('Preferences', [
            _buildTile(Icons.music_note_outlined, 'Music'),
            _buildTile(Icons.mail_outline, 'Inbox & Messaging'),
            _buildTile(Icons.history, 'Activity centre'),
            _buildTile(Icons.tune_outlined, 'Audience controls'),
            _buildTile(Icons.campaign_outlined, 'Ads'),
            _buildTile(Icons.play_circle_filled_outlined, 'Playback', showRedDot: true),
            _buildTile(Icons.language, 'Language'),
            _buildTile(Icons.dark_mode_outlined, 'Display'),
            _buildTile(Icons.accessibility, 'Accessibility'),
            _buildTile(Icons.contact_phone_outlined, 'Contacts and location'),
          ]),
          _buildSection('Cache & mobile', [
            _buildTile(Icons.download_for_offline_outlined, 'Offline videos'),
            _buildTile(Icons.delete_outline, 'Free up space'),
            _buildTile(Icons.data_usage, 'Data saver'),
          ]),
          _buildSection('Support & about', [
            _buildTile(Icons.help_outline, 'Help Centre'),
            _buildTile(Icons.privacy_tip_outlined, 'Privacy Centre'),
            _buildTile(Icons.description_outlined, 'Terms and policies'),
          ]),
          _buildSection('Login', [
            _buildTile(Icons.group_outlined, 'Switch account', profileImage: 'https://i.pravatar.cc/150?u=a'),
            _buildTile(Icons.logout, 'Log out'),
          ]),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'v34.9.3 (20240320)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        ...children,
        const Divider(color: AppColors.surfaceStroke, height: 1, thickness: 0.5),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, {String? trailingText, bool showRedDot = false, String? profileImage}) {
    return ListTile(
      leading: profileImage != null 
        ? CircleAvatar(radius: 12, backgroundImage: NetworkImage(profileImage))
        : Icon(icon, color: Colors.white, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showRedDot) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          if (trailingText != null) ...[
            Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildToggleTile(IconData icon, String title, bool value) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Switch(
        value: value,
        onChanged: (v) {},
        activeColor: Colors.greenAccent,
      ),
    );
  }
}
