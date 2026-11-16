import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/supabase/supabase_providers.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/data/models/raid.dart';
import 'package:questline/data/models/raid_event.dart';
import 'package:questline/data/models/raid_member.dart';
import 'package:questline/features/raids/providers/raid_detail_providers.dart';
import 'package:questline/features/raids/raid_detail_screen.dart';
import 'package:questline/features/raids/raid_invite_screen.dart';
import 'package:questline/features/raids/raid_results_screen.dart';
import 'package:questline/features/raids/raid_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _rules = RaidRules(
  fairShareRatio: 0.5,
  narrowThreshold: 0.75,
  victoryBonus: 0.25,
  escapePenalty: 100,
  tiers: [('minion', 4, 100), ('brute', 12, 150), ('warlord', 25, 200), ('titan', 999, 300)],
  maxFights: 15,
  partyMin: 2,
  partyMax: 8,
  guildMax: 10,
);

Raid _raid(String status) => Raid(
      id: 'r1',
      source: 'party',
      name: 'The Endless Slideshow',
      title: 'Group project',
      type: 'project',
      tier: 'titan',
      perPersonMinutes: 480,
      participants: 4,
      maxHp: 1920,
      damage: status == 'victory' ? 1920 : status == 'escaped' ? 1200 : 690,
      deadline: DateTime.now().add(const Duration(days: 4, hours: 2)),
      status: status,
      createdBy: 'me',
      inviteCode: 'K7Q4MXB2',
      coinsEligible: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );

RaidMember _m(String id, String name, String skin, String body, {bool met = false, bool mvp = false}) => RaidMember(
      raidId: 'r1',
      userId: id,
      displayName: name,
      skinId: skin,
      bodyType: body,
      joinedAt: DateTime.now(),
      leftRaid: false,
      metFairShare: met,
      isMvp: mvp,
    );

final _members = [
  _m('me', 'Amaya', 'skin_chronomancer', 'b', met: true, mvp: true),
  _m('u2', 'Ama', 'skin_starweaver', 'b', met: true),
  _m('u3', 'Kavin', 'skin_elfwarden', 'a'),
  _m('u4', 'Nethmi', 'skin_sunscholar', 'b', met: true),
];

final _events = [
  RaidEvent(id: 1, raidId: 'r1', userId: 'u2', displayName: 'Ama', amount: 45, at: DateTime.now().subtract(const Duration(minutes: 2))),
  RaidEvent(id: 2, raidId: 'r1', userId: 'me', displayName: 'Amaya', amount: 60, at: DateTime.now().subtract(const Duration(hours: 1))),
  RaidEvent(id: 3, raidId: 'r1', userId: 'u4', displayName: 'Nethmi', amount: 30, at: DateTime.now().subtract(const Duration(days: 1))),
];

Future<void> _pump(WidgetTester tester, Widget screen, {List<RaidMember>? members, List overrides = const []}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => screen)]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      raidRulesProvider.overrideWith((ref) async => _rules),
      authStateProvider.overrideWith((ref) => const Stream<AuthState>.empty()),
      raidDetailProvider.overrideWith((ref, id) => Stream.value(RaidDetailSnapshot(
            raid: _raid('active'),
            members: members ?? _members,
            events: _events,
            focusingIds: const {'u2'},
            isCreator: false,
            myId: 'me',
            damageByUser: const {'me': 310},
          ))),
      ...overrides.cast(),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('raid detail shows the party, the log and Attack', (tester) async {
    await _pump(tester, const RaidDetailScreen(raidId: 'r1'));
    expect(find.text('The Endless Slideshow'), findsOneWidget);
    expect(find.text('PARTY RAID'), findsOneWidget);
    expect(find.text('Party · 4'), findsOneWidget);
    expect(find.text('Fair share: 240 damage'), findsOneWidget);
    expect(find.text('1 focusing now'), findsOneWidget);
    expect(find.text('Attack'), findsOneWidget);
    // Exact damage only for yourself; others show the share check.
    expect(find.text('310'), findsOneWidget);
    expect(find.text('Share met'), findsNWidgets(2));
    expect(find.text('Fighting'), findsOneWidget);
    expect(find.text('Battle log'), findsOneWidget);
  });

  testWidgets('invite shows the code and open seats', (tester) async {
    await _pump(tester, const RaidInviteScreen(raidId: 'r1'), members: _members.take(2).toList());
    expect(find.text('Invite your party'), findsOneWidget);
    expect(find.text('K'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Waiting'), findsNWidgets(2));
    expect(find.text('Share invite'), findsOneWidget);
  });

  testWidgets('results show loot, the escape penalty and the MVP', (tester) async {
    await _pump(
      tester,
      const RaidResultsScreen(raidId: 'r1'),
      overrides: [
        raidResultsProvider.overrideWith((ref, id) async => RaidResultsSnapshot(
              raid: _raid('escaped'),
              members: _members,
              damageByUser: const {'me': 620, 'u2': 560, 'u3': 200, 'u4': 470},
              isCreator: true,
              friendIds: const {'u2'},
            )),
      ],
    );
    expect(find.text('ESCAPED'), findsOneWidget);
    expect(find.text('Under 75%: no loot'), findsOneWidget);
    expect(find.text('−100'), findsOneWidget);
    expect(find.text('penalty'), findsOneWidget);
    expect(find.text('Amaya is the MVP'), findsOneWidget);
  });
}
