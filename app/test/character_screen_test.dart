import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/supabase/auth_providers.dart';
import 'package:questline/core/supabase/supabase_providers.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/onboarding/character_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('character screen shows the starter and sends the chosen name', (tester) async {
    String? sentName;
    String? sentBody;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream<AuthState>.empty()),
          completeOnboardingProvider.overrideWith((ref) {
            return (String step, {Map<String, dynamic>? data}) async {
              sentName = data?['displayName'] as String?;
              sentBody = data?['bodyType'] as String?;
            };
          }),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const CharacterScreen()),
      ),
    );

    expect(find.text('Who is waking up?'), findsOneWidget);
    await tester.tap(find.text('Look B'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(sentName, 'Ada');
    expect(sentBody, 'b');
  });
}
