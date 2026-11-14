import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/shadows.dart';
import 'auth_clay.dart';

/// Stadium-shaped button: the gradient and every shadow sit on one rounded
/// decoration, and the ink ripple is clipped to the same stadium shape.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.height,
    required this.gradient,
    required this.shadows,
    required this.semanticLabel,
    required this.enabled,
    required this.loading,
    required this.onPressed,
    required this.child,
  });

  final double height;
  final Gradient gradient;
  final List<BoxShadow> shadows;
  final String semanticLabel;
  final bool enabled;
  final bool loading;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Opacity(
        opacity: loading ? 0.85 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: gradient,
            boxShadow: shadows,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 3, color: color),
    );
  }
}

/// Full-width soft teal primary button for auth screens.
class AuthTealButton extends StatelessWidget {
  const AuthTealButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final String loadingLabel;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = loading ? loadingLabel : label;
    return _PillButton(
      height: 58,
      gradient: authTealButtonGradient,
      shadows: AppShadows.tealButton,
      semanticLabel: text,
      enabled: onPressed != null && !loading,
      loading: loading,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) ...[
            const _ButtonSpinner(color: AppColors.white),
            const SizedBox(width: 10),
          ],
          Text(text, style: AppText.authPrimaryButton),
        ],
      ),
    );
  }
}

/// Clay Google sign-in button.
class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  static const _label = 'Continue with Google';

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      height: 54,
      gradient: authClayGradient,
      shadows: AppShadows.claySoft,
      semanticLabel: _label,
      enabled: onPressed != null && !loading,
      loading: loading,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const _ButtonSpinner(color: AppColors.ink)
            else
              const SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(painter: _GoogleGPainter()),
              ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                _label,
                style: AppText.authGoogleButton,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final inset = stroke / 2;
    final arcRect = Rect.fromLTRB(inset, inset, size.width - inset, size.height - inset);

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        arcRect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = color,
      );
    }

    // Official-ish Google colours around the G ring.
    arc(const Color(0xFFEA4335), -2.2, 1.4);
    arc(const Color(0xFFFBBC05), -0.8, 1.2);
    arc(const Color(0xFF34A853), 0.4, 1.3);
    arc(const Color(0xFF4285F4), 1.7, 1.6);

    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.45, size.height * 0.42, size.width * 0.42, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
