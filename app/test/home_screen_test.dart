import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/data/models/player_state.dart';
import 'package:questline/data/models/profile.dart';
import 'package:questline/features/home/home_screen.dart';
import 'package:questline/features/home/home_snapshot.dart';
import 'package:questline/features/home/providers/home_providers.dart';

HomeSnapshot _sample({bool offline = false}) {
  final now = DateTime.utc(2026, 10, 20);
  return HomeSnapshot(
    profile: Profile(
      id: 'u1',
      username: 'asha',
      friendCode: 'ABCDEF',
      displayName: 'Asha',
      bodyType: 'a',
      level: 2,
      equippedSkinId: 'skin_starter',
      equippedBackgroundId: 'bg_starter',
      equippedFrameId: 'frame_apprentice',
      pinnedBadges: const [],
      hideRadar: false,
      showBossNames: true,
      createdAt: now,
    ),
    player: PlayerState(
      userId: 'u1',
      coins: 100,
      xpTotal: 80,
      weeklyRawXp: 40,
      weekId: '2026-W42',
      streakCount: 3,
      streakBest: 3,
      shields: 0,
      potions: 0,
      scrolls: 0,
      freeChests: 0,
      activePotion: false,
      comebackArmed: false,
      inactiveDays: 0,
      chestsSinceLegendary: 0,
      bossCoinsThisWeek: 0,
      aiCallsToday: 0,
      focusMinutesToday: 0,
      onboardingStep: 'done',
      onboardingBonus: const {},
      ownedTitles: const [],
      counters: const {},
      milestonesPaid: const [],
      timezone: 'UTC',
      nextRolloverAt: now,
      pauseActive: false,
      pauseDaysUsed: 0,
    ),
    tasks: const [],
    weeklyRank: 1,
    nextRewardLabel: 'Next level reward',
    offline: offline,
  );
}

void main() {
  testWidgets('Home shows greeting, offline pill and boss placeholder', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(path: '/inbox', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/quests/new', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/focus/start', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/bosses/new', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/hero/level-road', builder: (context, state) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeSnapshotProvider.overrideWith((ref) async => _sample(offline: true)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hi, Asha'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Got a deadline coming up?'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Start focus'), 200);
    expect(find.text('Start focus'), findsOneWidget);
    expect(find.text('Add your first quest'), findsOneWidget);
  });
}
