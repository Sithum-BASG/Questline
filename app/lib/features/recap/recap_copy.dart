/// One swipe card in the weekly recap.
class RecapCardData {
  const RecapCardData({
    required this.title,
    required this.body,
    this.isClaim = false,
  });

  final String title;
  final String body;
  final bool isClaim;
}

/// Parsed fields from an inbox `weekly_results` payload.
class WeeklyResultsPayload {
  const WeeklyResultsPayload({
    required this.weekId,
    required this.rawXp,
    required this.targetHit,
    required this.targetCoins,
    required this.activeFriends,
    required this.rank,
    required this.rankCoins,
    required this.specialItem,
    required this.guildQuestCoins,
    required this.intellect,
    required this.vitality,
    required this.craft,
    required this.charisma,
    required this.bestDay,
    required this.bestDayXp,
    required this.bossesBeaten,
  });

  factory WeeklyResultsPayload.fromJson(Map<String, dynamic> json) {
    int asInt(Object? value) => value is num ? value.toInt() : 0;
    return WeeklyResultsPayload(
      weekId: json['weekId'] as String? ?? '',
      rawXp: asInt(json['rawXp']),
      targetHit: json['targetHit'] == true,
      targetCoins: asInt(json['targetCoins']),
      activeFriends: asInt(json['activeFriends']),
      rank: json['rank'] is num ? (json['rank'] as num).toInt() : null,
      rankCoins: asInt(json['rankCoins']),
      specialItem: json['specialItem'] as String?,
      guildQuestCoins: asInt(json['guildQuestCoins']),
      intellect: asInt(json['intellect']),
      vitality: asInt(json['vitality']),
      craft: asInt(json['craft']),
      charisma: asInt(json['charisma']),
      bestDay: json['bestDay'] as String?,
      bestDayXp: asInt(json['bestDayXp']),
      bossesBeaten: asInt(json['bossesBeaten']),
    );
  }

  final String weekId;
  final int rawXp;
  final bool targetHit;
  final int targetCoins;
  final int activeFriends;
  final int? rank;
  final int rankCoins;
  final String? specialItem;
  final int guildQuestCoins;
  final int intellect;
  final int vitality;
  final int craft;
  final int charisma;
  final String? bestDay;
  final int bestDayXp;
  final int bossesBeaten;

  int get totalCoins => targetCoins + rankCoins + guildQuestCoins;
}

String _ordinal(int place) {
  final mod100 = place % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${place}th';
  return switch (place % 10) {
    1 => '${place}st',
    2 => '${place}nd',
    3 => '${place}rd',
    _ => '${place}th',
  };
}

String _specialLabel(String? id) {
  if (id == null) return '';
  return id.replaceAll('_', ' ');
}

/// Story-style cards: XP → stats → best day → bosses → rank → claim.
List<RecapCardData> buildRecapCards(WeeklyResultsPayload data) {
  final cards = <RecapCardData>[
    RecapCardData(
      title: 'This week',
      body: data.rawXp == 0
          ? 'No verified XP this week — a fresh board is ready.'
          : '${data.rawXp} raw XP verified.',
    ),
    RecapCardData(
      title: 'Stat split',
      body:
          'Intellect ${data.intellect} · Vitality ${data.vitality} · Craft ${data.craft} · Charisma ${data.charisma}',
    ),
    RecapCardData(
      title: 'Best day',
      body: data.bestDay == null
          ? 'No standout day yet.'
          : '${data.bestDay} · ${data.bestDayXp} raw XP.',
    ),
    RecapCardData(
      title: 'Bosses',
      body: data.bossesBeaten == 0
          ? 'No bosses defeated this week.'
          : data.bossesBeaten == 1
              ? '1 boss defeated.'
              : '${data.bossesBeaten} bosses defeated.',
    ),
  ];

  if (data.rank != null) {
    final item = data.specialItem != null ? ' Plus a ${_specialLabel(data.specialItem)}.' : '';
    cards.add(
      RecapCardData(
        title: 'Leaderboard',
        body: 'You placed ${_ordinal(data.rank!)} among friends (+${data.rankCoins} coins).$item',
      ),
    );
  } else if (!data.targetHit) {
    cards.add(
      const RecapCardData(
        title: 'Leaderboard',
        body: 'Reach 500 raw XP next week to unlock rank rewards.',
      ),
    );
  } else {
    cards.add(
      RecapCardData(
        title: 'Leaderboard',
        body: data.activeFriends < 4
            ? 'Need 4 active friends on the board for rank rewards. Weekly target: +${data.targetCoins} coins.'
            : 'Weekly target hit (+${data.targetCoins} coins).',
      ),
    );
  }

  if (data.guildQuestCoins > 0) {
    cards.add(
      RecapCardData(
        title: 'Guild quest',
        body: 'Your guild cleared the week · +${data.guildQuestCoins} coins.',
      ),
    );
  }

  final coinLine = data.totalCoins > 0
      ? '${data.totalCoins} coins are already in your pouch.'
      : 'No coin rewards this week — next Monday is a new shot.';
  cards.add(
    RecapCardData(
      title: 'Claim',
      body: coinLine,
      isClaim: true,
    ),
  );
  return cards;
}
