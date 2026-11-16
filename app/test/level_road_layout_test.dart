import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/assets/game_assets.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/features/hero/level_road_screen.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('level road cards fit without overflow at $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            levelRoadProvider.overrideWith((ref) async => const LevelRoadData(
                  level: 12,
                  xpTotal: 2000,
                  skinId: 'starter',
                  backgroundId: 'starter',
                  frameId: 'apprentice',
                  body: BodyType.a,
                  rows: [
                    LevelRoadRow(level: 10, reached: true, rewards: [
                      RoadReward(
                        type: 'item',
                        id: 'gear_armour_patched_jacket',
                        name: 'Patched Jacket',
                        itemType: 'gear',
                        slot: 'armour',
                        rarity: 'common',
                      ),
                    ]),
                    LevelRoadRow(level: 12, reached: true, rewards: [
                      RoadReward(type: 'item', id: 'frame_silver_quill', name: 'Silver Quill', itemType: 'frame', rarity: 'rare'),
                    ]),
                    LevelRoadRow(level: 20, reached: false, rewards: [
                      RoadReward(
                        type: 'item',
                        id: 'gear_weapon_ink_nib_dagger',
                        name: 'Ink Nib Dagger',
                        itemType: 'gear',
                        slot: 'weapon',
                        rarity: 'rare',
                      ),
                    ]),
                    LevelRoadRow(level: 25, reached: false, rewards: [
                      RoadReward(
                        type: 'item',
                        id: 'gear_armour_scholar_coat',
                        name: 'Scholar Coat',
                        itemType: 'gear',
                        slot: 'armour',
                        rarity: 'rare',
                      ),
                      RoadReward(type: 'title', id: 'title_adept', name: 'Adept'),
                    ]),
                    LevelRoadRow(level: 50, reached: false, rewards: [
                      RoadReward(
                        type: 'item',
                        id: 'gear_weapon_deadline_breaker',
                        name: 'Deadline Breaker',
                        itemType: 'gear',
                        slot: 'weapon',
                        rarity: 'legendary',
                      ),
                      RoadReward(type: 'item', id: 'skin_awakened', name: 'Awakened', itemType: 'skin', rarity: 'epic'),
                      RoadReward(type: 'title', id: 'title_fully_awakened', name: 'Fully Awakened'),
                    ]),
                  ],
                )),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const LevelRoadScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final scrollable = find.byType(Scrollable).last;
      await tester.drag(scrollable, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
