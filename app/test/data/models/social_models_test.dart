import 'package:flutter_test/flutter_test.dart';
import 'package:questline/data/models/friendship.dart';
import 'package:questline/data/models/inbox_message.dart';
import 'package:questline/data/models/presence.dart';
import 'package:questline/data/models/raid.dart';

void main() {
  test('social models round-trip snake_case json', () {
    final friendship = Friendship.fromJson({
      'user_id': '11111111-1111-1111-1111-111111111111',
      'friend_id': '22222222-2222-2222-2222-222222222222',
      'status': 'accepted',
      'since': '2026-10-10T04:00:00.000Z',
    });
    expect(friendship.toJson()['friend_id'], friendship.friendId);

    final presence = Presence.fromJson({
      'user_id': friendship.userId,
      'state': 'idle',
      'stat': null,
      'started_at': null,
      'raid_id': null,
      'last_seen': '2026-10-10T04:00:00.000Z',
    });
    expect(presence.toJson()['last_seen'], isNotNull);

    final raid = Raid.fromJson({
      'id': '33333333-3333-3333-3333-333333333333',
      'source': 'party',
      'guild_id': null,
      'name': 'The Practice Shade',
      'title': 'Group revision',
      'type': 'project',
      'tier': 'minion',
      'per_person_minutes': 120,
      'participants': 2,
      'max_hp': 240,
      'damage': 0,
      'deadline': '2026-10-20T04:00:00.000Z',
      'status': 'active',
      'created_by': friendship.userId,
      'invite_code': 'PARTY01',
      'coins_eligible': true,
      'created_at': '2026-10-10T04:00:00.000Z',
    });
    expect(raid.toJson()['per_person_minutes'], 120);

    final message = InboxMessage.fromJson({
      'id': '44444444-4444-4444-4444-444444444444',
      'user_id': friendship.userId,
      'type': 'friend_request',
      'payload': {'from': 'ada'},
      'created_at': '2026-10-10T04:00:00.000Z',
      'read_at': null,
    });
    expect(message.toJson()['type'], 'friend_request');
  });
}
