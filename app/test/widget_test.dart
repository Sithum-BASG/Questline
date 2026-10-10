import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/app.dart';
import 'package:questline/core/supabase/supabase_config.dart';
import 'package:questline/core/supabase/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('a blank anon key is rejected', () {
    expect(supabaseUrl, 'http://127.0.0.1:54321');
    expect(assertSupabaseConfig, throwsStateError);
  });

  testWidgets('app builds while auth is loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream<AuthState>.empty()),
        ],
        child: const QuestlineApp(),
      ),
    );
    expect(find.text('Home'), findsWidgets);
  });
}
