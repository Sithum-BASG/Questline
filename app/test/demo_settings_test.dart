import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/supabase/api_client.dart';
import 'package:questline/core/supabase/supabase_providers.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/auth/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _client() =>
    SupabaseClient('http://localhost', 'anon', authOptions: const AuthClientOptions(autoRefreshToken: false));

class _FakeApi extends ApiClient {
  _FakeApi({required this.allowed}) : super(_client());

  final bool allowed;
  bool enabled = false;
  final List<bool> requests = [];

  @override
  Future<({bool allowed, bool enabled})> demoStatus() async => (allowed: allowed, enabled: enabled);

  @override
  Future<bool> setDemoMode(bool value) async {
    requests.add(value);
    enabled = value;
    return value;
  }
}

Future<void> _pump(WidgetTester tester, _FakeApi api) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      supabaseClientProvider.overrideWithValue(_client()),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('an allow-listed account can switch demo mode on', (tester) async {
    final api = _FakeApi(allowed: true);
    await _pump(tester, api);
    final toggle = find.byKey(const Key('demo-mode-switch'));
    await tester.scrollUntilVisible(toggle, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump();
    expect(api.requests, [true]);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('other accounts do not see demo mode', (tester) async {
    await _pump(tester, _FakeApi(allowed: false));
    expect(find.byKey(const Key('demo-mode-switch')), findsNothing);
    expect(find.text('Demo mode'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
