import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/supabase/api_client.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/bosses/create_boss_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeApi extends ApiClient {
  _FakeApi() : super(SupabaseClient('http://localhost', 'anon', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  String? summonedName;
  double? summonedHours;

  @override
  Future<Map<String, dynamic>> createBossPreview({
    required String title,
    String? description,
    required String type,
    required DateTime deadline,
  }) async =>
      {
        'preview': {'name': 'The Packet Kraken', 'hours': 10},
      };

  @override
  Future<Map<String, dynamic>> createBoss({
    required String title,
    String? description,
    required String type,
    required DateTime deadline,
    required double hours,
    required String name,
    String? taskId,
  }) async {
    summonedName = name;
    summonedHours = hours;
    return {
      'boss': {'id': 'boss-1'},
    };
  }
}

void main() {
  testWidgets('estimating names the boss, and summon sends the chosen hours', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _FakeApi();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (c, s) => const CreateBossScreen()),
      GoRoute(path: '/bosses/:id', builder: (c, s) => Text('boss ${s.pathParameters['id']}')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pump();

    expect(find.text('Summon a boss'), findsOneWidget);
    expect(find.text('AWAITING A NAME'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Networks lab report');
    await tester.tap(find.text('Pick a date and time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Estimate the boss'));
    await tester.pumpAndSettle();
    expect(find.text('The Packet Kraken'), findsOneWidget);
    expect(find.text('NEW BOSS'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);

    await tester.tap(find.text('Summon the boss'));
    await tester.pumpAndSettle();
    expect(api.summonedName, 'The Packet Kraken');
    expect(api.summonedHours, 10);
    expect(find.text('boss boss-1'), findsOneWidget);
  });
}
