import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/assets/game_assets.dart';
import 'package:questline/core/supabase/auth_providers.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/onboarding/story_screen.dart';

void main() {
  testWidgets('story skip stores the story step', (tester) async {
    String? step;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingLookProvider.overrideWith((ref) async {
            return const OnboardingLook(displayName: 'Ada', body: BodyType.a);
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
            initialLocation: '/onboarding/story',
            routes: [
              GoRoute(path: '/onboarding/story', builder: (context, state) => const StoryScreen()),
              GoRoute(path: '/onboarding/study', builder: (context, state) => const Text('study')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Lectures. Assignments. A planner that never stops filling up. Just another semester.'),
      findsOneWidget,
    );
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(step, 'story');
    expect(find.text('study'), findsOneWidget);
  });

  testWidgets('the last card names the player and begins', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingLookProvider.overrideWith((ref) async {
            return const OnboardingLook(displayName: 'Ada', body: BodyType.b);
          }),
          completeOnboardingProvider.overrideWith((ref) {
            return (String step, {Map<String, dynamic>? data}) async {};
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StoryScreen(initialCard: 6),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ada, your first quest is waiting.'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
}
