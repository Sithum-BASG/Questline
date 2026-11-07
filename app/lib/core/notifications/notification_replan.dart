import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_providers.dart';
import 'local_notifications.dart';
import 'notification_planner.dart';
import 'notification_scheduler.dart';
import 'planned_notification.dart';

/// Loads current settings + bosses + raids and re-schedules the next 7 days.
Future<void> replanLocalNotifications(WidgetRef ref) async {
  final session = ref.read(authStateProvider).asData?.value.session;
  if (session == null) return;

  final client = ref.read(supabaseClientProvider);
  final notifications = ref.read(localNotificationsProvider);
  final scheduler = NotificationScheduler(notifications);

  final settingsRow = await client.from('user_settings').select().eq('user_id', session.user.id).maybeSingle();
  final player = await client
      .from('player_state')
      .select('streak_count, inactive_days, comeback_armed, timezone')
      .maybeSingle();
  final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final dayStat = await client
      .from('daily_stats')
      .select('met_minimum, raw_xp')
      .eq('day', today)
      .maybeSingle();

  final bossRows = await client
      .from('bosses')
      .select('id, name, deadline, max_hp, damage, last_work_day, status')
      .inFilter('status', ['active', 'staggered']);
  final raidRows = await client
      .from('raids')
      .select('id, name, deadline, status')
      .eq('status', 'active');

  final settings = PlannerSettings(
    notifBosses: settingsRow?['notif_bosses'] != false,
    notifStreak: settingsRow?['notif_streak'] != false,
    notifRaids: settingsRow?['notif_raids'] != false,
    notifWeekly: settingsRow?['notif_weekly'] != false,
    notifLeaderboardNudge: settingsRow?['notif_leaderboard_nudge'] == true,
    quietStart: _hm(settingsRow?['quiet_start'] as String? ?? '23:00'),
    quietEnd: _hm(settingsRow?['quiet_end'] as String? ?? '07:00'),
  );

  final bosses = <BossPlanInput>[
    for (final row in bossRows)
      BossPlanInput(
        id: row['id'] as String,
        name: row['name'] as String? ?? 'Boss',
        deadline: DateTime.parse(row['deadline'] as String).toLocal(),
        maxHp: (row['max_hp'] as num?)?.toInt() ?? 1,
        damage: (row['damage'] as num?)?.toInt() ?? 0,
        lastWorkDay: row['last_work_day'] != null ? DateTime.tryParse(row['last_work_day'].toString()) : null,
      ),
  ];

  final raids = <({String id, String name, DateTime deadline})>[
    for (final row in raidRows)
      (
        id: row['id'] as String,
        name: row['name'] as String? ?? 'Raid',
        deadline: DateTime.parse(row['deadline'] as String).toLocal(),
      ),
  ];

  await scheduler.replan(
    PlannerInput(
      now: DateTime.now(),
      settings: settings,
      streakCount: (player?['streak_count'] as num?)?.toInt() ?? 0,
      streakMetToday: dayStat?['met_minimum'] == true || ((dayStat?['raw_xp'] as num?)?.toInt() ?? 0) >= 40,
      inactiveDays: (player?['inactive_days'] as num?)?.toInt() ?? 0,
      comebackArmed: player?['comeback_armed'] == true,
      bosses: bosses,
      raidDeadlines: raids,
    ),
  );
}

String _hm(String raw) {
  final parts = raw.split(':');
  final h = (parts.elementAtOrNull(0) ?? '0').padLeft(2, '0');
  final m = (parts.elementAtOrNull(1) ?? '0').padLeft(2, '0');
  return '$h:$m';
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(ref.watch(localNotificationsProvider));
});
