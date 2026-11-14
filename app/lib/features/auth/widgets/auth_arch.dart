import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/shadows.dart';
import 'auth_clay.dart';

/// Decorative portal arch with starter heroes and Questline nameplate.
///
/// Lays out from the very top of the screen: the scroll view hosting it must
/// not add top safe-area padding. Heads break out above the arch onto the page.
class AuthArch extends StatelessWidget {
  const AuthArch({super.key});

  static const double archWidth = 280;
  static const double archHeight = 220;
  static const double archTopMin = 76;
  static const double rimInset = 8;
  static const double heroLayerWidth = 264;
  static const double nameplateHeight = 46;
  static const double nameplateOverlap = 2;

  /// Arch top from the screen top; pushed down only if the status bar is taller.
  static double archTop(BuildContext context) =>
      math.max(archTopMin, MediaQuery.paddingOf(context).top + 12);

  static double height(BuildContext context) =>
      archTop(context) + archHeight - nameplateOverlap + nameplateHeight;

  @override
  Widget build(BuildContext context) {
    final top = archTop(context);
    final archBottom = top + archHeight;

    return ExcludeSemantics(
      child: SizedBox(
        height: height(context),
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final archLeft = (constraints.maxWidth - archWidth) / 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: archLeft,
                  top: top,
                  width: archWidth,
                  height: archHeight,
                  child: const _ArchBody(),
                ),
                Positioned(
                  left: archLeft + rimInset,
                  top: 0,
                  width: heroLayerWidth,
                  height: archBottom - rimInset,
                  child: ClipPath(
                    clipper: HeroClipper(),
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
                  left: 0,
                  right: 0,
                  top: archBottom - nameplateOverlap,
                  child: const Center(child: _Nameplate()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Cuts the heroes at the arch's inner bottom edge (28 px corners).
class HeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..addRRect(RRect.fromLTRBAndCorners(
      0,
      0,
      s.width,
      s.height,
      bottomLeft: const Radius.circular(28),
      bottomRight: const Radius.circular(28),
    ));

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ArchBody extends StatelessWidget {
  const _ArchBody();

  static const _panelRadius = BorderRadius.only(
    topLeft: Radius.circular(132),
    topRight: Radius.circular(132),
    bottomLeft: Radius.circular(28),
    bottomRight: Radius.circular(28),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: authClayDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(140),
          topRight: Radius.circular(140),
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AuthArch.rimInset),
        child: ClipRRect(
          borderRadius: _panelRadius,
          child: CustomPaint(
            painter: _ArchPanelPainter(),
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _HeroSkin extends StatelessWidget {
  const _HeroSkin({required this.asset, this.flip = false});

  final String asset;
  final bool flip;

  static const double width = 307;
  static const double height = 461;

  @override
  Widget build(BuildContext context) {
    final shadow = AppShadows.authHero.first;
    Widget figure = SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Drop shadow: a blurred, tinted copy of the image itself, so it
          // follows the silhouette instead of the image's bounding box.
          Positioned(
            left: shadow.offset.dx,
            top: shadow.offset.dy,
            width: width,
            height: height,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: shadow.blurSigma,
                sigmaY: shadow.blurSigma,
              ),
              child: Image.asset(
                asset,
                width: width,
                height: height,
                fit: BoxFit.contain,
                color: shadow.color,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          Image.asset(asset, width: width, height: height, fit: BoxFit.contain),
        ],
      ),
    );
    if (flip) figure = Transform.flip(flipX: true, child: figure);
    return figure;
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

/// Inner panel: radial glow, soft rays, two rune rings, sparkles, inner border.
/// Coordinates are in panel space (264 × 204 in the reference frame).
class _ArchPanelPainter extends CustomPainter {
  const _ArchPanelPainter();

  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = Offset(size.width / 2, size.height * (1 + 0.24) / 2);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.24),
          radius: 0.95,
          colors: [
            Color(0xFFE9FBF7),
            Color(0xFFB9EDE4),
            Color(0xFF7FCFD0),
            Color(0xFF6A8FCF),
          ],
          stops: [0, 0.38, 0.72, 1],
        ).createShader(rect),
    );

    _paintRays(canvas, rect, centre);

    canvas.drawCircle(
      const Offset(28 + 104, 40 + 104),
      104,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _white.withValues(alpha: 0.5),
    );
    _paintDashedCircle(
      canvas,
      const Offset(58 + 74, 70 + 74),
      74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _white.withValues(alpha: 0.45),
    );

    _paintSparkle(canvas, const Offset(40, 90), 12, 0.9);
    _paintSparkle(canvas, const Offset(222, 110), 9, 0.85);
    _paintSparkle(canvas, const Offset(206, 196), 7, 0.8);

    final border = RRect.fromRectAndCorners(
      rect.deflate(1),
      topLeft: const Radius.circular(131),
      topRight: const Radius.circular(131),
      bottomLeft: const Radius.circular(27),
      bottomRight: const Radius.circular(27),
    );
    canvas.drawRRect(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _white.withValues(alpha: 0.6),
    );
  }

  void _paintRays(Canvas canvas, Rect rect, Offset centre) {
    // 20 wedges of 6° white then 12° clear, with hard stops.
    const wedges = 20;
    const on = 6 / 360;
    const period = 18 / 360;
    final ray = _white.withValues(alpha: 0.22);
    const clear = Color(0x00FFFFFF);
    final colors = <Color>[];
    final stops = <double>[];
    for (var i = 0; i < wedges; i++) {
      final start = i * period;
      colors.addAll([ray, ray, clear, clear]);
      stops.addAll([start, start + on, start + on, start + period]);
    }

    final reach = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ].map((corner) => (corner - centre).distance).reduce(math.max);

    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()..shader = ui.Gradient.sweep(centre, colors, stops),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.radial(
          centre,
          reach,
          const [Color(0xFF000000), Color(0x00000000)],
          const [0.08, 0.40],
        ),
    );
    canvas.restore();
  }

  void _paintDashedCircle(Canvas canvas, Offset c, double r, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    final step = (dash + gap) / r;
    final sweep = dash / r;
    final bounds = Rect.fromCircle(center: c, radius: r);
    for (var a = 0.0; a < math.pi * 2; a += step) {
      canvas.drawArc(bounds, a, sweep, false, paint);
    }
  }

  /// 4-point star from a 24 × 24 box, drawn with its top-left at [topLeft].
  void _paintSparkle(Canvas canvas, Offset topLeft, double size, double opacity) {
    final k = size / 24;
    Offset p(double x, double y) => topLeft + Offset(x * k, y * k);
    final path = Path()
      ..moveTo(p(12, 0).dx, p(12, 0).dy)
      ..lineTo(p(14, 10).dx, p(14, 10).dy)
      ..lineTo(p(24, 12).dx, p(24, 12).dy)
      ..lineTo(p(14, 14).dx, p(14, 14).dy)
      ..lineTo(p(12, 24).dx, p(12, 24).dy)
      ..lineTo(p(10, 14).dx, p(10, 14).dy)
      ..lineTo(p(0, 12).dx, p(0, 12).dy)
      ..lineTo(p(10, 10).dx, p(10, 10).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = _white.withValues(alpha: opacity));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
