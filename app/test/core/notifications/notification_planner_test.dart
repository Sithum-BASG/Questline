import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/notifications/notification_planner.dart';
import 'package:questline/core/notifications/planned_notification.dart';

void main() {
  final settings = const PlannerSettings();

  test('schedules 48h and 24h boss warnings only under 75% damage', () {
    final now = DateTime(2026, 11, 7, 12);
    final boss = BossPlanInput(
      id: 'b1',
      name: 'The Forensic Phantom',
      deadline: now.add(const Duration(hours: 50)),
      maxHp: 100,
      damage: 40,
    );
    final planned = planNotifications(
      PlannerInput(now: now, settings: settings, bosses: [boss]),
    );
    expect(planned.where((n) => n.kind == NotifKind.bossWarning48), isNotEmpty);
    expect(planned.where((n) => n.kind == NotifKind.bossWarning24), isNotEmpty);

    final almostDone = BossPlanInput(
      id: 'b2',
      name: 'Done-ish',
      deadline: now.add(const Duration(hours: 50)),
      maxHp: 100,
      damage: 80,
    );
    final none = planNotifications(
      PlannerInput(now: now, settings: settings, bosses: [almostDone]),
    );
    expect(none.where((n) => n.kind == NotifKind.bossWarning48 || n.kind == NotifKind.bossWarning24), isEmpty);
  });

  test('boss healed fires next morning after a no-work day', () {
    final now = DateTime(2026, 11, 7, 10);
    final boss = BossPlanInput(
      id: 'b1',
      name: 'Shade',
      deadline: now.add(const Duration(days: 5)),
      maxHp: 100,
      damage: 10,
      lastWorkDay: DateTime(2026, 11, 5),
    );
    final planned = planNotifications(
      PlannerInput(now: now, settings: settings, bosses: [boss]),
    );
    final heal = planned.where((n) => n.kind == NotifKind.bossHealed).single;
    expect(heal.when.hour, 8);
    expect(heal.route, '/bosses/b1');
  });

  test('streak reminder at 20:00 when streak is 3+ and unmet', () {
    final now = DateTime(2026, 11, 7, 15);
    final planned = planNotifications(
      PlannerInput(
        now: now,
        settings: settings,
        streakCount: 12,
        streakMetToday: false,
      ),
    );
    final streak = planned.where((n) => n.kind == NotifKind.streak).single;
    expect(streak.when, DateTime(2026, 11, 7, 20));
    expect(streak.body, contains('12-day'));
  });

  test('comeback after three inactive days', () {
    final now = DateTime(2026, 11, 7, 10);
    final planned = planNotifications(
      PlannerInput(now: now, settings: settings, inactiveDays: 3),
    );
    expect(planned.where((n) => n.kind == NotifKind.comeback), isNotEmpty);
    expect(planned.firstWhere((n) => n.kind == NotifKind.comeback).body, contains('2× XP'));
  });

  test('quiet hours push a 23:30 plan to 07:00 next morning', () {
    final shifted = applyQuietHours(
      DateTime(2026, 11, 7, 23, 30),
      '23:00',
      '07:00',
    );
    expect(shifted, DateTime(2026, 11, 8, 7));
  });

  test('daily cap keeps higher-priority notifs (boss over comeback)', () {
    final now = DateTime(2026, 11, 7, 12);
    final boss = BossPlanInput(
      id: 'b1',
      name: 'Boss',
      deadline: now.add(const Duration(hours: 50)),
      maxHp: 100,
      damage: 0,
      lastWorkDay: DateTime(2026, 11, 5),
    );
    final planned = planNotifications(
      PlannerInput(
        now: now,
        settings: const PlannerSettings(dailyCap: 2),
        streakCount: 5,
        streakMetToday: false,
        inactiveDays: 3,
        bosses: [boss],
      ),
    );
    final day = planned.where((n) => n.when.year == 2026 && n.when.month == 11 && n.when.day == 7).toList();
    expect(day.length, 2);
    // Boss warning (priority 0) beats comeback when competing for the same day.
    expect(day.any((n) => n.kind == NotifKind.bossWarning48), true);
    expect(day.any((n) => n.kind == NotifKind.comeback), false);
  });

  test('category toggle suppresses boss notifications', () {
    final now = DateTime(2026, 11, 7, 12);
    final boss = BossPlanInput(
      id: 'b1',
      name: 'Boss',
      deadline: now.add(const Duration(hours: 50)),
      maxHp: 100,
      damage: 0,
    );
    final planned = planNotifications(
      PlannerInput(
        now: now,
        settings: const PlannerSettings(notifBosses: false),
        bosses: [boss],
      ),
    );
    expect(planned.where((n) => n.kind == NotifKind.bossWarning48), isEmpty);
  });

  test('raid ended schedules deadline + 20 minutes', () {
    final now = DateTime(2026, 11, 7, 12);
    final planned = planNotifications(
      PlannerInput(
        now: now,
        settings: settings,
        raidDeadlines: [
          (id: 'r1', name: 'Party of Four', deadline: now.add(const Duration(hours: 2))),
        ],
      ),
    );
    final raid = planned.where((n) => n.kind == NotifKind.raidEnded).single;
    expect(raid.when, now.add(const Duration(hours: 2, minutes: 20)));
    expect(raid.route, '/raids/r1/results');
  });

  test('Monday weekly results and optional Sunday nudge', () {
    // Saturday noon → next Monday 08:00 and Sunday 18:00 are in range.
    final now = DateTime(2026, 11, 7, 12);
    final planned = planNotifications(
      PlannerInput(
        now: now,
        settings: const PlannerSettings(notifLeaderboardNudge: true, dailyCap: 10),
        xpBehindSecond: 120,
      ),
    );
    final weekly = planned.where((n) => n.kind == NotifKind.weeklyResults).single;
    expect(weekly.when.weekday, DateTime.monday);
    expect(weekly.when.hour, 8);
    expect(weekly.route, startsWith('/recap/'));

    final nudge = planned.where((n) => n.kind == NotifKind.sundayNudge).single;
    expect(nudge.when.weekday, DateTime.sunday);
    expect(nudge.when.hour, 18);
    expect(nudge.body, contains('120 XP'));
  });

  test('Sunday nudge stays off by default', () {
    final now = DateTime(2026, 11, 7, 12);
    final planned = planNotifications(
      PlannerInput(
        now: now,
        settings: const PlannerSettings(dailyCap: 10),
        xpBehindSecond: 120,
      ),
    );
    expect(planned.where((n) => n.kind == NotifKind.sundayNudge), isEmpty);
  });
}
