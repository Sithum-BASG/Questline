import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Presence;

import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/presence.dart';
import '../../../data/models/raid.dart';
import '../../../data/models/raid_event.dart';
import '../../../data/models/raid_member.dart';
import '../../social/providers/presence_providers.dart';

class RaidDetailSnapshot {
  const RaidDetailSnapshot({
    required this.raid,
    required this.members,
    required this.events,
    required this.focusingIds,
    required this.isCreator,
  });

  final Raid raid;
  final List<RaidMember> members;
  final List<RaidEvent> events;
  final Set<String> focusingIds;
  final bool isCreator;
}

Future<RaidDetailSnapshot?> loadRaidDetail(SupabaseClient client, String raidId, String? myId) async {
  final row = await client.from('raids').select().eq('id', raidId).maybeSingle();
  if (row == null) return null;
  final raid = Raid.fromJson(Map<String, dynamic>.from(row));

  final memberRows = await client.from('raid_members').select().eq('raid_id', raidId).order('joined_at');
  final members = [
    for (final m in memberRows) RaidMember.fromJson(Map<String, dynamic>.from(m as Map)),
  ];

  final eventRows = await client
      .from('raid_events')
      .select()
      .eq('raid_id', raidId)
      .order('at', ascending: false)
      .limit(20);
  final events = [
    for (final e in eventRows) RaidEvent.fromJson(Map<String, dynamic>.from(e as Map)),
  ];

  final ids = members.map((m) => m.userId).toList();
  final focusing = <String>{};
  if (ids.isNotEmpty) {
    final presenceRows = await client.from('presence').select().inFilter('user_id', ids);
    final now = DateTime.now().toUtc();
    for (final p in presenceRows) {
      final presence = Presence.fromJson(Map<String, dynamic>.from(p as Map));
      if (isFocusingNow(presence, now)) focusing.add(presence.userId);
    }
  }

  return RaidDetailSnapshot(
    raid: raid,
    members: members,
    events: events,
    focusingIds: focusing,
    isCreator: myId != null && raid.createdBy == myId,
  );
}

/// Live raid detail: HP, members, ticker via Realtime.
final raidDetailProvider = StreamProvider.autoDispose.family<RaidDetailSnapshot?, String>((ref, raidId) async* {
  final client = ref.watch(supabaseClientProvider);
  final myId = ref.watch(authStateProvider).asData?.value.session?.user.id;

  Future<RaidDetailSnapshot?> load() => loadRaidDetail(client, raidId, myId);

  yield await load();

  final controller = StreamController<RaidDetailSnapshot?>();
  ref.onDispose(controller.close);

  void push() async {
    if (!controller.isClosed) controller.add(await load());
  }

  final channel = client
      .channel('raid-$raidId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'raids',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: raidId),
        callback: (_) => push(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'raid_members',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'raid_id', value: raidId),
        callback: (_) => push(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'raid_events',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'raid_id', value: raidId),
        callback: (_) => push(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'presence',
        callback: (_) => push(),
      )
      .subscribe();
  ref.onDispose(() {
    client.removeChannel(channel);
  });

  final ticker = Timer.periodic(const Duration(seconds: 30), (_) => push());
  ref.onDispose(ticker.cancel);

  yield* controller.stream;
});
