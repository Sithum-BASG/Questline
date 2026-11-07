import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Presence;

import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/presence.dart';
import 'friends_providers.dart';

const _staleSeconds = 120;

bool isFocusingNow(Presence row, DateTime now) {
  if (row.state != 'focusing') return false;
  return now.difference(row.lastSeen.toUtc()).inSeconds <= _staleSeconds;
}

/// Live focusing map for accepted friends. Realtime on presence; stale after 2 minutes.
final focusingFriendsProvider = StreamProvider.autoDispose<Map<String, Presence>>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  final friendships = await ref.watch(friendshipsProvider.future);
  final friendIds = friendships
      .where((row) => row.status == 'accepted')
      .map((row) => row.friendId)
      .toSet()
      .toList();
  if (friendIds.isEmpty) {
    yield <String, Presence>{};
    return;
  }

  Future<Map<String, Presence>> load() async {
    final rows = await client.from('presence').select().inFilter('user_id', friendIds);
    final now = DateTime.now().toUtc();
    final map = <String, Presence>{};
    for (final row in rows) {
      final presence = Presence.fromJson(Map<String, dynamic>.from(row as Map));
      if (isFocusingNow(presence, now)) map[presence.userId] = presence;
    }
    return map;
  }

  yield await load();

  final controller = StreamController<Map<String, Presence>>();
  ref.onDispose(controller.close);

  final channel = client
      .channel('focusing-friends')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'presence',
        callback: (_) async {
          if (!controller.isClosed) controller.add(await load());
        },
      )
      .subscribe();
  ref.onDispose(() {
    client.removeChannel(channel);
  });

  // Re-filter stale rows every 30 s without waiting for a heartbeat.
  final ticker = Timer.periodic(const Duration(seconds: 30), (_) async {
    if (!controller.isClosed) controller.add(await load());
  });
  ref.onDispose(ticker.cancel);

  yield* controller.stream;
});
