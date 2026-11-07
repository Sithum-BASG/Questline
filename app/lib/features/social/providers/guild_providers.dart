import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/assets/game_assets.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/guild.dart';
import '../../../data/models/guild_member.dart';
import '../../../data/models/guild_trophy.dart';
import '../../../data/models/presence.dart';
import '../../../data/models/profile.dart';
import 'presence_providers.dart';

class GuildMemberView {
  const GuildMemberView({
    required this.member,
    required this.profile,
    required this.focusing,
  });

  final GuildMember member;
  final Profile profile;
  final bool focusing;
}

class GuildHomeSnapshot {
  const GuildHomeSnapshot({
    required this.guild,
    required this.members,
    required this.trophies,
    required this.isLeader,
  });

  final Guild guild;
  final List<GuildMemberView> members;
  final List<GuildTrophy> trophies;
  final bool isLeader;
}

final myGuildIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final userId = ref.watch(authStateProvider).asData?.value.session?.user.id;
  if (userId == null) return null;
  final row = await ref
      .watch(supabaseClientProvider)
      .from('profiles')
      .select('guild_id')
      .eq('id', userId)
      .maybeSingle();
  return row?['guild_id'] as String?;
});

final guildHomeProvider = FutureProvider.autoDispose<GuildHomeSnapshot?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(authStateProvider).asData?.value.session?.user.id;
  if (userId == null) return null;

  final guildId = await ref.watch(myGuildIdProvider.future);
  if (guildId == null) return null;

  final guildRow = await client.from('guilds').select().eq('id', guildId).maybeSingle();
  if (guildRow == null) return null;
  final guild = Guild.fromJson(Map<String, dynamic>.from(guildRow));

  final memberRows = await client.from('guild_members').select().eq('guild_id', guildId).order('joined_at');
  final members = [
    for (final row in memberRows) GuildMember.fromJson(Map<String, dynamic>.from(row as Map)),
  ];
  final ids = members.map((m) => m.userId).toList();
  final profileRows = ids.isEmpty
      ? <dynamic>[]
      : await client
          .from('profiles')
          .select(
            'id, username, friend_code, display_name, body_type, level, title_id, equipped_skin_id, equipped_background_id, equipped_frame_id, pinned_badges, guild_id, hide_radar, show_boss_names, created_at',
          )
          .inFilter('id', ids);
  final profiles = <String, Profile>{};
  for (final row in profileRows) {
    final profile = Profile.fromJson(Map<String, dynamic>.from(row as Map));
    profiles[profile.id] = profile;
  }

  final presenceRows = ids.isEmpty
      ? <dynamic>[]
      : await client.from('presence').select().inFilter('user_id', ids);
  final now = DateTime.now().toUtc();
  final focusing = <String>{};
  for (final row in presenceRows) {
    final presence = Presence.fromJson(Map<String, dynamic>.from(row as Map));
    if (isFocusingNow(presence, now)) focusing.add(presence.userId);
  }

  final trophyRows =
      await client.from('guild_trophies').select().eq('guild_id', guildId).order('won_at', ascending: false);
  final trophies = [
    for (final row in trophyRows) GuildTrophy.fromJson(Map<String, dynamic>.from(row as Map)),
  ];

  final views = <GuildMemberView>[];
  for (final member in members) {
    final profile = profiles[member.userId];
    if (profile == null) continue;
    views.add(
      GuildMemberView(
        member: member,
        profile: profile,
        focusing: focusing.contains(member.userId),
      ),
    );
  }

  return GuildHomeSnapshot(
    guild: guild,
    members: views,
    trophies: trophies,
    isLeader: guild.leaderId == userId,
  );
});

BodyType bodyFromProfile(Profile profile) => profile.bodyType == 'b' ? BodyType.b : BodyType.a;

String assetShort(String id, String prefix) => id.startsWith(prefix) ? id.substring(prefix.length) : id;
