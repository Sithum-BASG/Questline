import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';
import 'package:questline/core/assets/decode_size.dart';

/// Boss encounter card: the boss breaks out of a rose portal on the left,
/// then the eyebrow, name, HP bar, HP numbers and time left.
class BossCard extends StatelessWidget {
  const BossCard({
    super.key,
    required this.name,
    required this.tier,
    required this.hp,
    required this.timeLeft,
    required this.status,
    this.eyebrow,
    this.hpLabel,
    this.onTap,
  });

  final String name;
  final String tier;

  /// Remaining HP as a fraction.
  final double hp;
  final String timeLeft;
  final String status;

  /// Small coloured label above the name (defaults to [status]).
  final String? eyebrow;

  /// e.g. "720 / 1,200 HP". Defaults to the percentage.
  final String? hpLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final clamped = hp.isNaN ? 0.0 : hp.clamp(0.0, 1.0);
    return Semantics(
      label: '$name, ${hpLabel ?? '${(clamped * 100).round()} percent HP'}, $timeLeft',
      button: onTap != null,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Clay(
              radius: AppRadius.stage,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(122, 18, 20, 18),
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(eyebrow ?? status, style: AppText.eyebrow.copyWith(color: AppColors.bossHpText)),
                      const SizedBox(height: 6),
                      Text(name, style: AppText.encounter, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      ClayBar(value: clamped, gradient: hpFillGradient),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(hpLabel ?? '${(clamped * 100).round()}% HP', style: AppText.caption),
                          ),
                          Text(
                            timeLeft,
                            style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.bossHpText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(left: 22, top: 18, child: BossPortal()),
            Positioned(
              left: 4,
              top: -30,
              child: IgnorePointer(child: BossArt(tier: tier)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft rose sunken circle the boss stands in.
class BossPortal extends StatelessWidget {
  const BossPortal({super.key, this.size = 80, this.neutral = false});

  final double size;

  /// Grey well instead of rose (empty state).
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    return Well(
      circle: true,
      width: size,
      height: size,
      color: neutral ? AppColors.well : AppColors.bossHpSoft,
      shade: neutral
          ? wellInnerShade
          : const [
              InnerShadow(Offset(4, 4), 10, Color(0x29A72A4B)),
              InnerShadow(Offset(-4, -4), 10, Color(0xD9FFFFFF)),
            ],
    );
  }
}

/// Boss art with a soft drop shadow. Greyed for empty states.
class BossArt extends StatelessWidget {
  const BossArt({super.key, required this.tier, this.size = 116, this.greyed = false});

  final String tier;
  final double size;
  final bool greyed;

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(
      GameAssets.boss(tier),
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: decodeWidth(context, size),
    );
    if (greyed) {
      img = Opacity(
        opacity: 0.35,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
          child: img,
        ),
      );
    }
    return ExcludeSemantics(child: img);
  }
}

/// Gap between stacked boss cards.
const double bossCardGap = AppSpacing.s16;
