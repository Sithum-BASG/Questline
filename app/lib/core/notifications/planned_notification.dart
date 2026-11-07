import 'notification_channels.dart';

enum NotifKind {
  bossWarning48,
  bossWarning24,
  bossHealed,
  streak,
  comeback,
  raidEnded,
  weeklyResults,
  sundayNudge,
}

/// Lower number = higher priority when applying the daily cap.
int notifPriority(NotifKind kind) => switch (kind) {
      NotifKind.bossWarning48 || NotifKind.bossWarning24 => 0,
      NotifKind.raidEnded => 1,
      NotifKind.streak => 2,
      NotifKind.weeklyResults => 3,
      NotifKind.comeback => 4,
      NotifKind.bossHealed => 5,
      NotifKind.sundayNudge => 6,
    };

String notifChannel(NotifKind kind) => switch (kind) {
      NotifKind.bossWarning48 || NotifKind.bossWarning24 || NotifKind.bossHealed =>
        NotificationChannels.bosses,
      NotifKind.streak => NotificationChannels.streak,
      NotifKind.raidEnded => NotificationChannels.raids,
      NotifKind.weeklyResults || NotifKind.sundayNudge => NotificationChannels.weekly,
      NotifKind.comeback => NotificationChannels.comeback,
    };

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.when,
    required this.title,
    required this.body,
    required this.route,
  });

  final int id;
  final NotifKind kind;
  final DateTime when;
  final String title;
  final String body;
  final String route;

  int get priority => notifPriority(kind);
  String get channelId => notifChannel(kind);
}

class BossPlanInput {
  const BossPlanInput({
    required this.id,
    required this.name,
    required this.deadline,
    required this.maxHp,
    required this.damage,
    this.lastWorkDay,
  });

  final String id;
  final String name;
  final DateTime deadline;
  final int maxHp;
  final int damage;
  final DateTime? lastWorkDay;

  double get damageRatio => maxHp <= 0 ? 0 : damage / maxHp;
}
