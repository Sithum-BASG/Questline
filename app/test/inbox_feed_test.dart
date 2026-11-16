import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/data/models/activity_event.dart';
import 'package:questline/data/models/friendship.dart';
import 'package:questline/data/models/inbox_message.dart';
import 'package:questline/data/models/profile.dart';
import 'package:questline/features/inbox/inbox_screen.dart';
import 'package:questline/features/inbox/providers/inbox_providers.dart';
import 'package:questline/features/social/feed_screen.dart';
import 'package:questline/features/social/providers/feed_providers.dart';
import 'package:questline/features/social/providers/friends_providers.dart';

final _now = DateTime.now();

FriendRow _incoming(String id) => FriendRow(
      friendship: Friendship(userId: 'me', friendId: id, status: 'pending_in', since: DateTime(2026)),
      profile: Profile(
        id: id,
        username: 'sanu_1234',
        friendCode: 'AB12CD34',
        displayName: 'Sanu',
        bodyType: 'b',
        level: 7,
        equippedSkinId: 'skin_starter',
        equippedBackgroundId: 'bg_starter',
        equippedFrameId: 'frame_apprentice',
        pinnedBadges: const [],
        hideRadar: false,
        showBossNames: true,
        createdAt: DateTime(2026),
      ),
    );

Widget _app(Widget screen, List overrides) {
  final router = GoRouter(routes: [GoRoute(path: '/', builder: (c, s) => screen)]);
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

void main() {
  testWidgets('inbox shows new and earlier rows with their actions', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const InboxScreen(), [
      inboxMessagesProvider.overrideWith((ref) => Stream.value([
            InboxMessage(
              id: '1',
              userId: 'me',
              type: 'weekly_results',
              payload: const {'weekId': '2026-W46', 'rank': 3, 'activeFriends': 7, 'rankCoins': 250},
              createdAt: _now,
            ),
            InboxMessage(
              id: '2',
              userId: 'me',
              type: 'friend_request',
              payload: const {'fromUid': 'u2', 'displayName': 'Sanu'},
              createdAt: _now,
            ),
            InboxMessage(
              id: '3',
              userId: 'me',
              type: 'raid_result',
              payload: const {'result': 'victory', 'name': 'The Endless Slideshow', 'coins': 375},
              createdAt: _now.subtract(const Duration(days: 2)),
              readAt: _now,
            ),
          ])),
      friendRowsProvider.overrideWith((ref) async => (accepted: <FriendRow>[], incoming: [_incoming('u2')], outgoing: <FriendRow>[])),
    ]));
    await tester.pump();
    await tester.pump();

    expect(find.text('Mark all read'), findsOneWidget);
    expect(find.text('See your recap'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.textContaining('You finished #3 of 8 and earned 250 coins.'), findsOneWidget);
    expect(find.textContaining('Victory, +375 coins'), findsOneWidget);
  });

  testWidgets('feed groups friends milestones by day', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    FeedItem item(String type, Map<String, dynamic> payload, Duration ago, String name) => FeedItem(
          event: ActivityEvent(id: name, actorId: name, type: type, payload: payload, visibleTo: const [], createdAt: _now.subtract(ago)),
          line: '',
          actorName: name,
          actor: FeedActor(name: name),
        );
    await tester.pumpWidget(_app(const FeedScreen(), [
      feedPageProvider.overrideWith((ref, page) async => FeedPage(hasMore: false, items: [
            item('level_up', const {'level': 16}, Duration.zero, 'Ravi'),
            item('chest_drop', const {'rarity': 'epic'}, const Duration(days: 5), 'Tharaka'),
          ])),
    ]));
    await tester.pump();
    await tester.pump();

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('EARLIER'), findsOneWidget);
    expect(find.textContaining('reached'), findsOneWidget);
    expect(find.textContaining('Epic loot'), findsOneWidget);
    expect(find.text('Only milestones show here. Quest titles are never shared.'), findsOneWidget);
  });
}
