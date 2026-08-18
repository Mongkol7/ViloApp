import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../pages/balance_screen.dart';
import '../pages/activity_centre_screen.dart';
import '../pages/offline_videos_screen.dart';
import '../pages/qr_code_screen.dart';
import '../pages/tiktok_studio_screen.dart';
import '../pages/promote_screen.dart';
import '../pages/settings_screen.dart';

class ProfileMenuDrawer extends StatelessWidget {
  const ProfileMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(color: AppColors.surfaceStroke, height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionHeader('Assets'),
                  _buildMenuTile(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Balance',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BalanceScreen())),
                  ),
                  _buildDivider(),
                  
                  _buildSectionHeader('Personal tools'),
                  _buildMenuTile(
                    context,
                    icon: Icons.history_outlined,
                    title: 'Activity centre',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityCentreScreen())),
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.download_for_offline_outlined,
                    title: 'Offline videos',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OfflineVideosScreen())),
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.qr_code_scanner_outlined,
                    title: 'Your QR code',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrCodeScreen())),
                  ),
                  _buildDivider(),

                  _buildSectionHeader('Creation & business tools'),
                  _buildMenuTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'TikTok Studio',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TikTokStudioScreen())),
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.campaign_outlined,
                    title: 'Promote',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PromoteScreen())),
                  ),
                  _buildMenuTile(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings and privacy',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: AppTypography.labelCaps.copyWith(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: AppTypography.bodyLg.copyWith(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Divider(color: AppColors.surfaceStroke, height: 1),
    );
  }
}
