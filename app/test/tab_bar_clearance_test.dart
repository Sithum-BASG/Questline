import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/floating_tab_bar.dart';
import 'package:questline/features/hero/achievements_screen.dart';
import 'package:questline/features/hero/providers/achievements_providers.dart';
import 'package:questline/router.dart';

GoRoute _blank(String path) => GoRoute(path: path, builder: (context, state) => const SizedBox());

void main() {
  testWidgets('a sub-screen inside the tab shell scrolls its last item clear of the tab bar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/hero/achievements',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [_blank('/home')]),
            StatefulShellBranch(routes: [_blank('/quests')]),
            StatefulShellBranch(routes: [_blank('/bosses')]),
            StatefulShellBranch(routes: [_blank('/social')]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/hero',
                builder: (context, state) => const SizedBox(),
                routes: [GoRoute(path: 'achievements', builder: (context, state) => const AchievementsScreen())],
              ),
            ]),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          badgeTierCoinsProvider.overrideWith((ref) async => const [50, 100, 200]),
          achievementsViewProvider.overrideWith((ref) async => const AchievementsViewData(
                badges: [
                  BadgeProgress(badgeId: 'badge_deep_worker', name: 'Deep Worker', progress: 0, tier: 0),
                  BadgeProgress(badgeId: 'badge_boss_hunter', name: 'Boss Hunter', progress: 0, tier: 0),
                  BadgeProgress(badgeId: 'badge_team_player', name: 'Team Player', progress: 0, tier: 0),
                  BadgeProgress(badgeId: 'badge_unbroken', name: 'Unbroken', progress: 0, tier: 0),
                  BadgeProgress(badgeId: 'badge_balanced', name: 'Balanced', progress: 0, tier: 0),
                  BadgeProgress(badgeId: 'badge_early_bird', name: 'Early Bird', progress: 0, tier: 0),
                  BadgeProgress(badgeId: 'badge_steady_pace', name: 'Steady Pace', progress: 0, tier: 0),
                  BadgeProgress(badgeId: 'badge_punctual', name: 'Punctual', progress: 0, tier: 0),
                ],
                pinnedBadges: [],
                titles: [],
                equippedTitleId: null,
              )),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to the very end of the list.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -5000));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(FloatingTabBar));
    final lastCard = tester.getRect(find.text('Punctual'));
    // The last badge's text and its card bottom (≥ 120 px below the name) stay above the bar.
    expect(lastCard.bottom + 100, lessThanOrEqualTo(bar.top));
  });
}
