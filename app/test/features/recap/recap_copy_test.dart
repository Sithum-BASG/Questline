import 'package:flutter_test/flutter_test.dart';
import 'package:questline/features/recap/recap_copy.dart';

void main() {
  test('buildRecapCards covers XP, split, rank and claim', () {
    final cards = buildRecapCards(
      WeeklyResultsPayload.fromJson({
        'weekId': '2026-W41',
        'rawXp': 800,
        'targetHit': true,
        'targetCoins': 200,
        'activeFriends': 4,
        'rank': 2,
        'rankCoins': 200,
        'specialItem': 'focus_potion',
        'guildQuestCoins': 100,
        'intellect': 200,
        'vitality': 200,
        'craft': 200,
        'charisma': 200,
        'bestDay': '2026-10-08',
        'bestDayXp': 300,
        'bossesBeaten': 2,
      }),
    );

    expect(cards.first.body, contains('800 raw XP'));
    expect(cards.any((c) => c.title == 'Stat split'), true);
    expect(cards.any((c) => c.body.contains('2nd')), true);
    expect(cards.any((c) => c.body.contains('focus potion')), true);
    expect(cards.any((c) => c.title == 'Guild quest'), true);
    expect(cards.last.isClaim, true);
    expect(cards.last.body, contains('500 coins'));
  });

  test('missed target nudges toward 500 XP', () {
    final cards = buildRecapCards(
      const WeeklyResultsPayload(
        weekId: '2026-W41',
        rawXp: 120,
        targetHit: false,
        targetCoins: 0,
        activeFriends: 0,
        rank: null,
        rankCoins: 0,
        specialItem: null,
        guildQuestCoins: 0,
        intellect: 30,
        vitality: 30,
        craft: 30,
        charisma: 30,
        bestDay: null,
        bestDayXp: 0,
        bossesBeaten: 0,
      ),
    );
    expect(cards.any((c) => c.body.contains('500 raw XP')), true);
    expect(cards.last.body.contains('No coin rewards'), true);
  });
}
