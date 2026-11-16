import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/data/models/friendship.dart';
import 'package:questline/data/models/presence.dart';
import 'package:questline/data/models/profile.dart';
import 'package:questline/features/social/friends_screen.dart';
import 'package:questline/features/social/providers/friends_providers.dart';
import 'package:questline/features/social/providers/presence_providers.dart';

FriendRow _row(String id, String name, String status) => FriendRow(
      friendship: Friendship(userId: 'me', friendId: id, status: status, since: DateTime(2026)),
      profile: Profile(
        id: id,
        username: '${name.toLowerCase()}_1234',
        friendCode: 'AB12CD34',
        displayName: name,
        bodyType: 'a',
        level: 12,
        equippedSkinId: 'skin_starter',
        equippedBackgroundId: 'bg_starter',
        equippedFrameId: 'frame_apprentice',
        pinnedBadges: const [],
        hideRadar: false,
        showBossNames: true,
        createdAt: DateTime(2026),
      ),
    );

void main() {
  testWidgets('friends shows your code, requests, friends and the add sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (c, s) => const FriendsScreen())]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        myFriendCodeProvider.overrideWith((ref) async => 'QL7K2P9X'),
        focusingFriendsProvider.overrideWith((ref) => Stream.value({
              'f1': Presence(userId: 'f1', state: 'focusing', lastSeen: DateTime.now()),
            })),
        friendRowsProvider.overrideWith((ref) async => (
              accepted: [_row('f1', 'Tharaka', 'accepted')],
              incoming: [_row('f2', 'Sanu', 'pending_in')],
              outgoing: [_row('f3', 'Pasindu', 'pending_out')],
            )),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('QL7K2P9X'), findsOneWidget);
    expect(find.text('Sanu'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Focusing now'), findsOneWidget);
    expect(find.text('Requested'), findsOneWidget);

    await tester.tap(find.text('Username'));
    await tester.pumpAndSettle();
    expect(find.text('Add by username'), findsOneWidget);
    await tester.tap(find.text('Send request'));
    await tester.pump();
    expect(find.text('Enter a username or friend code.'), findsOneWidget);
  });
}
