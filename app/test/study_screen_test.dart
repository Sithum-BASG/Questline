import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/supabase/auth_providers.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/onboarding/study_screen.dart';

void main() {
  testWidgets('study saves context and advances', (tester) async {
    String? saved;
    String? step;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveStudyContextProvider.overrideWith((ref) {
            return (value) async {
              saved = value;
            };
          }),
          completeOnboardingProvider.overrideWith((ref) {
            return (String sent, {Map<String, dynamic>? data}) async {
              step = sent;
            };
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/onboarding/study',
            routes: [
              GoRoute(path: '/onboarding/study', builder: (context, state) => const StudyScreen()),
              GoRoute(path: '/onboarding/first-task', builder: (context, state) => const Text('first task')),
            ],
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Task text and your optional study context are sent to our AI provider (Groq) to rate the task. Nothing else is shared.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'BSc IT, 3rd year');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(saved, 'BSc IT, 3rd year');
    expect(step, 'study');
    expect(find.text('first task'), findsOneWidget);
  });

  testWidgets('study skip leaves the context unset', (tester) async {
    var saved = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveStudyContextProvider.overrideWith((ref) {
            return (value) async {
              saved = true;
            };
          }),
          completeOnboardingProvider.overrideWith((ref) {
            return (String step, {Map<String, dynamic>? data}) async {};
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/onboarding/study',
            routes: [
              GoRoute(path: '/onboarding/study', builder: (context, state) => const StudyScreen()),
              GoRoute(path: '/onboarding/first-task', builder: (context, state) => const SizedBox()),
            ],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'ignored');
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(saved, isFalse);
  });
}
