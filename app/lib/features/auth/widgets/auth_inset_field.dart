import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Inset-well labelled field used on auth screens.
class AuthInsetField extends StatelessWidget {
  const AuthInsetField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.hasError = false,
    this.trailing,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final Widget? trailing;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.insetWell,
        borderRadius: BorderRadius.circular(20),
        border: hasError
            ? Border.all(color: AppColors.authErrorOutline, width: 2)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x14101935),
                      Color(0x00FFFFFF),
                      Color(0xE6FFFFFF),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.fieldIcon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: AppText.authFieldLabel),
                      SizedBox(
                        height: 20,
                        child: TextField(
                          controller: controller,
                          obscureText: obscureText,
                          keyboardType: keyboardType,
                          textInputAction: textInputAction,
                          autofillHints: autofillHints,
                          onChanged: onChanged,
                          style: AppText.authFieldValue,
                          cursorColor: AppColors.tealDeep,
                          inputFormatters: const [],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Password visibility toggle with a ≥48 dp tap target.
class AuthPasswordToggle extends StatelessWidget {
  const AuthPasswordToggle({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: visible ? 'Hide password' : 'Show password',
      child: IconButton(
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTap,
          minHeight: AppSpacing.minTap,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: AppColors.fieldIcon,
        ),
      ),
    );
  }
}
