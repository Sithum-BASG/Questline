import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../data/models/activity_event.dart';
import '../feed_copy.dart';

const feedPageSize = 20;

class FeedItem {
  const FeedItem({
    required this.event,
    required this.line,
    required this.actorName,
  });

  final ActivityEvent event;
  final String line;
  final String actorName;
}

class FeedPage {
  const FeedPage({
    required this.items,
    required this.hasMore,
  });

  final List<FeedItem> items;
  final bool hasMore;
}

final feedPageProvider =
    FutureProvider.autoDispose.family<FeedPage, int>((ref, pageIndex) async {
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
  final profiles = await client.from('profiles').select('id, display_name').inFilter('id', actorIds);
  final names = <String, String>{
    for (final row in profiles) row['id'] as String: row['display_name'] as String,
  };

  final items = [
    for (final event in events)
      FeedItem(
        event: event,
        actorName: names[event.actorId] ?? 'A friend',
        line: activityFeedLine(
          actorName: names[event.actorId] ?? 'A friend',
          type: event.type,
          payload: event.payload,
        ),
      ),
  ];

  return FeedPage(items: items, hasMore: events.length >= feedPageSize);
});
