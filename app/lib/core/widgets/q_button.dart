import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../theme/shadows.dart';

enum QButtonVariant { primary, secondary, text, destructive }

/// Clay or text button. Primary uses the teal edge; pressed shifts down 2 px.
class QButton extends StatefulWidget {
  const QButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = QButtonVariant.primary,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final QButtonVariant variant;
  final bool loading;

  bool get _enabled => onPressed != null && !loading;

  @override
  State<QButton> createState() => _QButtonState();
}

class _QButtonState extends State<QButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final enabled = widget._enabled;
    final pressed = _down && enabled;
    final (background, foreground, shadows) = _look(pressed);

    final child = AnimatedContainer(
      duration: reduce ? const Duration(milliseconds: 150) : const Duration(milliseconds: 80),
      transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
      constraints: const BoxConstraints(minHeight: AppSpacing.minTap, minWidth: AppSpacing.minTap),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20, vertical: AppSpacing.s12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: widget.variant == QButtonVariant.text ? null : shadows,
      ),
      child: widget.loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
            )
          : Text(widget.label, style: AppText.title.copyWith(color: foreground)),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: enabled ? widget.onPressed : null,
        child: child,
      ),
    );
  }

  (Color?, Color, List<BoxShadow>?) _look(bool pressed) {
    final disabled = !widget._enabled;
    switch (widget.variant) {
      case QButtonVariant.primary:
        return (
          disabled ? AppColors.inkFaint : AppColors.tealDeep,
          AppColors.white,
          pressed ? AppShadows.clayPressed : AppShadows.clay,
        );
      case QButtonVariant.secondary:
        return (
          AppColors.white,
          disabled ? AppColors.inkFaint : AppColors.tealDeep,
          pressed ? AppShadows.clayPressed : AppShadows.chip,
        );
      case QButtonVariant.text:
        return (null, disabled ? AppColors.inkFaint : AppColors.tealDeep, null);
      case QButtonVariant.destructive:
        return (
          disabled ? AppColors.inkFaint : AppColors.error,
          AppColors.white,
          pressed ? AppShadows.clayPressed : AppShadows.card,
        );
    }
  }
}
