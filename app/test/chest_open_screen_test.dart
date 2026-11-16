import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/assets/game_assets.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/reward_overlay.dart';
import 'package:questline/features/chests/chest_open_screen.dart';
import 'package:questline/features/hero/wardrobe_screen.dart';

Widget _app(Map<String, dynamic> result, {List<WardrobeItem> items = const []}) {
  return ProviderScope(
    overrides: [
      wardrobeProvider.overrideWith((ref) async => WardrobeData(
            skinId: 'skin_starter',
            backgroundId: 'bg_starter',
            frameId: 'frame_apprentice',
            titleId: null,
            body: BodyType.a,
            items: items,
          )),
      legendaryPityProvider.overrideWith((ref) async => 30),
    ],
    child: MaterialApp(theme: AppTheme.light, home: ChestOpenScreen(result: result)),
  );
}

void main() {
  test('chest reveal maps a pouch drop to a loot moment', () {
    final moment = ChestOpenScreen.momentFromResult({
      'rarity': 'common',
      'drop': {'kind': 'pouch', 'coins': 100},
      'pityCounter': 1,
    });
    expect(moment.kind, RewardKind.loot);
    expect(moment.title, '+100 coins');
    expect(moment.rarity, 'common');
  });

  test('duplicate refund updates the subtitle', () {
    final moment = ChestOpenScreen.momentFromResult({
      'rarity': 'epic',
      'drop': {'kind': 'item', 'id': 'frame_cloister'},
      'refund': 200,
    });
    expect(moment.subtitle, 'Duplicate · +200 coins');
  });

  test('coins drop kind shows the refund amount as the title', () {
    final moment = ChestOpenScreen.momentFromResult({
      'rarity': 'mythic',
      'drop': {'kind': 'coins', 'coins': 500},
      'refund': 500,
    });
    expect(moment.title, '+500 coins');
    expect(moment.subtitle, 'Duplicate · +500 coins');
  });

  testWidgets('chest opens, then reveals the drop with Done', (tester) async {
    await tester.pumpWidget(_app({
      'rarity': 'rare',
      'pityCounter': 12,
      'drop': {'kind': 'consumable', 'id': 'focus_potion'},
    }));
    await tester.pump();
    expect(find.text('Tap to skip'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Focus Potion'), findsOneWidget);
    expect(find.text('RARE'), findsOneWidget);
    expect(find.text('12 / 30'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('tapping skips to the reveal; a cosmetic offers Equip now', (tester) async {
    await tester.pumpWidget(_app(
      {
        'rarity': 'epic',
        'pityCounter': 19,
        'drop': {'kind': 'item', 'id': 'bg_cloister'},
      },
      items: const [
        WardrobeItem(id: 'bg_cloister', name: 'Cloister', type: 'background', rarity: 'epic', source: 'chest', owned: true),
      ],
    ));
    await tester.pump();
    await tester.tap(find.text('Tap to skip'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Cloister'), findsOneWidget);
    expect(find.text('Equip now'), findsOneWidget);
    expect(find.text('NEW!'), findsOneWidget);
  });

  testWidgets('a coin pouch is collected', (tester) async {
    await tester.pumpWidget(_app({
      'rarity': 'common',
      'pityCounter': 5,
      'drop': {'kind': 'pouch', 'coins': 100},
    }));
    await tester.pump();
    await tester.tap(find.text('Tap to skip'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Coin pouch'), findsOneWidget);
    expect(find.text('Collect'), findsOneWidget);
    expect(find.text('Equip now'), findsNothing);
  });
}
