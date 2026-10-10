import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'stat_icon.dart';

/// Gear or cosmetic card. Rarity colours the border. States are owned, new, equipped.
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
  });

  final String name;
  final String art;
  final String rarity;
  final bool owned;
  final bool isNew;
  final bool equipped;
  final String? attunedStat;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.rarity(rarity);
    return Container(
      width: 140,
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tint, width: equipped ? 2 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(art, height: 72, fit: BoxFit.contain),
          const SizedBox(height: AppSpacing.s8),
          Text(name, style: AppText.title, textAlign: TextAlign.center),
          if (attunedStat != null) StatIcon(stat: attunedStat!, size: 16),
          if (isNew) Text('New', style: AppText.caption.copyWith(color: tint)),
          if (!owned) Text('Locked', style: AppText.caption),
          if (equipped) Text('Equipped', style: AppText.caption.copyWith(color: AppColors.tealDeep)),
        ],
      ),
    );
  }
}
