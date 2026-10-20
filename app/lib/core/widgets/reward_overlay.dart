import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_button.dart';

enum RewardKind { levelUp, loot, boss, badge, streak }

class RewardMoment {
  const RewardMoment({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.artPath,
    this.rarity,
  });

  final RewardKind kind;
  final String title;
  final String subtitle;
  final String? artPath;
  final String? rarity;

  Color get burstColor {
    switch (kind) {
      case RewardKind.levelUp:
        return AppColors.awakeningTeal;
      case RewardKind.streak:
        return AppColors.streakEmber;
      case RewardKind.loot:
        return AppColors.rarity(rarity ?? 'common');
      case RewardKind.boss:
        return AppColors.epic;
      case RewardKind.badge:
        return AppColors.tealDeep;
    }
  }
}

/// Plays reward moments one after another. Session complete and chests push into this.
class RewardQueue extends ChangeNotifier {
  final List<RewardMoment> _pending = [];
  RewardMoment? current;

  List<RewardMoment> get pending => List.unmodifiable(_pending);

  void add(Iterable<RewardMoment> rewards) {
    _pending.addAll(rewards);
    notifyListeners();
  }

  /// Starts the next moment if nothing is showing.
  RewardMoment? next() {
    if (current != null || _pending.isEmpty) return current;
    current = _pending.removeAt(0);
    notifyListeners();
    return current;
  }

  void claim() {
    current = null;
    notifyListeners();
    next();
  }
}

final rewardQueueProvider = Provider<RewardQueue>((ref) => RewardQueue());

/// Full-screen reward template. Tap after 0.6 s jumps to the settled Claim state.
class RewardOverlay extends StatefulWidget {
  const RewardOverlay({
    super.key,
    required this.moment,
    required this.onClaim,
    this.entrance = const Duration(milliseconds: 1400),
    this.skipAfter = const Duration(milliseconds: 600),
  });

  final RewardMoment moment;
  final VoidCallback onClaim;
  final Duration entrance;
  final Duration skipAfter;

  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.entrance);
  var _settled = false;
  DateTime? _started;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    final reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduce) {
      _settled = true;
      _controller.value = 1;
    } else {
      _controller.forward().whenComplete(() {
        if (mounted) setState(() => _settled = true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    final started = _started;
    if (started == null) return;
    if (DateTime.now().difference(started) < widget.skipAfter) return;
    _controller.value = 1;
    setState(() => _settled = true);
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moment;
    final scale = Tween(begin: 0.72, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Material(
      color: AppColors.paper,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: fade.value.clamp(0.0, 1.0),
                child: Transform.scale(scale: scale.value, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                children: [
                  const Spacer(),
                  CustomPaint(
                    painter: _BurstPainter(color: moment.burstColor.withValues(alpha: 0.35)),
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: moment.artPath == null
                          ? Icon(Icons.auto_awesome, size: 72, color: moment.burstColor)
                          : Image.asset(moment.artPath!, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Text(moment.title, style: AppText.display, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.s8),
                  Text(moment.subtitle, style: AppText.body, textAlign: TextAlign.center),
                  const Spacer(),
                  if (_settled)
                    QButton(label: 'Claim', onPressed: widget.onClaim)
                  else
                    const SizedBox(height: AppSpacing.minTap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(
        Rect.fromCircle(center: center, radius: size.shortestSide * 0.7),
      );
    canvas.drawCircle(center, size.shortestSide * 0.7, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.color != color;
}
