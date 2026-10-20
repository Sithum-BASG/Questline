import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'badge_medallion.dart';
import 'boss_card.dart';
import 'empty_state.dart';
import 'item_card.dart';
import 'judgement_card.dart';
import 'leaderboard_row.dart';
import 'member_card.dart';
import 'portrait_frame.dart';
import 'progress_bar.dart';
import 'q_bottom_sheet.dart';
import 'q_button.dart';
import 'q_card.dart';
import 'q_chip.dart';
import 'stage_card.dart';
import 'stat_icon.dart';
import 'stat_tile.dart';
import 'task_tile.dart';
import 'timer_display.dart';

/// Debug-only catalogue of the shared widgets.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery', style: AppText.h2)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, AppSpacing.aboveTabBar),
        children: [
          const _Label('Buttons'),
          QButton(label: 'Start focus', onPressed: () {}),
          const SizedBox(height: AppSpacing.s8),
          const QButton(label: 'Save', variant: QButtonVariant.secondary, onPressed: null),
          const _Label('Card and chips'),
          const QCard(child: Text('A quiet card', style: AppText.body)),
          const SizedBox(height: AppSpacing.s8),
          const Wrap(
            spacing: AppSpacing.s8,
            children: [
              QChip(label: 'Intellect', kind: QChipKind.stat),
              QChip(label: 'Today', selected: true),
              QChip(label: 'Rare', kind: QChipKind.rarity),
            ],
          ),
          const _Label('Stats'),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatIcon(stat: 'intellect', size: 16),
              StatIcon(stat: 'vitality', size: 20),
              StatIcon(stat: 'craft', size: 24),
              StatTile(stat: 'charisma', value: '3', label: 'Rank'),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          const ProgressBar(value: 0.6, leading: 'XP', trailing: '86'),
          const _Label('Stage'),
          const StageCard(skinId: 'starter', backgroundId: 'starter', body: BodyType.a),
          const SizedBox(height: AppSpacing.s12),
          const PortraitFrame(
            skinId: 'starter',
            backgroundId: 'starter',
            frameId: 'apprentice',
            body: BodyType.a,
          ),
          const _Label('Tasks and bosses'),
          const TaskTile(title: 'Read chapter 3', stat: 'intellect', dueLabel: 'Today'),
          const SizedBox(height: AppSpacing.s8),
          const BossCard(name: 'The Deadline Shade', tier: 'minion', hp: 0.4, timeLeft: '2 days', status: 'Active'),
          const _Label('Loot'),
          ItemCard(
            name: 'Apprentice wand',
            art: GameAssets.gear('weapon_apprentice_wand'),
            rarity: 'common',
            owned: true,
          ),
          const BadgeMedallion(id: 'deep_worker', tier: 1, caption: 'Deep worker'),
          const _Label('Judgement'),
          const JudgementCard(
            stat: 'intellect',
            difficulty: 4,
            minutes: 90,
            xpPreview: 86,
            reason: 'A long writing task.',
          ),
          const _Label('People'),
          const LeaderboardRow(
            rank: 1,
            name: 'Asha',
            title: 'Adept',
            xp: 500,
            skinId: 'starter',
            backgroundId: 'starter',
            body: BodyType.a,
            isYou: true,
          ),
          const MemberCard(
            name: 'Nimal',
            title: 'Freshly awakened',
            skinId: 'starter',
            backgroundId: 'starter',
            body: BodyType.b,
            focusing: true,
          ),
          const _Label('Empty, sheet, timer'),
          const EmptyState(title: 'No quests yet', body: 'Add one real task to get a judgement.'),
          const SizedBox(height: AppSpacing.s8),
          QButton(
            label: 'Open sheet',
            variant: QButtonVariant.secondary,
            onPressed: () {
              QBottomSheet.show(
                context: context,
                title: 'Add task',
                actionLabel: 'Judge',
                onAction: () => Navigator.of(context).pop(),
                child: const Text('What do you need to do?', style: AppText.body),
              );
            },
          ),
          const SizedBox(height: AppSpacing.s16),
          const Center(child: TimerDisplay(elapsedSeconds: 125, estimateSeconds: 300)),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s24, bottom: AppSpacing.s8),
      child: Text(text, style: AppText.h2),
    );
  }
}
