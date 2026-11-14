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
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.hasError = false,
    this.trailing,
    this.autofillHints,
  });

  static const double height = 56;
  static const double radius = 20;

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final Widget? trailing;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return Container(
      height: height,
      decoration: BoxDecoration(color: AppColors.insetWell, borderRadius: shape),
      foregroundDecoration: hasError
          ? BoxDecoration(
              borderRadius: shape,
              border: Border.all(color: AppColors.authErrorOutline, width: 2),
            )
          : null,
      child: ClipRRect(
        borderRadius: shape,
        child: CustomPaint(
          painter: const InsetShadowPainter(radius),
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: trailing == null ? 16 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.fieldIcon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(label, style: AppText.authFieldLabel),
                      TextField(
                        controller: controller,
                        obscureText: obscureText,
                        keyboardType: keyboardType,
                        textInputAction: textInputAction,
                        autofillHints: autofillHints,
                        onChanged: onChanged,
                        style: AppText.authFieldValue,
                        cursorColor: AppColors.tealDeep,
                        decoration: InputDecoration.collapsed(
                          hintText: hint,
                          hintStyle: AppText.authFieldHint,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft inner shadow: dark on the top-left inner edge, light on the bottom-right.
class InsetShadowPainter extends CustomPainter {
  const InsetShadowPainter(this.radius);

  final double radius;

  @override
  void paint(Canvas c, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(radius));
    c.save();
    c.clipRRect(r);
    void ring(Offset o, Color col) {
      final p = Path()
        ..addRect(Rect.fromLTWH(-40, -40, s.width + 80, s.height + 80))
        ..addRRect(r.shift(o))
        ..fillType = PathFillType.evenOdd;
      c.drawPath(
        p,
        Paint()
          ..color = col
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    ring(const Offset(4, 4), AppColors.insetShadowDark);
    ring(const Offset(-4, -4), AppColors.insetShadowLight);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant InsetShadowPainter oldDelegate) =>
      oldDelegate.radius != radius;
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
      excludeSemantics: true,
      child: IconButton(
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTap,
          minHeight: AppSpacing.minTap,
        ),
        padding: EdgeInsets.zero,
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: AppColors.fieldIcon,
        ),
      ),
    );
  }
}
