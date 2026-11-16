import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/data/models/raid.dart';
import 'package:questline/features/bosses/bosses_screen.dart';
import 'package:questline/features/bosses/providers/boss_providers.dart';

Raid _raid(String id, String name, String source, String status, int daysFromNow) => Raid(
      id: id,
      source: source,
      guildId: source == 'guild' ? 'g1' : null,
      name: name,
      title: name,
      type: 'exam',
      tier: 'brute',
      perPersonMinutes: 60,
      participants: 3,
      maxHp: 180,
      damage: 60,
      deadline: DateTime.now().add(Duration(days: daysFromNow)),
      status: status,
      coinsEligible: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );

void main() {
  testWidgets('the Bosses tab lists party raids and guild battles', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var opened = '';
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const BossesScreen()),
      GoRoute(path: '/raids/:id', builder: (context, state) {
        opened = state.pathParameters['id']!;
        return const SizedBox();
      }),
      GoRoute(path: '/raids/:id/results', builder: (context, state) {
        opened = 'results:${state.pathParameters['id']}';
        return const SizedBox();
      }),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        bossesProvider.overrideWith((ref) async => const []),
        activeFightCountProvider.overrideWith((ref) async => 2),
        maxActiveFightsProvider.overrideWith((ref) async => 15),
        myRaidsProvider.overrideWith((ref) async => [
              RaidSummary(raid: _raid('r1', 'Group Project Golem', 'party', 'active', 3), members: const ['Amaya', 'Tharindu']),
              RaidSummary(raid: _raid('r2', 'Viva Basilisk', 'guild', 'active', 9), members: const ['Dinithi', 'Amaya']),
              RaidSummary(raid: _raid('r3', 'Midterm Wyvern', 'guild', 'victory', -8), members: const ['Amaya']),
            ]),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Group Project Golem'), findsOneWidget);
    expect(find.text('PARTY RAID'), findsOneWidget);
    expect(find.text('Viva Basilisk'), findsOneWidget);
    expect(find.text('GUILD BATTLE'), findsNWidgets(2));
    expect(find.text('Midterm Wyvern'), findsOneWidget);
    expect(find.text('Victory'), findsOneWidget);
    // With raids, the empty-arena prompt does not show.
    expect(find.textContaining('No bosses'), findsNothing);

    await tester.tap(find.text('Viva Basilisk'));
    await tester.pumpAndSettle();
    expect(opened, 'r2');
  });
}
