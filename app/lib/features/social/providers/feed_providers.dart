import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/activity_event.dart';
import '../feed_copy.dart';

const feedPageSize = 20;

/// The look of the friend behind a feed row, for their framed portrait.
class FeedActor {
  const FeedActor({
    required this.name,
    this.skinId = 'starter',
    this.backgroundId = 'starter',
    this.frameId = 'apprentice',
    this.bodyType = 'a',
  });

  final String name;
  final String skinId;
  final String backgroundId;
  final String frameId;
  final String bodyType;
}

class FeedItem {
  const FeedItem({
    required this.event,
    required this.line,
    required this.actorName,
    this.actor,
  });

  final ActivityEvent event;
  final String line;
  final String actorName;
  final FeedActor? actor;
}

class FeedPage {
  const FeedPage({
    required this.items,
    required this.hasMore,
  });

  final List<FeedItem> items;
  final bool hasMore;
}

String _short(Object? id, String prefix, String fallback) {
  if (id is! String || id.isEmpty) return fallback;
  return id.startsWith(prefix) ? id.substring(prefix.length) : id;
}

final feedPageProvider =
    FutureProvider.autoDispose.family<FeedPage, int>((ref, pageIndex) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final from = pageIndex * feedPageSize;
  final to = from + feedPageSize - 1;

  final rows = await client
      .from('activity_events')
      .select()
      .order('created_at', ascending: false)
      .range(from, to);

  final events = [
    for (final row in rows) ActivityEvent.fromJson(Map<String, dynamic>.from(row as Map)),
  ];

  if (events.isEmpty) {
    return const FeedPage(items: [], hasMore: false);
  }

  final actorIds = events.map((e) => e.actorId).toSet().toList();
  final profiles = await client
      .from('profiles')
      .select('id, display_name, equipped_skin_id, equipped_background_id, equipped_frame_id, body_type')
      .inFilter('id', actorIds);
  final actors = <String, FeedActor>{
    for (final row in profiles)
      row['id'] as String: FeedActor(
        name: row['display_name'] as String? ?? 'A friend',
        skinId: _short(row['equipped_skin_id'], 'skin_', 'starter'),
        backgroundId: _short(row['equipped_background_id'], 'bg_', 'starter'),
        frameId: _short(row['equipped_frame_id'], 'frame_', 'apprentice'),
        bodyType: row['body_type'] as String? ?? 'a',
      ),
  };

  final items = [
    for (final event in events)
      FeedItem(
        event: event,
        actor: actors[event.actorId],
        actorName: actors[event.actorId]?.name ?? 'A friend',
        line: activityFeedLine(
          actorName: actors[event.actorId]?.name ?? 'A friend',
          type: event.type,
          payload: event.payload,
        ),
      ),
  ];

  return FeedPage(items: items, hasMore: events.length >= feedPageSize);
});
