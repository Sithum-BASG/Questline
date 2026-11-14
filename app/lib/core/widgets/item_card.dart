import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';
import 'stat_icon.dart';

/// Gear or cosmetic card: a clay tile with the item in a rarity-tinted well,
/// its name and rarity word. Equipped gets a teal ring and check; locked is
/// greyed.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.name,
    required this.art,
    required this.rarity,
    this.owned = false,
    this.isNew = false,
    this.equipped = false,
    this.attunedStat,
    this.width = 140,
  });

  final String name;
  final String art;
  final String rarity;
  final bool owned;
  final bool isNew;
  final bool equipped;
  final String? attunedStat;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.rarity(rarity);
    final rarityLabel = rarity.isEmpty ? rarity : rarity[0].toUpperCase() + rarity.substring(1);
    Widget image = Image.asset(art, height: 64, fit: BoxFit.contain);
    if (!owned) {
      image = Opacity(
        opacity: 0.4,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
          child: image,
        ),
      );
    }
    return Semantics(
      label: [
        name,
        rarityLabel,
        if (isNew) 'New',
        if (!owned) 'Locked',
        if (equipped) 'Equipped',
      ].join(', '),
      child: SizedBox(
        width: width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Clay(
              radius: AppRadius.card,
              padding: const EdgeInsets.all(10),
              border: equipped ? Border.all(color: AppColors.tealDeep, width: 2.5) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: RadialGradient(colors: [AppColors.white, AppColors.raritySoft(rarity)], radius: 0.9),
                      border: Border.all(color: tint.withValues(alpha: owned ? 0.55 : 0.25), width: 1.5),
                    ),
                    child: Center(child: image),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    name,
                    style: AppText.title.copyWith(fontSize: 13, height: 17 / 13),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        owned ? rarityLabel : 'Locked',
                        style: AppText.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: owned ? AppColors.rarityText(rarity) : AppColors.inkMuted,
                        ),
                      ),
                      if (attunedStat != null) ...[const SizedBox(width: 4), StatIcon(stat: attunedStat!, size: 14)],
                    ],
                  ),
                ],
              ),
            ),
            if (isNew)
              Positioned(
                top: -6,
                left: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: clayTealGradient,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Text(
                    'New',
                    style: AppText.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 10),
                  ),
                ),
              ),
            if (equipped)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.tealDeep,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                  ),
                  child: const Icon(Icons.check_rounded, size: 13, color: AppColors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
