import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/friendship.dart';
import '../../../data/models/profile.dart';

class FriendRow {
  const FriendRow({
    required this.friendship,
    required this.profile,
  });

  final Friendship friendship;
  final Profile profile;
}

/// Accepted friends and incoming/outgoing requests for the signed-in user.
final friendshipsProvider = FutureProvider.autoDispose<List<Friendship>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client.from('friendships').select().order('since', ascending: false);
  return [
    for (final row in rows) Friendship.fromJson(Map<String, dynamic>.from(row as Map)),
  ];
});

final friendRowsProvider = FutureProvider.autoDispose<({
  List<FriendRow> accepted,
  List<FriendRow> incoming,
  List<FriendRow> outgoing,
})>((ref) async {
  final friendships = await ref.watch(friendshipsProvider.future);
  if (friendships.isEmpty) {
    return (accepted: <FriendRow>[], incoming: <FriendRow>[], outgoing: <FriendRow>[]);
  }
  final client = ref.watch(supabaseClientProvider);
  final ids = friendships.map((row) => row.friendId).toSet().toList();
  final profiles = await client
      .from('profiles')
      .select(
        'id, username, friend_code, display_name, body_type, level, title_id, equipped_skin_id, equipped_background_id, equipped_frame_id, pinned_badges, guild_id, hide_radar, show_boss_names, created_at',
      )
      .inFilter('id', ids);
  final byId = <String, Profile>{};
  for (final row in profiles) {
    final profile = Profile.fromJson(Map<String, dynamic>.from(row as Map));
    byId[profile.id] = profile;
  }

  final accepted = <FriendRow>[];
  final incoming = <FriendRow>[];
  final outgoing = <FriendRow>[];
  for (final friendship in friendships) {
    final profile = byId[friendship.friendId];
    if (profile == null) continue;
    final row = FriendRow(friendship: friendship, profile: profile);
    switch (friendship.status) {
      case 'accepted':
        accepted.add(row);
      case 'pending_in':
        incoming.add(row);
      case 'pending_out':
        outgoing.add(row);
    }
  }
  return (accepted: accepted, incoming: incoming, outgoing: outgoing);
});

final myFriendCodeProvider = FutureProvider.autoDispose<String?>((ref) async {
  final userId = ref.watch(authStateProvider).asData?.value.session?.user.id;
  if (userId == null) return null;
  final row = await ref
      .watch(supabaseClientProvider)
      .from('profiles')
      .select('friend_code')
      .eq('id', userId)
      .maybeSingle();
  return row?['friend_code'] as String?;
});
