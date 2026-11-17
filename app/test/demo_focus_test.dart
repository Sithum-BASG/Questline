import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/config/game_config_reader.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/focus/focus_screen.dart';
import 'package:questline/features/focus/focus_session_info.dart';
import 'package:questline/features/focus/presence_session.dart';
import 'package:questline/features/focus/session_alerts.dart';

class _Alerts implements SessionAlerts {
  @override
  Future<void> clearOngoing() async {}

  @override
  Future<void> clearReturnPrompt() async {}

  @override
  Future<void> showOngoing(String elapsed, {String? sessionId}) async {}

  @override
  Future<void> showReturnPrompt({String? sessionId}) async {}
}

class _Presence implements FocusPresence {
  @override
  void begin({required String stat, required DateTime startedAt}) {}

  @override
  void finish(DateTime now) {}

  @override
  void heartbeat(DateTime now) {}
}

FocusTaskInfo _info({required bool demo}) => FocusTaskInfo(
  taskId: 'task-1',
  title: 'Read chapter 4',
  stat: 'intellect',
  difficulty: 3,
  estMinutes: 25,
  dueAt: null,
  rescheduled: false,
  scrollUsed: false,
  target: null,
  skinId: 'skin_starter',
  bodyType: 'a',
  streak: 0,
  rates: XpRates.defaults,
  demo: demo,
);

void main() {
  test('a demo session counts 2 seconds as a minute; a normal one runs in real time', () {
    expect(XpRates.defaults.demoSecondsPerMinute, 2);
    expect(_info(demo: true).focusSeconds(10), 300);
    expect(_info(demo: true).focusSeconds(1), 30);
    expect(_info(demo: false).focusSeconds(10), 10);
  });

  testWidgets('the focus clock runs on demo time in a demo session', (tester) async {
    final router = GoRouter(
      initialLocation: '/focus/session-1',
      routes: [
        GoRoute(
          path: '/focus/:sessionId',
          builder: (context, state) => FocusScreen(
            sessionId: 'session-1',
            startedAt: DateTime.now().subtract(const Duration(seconds: 10)),
            estimateMinutes: 25,
          ),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sessionAlertsProvider.overrideWithValue(_Alerts()),
        focusPresenceProvider.overrideWithValue(_Presence()),
        focusSessionInfoProvider.overrideWith((ref, id) async => _info(demo: true)),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pump();
    // 10 real seconds at 2 s per minute is 5 focus minutes.
    expect(find.text('05:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
