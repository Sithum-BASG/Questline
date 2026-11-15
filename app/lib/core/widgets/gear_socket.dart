import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/shadows.dart';
import 'clay.dart';
import 'stat_icon.dart';

/// Round gear socket: rarity metal ring, recessed face, item art, and an
/// optional attunement badge in the top-right.
class GearSocket extends StatelessWidget {
  const GearSocket({super.key, required this.rarity, this.art, this.stat, this.size = 70});

  final String rarity;
  final String? art;
  final String? stat;
  final double size;

  @override
  Widget build(BuildContext context) {
    final metal = AppColors.rarity(rarity);
    final soft = AppColors.raritySoft(rarity);
    final image = art;
    final face = size - 8;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [soft, metal, soft, metal, soft]),
              boxShadow: AppShadows.dot,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(center: const Alignment(0, -0.24), colors: [AppColors.white, soft]),
              ),
              alignment: Alignment.center,
              child: image == null
                  ? Icon(Icons.add_rounded, size: face * 0.4, color: AppColors.inkFaint)
                  : ClipOval(child: Image.asset(image, width: face * 0.78, height: face * 0.78, fit: BoxFit.contain)),
            ),
          ),
          if (stat != null)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: StatDot(stat: stat!, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small rarity tag: COMMON, RARE, EPIC...
class RarityTag extends StatelessWidget {
  const RarityTag({super.key, required this.rarity, this.label});

  final String rarity;

  /// Overrides the rarity name, e.g. "TIER III · MAX".
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.raritySoft(rarity),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      alignment: Alignment.center,
      child: Text(
        label ?? rarity.toUpperCase(),
        style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, color: AppColors.rarityText(rarity)),
      ),
    );
  }
}

/// Coin balance pill for headers.
class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$coins coins',
      excludeSemantics: true,
      child: Clay(
        kind: ClayKind.control,
        radius: 20,
        height: 40,
        padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(GameAssets.icon('coin'), width: 28, height: 28),
            const SizedBox(width: 6),
            Text(formatThousands(coins), style: AppText.title.copyWith(fontSize: 15, height: 20 / 15)),
          ],
        ),
      ),
    );
  }
}

/// 2350 -> "2,350".
String formatThousands(int n) {
  final negative = n < 0;
  final digits = n.abs().toString();
  final out = StringBuffer(negative ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
