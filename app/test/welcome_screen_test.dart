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
  int signIns = 0;
  int googleCalls = 0;
  int resets = 0;

  @override
  Future<void> signUp({required String email, required String password}) async {
    signUps += 1;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signIns += 1;
  }

  @override
  Future<void> signInWithGoogle({required String serverClientId}) async {
    googleCalls += 1;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    resets += 1;
  }

  @override
  Future<void> updatePassword(String password) async {}

  @override
  Future<void> signOut() async {}
}

Future<void> _pumpWelcome(WidgetTester tester, AuthApi auth) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
}

void main() {
  testWidgets('welcome asks for a real email and password', (tester) async {
    await _pumpWelcome(tester, _FakeAuth());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Your quests and bosses are waiting.'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign in').last);
    await tester.tap(find.text('Sign in').last);
    await tester.pump();
    expect(find.textContaining('at least 6 characters'), findsWidgets);
  });

  testWidgets('create account calls sign up', (tester) async {
    final auth = _FakeAuth();
    await _pumpWelcome(tester, auth);

    await tester.ensureVisible(find.text('Create an account'));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Begin your quest'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'ada@questline.test');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(auth.signUps, 1);

    await tester.ensureVisible(find.text('Continue with Google'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(auth.googleCalls, 1);
  });
}
