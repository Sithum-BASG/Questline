import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'clay.dart';
import 'stat_icon.dart';

/// A quest's wax seal: scalloped, in its stat's colours with the stat icon. Before the Judge
/// stamps a stat it is a dashed grey blank with a sparkle.
class QuestSeal extends StatelessWidget {
  const QuestSeal({super.key, this.stat, this.size = 52, this.done = false});

  /// Null while the quest is unjudged.
  final String? stat;
  final double size;

  /// Adds a green tick for a cleared quest.
  final bool done;

  @override
  Widget build(BuildContext context) {
    final s = stat;
    return Semantics(
      image: true,
      label: s == null ? 'Stat not judged yet' : '${StatIcon.labelFor(s)} quest${done ? ', cleared' : ''}',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _SealPainter(stat: s))),
            Center(
              child: s == null
                  ? Icon(Icons.auto_awesome_rounded, size: size * 0.34, color: AppColors.inkFaint)
                  : Icon(StatIcon.iconFor(s), size: size * 0.36, color: AppColors.white),
            ),
            if (done)
              Positioned(
                right: -2,
                bottom: 2,
                child: Container(
                  width: size * 0.32,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    color: AppColors.successText,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                  ),
                  child: Icon(Icons.check_rounded, size: size * 0.16, color: AppColors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter({required this.stat});

  final String? stat;

  /// Twenty scallops around the centre, drawn on a 60 px grid.
  Path _path(Size size) {
    final k = size.width / 60;
    final path = Path();
    const bumps = 20;
    for (var i = 0; i <= bumps; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / bumps;
      final outer = Offset(30 + 27 * math.cos(a), 30 + 27 * math.sin(a)) * k;
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
        continue;
      }
      final mid = a - math.pi / bumps;
      final control = Offset(30 + 24.6 * math.cos(mid), 30 + 24.6 * math.sin(mid)) * k;
      path.quadraticBezierTo(control.dx, control.dy, outer.dx, outer.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    final k = size.width / 60;
    final s = stat;
    if (s == null) {
      canvas.drawPath(path, Paint()..color = const Color(0xFFE8ECF2));
      final dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * k
        ..color = const Color(0xFFC3CAD6);
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 6 * k) {
          canvas.drawPath(metric.extractPath(d, d + 3 * k), dash);
        }
      }
      return;
    }
    canvas.drawPath(
      path.shift(Offset(2 * k, 5 * k)),
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * k),
    );
    canvas.drawPath(path, Paint()..shader = statGradient(s).createShader(Offset.zero & size));
    canvas.drawCircle(
      Offset(30, 30) * k,
      18.5 * k,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * k
        ..color = AppColors.white.withValues(alpha: 0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(24, 19) * k, width: 18 * k, height: 10 * k),
      Paint()..color = AppColors.white.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(_SealPainter oldDelegate) => oldDelegate.stat != stat;
}
