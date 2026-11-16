import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/supabase/auth_providers.dart';
import 'package:questline/core/supabase/auth_redirect.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/quests/add_task_screen.dart';

void main() {
  test('saving the first quest moves on to the first focus session', () {
    expect(
      authRedirect(
        loading: false,
        signedIn: true,
        location: '/onboarding/first-task',
        onboardingStep: 'first_task',
      ),
      '/onboarding/first-session',
    );
    expect(
      authRedirect(
        loading: false,
        signedIn: true,
        location: '/onboarding/first-session',
        onboardingStep: 'first_task',
      ),
      isNull,
    );
  });

  test('the first focus session can run before first_session is stored', () {
    expect(
      authRedirect(
        loading: false,
        signedIn: true,
        location: '/focus/session-1',
        onboardingStep: 'first_task',
      ),
      isNull,
    );
    expect(
      authRedirect(
        loading: false,
        signedIn: true,
        location: '/focus/session-1/complete',
        onboardingStep: 'first_task',
      ),
      isNull,
    );
  });

  test('a skipped onboarding goes home', () {
    expect(
      authRedirect(loading: false, signedIn: true, location: '/home', onboardingStep: 'done'),
      isNull,
    );
  });

  testWidgets('the first quest can be skipped', (tester) async {
    final steps = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          completeOnboardingProvider.overrideWith((ref) {
            return (step, {data}) async => steps.add(step);
          }),
          onboardingStepProvider.overrideWith((ref) async => 'study'),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/onboarding/first-task',
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const Text('home')),
              GoRoute(
                path: '/onboarding/first-task',
                builder: (context, state) => const AddTaskScreen(onboarding: true),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(steps, ['done']);
    expect(find.text('home'), findsOneWidget);
  });
}
