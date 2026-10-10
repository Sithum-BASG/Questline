import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// `mm:ss` with a ring against the estimate. Numbers stay tabular.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({
    super.key,
    required this.elapsedSeconds,
    required this.estimateSeconds,
  });

  final int elapsedSeconds;
  final int estimateSeconds;

  static String format(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final rest = safe % 60;
    return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = estimateSeconds <= 0 ? 0.0 : (elapsedSeconds / estimateSeconds).clamp(0.0, 1.0);
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              color: AppColors.awakeningTeal,
              backgroundColor: AppColors.line,
            ),
          ),
          Text(format(elapsedSeconds), style: AppText.timer),
        ],
      ),
    );
  }
}
