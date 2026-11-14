import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';

enum QButtonVariant { primary, secondary, text, destructive }

/// Pill clay button. Primary is teal clay, secondary is white clay,
/// destructive is red-orange clay. Pressed sinks 2 px.
class QButton extends StatefulWidget {
  const QButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = QButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.height,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final QButtonVariant variant;
  final bool loading;
  final IconData? icon;

  /// Defaults to 60 for primary, 52 otherwise.
  final double? height;

  /// Overrides the label colour (e.g. a destructive word on white clay).
  final Color? foreground;

  bool get _enabled => onPressed != null && !loading;

  @override
  State<QButton> createState() => _QButtonState();
}

class _QButtonState extends State<QButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget._enabled;
    final pressed = _down && enabled;
    final variant = widget.variant;

    if (variant == QButtonVariant.text) {
      return Semantics(
        button: true,
        enabled: enabled,
        label: widget.label,
        excludeSemantics: true,
        child: TextButton(
          onPressed: enabled ? widget.onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: widget.foreground ?? AppColors.tealDeep,
            minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
            textStyle: AppText.title.copyWith(fontSize: 15),
            shape: const StadiumBorder(),
          ),
          child: widget.loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.label),
        ),
      );
    }

    final height = widget.height ?? (variant == QButtonVariant.primary ? 60.0 : 52.0);
    final kind = switch (variant) {
      QButtonVariant.primary => ClayKind.teal,
      QButtonVariant.destructive => ClayKind.danger,
      _ => ClayKind.control,
    };
    final teal = kind != ClayKind.control;
    final fg = widget.foreground ?? (teal ? AppColors.white : AppColors.ink);
    final textStyle = AppText.button.copyWith(color: fg, fontSize: height >= 58 ? 17 : 15);

    final content = widget.loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: fg),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: textStyle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: AppMotion.button(context),
          transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
          child: Opacity(
            opacity: enabled || widget.loading ? 1 : 0.45,
            child: LayoutBuilder(
              builder: (context, box) => Clay(
                kind: kind,
                radius: height / 2,
                height: height,
                shadows: !enabled && !widget.loading ? const [] : null,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
                // Full width when the parent bounds us, hug the label otherwise.
                child: Center(widthFactor: box.hasBoundedWidth ? null : 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
