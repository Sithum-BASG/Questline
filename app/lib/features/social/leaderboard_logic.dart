// Pure helpers for the weekly friends leaderboard (display rules from APP-FLOW §7).

bool leaderboardNeedsMoreFriends(int acceptedFriendCount, {int minFriends = 4}) =>
    acceptedFriendCount < minFriends;

bool leaderboardBelowWeeklyTarget(int myRawXp, {int weeklyTarget = 500}) =>
    myRawXp < weeklyTarget;

String leaderboardTitleLabel(String? titleId, int level) {
  if (titleId == null || titleId.isEmpty) return 'Level $level';
  final id = titleId.startsWith('title_') ? titleId.substring(6) : titleId;
  return id.replaceAll('_', ' ');
}

String catalogAssetShort(String id, String prefix) =>
    id.startsWith(prefix) ? id.substring(prefix.length) : id;
