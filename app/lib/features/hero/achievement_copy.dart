/// Display helpers for the eight badges (thresholds match `01-PRD.md` §6.13).
const badgeCatalogIds = <String>[
  'badge_deep_worker',
  'badge_boss_hunter',
  'badge_team_player',
  'badge_unbroken',
  'badge_balanced',
  'badge_early_bird',
  'badge_steady_pace',
  'badge_punctual',
];

const badgeThresholds = <String, List<int>>{
  'badge_deep_worker': [10, 50, 200],
  'badge_boss_hunter': [1, 10, 40],
  'badge_team_player': [1, 5, 20],
  'badge_unbroken': [7, 30, 100],
  'badge_balanced': [1, 4, 12],
  'badge_early_bird': [5, 25, 100],
  'badge_steady_pace': [1, 4, 12],
  'badge_punctual': [10, 50, 200],
};

const badgeDisplayNames = <String, String>{
  'badge_deep_worker': 'Deep Worker',
  'badge_boss_hunter': 'Boss Hunter',
  'badge_team_player': 'Team Player',
  'badge_unbroken': 'Unbroken',
  'badge_balanced': 'Balanced',
  'badge_early_bird': 'Early Bird',
  'badge_steady_pace': 'Steady Pace',
  'badge_punctual': 'Punctual',
};

String badgeShortId(String catalogId) =>
    catalogId.startsWith('badge_') ? catalogId.substring('badge_'.length) : catalogId;

String badgeDisplayName(String catalogId) =>
    badgeDisplayNames[catalogId] ?? badgeShortId(catalogId).replaceAll('_', ' ');

/// Progress within the current tier toward the next threshold (0–1).
double badgeProgressFraction({
  required String badgeId,
  required int progress,
  required int tier,
}) {
  final thresholds = badgeThresholds[badgeId];
  if (thresholds == null || tier >= 3) return 1;
  final next = thresholds[tier.clamp(0, 2)];
  final prev = tier <= 0 ? 0 : thresholds[tier - 1];
  if (next <= prev) return 1;
  return ((progress - prev) / (next - prev)).clamp(0, 1);
}

String badgeProgressLabel({
  required String badgeId,
  required int progress,
  required int tier,
}) {
  final thresholds = badgeThresholds[badgeId];
  if (thresholds == null) return '$progress';
  if (tier >= 3) return 'Tier III';
  final next = thresholds[tier.clamp(0, 2)];
  return '$progress / $next';
}

/// Pin or unpin [badgeId]. Returns null when the pin would exceed 3.
List<String>? togglePinnedBadge(List<String> current, String badgeId) {
  if (current.contains(badgeId)) {
    return [for (final id in current) if (id != badgeId) id];
  }
  if (current.length >= 3) return null;
  return [...current, badgeId];
}
