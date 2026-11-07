import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/config/game_config_reader.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/profile.dart';
import '../leaderboard_logic.dart';
import 'friends_providers.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.rawXp,
    required this.rank,
    required this.displayName,
    required this.title,
    required this.skinId,
    required this.backgroundId,
    required this.frameId,
    required this.body,
    required this.isYou,
  });

  final String userId;
  final int rawXp;
  final int rank;
  final String displayName;
  final String title;
  final String skinId;
  final String backgroundId;
  final String frameId;
  final BodyType body;
  final bool isYou;
}

class LeaderboardSnapshot {
  const LeaderboardSnapshot({
    required this.weekId,
    required this.entries,
    required this.acceptedFriendCount,
    required this.minFriends,
    required this.weeklyTarget,
    required this.myRawXp,
    required this.friendCode,
    required this.needsMoreFriends,
    required this.belowWeeklyTarget,
  });

  final String weekId;
  final List<LeaderboardEntry> entries;
  final int acceptedFriendCount;
  final int minFriends;
  final int weeklyTarget;
  final int myRawXp;
  final String? friendCode;
  final bool needsMoreFriends;
  final bool belowWeeklyTarget;
}

final leaderboardProvider = FutureProvider.autoDispose<LeaderboardSnapshot>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final myId = ref.watch(authStateProvider).asData?.value.session?.user.id;
  if (myId == null) throw StateError('Not signed in');

  final config = await ref.watch(gameConfigReaderProvider).load();
  final minFriends = (config['leaderboard_min_friends'] as num?)?.toInt() ?? 4;
  final weeklyTarget = (config['weekly_target_raw_xp'] as num?)?.toInt() ?? 500;

  final player = await client.from('player_state').select('week_id, weekly_raw_xp').maybeSingle();
  final weekId = player?['week_id'] as String? ?? '';
  final myRawXp = (player?['weekly_raw_xp'] as num?)?.toInt() ?? 0;

  final friendships = await ref.watch(friendshipsProvider.future);
  final acceptedFriendCount = friendships.where((row) => row.status == 'accepted').length;

  final friendCode = await ref.watch(myFriendCodeProvider.future);

  // RLS already limits weekly_scores to me + accepted friends.
  final scoreRows = weekId.isEmpty
      ? <dynamic>[]
      : await client
          .from('weekly_scores')
          .select('user_id, raw_xp')
          .eq('week_id', weekId)
          .order('raw_xp', ascending: false);

  final userIds = <String>{
    for (final row in scoreRows) row['user_id'] as String,
    myId,
  }.toList();

  final profileRows = await client
      .from('profiles')
      .select(
        'id, username, friend_code, display_name, body_type, level, title_id, equipped_skin_id, equipped_background_id, equipped_frame_id, pinned_badges, guild_id, hide_radar, show_boss_names, created_at',
      )
      .inFilter('id', userIds);
  final profiles = <String, Profile>{};
  for (final row in profileRows) {
    final profile = Profile.fromJson(Map<String, dynamic>.from(row as Map));
    profiles[profile.id] = profile;
  }

  final entries = <LeaderboardEntry>[];
  for (var i = 0; i < scoreRows.length; i++) {
    final userId = scoreRows[i]['user_id'] as String;
    final rawXp = (scoreRows[i]['raw_xp'] as num).toInt();
    final profile = profiles[userId];
    if (profile == null) continue;
    entries.add(
      LeaderboardEntry(
        userId: userId,
        rawXp: rawXp,
        rank: i + 1,
        displayName: profile.displayName,
        title: leaderboardTitleLabel(profile.titleId, profile.level),
        skinId: catalogAssetShort(profile.equippedSkinId, 'skin_'),
        backgroundId: catalogAssetShort(profile.equippedBackgroundId, 'bg_'),
        frameId: catalogAssetShort(profile.equippedFrameId, 'frame_'),
        body: profile.bodyType == 'b' ? BodyType.b : BodyType.a,
        isYou: userId == myId,
      ),
    );
  }

  // Own row may be missing until the first scored session this week.
  if (entries.every((e) => !e.isYou)) {
    final me = profiles[myId];
    if (me != null) {
      entries.add(
        LeaderboardEntry(
          userId: myId,
          rawXp: myRawXp,
          rank: entries.length + 1,
          displayName: me.displayName,
          title: leaderboardTitleLabel(me.titleId, me.level),
          skinId: catalogAssetShort(me.equippedSkinId, 'skin_'),
          backgroundId: catalogAssetShort(me.equippedBackgroundId, 'bg_'),
          frameId: catalogAssetShort(me.equippedFrameId, 'frame_'),
          body: me.bodyType == 'b' ? BodyType.b : BodyType.a,
          isYou: true,
        ),
      );
      entries.sort((a, b) => b.rawXp.compareTo(a.rawXp));
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        entries[i] = LeaderboardEntry(
          userId: e.userId,
          rawXp: e.rawXp,
          rank: i + 1,
          displayName: e.displayName,
          title: e.title,
          skinId: e.skinId,
          backgroundId: e.backgroundId,
          frameId: e.frameId,
          body: e.body,
          isYou: e.isYou,
        );
      }
    }
  }

  return LeaderboardSnapshot(
    weekId: weekId,
    entries: entries,
    acceptedFriendCount: acceptedFriendCount,
    minFriends: minFriends,
    weeklyTarget: weeklyTarget,
    myRawXp: myRawXp,
    friendCode: friendCode,
    needsMoreFriends: leaderboardNeedsMoreFriends(acceptedFriendCount, minFriends: minFriends),
    belowWeeklyTarget: leaderboardBelowWeeklyTarget(myRawXp, weeklyTarget: weeklyTarget),
  );
});
