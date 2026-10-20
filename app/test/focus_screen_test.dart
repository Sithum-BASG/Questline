import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/focus/focus_screen.dart';
import 'package:questline/features/focus/presence_session.dart';
import 'package:questline/features/focus/session_alerts.dart';

class _Alerts implements SessionAlerts {
  int shown = 0;
  int ongoing = 0;

  @override
  Future<void> clearOngoing() async {}

  @override
  Future<void> clearReturnPrompt() async {}

  @override
  Future<void> showOngoing(String elapsed) async {
    ongoing += 1;
  }

  @override
  Future<void> showReturnPrompt() async {
    shown += 1;
  }
}

class _Presence implements FocusPresence {
  int began = 0;
  int finished = 0;

  @override
  void begin({required String stat, required DateTime startedAt}) {
    began += 1;
  }

  @override
  void finish(DateTime now) {
    finished += 1;
  }

  @override
  void heartbeat(DateTime now) {}
}

Widget _app({required Widget home, required List overrides}) {
  final router = GoRouter(
    initialLocation: '/focus/session-1',
    routes: [
      GoRoute(path: '/focus/:sessionId', builder: (context, state) => home, routes: [
        GoRoute(path: 'complete', builder: (context, state) => const Scaffold(body: Text('Complete'))),
      ]),
      GoRoute(path: '/quests', builder: (context, state) => const Scaffold(body: Text('Quests'))),
    ],
  );
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

void main() {
  testWidgets('the timer starts from the server time and ending asks first', (tester) async {
    var ended = false;
    await tester.pumpWidget(_app(
      home: FocusScreen(
        sessionId: 'session-1',
        startedAt: DateTime.now().subtract(const Duration(seconds: 65)),
        estimateMinutes: 60,
      ),
      overrides: [
        sessionAlertsProvider.overrideWithValue(_Alerts()),
        focusPresenceProvider.overrideWithValue(_Presence()),
        endSessionProvider.overrideWith((ref) {
            return (sessionId, interruptions, {required bool broken}) async {
              ended = true;
              return {'rawXp': 86, 'finalXp': 86, 'verifiedMinutes': 60, 'level': 2, 'rewards': []};
            };
        }),
      ],
    ));
    expect(find.text('01:05'), findsOneWidget);

    await tester.tap(find.text('End session'));
    await tester.pump();
    expect(find.text('End session?'), findsOneWidget);
    await tester.tap(find.text('End'));
    await tester.pump();
    expect(ended, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving the app asks the player to return', (tester) async {
    final alerts = _Alerts();
    await tester.pumpWidget(_app(
      home: FocusScreen(sessionId: 'session-1', startedAt: DateTime.now(), estimateMinutes: 25),
      overrides: [
        sessionAlertsProvider.overrideWithValue(alerts),
        focusPresenceProvider.overrideWithValue(_Presence()),
        endSessionProvider.overrideWith((ref) {
          return (sessionId, interruptions, {required bool broken}) async => {};
        }),
      ],
    ));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(alerts.shown, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an activity session stays alive in the background', (tester) async {
    final alerts = _Alerts();
    await tester.pumpWidget(_app(
      home: FocusScreen(
        sessionId: 'session-1',
        startedAt: DateTime.now(),
        estimateMinutes: 40,
        mode: 'activity',
      ),
      overrides: [
        sessionAlertsProvider.overrideWithValue(alerts),
        focusPresenceProvider.overrideWithValue(_Presence()),
        endSessionProvider.overrideWith((ref) {
          return (sessionId, interruptions, {required bool broken}) async => {};
        }),
      ],
    ));
    expect(find.text('Activity'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(alerts.shown, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
