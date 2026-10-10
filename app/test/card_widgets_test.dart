import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/assets/game_assets.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/badge_medallion.dart';
import 'package:questline/core/widgets/boss_card.dart';
import 'package:questline/core/widgets/item_card.dart';
import 'package:questline/core/widgets/task_tile.dart';

void main() {
  testWidgets('task tile marks a late due in the row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: TaskTile(title: 'Read chapter 3', stat: 'intellect', dueLabel: '2 days late', late: true),
        ),
      ),
    );
    expect(find.text('Read chapter 3'), findsOneWidget);
    expect(find.text('2 days late'), findsOneWidget);
  });

  testWidgets('boss, item and badge cards show their names', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            children: [
              const BossCard(name: 'The Deadline Shade', tier: 'minion', hp: 0.5, timeLeft: '2 days', status: 'Active'),
              ItemCard(name: 'Apprentice wand', art: GameAssets.gear('weapon_apprentice_wand'), rarity: 'common', owned: true),
              const BadgeMedallion(id: 'deep_worker', tier: 1, caption: 'Deep worker'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('The Deadline Shade'), findsOneWidget);
    expect(find.text('Apprentice wand'), findsOneWidget);
    expect(find.text('Deep worker'), findsOneWidget);
  });
}
