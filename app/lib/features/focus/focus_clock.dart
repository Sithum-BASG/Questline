/// Tracks a focus session against the server start time.
class FocusClock {
  FocusClock({
    required this.startedAt,
    this.grace = const Duration(seconds: 30),
  });

  final DateTime startedAt;
  final Duration grace;
  final List<FocusInterruption> interruptions = [];
  DateTime? leftAt;
  bool broken = false;

  int elapsedSeconds(DateTime now) {
    var away = Duration.zero;
    for (final interruption in interruptions) {
      away += interruption.returnedAt.difference(interruption.leftAt);
    }
    final openLeave = leftAt;
    if (openLeave != null) away += now.difference(openLeave);
    final elapsed = now.difference(startedAt) - away;
    final seconds = elapsed.inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  /// True when the player just left and should be asked to come back.
  bool leave(DateTime now) {
    if (broken || leftAt != null) return false;
    leftAt = now;
    return true;
  }

  void returned(DateTime now) {
    final left = leftAt;
    if (left == null || broken) return;
    leftAt = null;
    if (now.difference(left) > grace) {
      broken = true;
      return;
    }
    interruptions.add(FocusInterruption(leftAt: left, returnedAt: now));
  }
}

class FocusInterruption {
  const FocusInterruption({required this.leftAt, required this.returnedAt});

  final DateTime leftAt;
  final DateTime returnedAt;

  Map<String, String> toJson() {
    return {
      'leftAt': leftAt.toUtc().toIso8601String(),
      'returnedAt': returnedAt.toUtc().toIso8601String(),
    };
  }
}
