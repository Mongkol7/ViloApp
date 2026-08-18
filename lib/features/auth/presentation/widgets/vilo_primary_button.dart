import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Primary CTA button following Obsidian Pulse style guide.
///
/// - Solid White background, Black text
/// - Fixed height: 52px
/// - Fully pill-shaped radius (rounded-full)
/// - Trailing circular icon in black container as "pulse" accent
/// - Animated loading state
class ViloPrimaryButton extends StatelessWidget {
  const ViloPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: isFullWidth ? double.infinity : null,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: AppColors.primary,
          borderRadius: AppRadii.roundedFull,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: AppRadii.roundedFull,
            splashColor: AppColors.onSurface.withValues(alpha: 0.12),
            highlightColor: AppColors.onSurface.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize:
                    isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  // Invisible spacer to balance the trailing icon
                  if (isFullWidth)
                    const SizedBox(width: 32),

                  // Label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isLoading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            key: const ValueKey('label'),
                            label,
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),

                  // Trailing circular icon — the "pulse" accent
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      trailingIcon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
