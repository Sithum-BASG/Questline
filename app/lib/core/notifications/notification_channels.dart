/// Android notification channel ids used by the local notification plugin.
class NotificationChannels {
  const NotificationChannels._();

  static const focus = 'focus';
  static const bosses = 'bosses';
  static const streak = 'streak';
  static const raids = 'raids';
  static const weekly = 'weekly';
  static const comeback = 'comeback';

  static const all = <String>[
    focus,
    bosses,
    streak,
    raids,
    weekly,
    comeback,
  ];

  static String titleFor(String id) => switch (id) {
        focus => 'Focus',
        bosses => 'Bosses',
        streak => 'Streak',
        raids => 'Raids',
        weekly => 'Weekly',
        comeback => 'Comeback',
        _ => id,
      };

  static String descriptionFor(String id) => switch (id) {
        focus => 'Focus timer and return reminders during a session.',
        bosses => 'Deadline warnings and boss healing updates.',
        streak => 'Evening streak reminders.',
        raids => 'Raid ended reminders.',
        weekly => 'Monday results and the optional Sunday nudge.',
        comeback => 'A single comeback nudge after a few quiet days.',
        _ => '',
      };
}
