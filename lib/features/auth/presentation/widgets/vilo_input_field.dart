import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/theme/app_typography.dart';

/// Reusable input field — Obsidian Pulse design system.
///
/// - Background: [AppColors.surface] (#141414)
/// - Border brightens on focus (rgba(255,255,255,0.2))
/// - 16px border-radius per style guide
class ViloInputField extends StatefulWidget {
  const ViloInputField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final String? errorText;

  @override
  State<ViloInputField> createState() => _ViloInputFieldState();
}

class _ViloInputFieldState extends State<ViloInputField> {
  late bool _isObscured;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsNode = true;
    }
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (_ownsNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.errorText != null
        ? AppColors.error
        : _isFocused
            ? const Color(0x33FFFFFF) // rgba(255,255,255,0.2)
            : const Color(0x1AFFFFFF); // surfaceStroke subtle

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.roundedLg,
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _isObscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            onSubmitted: widget.onSubmitted,
            style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface, fontSize: 14),
            cursorColor: AppColors.primary,
            cursorWidth: 1.5,
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: AppTypography.bodyMd.copyWith(
                color: _isFocused ? AppColors.onSurfaceVariant : AppColors.outline,
                fontSize: 13,
              ),
              floatingLabelStyle: AppTypography.labelCaps.copyWith(
                color: _isFocused ? AppColors.onSurface : AppColors.outline,
                letterSpacing: 0.4,
                fontSize: 10,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(widget.prefixIcon, size: 18,
                          color: _isFocused ? AppColors.onSurfaceVariant : AppColors.outline),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              // Suffix: password toggle or static icon
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 18, color: AppColors.outline,
                      ),
                      onPressed: () => setState(() => _isObscured = !_isObscured),
                      splashRadius: 18,
                    )
                  : (widget.suffixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Icon(widget.suffixIcon, size: 18, color: AppColors.outline),
                        )
                      : null),
              suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              widget.errorText!,
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.error, letterSpacing: 0, fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
