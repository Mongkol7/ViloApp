import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/vilo_primary_button.dart';
import 'link_sent_screen.dart';

/// Screen 4 — Forgot / Reset Password
///
/// Matches design reference:
/// - Back arrow + "FOR YOU" top bar
/// - "Reset Password" heading + description
/// - EMAIL ADDRESS labeled input with mail icon
/// - White pill "Send Reset Link" button
/// - "Back to Login" text button
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailCtrl.text.trim();
    String? err;
    if (email.isEmpty) {
      err = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      err = 'Enter a valid email';
    }
    setState(() => _emailError = err);
    return err == null;
  }

  Future<void> _handleSend() async {
    if (!_validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).push(_fadeRoute(const LinkSentScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.voidBackground,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.edgeMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top bar: back + FOR YOU label ─────────────────
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.onSurface,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'FOR YOU',
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // ── Heading ───────────────────────────────────────
                    Text(
                      'Reset Password',
                      style: AppTypography.headlineLg.copyWith(
                        fontSize: 30,
                        letterSpacing: -0.6,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Enter your email address below. We'll send you a\nsecure link to reset your access.",
                      style: AppTypography.bodyMd,
                    ),
                    const SizedBox(height: 36),

                    // ── Email label ───────────────────────────────────
                    Text(
                      'EMAIL ADDRESS',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Email input ───────────────────────────────────
                    _ResetEmailField(
                      controller: _emailCtrl,
                      errorText: _emailError,
                      onSubmitted: (_) => _handleSend(),
                    ),
                    const SizedBox(height: 32),

                    // ── Send Reset Link CTA ───────────────────────────
                    ViloPrimaryButton(
                      label: 'Send Reset Link',
                      onPressed: _isLoading ? null : _handleSend,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),

                    // ── Back to Login ─────────────────────────────────
                    _BackToLoginButton(onTap: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom email input for reset password screen (with leading mail icon inside).
class _ResetEmailField extends StatefulWidget {
  const _ResetEmailField({
    required this.controller,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_ResetEmailField> createState() => _ResetEmailFieldState();
}

class _ResetEmailFieldState extends State<_ResetEmailField> {
  final _focus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _isFocused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.errorText != null
        ? AppColors.error
        : _isFocused
            ? const Color(0x33FFFFFF)
            : const Color(0x1AFFFFFF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.roundedLg,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: widget.onSubmitted,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
            cursorColor: AppColors.primary,
            cursorWidth: 1.5,
            decoration: InputDecoration(
              hintText: 'here@example.com',
              hintStyle: TextStyle(color: AppColors.outline.withValues(alpha: 0.7), fontSize: 13),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.mail_outline_rounded, size: 18,
                    color: _isFocused ? AppColors.onSurfaceVariant : AppColors.outline),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}

/// Outlined "Back to Login" button.
class _BackToLoginButton extends StatelessWidget {
  const _BackToLoginButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
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
            alignment: Alignment.center,
            child: Text(
              'Back to Login',
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Route<T> _fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 350),
  );
}
