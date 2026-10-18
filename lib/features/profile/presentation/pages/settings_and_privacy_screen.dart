import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/dialogs/logout_dialog.dart';
import '../../../auth/presentation/pages/login_screen.dart';

class SettingsAndPrivacyScreen extends StatelessWidget {
  const SettingsAndPrivacyScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    await showViloLogoutDialog(context);
  }

  void _showSwitchAccountDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Switch account',
                style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.primary),
                title: Text(
                  'Add existing account',
                  style: AppTypography.bodyLg.copyWith(color: AppColors.primary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            _buildTile(
              Icons.group_outlined,
              'Switch account',
              profileImage: 'https://i.pravatar.cc/150?u=a',
              onTap: () => _showSwitchAccountDialog(context),
            ),
            _buildTile(
              Icons.logout,
              'Log out',
              titleColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () => _showLogoutDialog(context),
            ),
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

  Widget _buildTile(
    IconData icon,
    String title, {
    String? trailingText,
    bool showRedDot = false,
    String? profileImage,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: profileImage != null
          ? ClipOval(
              child: Image.network(
                profileImage,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(icon, color: iconColor ?? Colors.white, size: 22),
              ),
            )
          : Icon(icon, color: iconColor ?? Colors.white, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontSize: 15,
          fontWeight: titleColor != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showRedDot)
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          if (trailingText != null) ...[
            Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      onTap: onTap ?? () {},
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
