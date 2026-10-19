import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
    await tester.pump();
    expect(queue.pending, [
      {'type': 'item', 'id': 'frame_margin_notes'},
    ]);
  });
}
