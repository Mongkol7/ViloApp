import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../auth/presentation/dialogs/logout_dialog.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../bottom_nav/presentation/pages/main_navigation_shell.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../inbox_activity/data/datasources/chat_manager.dart';
import '../../../inbox_activity/data/datasources/thought_story_manager.dart';
import '../../data/datasources/profile_sync_service.dart';

class SettingsAndPrivacyScreen extends StatefulWidget {
  const SettingsAndPrivacyScreen({super.key});

  @override
  State<SettingsAndPrivacyScreen> createState() => _SettingsAndPrivacyScreenState();
}

class _SettingsAndPrivacyScreenState extends State<SettingsAndPrivacyScreen> {
  String _storyPrivacy = 'PUBLIC'; // 'PUBLIC', 'FOLLOWERS', 'FRIENDS'

  String get _storyPrivacyDisplay {
    switch (_storyPrivacy) {
      case 'FRIENDS':
        return 'Friends only';
      case 'FOLLOWERS':
        return 'Followers';
      default:
        return 'Public';
    }
  }

  void _showStoryPrivacyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF48484E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Who can view your stories?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose who is allowed to view your photo, video, and thought stories.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 18),
                _buildPrivacySettingOption(
                  icon: Icons.public_rounded,
                  title: 'Public',
                  subtitle: 'Anyone on Vilo can view your stories',
                  value: 'PUBLIC',
                  color: const Color(0xFF2F80ED),
                  modalCtx: modalCtx,
                ),
                const SizedBox(height: 8),
                _buildPrivacySettingOption(
                  icon: Icons.people_outline_rounded,
                  title: 'Followers',
                  subtitle: 'Only accounts that follow you can view',
                  value: 'FOLLOWERS',
                  color: const Color(0xFF56CCF2),
                  modalCtx: modalCtx,
                ),
                const SizedBox(height: 8),
                _buildPrivacySettingOption(
                  icon: Icons.favorite_rounded,
                  title: 'Friends only',
                  subtitle: 'Only mutual friends you follow back can view',
                  value: 'FRIENDS',
                  color: const Color(0xFF27AE60),
                  modalCtx: modalCtx,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacySettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    required BuildContext modalCtx,
  }) {
    final isSelected = _storyPrivacy == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() => _storyPrivacy = value);
        Navigator.pop(modalCtx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Story privacy set to $title'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF222228),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFF26262B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF333338),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFF48484E), size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    await showViloLogoutDialog(context);
  }

  void _showSwitchAccountDialog(BuildContext context) {
    final currentUsername = TokenStorage.instance.currentUsernameSync
            ?.replaceAll('@', '')
            .toLowerCase()
            .trim() ??
        '';
    final teamAccounts = [
      {
        'username': 'setkimliza',
        'displayName': 'Set Kimliza',
        'role': 'Social Stories & Real-Time Chat',
        'avatar':
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
        'password': 'password123',
      },
      {
        'username': 'mongkol',
        'displayName': 'Thoeung Sereymongkol',
        'role': 'Flutter & Spring Boot Engineer',
        'avatar':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
        'password': 'password123',
      },
      {
        'username': 'bunheng',
        'displayName': 'Lim Bunheng',
        'role': 'Video Engine & Feed Specialist',
        'avatar':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
        'password': 'password123',
      },
      {
        'username': 'rithysak',
        'displayName': 'Sok Rithysak',
        'role': 'Mobile UI/UX Developer',
        'avatar':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
        'password': 'password123',
      },
      {
        'username': 's1',
        'displayName': 's1',
        'role': 'Chat Tester & Vilo Creator',
        'avatar':
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80',
        'password': 'password123',
      },
      {
        'username': 'admin',
        'displayName': 'Vilo System Admin',
        'role': 'System Administrator',
        'avatar':
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80',
        'password': 'admin123',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Switch account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...teamAccounts.map((acc) {
                final uName = acc['username']!;
                final isCurrent = currentUsername == uName ||
                    (currentUsername.isEmpty && uName == 'mongkol') ||
                    ((currentUsername == 'liza' || currentUsername == 'kimliza') &&
                        uName == 'setkimliza') ||
                    ((currentUsername == 'sak') && uName == 'rithysak');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF2C2C2E)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF2F80ED).withValues(alpha: 0.6)
                          : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(acc['avatar']!),
                      backgroundColor: const Color(0xFF333333),
                    ),
                    title: Text(
                      acc['displayName']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      '@${acc['username']} • ${acc['role']}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2F80ED),
                            size: 22,
                          )
                        : const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white24,
                            size: 14,
                          ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (isCurrent) return;
                      await _performAccountSwitch(
                        context,
                        acc['username']!,
                        acc['password']!,
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF2F80ED), size: 22),
                ),
                title: const Text(
                  'Log in to another account',
                  style: TextStyle(
                    color: Color(0xFF2F80ED),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final authSource = AuthRemoteDataSource();
                  await authSource.logout();
                  ProfileSyncService.instance.clearSession();
                  ThoughtStoryManager.instance.deleteStory();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) =>
                            const LoginScreen(isSwitchingAccount: true),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performAccountSwitch(
    BuildContext context,
    String username,
    String password,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2F80ED)),
      ),
    );

    try {
      final authSource = AuthRemoteDataSource();
      await authSource.logout();
      ProfileSyncService.instance.clearSession();
      ThoughtStoryManager.instance.deleteStory();

      final user = await authSource.login(
        usernameOrEmail: username,
        password: password,
      );

      ProfileSyncService.instance.setCurrentUser(user);
      ChatManager.instance.switchUser(user.id);
      FeedRemoteDataSource.instance.clearCache();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainNavigationShell(initialIndex: 3),
          ),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to @${user.username}'),
            backgroundColor: const Color(0xFF2F80ED),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not switch account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
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
            _buildTile(
              Icons.auto_stories_outlined,
              'Story privacy',
              trailingText: _storyPrivacyDisplay,
              onTap: () => _showStoryPrivacyDialog(context),
            ),
            _buildTile(Icons.block_flipped, 'Blocked accounts'),
          ]),
          _buildSection('Interactions', [
            _buildTile(Icons.chat_bubble_outline, 'Comments'),
            _buildTile(Icons.alternate_email, 'Mentions'),
            _buildTile(Icons.send_outlined, 'Direct messages'),
            _buildTile(Icons.loop, 'Reuse of content'),
            _buildTile(
              Icons.download_outlined,
              'Downloads',
              trailingText: 'On',
            ),
            _buildTile(
              Icons.list_alt,
              'Following list',
              trailingText: 'Only you',
            ),
            _buildTile(
              Icons.favorite_border,
              'Liked videos',
              trailingText: 'Only you',
            ),
            _buildTile(
              Icons.visibility_outlined,
              'Viewers',
              trailingText: 'On',
            ),
          ]),
          _buildSection('Preferences', [
            _buildTile(Icons.music_note_outlined, 'Music'),
            _buildTile(Icons.mail_outline, 'Inbox & Messaging'),
            _buildTile(Icons.history, 'Activity centre'),
            _buildTile(Icons.tune_outlined, 'Audience controls'),
            _buildTile(Icons.campaign_outlined, 'Ads'),
            _buildTile(
              Icons.play_circle_filled_outlined,
              'Playback',
              showRedDot: true,
            ),
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
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
        const Divider(
          color: AppColors.surfaceStroke,
          height: 1,
          thickness: 0.5,
        ),
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
                errorBuilder: (_, _, _) =>
                    Icon(icon, color: iconColor ?? Colors.white, size: 22),
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
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
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
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: Switch(
        value: value,
        onChanged: (v) {},
        activeThumbColor: Colors.greenAccent,
      ),
    );
  }
}
