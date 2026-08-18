import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/vilo_input_field.dart';
import '../widgets/vilo_logo_mark.dart';
import '../widgets/vilo_primary_button.dart';
import '../widgets/vilo_social_login_section.dart';
import 'login_screen.dart';

/// Screen 3 — Register / Join Vilo
///
/// Matches design reference:
/// - "Join Vilo" + cloud logo inline
/// - Full Name, Email, Password, Confirm Password fields
/// - Terms checkbox
/// - White pill "Create Account" button
/// - OR JOIN WITH social section
/// - Already have an account? Login
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _agreedToTerms = false;
  bool _isLoading = false;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  bool _validate() {
    String? nameErr, emailErr, passErr, confirmErr;

    if (_nameCtrl.text.trim().isEmpty) nameErr = 'Full name is required';
    if (_emailCtrl.text.trim().isEmpty) {
      emailErr = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailCtrl.text.trim())) {
      emailErr = 'Enter a valid email';
    }
    if (_passwordCtrl.text.length < 6) passErr = 'At least 6 characters';
    if (_confirmCtrl.text != _passwordCtrl.text) confirmErr = 'Passwords do not match';

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmError = confirmErr;
    });
    return nameErr == null && emailErr == null && passErr == null && confirmErr == null;
  }

  Future<void> _handleCreate() async {
    if (!_validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the terms.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface)),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  void _goToLogin() => Navigator.of(context).pushReplacement(
        _slideRoute(const LoginScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.voidBackground,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.edgeMargin,
                  AppSpacing.sectionMargin,
                  AppSpacing.edgeMargin,
                  bottomInset + AppSpacing.sectionMargin,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header: "Join Vilo" + logo inline ────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join Vilo',
                              style: AppTypography.headlineLg.copyWith(
                                fontSize: 34,
                                height: 1.1,
                                letterSpacing: -0.8,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Step into the deep city.',
                              style: AppTypography.bodyMd,
                            ),
                          ],
                        ),
                        const Spacer(),
                        const ViloLogoMark(size: 56),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Fields ────────────────────────────────────────
                    ViloInputField(
                      label: 'Full Name',
                      controller: _nameCtrl,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      errorText: _nameError,
                      onSubmitted: (_) => _emailFocus.requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    ViloInputField(
                      label: 'Email',
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      errorText: _emailError,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    ViloInputField(
                      label: 'Password',
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      errorText: _passwordError,
                      onSubmitted: (_) => _confirmFocus.requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    ViloInputField(
                      label: 'Confirm Password',
                      controller: _confirmCtrl,
                      focusNode: _confirmFocus,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      errorText: _confirmError,
                      onSubmitted: (_) => _handleCreate(),
                    ),
                    const SizedBox(height: 16),

                    // ── Terms checkbox ────────────────────────────────
                    GestureDetector(
                      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                      child: Row(
                        children: [
                          _ViloCheckbox(value: _agreedToTerms),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.bodyMd.copyWith(fontSize: 12),
                                children: const [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'terms and privacy policy',
                                    style: TextStyle(
                                      color: Color(0xFF5DB8FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Create Account CTA ────────────────────────────
                    ViloPrimaryButton(
                      label: 'Create Account',
                      onPressed: _isLoading ? null : _handleCreate,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 28),

                    // ── Social section ────────────────────────────────
                    const ViloSocialLoginSection(dividerLabel: 'OR JOIN WITH'),
                    const SizedBox(height: 32),

                    // ── Login link ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.bodyMd,
                        ),
                        GestureDetector(
                          onTap: _goToLogin,
                          child: Text(
                            'Login',
                            style: AppTypography.bodyMd.copyWith(
                              color: const Color(0xFF5DB8FF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// Minimal square checkbox in Obsidian Pulse style.
class _ViloCheckbox extends StatelessWidget {
  const _ViloCheckbox({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: value ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: value ? AppColors.primary : AppColors.outlineVariant,
          width: 1.5,
        ),
      ),
      child: value
          ? const Icon(Icons.check_rounded, size: 13, color: AppColors.onPrimary)
          : null,
    );
  }
}

Route<T> _slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 320),
  );
}
