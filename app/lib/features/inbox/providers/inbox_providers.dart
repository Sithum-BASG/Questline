import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/inbox_message.dart';
import '../../home/providers/home_providers.dart';

class InboxRepository {
  InboxRepository(this._client);

  final SupabaseClient _client;

  Future<List<InboxMessage>> list() async {
    final rows = await _client
        .from('inbox')
        .select('id, user_id, type, payload, created_at, read_at')
        .order('created_at', ascending: false)
        .limit(50);
    return [
      for (final row in rows) InboxMessage.fromJson(Map<String, dynamic>.from(row as Map)),
    ];
  }

  Future<int> unreadCount() async {
    final rows = await _client.from('inbox').select('id').isFilter('read_at', null);
    return (rows as List).length;
  }

  Future<void> markRead(String id) async {
    await _client.from('inbox').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
  }

  Future<void> markAllRead(List<String> ids) async {
    if (ids.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('inbox').update({'read_at': now}).inFilter('id', ids);
  }
}

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(ref.watch(supabaseClientProvider));
});

/// Live inbox list while the screen (or shell) is subscribed.
final inboxMessagesProvider = StreamProvider.autoDispose<List<InboxMessage>>((ref) async* {
  final repo = ref.watch(inboxRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);

  yield await repo.list();

  final controller = StreamController<List<InboxMessage>>();
  ref.onDispose(controller.close);

  final channel = client
      .channel('inbox-live')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'inbox',
        callback: (_) async {
          if (!controller.isClosed) controller.add(await repo.list());
        },
      )
      .subscribe();
  ref.onDispose(() => client.removeChannel(channel));

  yield* controller.stream;
});

/// Unread count with realtime — drives the Home bell badge.
final unreadInboxCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final repo = ref.watch(inboxRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);

  yield await repo.unreadCount();

  final controller = StreamController<int>();
  ref.onDispose(controller.close);

  final channel = client
      .channel('inbox-unread')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'inbox',
        callback: (_) async {
          if (!controller.isClosed) controller.add(await repo.unreadCount());
        },
      )
      .subscribe();
  ref.onDispose(() => client.removeChannel(channel));

  yield* controller.stream;
});

Future<void> markInboxRead(WidgetRef ref, String id) async {
  await ref.read(inboxRepositoryProvider).markRead(id);
  ref.invalidate(homeSnapshotProvider);
}
