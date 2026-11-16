import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';

/// A full field of colour with light rays and sparkles behind a reward or recap card:
/// it should feel like a burst, not a dialog.
class RewardField extends StatelessWidget {
  const RewardField({
    super.key,
    required this.color,
    this.centre = const Alignment(0, 0.04),
    this.coins = false,
    this.rays = true,
  });

  /// The field's middle colour. The centre is lighter and the rim darker.
  final Color color;

  /// Where the glow and the rays start.
  final Alignment centre;

  /// Scatter coins across the field (coin rewards).
  final bool coins;
  final bool rays;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: centre,
                    radius: 1.05,
                    colors: [
                      Color.lerp(color, AppColors.white, 0.45)!,
                      color,
                      Color.lerp(color, AppColors.ink, 0.5)!,
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
              if (rays) CustomPaint(painter: _RaysPainter(centre: centre)),
              for (final (x, y, size, opacity) in _sparkles)
                Positioned(
                  left: x * w,
                  top: y * h,
                  child: Opacity(
                    opacity: opacity,
                    child: CustomPaint(size: Size.square(size), painter: const _SparklePainter()),
                  ),
                ),
              for (final (x, y, size) in _dots)
                Positioned(
                  left: x * w,
                  top: y * h,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.7), shape: BoxShape.circle),
                  ),
                ),
              if (coins)
                for (final (x, y, size, turn) in _coins)
                  Positioned(
                    left: x * w,
                    top: y * h,
                    child: Transform.rotate(
                      angle: turn * math.pi / 180,
                      child: Image.asset(GameAssets.icon('coin'), width: size, height: size),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

// Positions as fractions of the field, sizes in px.
const _sparkles = [
  (0.12, 0.22, 14.0, 0.9),
  (0.82, 0.19, 18.0, 0.85),
  (0.08, 0.56, 10.0, 0.7),
  (0.89, 0.49, 12.0, 0.8),
  (0.23, 0.78, 8.0, 0.6),
  (0.77, 0.80, 10.0, 0.7),
  (0.38, 0.18, 8.0, 0.6),
  (0.64, 0.28, 6.0, 0.7),
  (0.15, 0.39, 6.0, 0.5),
  (0.86, 0.69, 6.0, 0.6),
];

const _dots = [
  (0.28, 0.28, 6.0),
  (0.72, 0.39, 5.0),
  (0.18, 0.67, 4.0),
  (0.83, 0.59, 5.0),
  (0.51, 0.87, 4.0),
];

const _coins = [
  (0.09, 0.31, 34.0, -18.0),
  (0.80, 0.28, 40.0, 14.0),
  (0.05, 0.61, 28.0, 22.0),
  (0.85, 0.56, 32.0, -10.0),
  (0.16, 0.81, 26.0, 8.0),
  (0.77, 0.80, 30.0, -24.0),
  (0.33, 0.22, 22.0, 30.0),
  (0.64, 0.18, 24.0, -6.0),
];

/// Crisp white rays from behind the reward, fading out from the centre.
class _RaysPainter extends CustomPainter {
  const _RaysPainter({required this.centre});

  final Alignment centre;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = centre.alongSize(size);
    final radius = size.longestSide * 0.62;
    final rect = Rect.fromCircle(center: origin, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.white.withValues(alpha: 0.16), AppColors.white.withValues(alpha: 0)],
        stops: const [0.2, 1],
      ).createShader(rect);
    const on = 7 * math.pi / 180;
    const step = 20 * math.pi / 180;
    for (var a = 0.0; a < math.pi * 2; a += step) {
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..arcTo(rect, a, on, false)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) => oldDelegate.centre != centre;
}

/// A four-point white sparkle.
class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = w / 2;
    final path = Path()
      ..moveTo(c, 0)
      ..lineTo(c + w * 0.083, c - w * 0.083)
      ..lineTo(w, c)
      ..lineTo(c + w * 0.083, c + w * 0.083)
      ..lineTo(c, w)
      ..lineTo(c - w * 0.083, c + w * 0.083)
      ..lineTo(0, c)
      ..lineTo(c - w * 0.083, c - w * 0.083)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => false;
}
