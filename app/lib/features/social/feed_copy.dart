// Display strings for activity_events. Never surface task titles.

String activityFeedLine({
  required String actorName,
  required String type,
  required Map<String, dynamic> payload,
}) {
  switch (type) {
    case 'level_up':
      final level = payload['level'];
      return level == null ? '$actorName levelled up' : '$actorName reached level $level';
    case 'boss_defeated':
      final name = payload['name'];
      if (name is String && name.trim().isNotEmpty) {
        return '$actorName defeated $name';
      }
      final tier = payload['tier'];
      if (tier is String && tier.isNotEmpty) {
        return '$actorName defeated a $tier boss';
      }
      return '$actorName defeated a boss';
    case 'raid_won':
      return '$actorName won a raid';
    case 'chest_drop':
      final rarity = payload['rarity'];
      if (rarity is String && rarity.isNotEmpty) {
        return '$actorName found $rarity loot in a chest';
      }
      return '$actorName found loot in a chest';
    case 'badge':
      final badge = payload['badge'] ?? payload['badge_id'] ?? payload['id'];
      if (badge is String && badge.isNotEmpty) {
        final short = badge.startsWith('badge_') ? badge.substring(6) : badge;
        return '$actorName earned ${short.replaceAll('_', ' ')}';
      }
      return '$actorName earned a badge';
    default:
      return '$actorName did something new';
  }
}
