import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/vilo_input_field.dart';
import '../widgets/vilo_primary_button.dart';
import '../widgets/vilo_social_login_section.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Screen 2 — Login
///
/// Matches design reference:
/// - "Welcome Back" large heading
/// - Email/Username + Password fields
/// - Forget Password link
/// - White pill Login button
/// - OR CONTINUE WITH social section
/// - Don't have an account? Sign up link
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

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
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  bool _validate() {
    String? emailErr;
    String? passErr;
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (email.isEmpty) {
      emailErr = 'Email is required';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailErr = 'Enter a valid email';
    }
    if (pass.isEmpty) passErr = 'Password is required';

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });
    return emailErr == null && passErr == null;
  }

  Future<void> _handleLogin() async {
    if (!_validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  void _goToRegister() => Navigator.of(context).push(_slideRoute(const RegisterScreen()));
  void _goToForgot() => Navigator.of(context).push(_slideRoute(const ForgotPasswordScreen()));

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
                    // ── Heading ──────────────────────────────────────
                    Text(
                      'Welcome Back',
                      style: AppTypography.headlineLg.copyWith(
                        fontSize: 36,
                        height: 1.1,
                        letterSpacing: -0.8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your details to access the void.',
                      style: AppTypography.bodyMd,
                    ),
                    const SizedBox(height: 32),

                    // ── Email/Username field ──────────────────────────
                    ViloInputField(
                      label: 'Email/Username',
                      controller: _emailCtrl,
                      prefixIcon: null,
                      suffixIcon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      errorText: _emailError,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                    const SizedBox(height: 12),

                    // ── Password field ────────────────────────────────
                    ViloInputField(
                      label: 'Password',
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      errorText: _passwordError,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 8),

                    // ── Forget password ───────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _goToForgot,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forget Password?',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Login CTA ─────────────────────────────────────
                    ViloPrimaryButton(
                      label: 'Login',
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 28),

                    // ── Social section ────────────────────────────────
                    const ViloSocialLoginSection(),
                    const SizedBox(height: 32),

                    // ── Sign up link ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTypography.bodyMd,
                        ),
                        GestureDetector(
                          onTap: _goToRegister,
                          child: Text(
                            'Sign up',
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

Route<T> _slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 320),
  );
}
