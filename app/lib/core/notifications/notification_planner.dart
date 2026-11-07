import 'planned_notification.dart';

class PlannerSettings {
  const PlannerSettings({
    this.notifBosses = true,
    this.notifStreak = true,
    this.notifRaids = true,
    this.notifWeekly = true,
    this.notifLeaderboardNudge = false,
    this.quietStart = '23:00',
    this.quietEnd = '07:00',
    this.dailyCap = 2,
  });

  final bool notifBosses;
  final bool notifStreak;
  final bool notifRaids;
  final bool notifWeekly;
  final bool notifLeaderboardNudge;
  final String quietStart;
  final String quietEnd;
  final int dailyCap;
}

class PlannerInput {
  const PlannerInput({
    required this.now,
    required this.settings,
    this.streakCount = 0,
    this.streakMetToday = false,
    this.inactiveDays = 0,
    this.comebackArmed = false,
    this.bosses = const [],
    this.raidDeadlines = const [],
    this.xpBehindSecond,
    this.horizonDays = 7,
  });

  final DateTime now;
  final PlannerSettings settings;
  final int streakCount;
  final bool streakMetToday;
  final int inactiveDays;
  final bool comebackArmed;
  final List<BossPlanInput> bosses;
  /// Active raid deadlines used for "raid ended" +20 min reminders (T111).
  final List<({String id, String name, DateTime deadline})> raidDeadlines;
  /// Last known XP gap to 2nd place for the Sunday nudge (T111).
  final int? xpBehindSecond;
  final int horizonDays;
}

(int hour, int minute) _parseHm(String value) {
  final parts = value.split(':');
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return (hour.clamp(0, 23), minute.clamp(0, 59));
}

DateTime _atLocal(DateTime day, int hour, int minute) =>
    DateTime(day.year, day.month, day.day, hour, minute);

/// Shifts [when] to just after quiet hours when it falls inside the quiet window.
DateTime applyQuietHours(DateTime when, String quietStart, String quietEnd) {
  final (startH, startM) = _parseHm(quietStart);
  final (endH, endM) = _parseHm(quietEnd);
  final startMinutes = startH * 60 + startM;
  final endMinutes = endH * 60 + endM;
  final minutes = when.hour * 60 + when.minute;

  final inQuiet = startMinutes <= endMinutes
      ? minutes >= startMinutes && minutes < endMinutes
      : minutes >= startMinutes || minutes < endMinutes;

  if (!inQuiet) return when;

  if (startMinutes > endMinutes) {
    // Overnight quiet (e.g. 23:00–07:00): fire at quiet end same calendar morning.
    if (minutes >= startMinutes) {
      final next = when.add(const Duration(days: 1));
      return _atLocal(next, endH, endM);
    }
    return _atLocal(when, endH, endM);
  }
  // Same-day quiet window.
  return _atLocal(when, endH, endM);
}

String _dayKey(DateTime when) =>
    '${when.year.toString().padLeft(4, '0')}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';

/// Keeps at most [cap] notifications per local day, preferring higher priority.
List<PlannedNotification> applyDailyCap(List<PlannedNotification> planned, int cap) {
  final byDay = <String, List<PlannedNotification>>{};
  for (final n in planned) {
    byDay.putIfAbsent(_dayKey(n.when), () => []).add(n);
  }
  final kept = <PlannedNotification>[];
  for (final day in byDay.values) {
    day.sort((a, b) {
      final byPriority = a.priority.compareTo(b.priority);
      if (byPriority != 0) return byPriority;
      return a.when.compareTo(b.when);
    });
    kept.addAll(day.take(cap));
  }
  kept.sort((a, b) => a.when.compareTo(b.when));
  return kept;
}

int _stableId(NotifKind kind, String key) {
  // Stay inside a positive 31-bit range for Android notification ids.
  return Object.hash(kind.index, key) & 0x7fffffff;
}

List<PlannedNotification> _bossCandidates(PlannerInput input) {
  if (!input.settings.notifBosses) return const [];
  final out = <PlannedNotification>[];
  final horizon = input.now.add(Duration(days: input.horizonDays));
  final today = DateTime(input.now.year, input.now.month, input.now.day);

  for (final boss in input.bosses) {
    if (boss.damageRatio >= 0.75) continue;

    for (final hours in const [48, 24]) {
      final when = boss.deadline.subtract(Duration(hours: hours));
      if (!when.isAfter(input.now) || when.isAfter(horizon)) continue;
      final kind = hours == 48 ? NotifKind.bossWarning48 : NotifKind.bossWarning24;
      final pct = (boss.damageRatio * 100).round();
      out.add(
        PlannedNotification(
          id: _stableId(kind, boss.id),
          kind: kind,
          when: when,
          title: '${boss.name} is due in $hours hours',
          body: "You've dealt $pct%.",
          route: '/bosses/${boss.id}',
        ),
      );
    }

    // Heal ping: next morning after a day with no work on this boss.
    final last = boss.lastWorkDay;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      if (today.difference(lastDay).inDays >= 1) {
        var healAt = _atLocal(today, 8, 0);
        if (!healAt.isAfter(input.now)) {
          healAt = _atLocal(today.add(const Duration(days: 1)), 8, 0);
        }
        if (!healAt.isAfter(horizon)) {
          out.add(
            PlannedNotification(
              id: _stableId(NotifKind.bossHealed, boss.id),
              kind: NotifKind.bossHealed,
              when: healAt,
              title: 'Your boss healed today',
              body: '${boss.name} recovered a little overnight.',
              route: '/bosses/${boss.id}',
            ),
          );
        }
      }
    }
  }
  return out;
}

List<PlannedNotification> _streakCandidates(PlannerInput input) {
  if (!input.settings.notifStreak) return const [];
  if (input.streakCount < 3 || input.streakMetToday) return const [];
  final todayAt8pm = _atLocal(input.now, 20, 0);
  if (!todayAt8pm.isAfter(input.now)) return const [];
  return [
    PlannedNotification(
      id: _stableId(NotifKind.streak, 'today'),
      kind: NotifKind.streak,
      when: todayAt8pm,
      title: 'Keep your streak',
      body: '40 XP keeps your ${input.streakCount}-day streak alive.',
      route: '/home',
    ),
  ];
}

List<PlannedNotification> _comebackCandidates(PlannerInput input) {
  if (input.inactiveDays < 3 && !input.comebackArmed) return const [];
  var when = _atLocal(input.now, 9, 0);
  if (!when.isAfter(input.now)) {
    when = input.now.add(const Duration(hours: 1));
  }
  final horizon = input.now.add(Duration(days: input.horizonDays));
  if (when.isAfter(horizon)) return const [];
  return [
    PlannedNotification(
      id: _stableId(NotifKind.comeback, 'once'),
      kind: NotifKind.comeback,
      when: when,
      title: 'Ready when you are',
      body: 'Your comeback session earns 2× XP.',
      route: '/home',
    ),
  ];
}

List<PlannedNotification> _raidCandidates(PlannerInput input) {
  if (!input.settings.notifRaids) return const [];
  final horizon = input.now.add(Duration(days: input.horizonDays));
  final out = <PlannedNotification>[];
  for (final raid in input.raidDeadlines) {
    final when = raid.deadline.add(const Duration(minutes: 20));
    if (!when.isAfter(input.now) || when.isAfter(horizon)) continue;
    out.add(
      PlannedNotification(
        id: _stableId(NotifKind.raidEnded, raid.id),
        kind: NotifKind.raidEnded,
        when: when,
        title: 'Your raid has ended',
        body: '${raid.name} results are ready.',
        route: '/raids/${raid.id}/results',
      ),
    );
  }
  return out;
}

List<PlannedNotification> _weeklyCandidates(PlannerInput input) {
  if (!input.settings.notifWeekly) return const [];
  final horizon = input.now.add(Duration(days: input.horizonDays));
  final out = <PlannedNotification>[];

  // Next Monday 08:00 local.
  var cursor = DateTime(input.now.year, input.now.month, input.now.day);
  while (cursor.weekday != DateTime.monday) {
    cursor = cursor.add(const Duration(days: 1));
  }
  var monday = _atLocal(cursor, 8, 0);
  if (!monday.isAfter(input.now)) {
    monday = monday.add(const Duration(days: 7));
  }
  if (!monday.isAfter(horizon)) {
    final weekId =
        '${monday.year}-W${((monday.difference(DateTime(monday.year, 1, 4)).inDays + DateTime(monday.year, 1, 4).weekday) ~/ 7).toString().padLeft(2, '0')}';
    out.add(
      PlannedNotification(
        id: _stableId(NotifKind.weeklyResults, weekId),
        kind: NotifKind.weeklyResults,
        when: monday,
        title: 'Weekly results are in',
        body: 'Your recap is ready.',
        route: '/recap/$weekId',
      ),
    );
  }

  if (input.settings.notifLeaderboardNudge && input.xpBehindSecond != null && input.xpBehindSecond! > 0) {
    var sunday = DateTime(input.now.year, input.now.month, input.now.day);
    while (sunday.weekday != DateTime.sunday) {
      sunday = sunday.add(const Duration(days: 1));
    }
    var when = _atLocal(sunday, 18, 0);
    if (!when.isAfter(input.now)) {
      when = when.add(const Duration(days: 7));
    }
    if (!when.isAfter(horizon)) {
      out.add(
        PlannedNotification(
          id: _stableId(NotifKind.sundayNudge, _dayKey(when)),
          kind: NotifKind.sundayNudge,
          when: when,
          title: 'Leaderboard nudge',
          body: "You're ${input.xpBehindSecond} XP behind 2nd place.",
          route: '/social',
        ),
      );
    }
  }
  return out;
}

/// Builds the next week of local notifications from current game state.
/// Focus-session alerts are excluded from the daily cap (handled separately).
List<PlannedNotification> planNotifications(PlannerInput input) {
  final raw = <PlannedNotification>[
    ..._bossCandidates(input),
    ..._streakCandidates(input),
    ..._comebackCandidates(input),
    ..._raidCandidates(input),
    ..._weeklyCandidates(input),
  ];

  final shifted = [
    for (final n in raw)
      PlannedNotification(
        id: n.id,
        kind: n.kind,
        when: applyQuietHours(n.when, input.settings.quietStart, input.settings.quietEnd),
        title: n.title,
        body: n.body,
        route: n.route,
      ),
  ].where((n) => n.when.isAfter(input.now)).toList();

  return applyDailyCap(shifted, input.settings.dailyCap);
}
