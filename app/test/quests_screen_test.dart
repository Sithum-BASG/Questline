import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/data/models/task.dart';
import 'package:questline/features/quests/add_task_screen.dart';
import 'package:questline/features/quests/providers/task_providers.dart';
import 'package:questline/features/quests/quests_screen.dart';

Task _task(String title, {String? stat}) {
  return Task(
    id: title,
    userId: 'user',
    title: title,
    status: 'open',
    rescheduled: false,
    scrollUsed: false,
    createdAt: DateTime.utc(2026, 10, 1),
    stat: stat,
    provisional: false,
    challenged: false,
  );
}

void main() {
  testWidgets('the stat filter hides other quests', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksProvider.overrideWith((ref) async => [
                _task('Read notes', stat: 'intellect'),
                _task('Leg day', stat: 'vitality'),
              ]),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const QuestsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Read notes'), findsOneWidget);
    await tester.tap(find.text('Vitality'));
    await tester.pumpAndSettle();
    expect(find.text('Leg day'), findsOneWidget);
    expect(find.text('Read notes'), findsNothing);
  });

  testWidgets('judge inserts a draft and leaves the sheet', (tester) async {
    String? saved;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insertDraftProvider.overrideWith((ref) {
            return ({required String title, String? notes, DateTime? dueAt, String? bossId}) async {
              saved = title;
            };
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/quests/new',
            routes: [
              GoRoute(path: '/quests', builder: (context, state) => const Text('list')),
              GoRoute(path: '/quests/new', builder: (context, state) => const AddTaskScreen()),
            ],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Revise chapter 3');
    await tester.tap(find.text('Judge'));
    await tester.pumpAndSettle();
    expect(saved, 'Revise chapter 3');
    expect(find.text('list'), findsOneWidget);
  });
}
