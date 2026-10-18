import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/supabase/auth_providers.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/data/models/task.dart';
import 'package:questline/features/quests/challenge_screen.dart';
import 'package:questline/features/quests/providers/task_providers.dart';
import 'package:questline/features/quests/task_screen.dart';

Task _draft() {
  return Task(
    id: 'task-1',
    userId: 'user',
    title: 'Write the introduction',
    status: 'draft',
    rescheduled: false,
    scrollUsed: false,
    createdAt: DateTime.utc(2026, 10, 1),
    provisional: false,
    challenged: false,
  );
}

void main() {
  testWidgets('save opens the judged draft and discard deletes it', (tester) async {
    String? saved;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskProvider.overrideWith((ref, id) async => _draft()),
          judgeTaskProvider.overrideWith((ref) {
            return (taskId) async => {
                  'stat': 'intellect',
                  'difficulty': 4,
                  'estimatedMinutes': 90,
                  'xpPreview': 129,
                  'reason': 'Careful writing.',
                  'provisional': false,
                  'challenged': false,
                  'tooBig': false,
                };
          }),
          saveTaskProvider.overrideWith((ref) {
            return (taskId) async {
              saved = taskId;
            };
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/quests/task-1',
            routes: [
              GoRoute(path: '/quests', builder: (context, state) => const Text('list')),
              GoRoute(path: '/quests/:taskId', builder: (context, state) => TaskScreen(taskId: state.pathParameters['taskId']!)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Careful writing.'), findsOneWidget);
    expect(find.text('129 XP'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, 'task-1');
    expect(find.text('list'), findsOneWidget);
  });

  testWidgets('the first quest save stores the onboarding step', (tester) async {
    String? step;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskProvider.overrideWith((ref, id) async => _draft()),
          judgeTaskProvider.overrideWith((ref) {
            return (taskId) async => {
                  'stat': 'intellect',
                  'difficulty': 4,
                  'estimatedMinutes': 90,
                  'xpPreview': 129,
                  'reason': 'Careful writing.',
                  'provisional': false,
                  'challenged': false,
                  'tooBig': false,
                };
          }),
          saveTaskProvider.overrideWith((ref) => (taskId) async {}),
          completeOnboardingProvider.overrideWith((ref) {
            return (sent, {data}) async {
              step = sent;
            };
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/onboarding/first-task',
            routes: [
              GoRoute(path: '/quests', builder: (context, state) => const Text('list')),
              GoRoute(
                path: '/onboarding/first-task',
                builder: (context, state) => const TaskScreen(taskId: 'task-1', onboarding: true),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Disagree?'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(step, 'first_task');
  });

  testWidgets('discard deletes the draft', (tester) async {
    String? discarded;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskProvider.overrideWith((ref, id) async => _draft()),
          judgeTaskProvider.overrideWith((ref) {
            return (taskId) async => {
                  'stat': 'intellect',
                  'difficulty': 4,
                  'estimatedMinutes': 90,
                  'xpPreview': 129,
                  'reason': 'Careful writing.',
                  'provisional': false,
                  'challenged': false,
                  'tooBig': false,
                };
          }),
          discardTaskProvider.overrideWith((ref) {
            return (taskId) async {
              discarded = taskId;
            };
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/quests/task-1',
            routes: [
              GoRoute(path: '/quests', builder: (context, state) => const Text('list')),
              GoRoute(path: '/quests/:taskId', builder: (context, state) => TaskScreen(taskId: state.pathParameters['taskId']!)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(discarded, 'task-1');
  });

  testWidgets('the challenge sheet sends the sentence', (tester) async {
    String? sent;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          challengeActionProvider.overrideWith((ref) {
            return (taskId, context) async {
              sent = context;
              return {};
            };
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/quests/task-1/challenge',
            routes: [
              GoRoute(path: '/quests/:taskId', builder: (context, state) => const Text('task')),
              GoRoute(
                path: '/quests/:taskId/challenge',
                builder: (context, state) => ChallengeScreen(taskId: state.pathParameters['taskId']!),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'It is only a paragraph.');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(sent, 'It is only a paragraph.');
  });
}
