import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'clay.dart';

/// `mm:ss` in a raised clay dial with a glossy teal ring against the
/// estimate. Numbers stay tabular.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({
    super.key,
    required this.elapsedSeconds,
    required this.estimateSeconds,
    this.caption,
    this.size = 248,
  });

  final int elapsedSeconds;
  final int estimateSeconds;

  /// Small line under the digits (e.g. "of ~45 min").
  final String? caption;
  final double size;

  static String format(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final rest = safe % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = estimateSeconds <= 0 ? 0.0 : (elapsedSeconds / estimateSeconds).clamp(0.0, 1.0);
    return Semantics(
      label: 'Elapsed ${format(elapsedSeconds)}',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Clay(circle: true, width: size, height: size),
            Well(circle: true, width: size - 36, height: size - 36),
            SizedBox(
              width: size - 36,
              height: size - 36,
              child: CustomPaint(painter: _RingPainter(progress)),
            ),
            Clay(
              circle: true,
              width: size - 72,
              height: size - 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(format(elapsedSeconds), style: AppText.timer.copyWith(fontSize: 48)),
                  ),
                  if (caption != null) Text(caption!, style: AppText.caption, textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    const stroke = 12.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [AppColors.tealLight, AppColors.awakeningTeal, AppColors.tealDeep],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
