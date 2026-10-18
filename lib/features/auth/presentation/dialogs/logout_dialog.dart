import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../pages/login_screen.dart';
import '../../../inbox_activity/data/datasources/thought_story_manager.dart';

Future<void> showViloLogoutDialog(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Log out of Vilo?',
        style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Are you sure you want to log out? You will need to log back in to access your profile and feed.',
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancel',
            style: AppTypography.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Log out',
            style: AppTypography.bodyLg.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  if (shouldLogout == true && context.mounted) {
    try {
      final authSource = AuthRemoteDataSource();
      await authSource.logout();
      ThoughtStoryManager.instance.deleteStory();
    } catch (_) {}

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged out successfully',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
