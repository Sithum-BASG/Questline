import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/reward_overlay.dart';

/// Reveal for one openChest result, then pops back to the chest list.
class ChestOpenScreen extends StatelessWidget {
  const ChestOpenScreen({super.key, required this.result});

  final Map<String, dynamic> result;

  static RewardMoment momentFromResult(Map<String, dynamic> result) {
    final rarity = (result['rarity'] as String?) ?? 'common';
    final drop = result['drop'];
    final refund = result['refund'];
    var title = 'Chest opened';
    var subtitle = rarity[0].toUpperCase() + rarity.substring(1);
    if (drop is Map) {
      final kind = drop['kind'] as String? ?? 'item';
      if (kind == 'pouch') {
        title = '+${drop['coins'] ?? 0} coins';
        subtitle = 'Coin pouch · $subtitle';
      } else if (kind == 'consumable') {
        title = (drop['id'] as String?)?.replaceAll('_', ' ') ?? 'Consumable';
        subtitle = 'Consumable · $subtitle';
      } else if (kind == 'set') {
        title = 'Mythic set';
        subtitle = 'Skin, background and frame';
      } else {
        title = (drop['id'] as String?)?.replaceAll('_', ' ') ?? 'New item';
        subtitle = 'Loot · $subtitle';
      }
    }
    if (refund is num && refund > 0) {
      subtitle = 'Duplicate · +$refund coins';
    }
    return RewardMoment.loot(title: title, subtitle: subtitle, rarity: rarity);
  }

  @override
  Widget build(BuildContext context) {
    return RewardOverlay(
      moment: momentFromResult(result),
      onClaim: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/chests');
        }
      },
    );
  }
}
