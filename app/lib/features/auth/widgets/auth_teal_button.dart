import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/shadows.dart';
import 'auth_clay.dart';

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

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: loading ? loadingLabel : label,
      child: Opacity(
        opacity: loading ? 0.85 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(29),
            child: Ink(
              height: 58,
              decoration: BoxDecoration(
                gradient: authTealButtonGradient,
                borderRadius: BorderRadius.circular(29),
                boxShadow: AppShadows.tealButton,
              ),
              child: Center(
                child: loading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(loadingLabel, style: AppText.authPrimaryButton),
                        ],
                      )
                    : Text(label, style: AppText.authPrimaryButton),
              ),
            ),
          ),
        ),
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

  final VoidCallback? onPressed;
  final bool loading;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: 'Continue with Google',
      child: Opacity(
        opacity: loading ? 0.85 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(27),
            child: Ink(
              height: 54,
              decoration: authClayDecoration(
                borderRadius: BorderRadius.circular(27),
              ),
              child: Center(
                child: loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Continue with Google',
                              style: AppText.authGoogleButton,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(painter: _GoogleGPainter()),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Continue with Google',
                              style: AppText.authGoogleButton,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
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
