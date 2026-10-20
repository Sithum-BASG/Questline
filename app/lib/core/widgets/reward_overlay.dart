import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_button.dart';

enum RewardKind { levelUp, loot, boss, badge, streak }

extension RewardKindLabel on RewardKind {
  String get label {
    switch (this) {
      case RewardKind.levelUp:
        return 'Level up';
      case RewardKind.loot:
        return 'Loot';
      case RewardKind.boss:
        return 'Boss defeated';
      case RewardKind.badge:
        return 'Badge';
      case RewardKind.streak:
        return 'Streak';
    }
  }

  IconData get fallbackIcon {
    switch (this) {
      case RewardKind.levelUp:
        return Icons.auto_awesome;
      case RewardKind.loot:
        return Icons.inventory_2_outlined;
      case RewardKind.boss:
        return Icons.sports_mma_outlined;
      case RewardKind.badge:
        return Icons.military_tech_outlined;
      case RewardKind.streak:
        return Icons.local_fire_department_outlined;
    }
  }
}

class RewardMoment {
  const RewardMoment({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.artPath,
    this.rarity,
  });

  factory RewardMoment.levelUp({required String title, required String subtitle, String? artPath}) =>
      RewardMoment(kind: RewardKind.levelUp, title: title, subtitle: subtitle, artPath: artPath);

  factory RewardMoment.loot({
    required String title,
    required String subtitle,
    String? artPath,
    String rarity = 'common',
  }) =>
      RewardMoment(kind: RewardKind.loot, title: title, subtitle: subtitle, artPath: artPath, rarity: rarity);

  factory RewardMoment.boss({required String title, required String subtitle, String? artPath}) =>
      RewardMoment(kind: RewardKind.boss, title: title, subtitle: subtitle, artPath: artPath);

  factory RewardMoment.badge({required String title, required String subtitle, String? artPath}) =>
      RewardMoment(kind: RewardKind.badge, title: title, subtitle: subtitle, artPath: artPath);

  factory RewardMoment.streak({required String title, required String subtitle, String? artPath}) =>
      RewardMoment(kind: RewardKind.streak, title: title, subtitle: subtitle, artPath: artPath);

  final RewardKind kind;
  final String title;
  final String subtitle;
  final String? artPath;
  final String? rarity;

  bool get isMythic => (rarity ?? '').toLowerCase() == 'mythic';

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
///
/// Reduced motion (OS): 150 ms fade only — no burst, scale, or shimmer.
class RewardOverlay extends StatefulWidget {
  const RewardOverlay({
    super.key,
    required this.moment,
    required this.onClaim,
    this.entrance = const Duration(milliseconds: 1400),
    this.skipAfter = const Duration(milliseconds: 600),
    this.reducedMotionEntrance = const Duration(milliseconds: 150),
    this.forceReducedMotion,
  });

  final RewardMoment moment;
  final VoidCallback onClaim;
  final Duration entrance;
  final Duration skipAfter;
  final Duration reducedMotionEntrance;

  /// Test hook; when null, reads [AccessibilityFeatures.disableAnimations].
  final bool? forceReducedMotion;

  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay> with TickerProviderStateMixin {
  late final bool _reduceMotion = widget.forceReducedMotion ??
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _reduceMotion ? widget.reducedMotionEntrance : widget.entrance,
  );
  AnimationController? _shimmer;
  var _settled = false;
  DateTime? _started;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    if (!_reduceMotion && widget.moment.isMythic) {
      _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    }
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _settled = true);
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _shimmer?.dispose();
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
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final scale = _reduceMotion
        ? const AlwaysStoppedAnimation(1.0)
        : Tween(begin: 0.72, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    Widget art = SizedBox(
      width: 180,
      height: 180,
      child: moment.artPath == null
          ? Icon(moment.kind.fallbackIcon, size: 72, color: moment.burstColor)
          : Image.asset(moment.artPath!, fit: BoxFit.contain),
    );

    if (!_reduceMotion) {
      art = CustomPaint(
        painter: _BurstPainter(
          color: moment.burstColor.withValues(alpha: 0.35),
          mythicGradient: moment.isMythic,
        ),
        child: art,
      );
      if (moment.isMythic && _shimmer != null) {
        art = AnimatedBuilder(
          animation: _shimmer!,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                final t = _shimmer!.value;
                return LinearGradient(
                  begin: Alignment(-1.2 + 2.4 * t, -0.2),
                  end: Alignment(-0.4 + 2.4 * t, 0.2),
                  colors: [
                    Colors.transparent,
                    AppColors.mythic.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.7),
                    AppColors.mythic.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                ).createShader(bounds);
              },
              child: child,
            );
          },
          child: art,
        );
      }
    }

    return Material(
      color: AppColors.paper,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, ?_shimmer]),
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
                  Text(
                    moment.kind.label.toUpperCase(),
                    style: AppText.caption.copyWith(
                      color: moment.burstColor,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  art,
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
  _BurstPainter({required this.color, this.mythicGradient = false});

  final Color color;
  final bool mythicGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.7;
    final Gradient gradient = mythicGradient
        ? SweepGradient(
            colors: [
              AppColors.mythic.withValues(alpha: 0.45),
              AppColors.legendary.withValues(alpha: 0.25),
              AppColors.mythic.withValues(alpha: 0.45),
            ],
            transform: const GradientRotation(math.pi / 8),
          )
        : RadialGradient(colors: [color, color.withValues(alpha: 0)]);
    final paint = Paint()..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.mythicGradient != mythicGradient;
}
