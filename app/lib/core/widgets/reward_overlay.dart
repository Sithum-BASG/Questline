import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../assets/game_assets.dart';
import '../motion/app_haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'clay.dart';
import 'q_button.dart';
import 'reward_field.dart';

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
    this.coins,
    this.eyebrow,
    this.tag,
  });

  factory RewardMoment.levelUp({required String title, required String subtitle, String? artPath}) =>
      RewardMoment(kind: RewardKind.levelUp, title: title, subtitle: subtitle, artPath: artPath);

  factory RewardMoment.loot({
    required String title,
    required String subtitle,
    String? artPath,
    String rarity = 'common',
    int? coins,
    String? eyebrow,
  }) =>
      RewardMoment(
        kind: RewardKind.loot,
        title: title,
        subtitle: subtitle,
        artPath: artPath,
        rarity: rarity,
        coins: coins,
        eyebrow: eyebrow,
      );

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

  /// Coins this moment pays, shown as a chip and scattered across the field.
  final int? coins;

  /// Replaces the kind's label in the pill at the top.
  final String? eyebrow;

  /// A tag pinned under the plinth, e.g. DEFEATED. Loot shows its rarity when this is null.
  final String? tag;

  bool get isMythic => (rarity ?? '').toLowerCase() == 'mythic';

  Color get burstColor {
    switch (kind) {
      case RewardKind.levelUp:
        return AppColors.awakeningTeal;
      case RewardKind.streak:
        return AppColors.streakEmber;
      case RewardKind.loot:
        // Coin rewards burst in gold; items in their rarity colour.
        return (coins ?? 0) > 0 ? AppColors.legendary : AppColors.rarity(rarity ?? 'common');
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
    this.position = 1,
    this.count = 1,
  });

  final RewardMoment moment;

  /// Place of this moment in the queue, for the dots at the top.
  final int position;
  final int count;
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
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final k = math.min(1.0, size.height / 844);
    final sheetTop = size.height * (480 / 844);
    final plinthTop = math.max(insets.top + 64, sheetTop - 320 * k);
    final field = moment.isMythic ? AppColors.mythic : moment.burstColor;
    final level = moment.kind == RewardKind.levelUp ? RegExp(r'Level (\d+)').firstMatch(moment.title)?.group(1) : null;
    final tag = moment.tag ??
        (moment.kind == RewardKind.loot && moment.coins == null && (moment.rarity ?? 'common') != 'common'
            ? moment.rarity!.toUpperCase()
            : null);

    Widget plinth = _Plinth(child: _art(moment));
    if (!_reduceMotion && moment.isMythic && _shimmer != null) {
      plinth = AnimatedBuilder(
        animation: _shimmer!,
        builder: (context, child) => ShaderMask(
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
        ),
        child: plinth,
      );
    }

    return Material(
      color: AppColors.paper,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, ?_shimmer]),
          builder: (context, _) {
            final opacity = fade.value.clamp(0.0, 1.0);
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: sheetTop + 60,
                  child: RewardField(color: field, centre: const Alignment(0, -0.1), coins: (moment.coins ?? 0) > 0),
                ),
                if (widget.count > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: insets.top + 2,
                    child: Semantics(
                      label: 'Reward ${widget.position} of ${widget.count}',
                      excludeSemantics: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 1; i <= widget.count; i++)
                            Container(
                              width: i == widget.position ? 18 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: i == widget.position ? 1 : 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: insets.top + 19,
                  child: Center(
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.55), width: 1.5),
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            (moment.eyebrow ?? moment.kind.label).toUpperCase(),
                            style: AppText.label.copyWith(color: AppColors.white, letterSpacing: 1.9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: plinthTop,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale.value,
                      child: SizedBox(
                        height: 240 + 60,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            plinth,
                            if (level != null) Positioned(top: 192, child: _LevelBadge(level: level)),
                            if (tag != null && level == null)
                              Positioned(
                                top: 224,
                                child: _Tag(
                                  label: tag,
                                  color: moment.kind == RewardKind.loot ? AppColors.rarity(moment.rarity ?? 'common') : AppColors.tealDeep,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: sheetTop,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                      boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.12), offset: const Offset(0, -10), blurRadius: 30)],
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(28, 40 * k, 28, insets.bottom + 20),
                      child: Opacity(
                        opacity: opacity,
                        child: Column(
                          children: [
                            Text(
                              moment.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.display.copyWith(fontSize: 34, height: 40 / 34, letterSpacing: -1),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              moment.subtitle,
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(fontSize: 16, height: 23 / 16, color: AppColors.inkMuted),
                            ),
                            // Coin loot already says the amount in its title.
                            if ((moment.coins ?? 0) > 0 && moment.kind != RewardKind.loot) ...[
                              const SizedBox(height: 18),
                              _CoinChip(coins: moment.coins!),
                            ],
                            const Spacer(),
                            if (_settled)
                              QButton(
                                label: 'Claim',
                                onPressed: () {
                                  // Claim first so a missing haptic channel never blocks the queue.
                                  widget.onClaim();
                                  AppHaptics.claim();
                                },
                              )
                            else
                              const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The reward on the plinth.
  Widget _art(RewardMoment moment) {
    switch (moment.kind) {
      case RewardKind.levelUp:
        if (_reduceMotion) return Icon(moment.kind.fallbackIcon, size: 96, color: moment.burstColor);
        return Lottie.asset(
          'assets/animations/level_up.json',
          controller: _controller,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            final ms = composition.duration.inMilliseconds.clamp(1200, 1800);
            _controller.duration = Duration(milliseconds: ms);
            if (!_controller.isAnimating && _controller.value == 0) _controller.forward();
          },
        );
      case RewardKind.streak:
        final days = RegExp(r'\d+').firstMatch(moment.title)?.group(0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department_rounded, size: 104, color: AppColors.streakEmber),
            if (days != null)
              Transform.translate(
                offset: const Offset(0, -4),
                child: Text(days, style: AppText.display.copyWith(fontSize: 44, height: 48 / 44)),
              ),
          ],
        );
      case RewardKind.loot:
        if ((moment.coins ?? 0) > 0 && moment.artPath == null) {
          return Image.asset(GameAssets.icon('pouch_large'), width: 176, height: 176);
        }
        if (moment.artPath == null) return Icon(moment.kind.fallbackIcon, size: 88, color: moment.burstColor);
        return Transform.rotate(
          angle: -18 * math.pi / 180,
          child: Image.asset(moment.artPath!, width: 200, height: 200, fit: BoxFit.contain),
        );
      case RewardKind.boss:
      case RewardKind.badge:
        if (moment.artPath == null) return Icon(moment.kind.fallbackIcon, size: 88, color: moment.burstColor);
        return Image.asset(moment.artPath!, width: 210, height: 210, fit: BoxFit.contain);
    }
  }
}

/// The white clay plinth ringed with light that the reward stands on.
class _Plinth extends StatelessWidget {
  const _Plinth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppColors.white.withValues(alpha: 0.28), spreadRadius: 10),
          BoxShadow(color: AppColors.white.withValues(alpha: 0.12), spreadRadius: 22),
          const BoxShadow(color: Color(0x47101935), offset: Offset(0, 24), blurRadius: 40),
        ],
      ),
      child: Clay(circle: true, shadows: const [], child: Center(child: child)),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Level $level',
      excludeSemantics: true,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 4),
          boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.28), offset: const Offset(4, 10), blurRadius: 18)],
        ),
        child: Clay(
          kind: ClayKind.teal,
          circle: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('LV', style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, color: AppColors.white, letterSpacing: 1)),
              Text(level, style: AppText.display.copyWith(fontSize: 30, height: 34 / 30, color: AppColors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white, width: 3),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.22), offset: const Offset(2, 6), blurRadius: 12)],
      ),
      child: Center(
        widthFactor: 1,
        child: Text(label, style: AppText.label.copyWith(color: AppColors.white, letterSpacing: 1.7)),
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 24,
      height: 48,
      padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(GameAssets.icon('coin'), width: 34, height: 34),
          const SizedBox(width: 8),
          Text('+$coins', style: AppText.numbers.copyWith(fontSize: 19, height: 24 / 19)),
        ],
      ),
    );
  }
}

