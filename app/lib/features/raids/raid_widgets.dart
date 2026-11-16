import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import 'package:questline/core/assets/decode_size.dart';

/// Raid numbers from `game_config`, for display only.
class RaidRules {
  const RaidRules({
    required this.fairShareRatio,
    required this.narrowThreshold,
    required this.victoryBonus,
    required this.escapePenalty,
    required this.tiers,
    required this.maxFights,
    required this.partyMin,
    required this.partyMax,
    required this.guildMax,
  });

  final double fairShareRatio;
  final double narrowThreshold;
  final double victoryBonus;
  final int escapePenalty;

  /// (name, hours below which it applies, base loot coins).
  final List<(String, double, int)> tiers;
  final int maxFights;
  final int partyMin;
  final int partyMax;
  final int guildMax;

  /// Damage a raider must deal to earn loot.
  int fairShare(int maxHp, int people) => people <= 0 ? 0 : (fairShareRatio * maxHp / people).ceil();

  /// Coins each raider who met their share gets, before the early-win bonus.
  int baseLoot(String tier) {
    for (final t in tiers) {
      if (t.$1 == tier) return t.$3;
    }
    return 0;
  }

  /// Tier a boss with [hours] per person falls in.
  String tierFor(double hours) {
    for (final t in tiers) {
      if (hours < t.$2) return t.$1;
    }
    return tiers.isEmpty ? 'brute' : tiers.last.$1;
  }

  /// Coins each raider gets for [status] when they met their share.
  int lootFor(String tier, String status) {
    final base = baseLoot(tier);
    return switch (status) {
      'victory' => (base * (1 + victoryBonus)).round(),
      'narrow_win' => (base * 0.5).round(),
      _ => 0,
    };
  }
}

final raidRulesProvider = FutureProvider<RaidRules>((ref) async {
  final config = ref.watch(gameConfigReaderProvider);
  return RaidRules(
    fairShareRatio: await config.raidFairShareRatio(),
    narrowThreshold: await config.raidNarrowThreshold(),
    victoryBonus: await config.raidVictoryBonus(),
    escapePenalty: await config.bossEscapePenalty(),
    tiers: await config.bossTiers(),
    maxFights: await config.maxActiveFights(),
    partyMin: await config.partyMin(),
    partyMax: await config.partyMax(),
    guildMax: await config.guildMax(),
  );
});

String raidTierLabel(String tier) => tier.isEmpty ? tier : tier[0].toUpperCase() + tier.substring(1);

String formatCount(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '−' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "due Mon", or "due 19 Oct" when more than a week away.
String raidDueLabel(DateTime deadline, DateTime now) {
  final local = deadline.toLocal();
  if (local.difference(now).inDays < 7 && !local.isBefore(now)) return 'due ${_weekdays[local.weekday - 1]}';
  return 'due ${local.day} ${_months[local.month - 1]}';
}

/// "Mon 19 Oct · 10:00 am".
String raidDeadlineLabel(DateTime deadline) {
  final local = deadline.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_weekdays[local.weekday - 1]} ${local.day} ${_months[local.month - 1]} · $hour:$minute ${local.hour < 12 ? 'am' : 'pm'}';
}

/// "2 min", "1 h", "3 d".
String raidAgo(DateTime at, DateTime now) {
  final diff = now.difference(at.toLocal());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes} min';
  if (diff.inDays < 1) return '${diff.inHours} h';
  return '${diff.inDays} d';
}

/// The lavender arena a raid boss stands in: radial glow, soft rays and a
/// red glow on the floor.
class RaidArena extends StatelessWidget {
  const RaidArena({
    super.key,
    this.center = const Alignment(0, -0.1),
    this.floor = const Alignment(0, 0.68),
    this.floorWidth = 240,
    this.floorColor,
    this.colors,
  });

  final Alignment center;
  final Alignment floor;
  final double floorWidth;
  final Color? floorColor;

  /// Centre, middle and rim of the field. Lavender when null.
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final glow = floorColor ?? AppColors.bossHp;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(center.x, center.y + 0.3),
              radius: 1.05,
              colors: colors ?? const [AppColors.arenaLight, AppColors.arenaMid, AppColors.arenaDeep],
              stops: const [0, 0.4, 1],
            ),
          ),
        ),
        CustomPaint(painter: RaidRaysPainter(center: center)),
        Align(
          alignment: floor,
          child: Container(
            width: floorWidth,
            height: floorWidth / 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.elliptical(floorWidth / 2, floorWidth / 10)),
              gradient: RadialGradient(
                colors: [glow.withValues(alpha: 0.6), glow.withValues(alpha: 0.22), glow.withValues(alpha: 0)],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// White rays fanning out from [center], fading with distance.
class RaidRaysPainter extends CustomPainter {
  const RaidRaysPainter({required this.center, this.alpha = 0.22, this.reach = 350});

  final Alignment center;
  final double alpha;
  final double reach;

  @override
  void paint(Canvas canvas, Size size) {
    final c = center.alongSize(size);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.white.withValues(alpha: alpha),
          AppColors.white.withValues(alpha: 0),
        ],
        stops: const [0.2, 1],
      ).createShader(Rect.fromCircle(center: c, radius: reach));
    const step = 20 * math.pi / 180;
    const width = 7 * math.pi / 180;
    for (var a = 0.0; a < 2 * math.pi; a += step) {
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + reach * math.cos(a), c.dy + reach * math.sin(a))
        ..lineTo(c.dx + reach * math.cos(a + width), c.dy + reach * math.sin(a + width))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(RaidRaysPainter old) => old.center != center || old.alpha != alpha;
}

/// Frosted pill sitting on the arena ("PARTY RAID", "RAID RESULT").
class ArenaPill extends StatelessWidget {
  const ArenaPill({super.key, required this.label, this.color = AppColors.raidInk});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.8), width: 1.5),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 1.5, color: color),
        ),
      ),
    );
  }
}

/// Back button, centred pill and an optional action, laid over the arena.
class ArenaTopBar extends StatelessWidget {
  const ArenaTopBar({
    super.key,
    required this.pill,
    required this.onBack,
    this.backIcon = Icons.arrow_back_rounded,
    this.action,
  });

  final String pill;
  final VoidCallback onBack;
  final IconData backIcon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          ClayIconButton(
            icon: backIcon,
            tooltip: backIcon == Icons.close_rounded ? 'Close' : 'Back',
            kind: ClayKind.onScene,
            onPressed: onBack,
          ),
          Expanded(
            child: Center(child: ArenaPill(label: pill)),
          ),
          action ?? const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Navy tier tag ("TITAN").
class RaidTierTag extends StatelessWidget {
  const RaidTierTag({super.key, required this.tier, this.height = 20});

  final String tier;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: AppColors.raidInk, borderRadius: BorderRadius.circular(height / 2)),
      child: Center(
        widthFactor: 1,
        child: Text(
          tier.toUpperCase(),
          style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1, color: AppColors.white),
        ),
      ),
    );
  }
}

/// Soft navy tag naming the kind of fight ("PARTY RAID", "GUILD BATTLE").
class RaidKindTag extends StatelessWidget {
  const RaidKindTag({super.key, required this.guild});

  final bool guild;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: guild ? AppColors.tealSoft : AppColors.raidSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          guild ? 'GUILD BATTLE' : 'PARTY RAID',
          style: AppText.label.copyWith(
            fontSize: 10,
            height: 12 / 10,
            letterSpacing: 1,
            color: guild ? AppColors.tealDeep : AppColors.raidInk,
          ),
        ),
      ),
    );
  }
}

/// A raider's head in a round teal frame.
class HeroHead extends StatelessWidget {
  const HeroHead({super.key, required this.skinId, required this.bodyType, this.size = 44});

  /// Skin id with or without the `skin_` prefix.
  final String? skinId;
  final String? bodyType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final skin = (skinId ?? 'starter').replaceFirst('skin_', '');
    final body = bodyType == 'b' ? BodyType.b : BodyType.a;
    final crop = GameAssets.portraitCrop(skin, body);
    final imageWidth = size * 3.4;
    final scale = imageWidth / GameAssets.stageCanvas.width;
    final centreX = crop.left + crop.width / 2 - 20;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, 0.4),
          colors: [AppColors.tealWash, Color.lerp(AppColors.tealWash, AppColors.tealLight, 0.45)!],
          stops: const [0, 0.7],
        ),
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.18), offset: const Offset(1, 2), blurRadius: 5)],
      ),
      child: ClipOval(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: imageWidth,
          maxHeight: imageWidth * 1.5,
          child: Transform.translate(
            offset: Offset(size / 2 - 2 - centreX * scale, size * 0.08),
            child: Image.asset(
              GameAssets.skin(skin, body),
              width: imageWidth,
              height: imageWidth * 1.5,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              cacheWidth: decodeWidth(context, imageWidth),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed empty seat for a raider who has not joined yet.
class EmptySeat extends StatelessWidget {
  const EmptySeat({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(),
      child: SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.placeholder),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.placeholder.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Offset.zero & size;
    const dashes = 16;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(1), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}

/// Pink damage chip with a bolt ("⚡ 45").
class DamageChip extends StatelessWidget {
  const DamageChip({super.key, required this.amount, this.height = 24});

  final int amount;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(color: AppColors.bossHpSoft, borderRadius: BorderRadius.circular(height / 2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.bossHpText),
          const SizedBox(width: 2),
          Text(
            formatCount(amount),
            style: AppText.numbers.copyWith(fontSize: 12, height: 16 / 12, color: AppColors.bossHpText),
          ),
        ],
      ),
    );
  }
}

/// One figure in a row of three ("8h / EACH").
class ValueCell extends StatelessWidget {
  const ValueCell({super.key, required this.value, required this.label, this.color = AppColors.ink, this.leading});

  final String value;
  final String label;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 4)],
              Text(
                value,
                style: AppText.h2.copyWith(fontSize: 20, height: 24 / 20, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1)),
        ],
      ),
    );
  }
}

/// Thin vertical divider between [ValueCell]s.
class ValueDivider extends StatelessWidget {
  const ValueDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.hairline);
  }
}

/// Teal primary button docked at the bottom with a fade behind it.
class RaidDock extends StatelessWidget {
  const RaidDock({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DockedAction(bottom: MediaQuery.paddingOf(context).bottom + 28, child: child);
  }
}

/// Space a scroll view leaves under its content for [RaidDock].
double raidDockClearance(BuildContext context) => MediaQuery.paddingOf(context).bottom + 120;
