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
    this.reconnecting = false,
  });

  final Raid raid;
  final List<RaidMember> members;
  final List<RaidEvent> events;
  final Set<String> focusingIds;
  final bool isCreator;
  final bool reconnecting;

  RaidDetailSnapshot copyWith({bool? reconnecting}) {
    return RaidDetailSnapshot(
      raid: raid,
      members: members,
      events: events,
      focusingIds: focusingIds,
      isCreator: isCreator,
      reconnecting: reconnecting ?? this.reconnecting,
    );
  }
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

  var reconnecting = false;
  RaidDetailSnapshot? lastGood;
  final memberIds = <String>{};

  Future<RaidDetailSnapshot?> load() async {
    final snap = await loadRaidDetail(client, raidId, myId);
    if (snap != null) {
      memberIds
        ..clear()
        ..addAll(snap.members.map((m) => m.userId));
      lastGood = snap.copyWith(reconnecting: reconnecting);
      return lastGood;
    }
    return lastGood?.copyWith(reconnecting: reconnecting);
  }

  try {
    yield await load();
  } catch (_) {
    yield null;
  }

  final controller = StreamController<RaidDetailSnapshot?>();
  ref.onDispose(controller.close);

  var loadSeq = 0;
  Future<void> push() async {
    final seq = ++loadSeq;
    try {
      final snap = await load();
      if (seq != loadSeq || controller.isClosed) return;
      controller.add(snap);
    } catch (_) {
      if (seq != loadSeq || controller.isClosed) return;
      reconnecting = true;
      if (lastGood != null) {
        controller.add(lastGood!.copyWith(reconnecting: true));
      }
    }
  }

  RealtimeChannel? channel;
  var channelGeneration = 0;

  void attachChannel() {
    final gen = ++channelGeneration;
    final name = 'raid-$raidId-$gen';
    final previous = channel;
    if (previous != null) {
      client.removeChannel(previous);
    }
    channel = client
        .channel(name)
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
          callback: (payload) {
            // Hotspot: ignore friend heartbeats outside this raid's party.
            final row = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
            final uid = row['user_id'];
            if (uid is String && memberIds.contains(uid)) push();
          },
        )
        .subscribe((status, [_]) {
          if (gen != channelGeneration) return;
          final ok = status == RealtimeSubscribeStatus.subscribed;
          reconnecting = !ok;
          push();
          if (!ok &&
              (status == RealtimeSubscribeStatus.timedOut ||
                  status == RealtimeSubscribeStatus.channelError ||
                  status == RealtimeSubscribeStatus.closed)) {
            // Re-open the channel so live HP/ticker recover after a hotspot blip.
            Future<void>.delayed(const Duration(seconds: 2), () {
              if (gen != channelGeneration || controller.isClosed) return;
              attachChannel();
            });
          }
        });
  }

  attachChannel();
  ref.onDispose(() {
    channelGeneration++;
    final current = channel;
    if (current != null) client.removeChannel(current);
  });

  final ticker = Timer.periodic(const Duration(seconds: 30), (_) => push());
  ref.onDispose(ticker.cancel);

  yield* controller.stream;
});
