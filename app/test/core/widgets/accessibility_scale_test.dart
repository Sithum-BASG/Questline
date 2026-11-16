import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/assets/game_assets.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/judgement_card.dart';
import 'package:questline/core/widgets/leaderboard_row.dart';
import 'package:questline/core/widgets/member_card.dart';
import 'package:questline/core/widgets/progress_bar.dart';
import 'package:questline/core/widgets/stat_icon.dart';
import 'package:questline/core/widgets/task_tile.dart';

void main() {
  testWidgets('KEY rows wrap at 130% font scale', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  TaskTile(
                    title: 'Read chapter three of the algorithms textbook carefully',
                    dueLabel: 'Due today after lunch',
                    stat: 'intellect',
                    provisional: true,
                  ),
                  SizedBox(height: 8),
                  LeaderboardRow(
                    rank: 1,
                    name: 'Asha with a longer display name',
                    title: 'Adept of the Archive',
                    xp: 1250,
                    skinId: 'starter',
                    backgroundId: 'starter',
                    frameId: 'apprentice',
                    body: BodyType.a,
                    isYou: true,
                  ),
                  SizedBox(height: 8),
                  MemberCard(
                    name: 'Nimal',
                    title: 'Freshly awakened',
                    skinId: 'starter',
                    backgroundId: 'starter',
                    frameId: 'apprentice',
                    body: BodyType.b,
                    focusing: true,
                    pulledWeight: true,
                  ),
                  SizedBox(height: 8),
                  JudgementCard(
                    stat: 'intellect',
                    difficulty: 4,
                    minutes: 90,
                    xpPreview: 86,
                    reason: 'A long writing task that needs room to wrap at larger text sizes.',
                    provisional: true,
                  ),
                  SizedBox(height: 8),
                  ProgressBar(value: 0.42, leading: 'HP', trailing: '420 / 1000 HP'),
                  SizedBox(height: 8),
                  StatIcon(stat: 'vitality'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TaskTile), findsOneWidget);
    expect(find.bySemanticsLabel('Vitality'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('focusing now')), findsOneWidget);
  });
}
