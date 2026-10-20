import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/supabase/auth_providers.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/focus/session_complete_screen.dart';

void main() {
  testWidgets('the summary shows 86 XP and queues the rewards', (tester) async {
    final queue = RewardQueue();
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SessionCompleteScreen(summary: {
          'rawXp': 86,
          'finalXp': 86,
          'verifiedMinutes': 60,
          'level': 2,
          'rewards': [
            {'type': 'item', 'id': 'frame_margin_notes'},
          ],
        }),
      ),
      GoRoute(path: '/quests', builder: (context, state) => const Scaffold(body: Text('Quests'))),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [rewardQueueProvider.overrideWithValue(queue)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    expect(find.text('86 XP'), findsOneWidget);
    expect(find.text('frame_margin_notes'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(queue.pending, [
      {'type': 'item', 'id': 'frame_margin_notes'},
    ]);
  });

  testWidgets('the first session claims starter XP for level 2', (tester) async {
    String? completed;
    final queue = RewardQueue();
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SessionCompleteScreen(summary: {
          'rawXp': 10,
          'finalXp': 10,
          'verifiedMinutes': 5,
          'level': 1,
          'onboarding': true,
          'rewards': <Map<String, dynamic>>[],
        }),
      ),
      GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('Home'))),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardQueueProvider.overrideWithValue(queue),
          completeOnboardingProvider.overrideWith((ref) {
            return (step, {data}) async {
              completed = step;
            };
          }),
          onboardingStepProvider.overrideWith((ref) async => 'first_session'),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    expect(find.text('Starter XP unlocks level 2 and a free chest.'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(completed, 'first_session');
    expect(find.text('Home'), findsOneWidget);
  });
}
