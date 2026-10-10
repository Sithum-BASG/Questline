import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'progress_bar.dart';
import 'q_card.dart';
import 'q_chip.dart';

/// Boss summary: tier art, name, HP, time left and a status pill.
class BossCard extends StatelessWidget {
  const BossCard({
    super.key,
    required this.name,
    required this.tier,
    required this.hp,
    required this.timeLeft,
    required this.status,
  });

  final String name;
  final String tier;
  final double hp;
  final String timeLeft;
  final String status;

  @override
  Widget build(BuildContext context) {
    return QCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Image.asset(GameAssets.boss(tier), width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.h2),
                const SizedBox(height: AppSpacing.s8),
                ProgressBar(value: hp, kind: ProgressKind.bossHp, leading: 'HP', trailing: timeLeft),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          QChip(label: status, kind: QChipKind.filter),
        ],
      ),
    );
  }
}
