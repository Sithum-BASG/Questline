import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/stat_radar.dart';
import 'package:questline/data/models/profile.dart';
import 'package:questline/features/hero/profile_screen.dart';
import 'package:questline/features/hero/providers/profile_providers.dart';

void main() {
  testWidgets('profile shows stage title and radar', (tester) async {
    final now = DateTime.utc(2026, 10, 20);
    final data = ProfileViewData(
      profile: Profile(
        id: 'u1',
        username: 'asha',
        friendCode: 'ABCDEF',
        displayName: 'Asha',
        bodyType: 'a',
        level: 3,
        titleId: 'title_freshly_awakened',
        equippedSkinId: 'skin_starter',
        equippedBackgroundId: 'bg_starter',
        equippedFrameId: 'frame_apprentice',
        pinnedBadges: const ['badge_deep_worker'],
        hideRadar: false,
        showBossNames: true,
        createdAt: now,
      ),
      titleName: 'Freshly Awakened',
      radar30: const StatRadarValues(intellect: 40, vitality: 10, craft: 20, charisma: 5),
      radar7: const StatRadarValues(intellect: 8, vitality: 2, craft: 4, charisma: 1),
      badgeTiers: const {'badge_deep_worker': 1},
    );

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const ProfileScreen()),
        GoRoute(path: '/hero/gear', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/hero/wardrobe', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/hero/inventory', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/chests', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/hero/level-road', builder: (context, state) => const SizedBox()),
        GoRoute(path: '/hero/achievements', builder: (context, state) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileViewProvider.overrideWith((ref) async => data),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Freshly Awakened'), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
  });
}
