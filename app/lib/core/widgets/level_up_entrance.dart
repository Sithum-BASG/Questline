import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';

/// Level-up burst (Lottie). 1.5 s at 60 fps; skippable after [skipAfter].
class LevelUpEntrance extends StatefulWidget {
  const LevelUpEntrance({
    super.key,
    this.duration = const Duration(milliseconds: 1500),
    this.skipAfter = const Duration(milliseconds: 600),
    this.forceReducedMotion,
    this.onFinished,
    this.child,
  });

  final Duration duration;
  final Duration skipAfter;
  final bool? forceReducedMotion;
  final VoidCallback? onFinished;
  final Widget? child;

  @override
  State<LevelUpEntrance> createState() => _LevelUpEntranceState();
}

class _LevelUpEntranceState extends State<LevelUpEntrance> with SingleTickerProviderStateMixin {
  late final bool _reduce = widget.forceReducedMotion ??
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _reduce ? const Duration(milliseconds: 150) : widget.duration,
  );
  DateTime? _started;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished?.call();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void skipIfAllowed() {
    final started = _started;
    if (started == null) return;
    if (DateTime.now().difference(started) < widget.skipAfter) return;
    _controller.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: skipIfAllowed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (!_reduce)
                Opacity(
                  opacity: (1 - t * 0.35).clamp(0.0, 1.0),
                  child: Lottie.asset(
                    'assets/animations/level_up.json',
                    controller: _controller,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                    onLoaded: (composition) {
                      _controller.duration = composition.duration;
                      if (!_controller.isAnimating && _controller.value == 0) {
                        _controller.forward();
                      }
                    },
                  ),
                )
              else
                Opacity(
                  opacity: t,
                  child: Icon(Icons.auto_awesome, size: 72, color: AppColors.awakeningTeal),
                ),
              if (child != null) child,
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}
