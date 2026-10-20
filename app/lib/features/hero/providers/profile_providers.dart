import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/widgets/stat_radar.dart';
import '../../../data/models/daily_stat.dart';
import '../../../data/models/profile.dart';

class ProfileViewData {
  const ProfileViewData({
    required this.profile,
    required this.titleName,
    required this.radar30,
    required this.radar7,
    required this.badgeTiers,
  });

  final Profile profile;
  final String? titleName;
  final StatRadarValues radar30;
  final StatRadarValues radar7;
  final Map<String, int> badgeTiers;
}

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileViewData> load() async {
    final profileRow = await _client
        .from('profiles')
        .select(
          'id, username, friend_code, display_name, body_type, level, title_id, equipped_skin_id, equipped_background_id, equipped_frame_id, pinned_badges, guild_id, hide_radar, show_boss_names, created_at',
        )
        .maybeSingle();
    if (profileRow == null) throw StateError('Profile missing');
    final profile = Profile.fromJson(profileRow);

    String? titleName;
    if (profile.titleId != null) {
      final title = await _client.from('catalog_items').select('name').eq('id', profile.titleId!).maybeSingle();
      titleName = title?['name'] as String?;
    }

    final dayRows = await _client
        .from('daily_stats')
        .select(
          'user_id, day, xp_intellect, xp_vitality, xp_craft, xp_charisma, raw_xp, focus_minutes, sessions_started, met_minimum, rest_day, paused',
        )
        .order('day', ascending: false)
        .limit(30);
    final stats = [for (final row in dayRows) DailyStat.fromJson(row)];
    final end = DateTime.now().toUtc();
    final mapped = stats.map(
      (s) => (
        day: s.day,
        intellect: s.xpIntellect,
        vitality: s.xpVitality,
        craft: s.xpCraft,
        charisma: s.xpCharisma,
      ),
    );
    final radar30 = StatRadarValues.fromDailyStats(mapped, days: 30, end: end);
    final radar7 = StatRadarValues.fromDailyStats(mapped, days: 7, end: end);

    final badgeTiers = <String, int>{};
    if (profile.pinnedBadges.isNotEmpty) {
      final rows = await _client
          .from('achievements')
          .select('badge_id, tier')
          .inFilter('badge_id', profile.pinnedBadges);
      for (final row in rows) {
        final id = row['badge_id'] as String?;
        if (id != null) badgeTiers[id] = (row['tier'] as num?)?.toInt() ?? 0;
      }
    }

    return ProfileViewData(
      profile: profile,
      titleName: titleName,
      radar30: radar30,
      radar7: radar7,
      badgeTiers: badgeTiers,
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final profileViewProvider = FutureProvider<ProfileViewData>((ref) {
  return ref.watch(profileRepositoryProvider).load();
});
