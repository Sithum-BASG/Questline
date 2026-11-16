import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/hero/level_road_screen.dart';

void main() {
  test('level road labels coins and item ids', () {
    const row = LevelRoadRow(
      level: 25,
      reached: false,
      rewards: [
        RoadReward(type: 'item', id: 'gear_armour_scholar_coat', name: 'Scholar Coat', itemType: 'gear', slot: 'armour'),
        RoadReward(type: 'title', id: 'title_adept', name: 'Adept'),
      ],
    );
    expect(row.level, 25);
    expect(row.hasItem, isTrue);
    expect(row.label, 'Scholar Coat · Adept');
    expect(row.rewards.first.kind, 'ARMOUR');
    expect(const RoadReward(type: 'coins', amount: 150).label, '150 coins');
    expect(const RoadReward(type: 'item', id: 'frame_margin_notes').label, 'frame margin notes');
  });
}
