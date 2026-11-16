import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/reward_overlay.dart';
import 'package:questline/features/recap/providers/recap_providers.dart';
import 'package:questline/features/recap/recap_copy.dart';
import 'package:questline/features/recap/recap_screen.dart';

const _payload = WeeklyResultsPayload(
  weekId: '2026-W46',
  rawXp: 860,
  targetHit: true,
  targetCoins: 200,
  activeFriends: 7,
  rank: 3,
  rankCoins: 150,
  specialItem: null,
  guildQuestCoins: 0,
  intellect: 410,
  vitality: 100,
  craft: 260,
  charisma: 90,
  bestDay: '2026-11-11',
  bestDayXp: 210,
  bossesBeaten: 2,
);

void main() {
  testWidgets('the recap walks five cards and claims the weekly coins', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final queue = RewardQueue();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const RecapScreen(weekId: '2026-W46')),
      GoRoute(path: '/reward', builder: (c, s) => const Scaffold(body: Text('Reward'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        recapProvider.overrideWith((ref, id) async => _payload),
        recapExtrasProvider.overrideWith((ref, id) async => RecapExtras(
              monday: DateTime(2026, 11, 9),
              dailyXp: const [92, 72, 210, 107, 61, 99, 65],
              daysMet: 7,
              streak: 12,
              board: const [('Tharaka', 1420, false), ('You', 860, true)],
              targetXp: 500,
              dailyMinimum: 40,
              balancedShare: 0.15,
            )),
        rewardQueueProvider.overrideWith((ref) => queue),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('You beat your weekly target'), findsOneWidget);
    expect(find.text('YOUR WEEK · 9–15 NOV'), findsOneWidget);
    for (final title in ['Mostly Intellect', 'Seven days out of seven', '2 bosses fell']) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your week paid off'), findsOneWidget);
    expect(find.text('#3'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Claim 350 coins'));
    await tester.pumpAndSettle();
    expect(find.text('Reward'), findsOneWidget);
    expect(queue.current?.coins, 350);
    expect(queue.current?.title, '+350 coins');
  });
}
