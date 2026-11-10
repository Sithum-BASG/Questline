import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/shadows.dart';
import 'auth_clay.dart';

/// Decorative portal arch with starter heroes and Questline nameplate.
class AuthArch extends StatelessWidget {
  const AuthArch({super.key});

  static const double archWidth = 280;
  static const double archHeight = 220;
  static const double topMargin = 76;
  static const double nameplateHeight = 46;
  static const double nameplateOverlap = 2;
  static const double clipWidth = 264;

  /// Total height so the nameplate sits overlapping the arch base.
  static const double totalHeight =
      topMargin + archHeight + (nameplateHeight / 2) - nameplateOverlap;

  @override
  Widget build(BuildContext context) {
    final archBottom = topMargin + archHeight;
    final clipBottom = archBottom - 8; // inner panel bottom edge

    return ExcludeSemantics(
      child: SizedBox(
        height: totalHeight,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: topMargin,
              child: Container(
                width: archWidth,
                height: archHeight,
                padding: const EdgeInsets.all(8),
                decoration: authClayDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(140),
                    topRight: Radius.circular(140),
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(132),
                    topRight: Radius.circular(132),
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: const Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, 0.24),
                            radius: 1.05,
                            colors: [
                              Color(0xFFE9FBF7),
                              Color(0xFFB9EDE4),
                              Color(0xFF7FCFD0),
                              Color(0xFF6A8FCF),
                            ],
                            stops: [0, 0.38, 0.72, 1],
                          ),
                        ),
                      ),
                      CustomPaint(painter: _ArchDecorPainter()),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(132),
                              topRight: Radius.circular(132),
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                            border: Border.fromBorderSide(
                              BorderSide(color: Color(0x99FFFFFF), width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Heroes: clipped to the arch inner base so feet are cut cleanly;
            // clip starts at screen top so heads break out above the arch.
            Positioned(
              top: 0,
              width: clipWidth,
              height: clipBottom,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 13,
                      top: 44,
                      child: _HeroSkin(
                        asset: GameAssets.skin('starter', BodyType.b),
                        flip: true,
                      ),
                    ),
                    Positioned(
                      left: -63,
                      top: 40,
                      child: _HeroSkin(
                        asset: GameAssets.skin('starter', BodyType.a),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: archBottom - nameplateOverlap - nameplateHeight / 2,
              child: const _Nameplate(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSkin extends StatelessWidget {
  const _HeroSkin({required this.asset, this.flip = false});

  final String asset;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      width: 307,
      height: 461,
      fit: BoxFit.cover,
    );
    if (flip) {
      image = Transform.flip(flipX: true, child: image);
    }
    return Container(
      decoration: const BoxDecoration(boxShadow: AppShadows.authHero),
      child: image,
    );
  }
}

class _Nameplate extends StatelessWidget {
  const _Nameplate();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AuthArch.nameplateHeight,
      padding: const EdgeInsets.only(left: 8, right: 18),
      decoration: authClayDecoration(
        borderRadius: BorderRadius.circular(23),
        shadows: AppShadows.claySoftSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(GameAssets.logoMark, width: 32, height: 32),
          const SizedBox(width: 8),
          const Text('Questline', style: AppText.authBrand),
        ],
      ),
    );
  }
}

class _ArchDecorPainter extends CustomPainter {
  const _ArchDecorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height * 0.55);

    canvas.saveLayer(Offset.zero & size, Paint());
    const step = 18.0 * math.pi / 180;
    const on = 6.0 * math.pi / 180;
    final wedge = Paint()..color = const Color(0x38FFFFFF);
    for (var a = 0.0; a < math.pi * 2; a += step) {
      final path = Path()
        ..moveTo(centre.dx, centre.dy)
        ..arcTo(
          Rect.fromCircle(center: centre, radius: size.width),
          a,
          on,
          false,
        )
        ..close();
      canvas.drawPath(path, wedge);
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = RadialGradient(
          center: Alignment(
            (centre.dx / size.width) * 2 - 1,
            (centre.dy / size.height) * 2 - 1,
          ),
          colors: const [Colors.white, Colors.transparent],
          stops: const [0.08, 0.40],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0x80FFFFFF);
    canvas.drawCircle(const Offset(28 + 104, 40 + 104), 104, ring);

    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0x73FFFFFF);
    _drawDashedCircle(canvas, const Offset(58 + 74, 70 + 74), 74, dash);

    _sparkle(canvas, const Offset(40, 90), 12);
    _sparkle(canvas, const Offset(222, 110), 9);
    _sparkle(canvas, const Offset(206, 196), 7);
  }

  void _drawDashedCircle(Canvas canvas, Offset c, double r, Paint paint) {
    const dashAngle = 0.12;
    const gapAngle = 0.10;
    var a = 0.0;
    while (a < math.pi * 2) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a,
        dashAngle,
        false,
        paint,
      );
      a += dashAngle + gapAngle;
    }
  }

  void _sparkle(Canvas canvas, Offset c, double size) {
    final paint = Paint()..color = const Color(0xE6FFFFFF);
    final half = size / 2;
    final path = Path()
      ..moveTo(c.dx, c.dy - half)
      ..lineTo(c.dx + half * 0.22, c.dy - half * 0.22)
      ..lineTo(c.dx + half, c.dy)
      ..lineTo(c.dx + half * 0.22, c.dy + half * 0.22)
      ..lineTo(c.dx, c.dy + half)
      ..lineTo(c.dx - half * 0.22, c.dy + half * 0.22)
      ..lineTo(c.dx - half, c.dy)
      ..lineTo(c.dx - half * 0.22, c.dy - half * 0.22)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
