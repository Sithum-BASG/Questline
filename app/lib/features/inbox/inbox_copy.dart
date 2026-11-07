/// Human-readable inbox lines. Never includes task titles.
String inboxTitle(String type) => switch (type) {
      'guild_fight' => 'Guild fight',
      'raid_result' => 'Raid result',
      'weekly_results' => 'Weekly results',
      'friend_request' => 'Friend request',
      'boss_result' => 'Boss result',
      'system' => 'Update',
      _ => 'Inbox',
    };

String inboxBody(String type, Map<String, dynamic> payload) {
  switch (type) {
    case 'guild_fight':
      final name = payload['name'] as String? ?? 'a guild fight';
      return '$name is on — open Raids to join.';
    case 'raid_result':
      final name = payload['name'] as String? ?? 'Your raid';
      final result = payload['result'] as String? ?? 'ended';
      return '$name $result.';
    case 'weekly_results':
      final week = payload['weekId'] as String? ?? 'this week';
      final rank = payload['rank'];
      if (rank is num) return 'Week $week — you placed ${rank.toInt()}.';
      return 'Week $week results are ready.';
    case 'friend_request':
      final name = payload['displayName'] as String? ?? payload['username'] as String? ?? 'Someone';
      return '$name wants to be friends.';
    case 'boss_result':
      final name = payload['name'] as String? ?? 'A boss';
      final result = payload['result'] as String? ?? 'resolved';
      return '$name $result.';
    default:
      return 'Tap to open.';
  }
}

/// Route for an inbox row. Refined in T112 deep-link pass.
String inboxRoute(String type, Map<String, dynamic> payload) {
  switch (type) {
    case 'guild_fight':
      final id = payload['raidId'] as String?;
      return id != null ? '/raids/$id' : '/bosses';
    case 'raid_result':
      final id = payload['raidId'] as String?;
      return id != null ? '/raids/$id/results' : '/bosses';
    case 'weekly_results':
      final week = payload['weekId'] as String?;
      return week != null ? '/recap/$week' : '/home';
    case 'friend_request':
      return '/social/friends';
    case 'boss_result':
      final id = payload['bossId'] as String?;
      return id != null ? '/bosses/$id/result' : '/bosses';
    default:
      return '/home';
  }
}
