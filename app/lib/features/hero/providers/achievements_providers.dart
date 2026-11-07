import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../achievement_copy.dart';
import 'profile_providers.dart';

class BadgeProgress {
  const BadgeProgress({
    required this.badgeId,
    required this.name,
    required this.progress,
    required this.tier,
  });

  final String badgeId;
  final String name;
  final int progress;
  final int tier;
}

class TitleOption {
  const TitleOption({required this.id, required this.name});

  final String id;
  final String name;
}

class AchievementsViewData {
  const AchievementsViewData({
    required this.badges,
    required this.pinnedBadges,
    required this.titles,
    required this.equippedTitleId,
  });

  final List<BadgeProgress> badges;
  final List<String> pinnedBadges;
  final List<TitleOption> titles;
  final String? equippedTitleId;
}

class AchievementsRepository {
  AchievementsRepository(this._client);

  final SupabaseClient _client;

  Future<AchievementsViewData> load() async {
    final profile = await _client
        .from('profiles')
        .select('pinned_badges, title_id')
        .maybeSingle();
    final pinned = [
      for (final id in (profile?['pinned_badges'] as List? ?? const []))
        if (id is String) id,
    ];
    final equippedTitleId = profile?['title_id'] as String?;

    final rows = await _client.from('achievements').select('badge_id, progress, tier');
    final byId = <String, ({int progress, int tier})>{};
    for (final row in rows) {
      final id = row['badge_id'] as String?;
      if (id == null) continue;
      byId[id] = (
        progress: (row['progress'] as num?)?.toInt() ?? 0,
        tier: (row['tier'] as num?)?.toInt() ?? 0,
      );
    }

    final badges = [
      for (final id in badgeCatalogIds)
        BadgeProgress(
          badgeId: id,
          name: badgeDisplayName(id),
          progress: byId[id]?.progress ?? 0,
          tier: byId[id]?.tier ?? 0,
        ),
    ];

    final player = await _client.from('player_state').select('owned_titles').maybeSingle();
    final ownedIds = [
      for (final id in (player?['owned_titles'] as List? ?? const []))
        if (id is String) id,
    ];
    final titles = <TitleOption>[];
    if (ownedIds.isNotEmpty) {
      final catalog = await _client.from('catalog_items').select('id, name').inFilter('id', ownedIds);
      final names = <String, String>{
        for (final row in catalog)
          if (row['id'] is String) row['id'] as String: (row['name'] as String?) ?? row['id'] as String,
      };
      for (final id in ownedIds) {
        titles.add(TitleOption(id: id, name: names[id] ?? id.replaceAll('_', ' ')));
      }
    }

    return AchievementsViewData(
      badges: badges,
      pinnedBadges: pinned,
      titles: titles,
      equippedTitleId: equippedTitleId,
    );
  }

  Future<void> setPinnedBadges(List<String> badgeIds) async {
    await _client.from('profiles').update({'pinned_badges': badgeIds});
  }

  Future<void> setTitleId(String? titleId) async {
    await _client.from('profiles').update({'title_id': titleId});
  }
}

final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  return AchievementsRepository(ref.watch(supabaseClientProvider));
});

final achievementsViewProvider = FutureProvider<AchievementsViewData>((ref) {
  return ref.watch(achievementsRepositoryProvider).load();
});

/// Keeps the hero profile in sync after pin/title changes.
void invalidateAchievementViews(WidgetRef ref) {
  ref.invalidate(achievementsViewProvider);
  ref.invalidate(profileViewProvider);
}
