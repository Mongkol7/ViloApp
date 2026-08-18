import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Shared social login buttons row/column for Auth screens.
/// Shows Apple, Google, Facebook options.
class ViloSocialLoginSection extends StatelessWidget {
  const ViloSocialLoginSection({
    super.key,
    this.dividerLabel = 'OR CONTINUE WITH',
  });

  final String dividerLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.outlineVariant, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                dividerLabel,
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.outline,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.outlineVariant, thickness: 1)),
          ],
        ),
        const SizedBox(height: 16),
        // Apple
        _SocialButton(
          label: 'Continue with Apple',
          icon: Icons.apple_rounded,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        // Google
        _SocialButton(
          label: 'Google',
          icon: Icons.g_mobiledata_rounded,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        // Facebook
        _SocialButton(
          label: 'Facebook',
          icon: Icons.facebook_rounded,
          onTap: () {},
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.roundedFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.roundedFull,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadii.roundedFull,
              border: Border.all(color: AppColors.outlineVariant, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: AppColors.onSurface),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
