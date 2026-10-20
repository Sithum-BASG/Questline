import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/reward_overlay.dart';
import 'package:questline/features/chests/chest_open_screen.dart';

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

  testWidgets('chest open shows Claim after reduced-motion fade', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChestOpenScreen(
          result: {
            'rarity': 'rare',
            'drop': {'kind': 'consumable', 'id': 'focus_potion'},
          },
        ),
      ),
    );
    // Force settle by pumping entrance; overlay may not have forceReducedMotion.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(find.text('Claim'), findsOneWidget);
    expect(find.text('LOOT'), findsOneWidget);
  });
}
