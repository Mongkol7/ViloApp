import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Outlined pill button — dark background, white/grey border.
/// Used for social login and secondary actions.
class ViloOutlineButton extends StatelessWidget {
  const ViloOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.leadingWidget,
    this.height = 52,
    this.borderColor,
    this.labelColor,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? leadingIcon;
  final Widget? leadingWidget;
  final double height;
  final Color? borderColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadii.roundedFull,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.roundedFull,
          splashColor: AppColors.surfaceStroke,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadii.roundedFull,
              border: Border.all(
                color: borderColor ?? AppColors.outlineVariant,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingWidget != null) ...[
                  leadingWidget!,
                  const SizedBox(width: 10),
                ] else if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: 20, color: labelColor ?? AppColors.onSurface),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: AppTypography.bodyLg.copyWith(
                    color: labelColor ?? AppColors.onSurface,
                    fontWeight: FontWeight.w600,
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
