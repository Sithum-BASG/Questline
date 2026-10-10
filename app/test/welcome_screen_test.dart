import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/supabase/auth_providers.dart';
import 'package:questline/core/supabase/auth_repository.dart';
import 'package:questline/core/supabase/supabase_providers.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/auth/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuth implements AuthApi {
  int signUps = 0;
  int googleCalls = 0;

  @override
  Future<void> signUp({required String email, required String password}) async {
    signUps += 1;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signInWithGoogle({required String serverClientId}) async {
    googleCalls += 1;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('welcome asks for a real email and password', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuth()),
          authStateProvider.overrideWith((ref) => const Stream<AuthState>.empty()),
          completeOnboardingProvider.overrideWith((ref) {
            return (String step, {Map<String, dynamic>? data}) async {};
          }),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const WelcomeScreen()),
      ),
    );

    expect(
      find.text('Your deadlines were always monsters. Now you can fight back.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Use an email and a password of at least 6 characters.'), findsOneWidget);
  });

  testWidgets('create account calls sign up', (tester) async {
    final auth = _FakeAuth();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          authStateProvider.overrideWith((ref) => const Stream<AuthState>.empty()),
          completeOnboardingProvider.overrideWith((ref) {
            return (String step, {Map<String, dynamic>? data}) async {};
          }),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const WelcomeScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'ada@questline.test');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(auth.signUps, 1);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(auth.googleCalls, 1);
  });
}
