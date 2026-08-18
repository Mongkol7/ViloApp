import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/vilo_primary_button.dart';

/// Screen 5 — Link Sent Confirmation
///
/// Matches design reference:
/// - Blue radial glow background orb (top-center)
/// - Blue circle checkmark icon
/// - "Link Sent" heading
/// - Description text
/// - White pill "Send Reset Link" button
/// - "Back to Login" text button
/// - "Didn't receive an email? Resend" link
class LinkSentScreen extends StatefulWidget {
  const LinkSentScreen({super.key});

  @override
  State<LinkSentScreen> createState() => _LinkSentScreenState();
}

class _LinkSentScreenState extends State<LinkSentScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _popToLogin() {
    // Pop until the login screen (pop all on top of it)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.voidBackground,
        body: Stack(
          children: [
            // ── Blue glow orb top center ──────────────────────────────
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF1A7FD4).withValues(alpha: 0.45),
                        const Color(0xFF0B5EAE).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content ──────────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.edgeMargin,
                  ),
                  child: Column(
                    children: [
                      // Spacer to push icon to upper-center area
                      const SizedBox(height: 80),

                      // ── Animated check icon ──────────────────────
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5DB8FF), Color(0xFF1A7FD4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A7FD4).withValues(alpha: 0.5),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── "Link Sent" heading ──────────────────────
                      Text(
                        'Link Sent',
                        style: AppTypography.headlineLg.copyWith(
                          fontSize: 28,
                          letterSpacing: -0.5,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Reset link sent to your email.\nCheck your inbox to proceed.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(),

                      // ── Send Reset Link (re-send) CTA ──────────
                      ViloPrimaryButton(
                        label: 'Send Reset Link',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Link resent!',
                                  style: AppTypography.bodyMd
                                      .copyWith(color: AppColors.onSurface)),
                              backgroundColor: AppColors.surfaceContainerHigh,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadii.roundedLg),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Back to Login text link ────────────────
                      GestureDetector(
                        onTap: _popToLogin,
                        child: SizedBox(
                          height: 44,
                          child: Center(
                            child: Text(
                              'Back to Login',
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Resend prompt ──────────────────────────
                      RichText(
                        text: TextSpan(
                          style: AppTypography.bodyMd.copyWith(fontSize: 12),
                          children: [
                            const TextSpan(text: "Didn't receive an email? "),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Resend',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: const Color(0xFF5DB8FF),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
