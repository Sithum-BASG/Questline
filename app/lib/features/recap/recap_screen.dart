import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/reward_field.dart';
import '../../core/widgets/reward_overlay.dart';
import '../../core/widgets/stat_icon.dart';
import 'providers/recap_providers.dart';
import 'recap_copy.dart';

const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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

String _thousands(int value) {
  final s = value.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return '${value < 0 ? '−' : ''}$out';
}

/// Five story cards for the week. Claim plays a reward moment; the coins were paid at the reset.
class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({super.key, required this.weekId});

  final String weekId;

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> {
  final _pages = PageController();
  var _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _claim(WeeklyResultsPayload data) {
    final queue = ref.read(rewardQueueProvider);
    final coins = data.totalCoins;
    queue.add([
      RewardMoment.loot(
        title: coins > 0 ? '+${_thousands(coins)} coins' : 'Week closed',
        subtitle: coins > 0 ? 'Weekly rewards are already in your pouch.' : 'A new leaderboard week has started.',
        coins: coins > 0 ? coins : null,
        eyebrow: 'Weekly rewards',
      ),
    ]);
    queue.next();
    if (mounted) context.go('/reward');
  }

  void _next() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    _pages.nextPage(
      duration: Duration(milliseconds: reduce ? 150 : 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recapProvider(widget.weekId));
    final extras = ref.watch(recapExtrasProvider(widget.weekId)).asData?.value;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load recap',
          body: 'Check your connection and try again.',
          actionLabel: 'Close',
          onAction: () => context.go('/home'),
        ),
        data: (payload) {
          if (payload == null) {
            return EmptyState(
              title: 'No recap yet',
              body: 'Weekly results show up here after the Monday reset.',
              actionLabel: 'Home',
              onAction: () => context.go('/home'),
            );
          }
          final cards = _cards(payload, extras);
          final last = _index >= cards.length - 1;
          final insets = MediaQuery.paddingOf(context);
          return Stack(
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: cards.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _CardView(card: cards[i]),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: insets.top + 9,
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Card ${_index + 1} of ${cards.length}',
                        excludeSemantics: true,
                        child: Row(
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              if (i > 0) const SizedBox(width: 5),
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: i < _index ? 1 : (i == _index ? 0.6 : 0),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      button: true,
                      label: 'Close',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white.withValues(alpha: 0.18),
                            border: Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: AppColors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: insets.bottom + 20,
                child: last
                    ? _ClaimButton(coins: payload.totalCoins, onPressed: () => _claim(payload))
                    : _NextButton(onPressed: _next),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Next',
      excludeSemantics: true,
      child: Clay(
        kind: ClayKind.teal,
        radius: 30,
        height: 60,
        onTap: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Next', style: AppText.button.copyWith(color: AppColors.white, fontSize: 17)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.coins, required this.onPressed});

  final int coins;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (coins <= 0) return QButton(label: 'Done', onPressed: onPressed);
    return Semantics(
      button: true,
      label: 'Claim ${_thousands(coins)} coins',
      excludeSemantics: true,
      child: Clay(
        kind: ClayKind.teal,
        radius: 30,
        height: 60,
        onTap: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Claim', style: AppText.button.copyWith(color: AppColors.white, fontSize: 17)),
            const SizedBox(width: 8),
            Image.asset(GameAssets.icon('coin'), width: 24, height: 24),
            const SizedBox(width: 4),
            Text(_thousands(coins), style: AppText.button.copyWith(color: AppColors.white, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}

/// One recap card: a coloured field with the headline, and a sheet that explains it.
class _Card {
  const _Card({
    required this.color,
    required this.kicker,
    required this.field,
    required this.label,
    required this.title,
    required this.body,
    this.extra,
    this.darkText = false,
  });

  final Color color;
  final String kicker;
  final Widget field;
  final String label;
  final String title;
  final String body;
  final Widget? extra;

  /// Light fields carry dark text.
  final bool darkText;
}

class _CardView extends StatelessWidget {
  const _CardView({required this.card});

  final _Card card;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final sheetTop = size.height * (500 / 844);
    final ink = card.darkText ? AppColors.tealDeep : AppColors.white;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: sheetTop + 60,
          child: RewardField(color: card.color, centre: const Alignment(0, -0.16)),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: insets.top + 61,
          child: Text(
            card.kicker,
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(
              fontSize: 11,
              height: 14 / 11,
              letterSpacing: 1.5,
              color: ink.withValues(alpha: 0.78),
            ),
          ),
        ),
        Positioned(left: 20, right: 20, top: insets.top + 86, bottom: size.height - sheetTop + 12, child: card.field),
        Positioned(
          left: 0,
          right: 0,
          top: sheetTop,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.14), offset: const Offset(0, -10), blurRadius: 30),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 30, 24, insets.bottom + 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.label,
                    style: AppText.label.copyWith(
                      fontSize: 11,
                      height: 14 / 11,
                      letterSpacing: 1.3,
                      color: AppColors.tealDeep,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(card.title, style: AppText.h1.copyWith(fontSize: 24, height: 30 / 24)),
                  const SizedBox(height: 6),
                  Text(
                    card.body,
                    style: AppText.body.copyWith(fontSize: 15, height: 22 / 15, color: AppColors.inkMuted),
                  ),
                  if (card.extra != null) ...[const SizedBox(height: 14), card.extra!],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<_Card> _cards(WeeklyResultsPayload d, RecapExtras? x) {
  final target = x?.targetXp ?? 500;
  return [_weekCard(d, x, target), _splitCard(d, x), _bestDayCard(d, x), _bossCard(d), _boardCard(d, x)];
}

_Card _weekCard(WeeklyResultsPayload d, RecapExtras? x, int target) {
  final monday = x?.monday ?? isoWeekMonday(d.weekId);
  final sunday = monday?.add(const Duration(days: 6));
  final range = monday == null || sunday == null
      ? ''
      : monday.month == sunday.month
      ? ' · ${monday.day}–${sunday.day} ${_months[sunday.month - 1]}'
      : ' · ${monday.day} ${_months[monday.month - 1]}–${sunday.day} ${_months[sunday.month - 1]}';
  final hit = d.targetHit || d.rawXp >= target;
  return _Card(
    color: AppColors.awakeningTeal,
    kicker: 'YOUR WEEK$range',
    field: Column(
      children: [
        Text(
          _thousands(d.rawXp),
          style: AppText.display.copyWith(fontSize: 76, height: 80 / 76, letterSpacing: -3, color: AppColors.white),
        ),
        Text('raw XP', style: AppText.h2.copyWith(fontSize: 17, color: AppColors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 20),
        Expanded(child: _DayBars(values: x?.dailyXp)),
      ],
    ),
    label: 'WEEKLY TARGET',
    title: hit ? 'You beat your weekly target' : (d.rawXp == 0 ? 'A quiet week' : 'Just short of your target'),
    body: hit
        ? '${_thousands(target)} XP was the goal. ${d.rawXp > target ? 'You went ${_thousands(d.rawXp - target)} past it.' : 'You hit it exactly.'}'
        : d.rawXp == 0
        ? 'No verified XP this week. A fresh week has started.'
        : '${_thousands(target - d.rawXp)} XP short of ${_thousands(target)}. Reach it next week to unlock rank rewards.',
    extra: hit
        ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (d.targetCoins > 0) _Chip(coins: d.targetCoins),
              const _Chip(text: 'Rank rewards unlocked'),
            ],
          )
        : null,
  );
}

_Card _splitCard(WeeklyResultsPayload d, RecapExtras? x) {
  final stats = [('intellect', d.intellect), ('vitality', d.vitality), ('craft', d.craft), ('charisma', d.charisma)];
  final total = stats.fold<int>(0, (sum, s) => sum + s.$2);
  final share = x?.balancedShare ?? 0.15;
  final sorted = [...stats]..sort((a, b) => b.$2.compareTo(a.$2));
  String pct(int v) => total == 0 ? '0%' : '${(v * 100 / total).round()}%';
  final balanced = total > 0 && stats.every((s) => s.$2 >= share * total);
  final weakest = sorted.last;
  final top = sorted.first;
  return _Card(
    color: AppColors.sceneMid,
    kicker: 'WHERE YOUR XP WENT',
    field: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (stat, value) in stats)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClayDot(
                      size: total == 0 ? 52 : 44 + 52 * value / math.max(1, top.$2),
                      gradient: statGradient(stat),
                      icon: StatIcon.iconFor(stat),
                      semanticLabel: StatIcon.labelFor(stat),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(pct(value), style: AppText.numbers.copyWith(fontSize: 19, color: AppColors.white)),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        StatIcon.labelFor(stat),
                        style: AppText.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.25), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (stat, value) in stats)
                    if (value > 0)
                      Expanded(
                        flex: value,
                        child: DecoratedBox(decoration: BoxDecoration(gradient: statGradient(stat))),
                      ),
                  if (total == 0) const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
    label: 'STAT SPLIT',
    title: total == 0 ? 'No XP to split yet' : (balanced ? 'Nicely balanced' : 'Mostly ${StatIcon.labelFor(top.$1)}'),
    body: total == 0
        ? 'Finish quests next week to see where your XP goes.'
        : '${StatIcon.labelFor(top.$1)} took ${pct(top.$2)} of your XP. ${StatIcon.labelFor(weakest.$1)} got the least at ${pct(weakest.$2)}.',
    extra: total == 0
        ? null
        : Well(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Balanced badge: ',
                    style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: balanced
                        ? 'every stat was at ${(share * 100).round()}% or more. This week counts.'
                        : 'needs every stat at ${(share * 100).round()}% or more. ${StatIcon.labelFor(weakest.$1)} is '
                              '${(share * 100 - weakest.$2 * 100 / total).ceil()}% short.',
                  ),
                ],
              ),
              style: AppText.bodySmall.copyWith(height: 18 / 13),
            ),
          ),
  );
}

_Card _bestDayCard(WeeklyResultsPayload d, RecapExtras? x) {
  final day = d.bestDay == null ? null : DateTime.tryParse(d.bestDay!);
  final daysMet = x?.daysMet;
  final minimum = x?.dailyMinimum ?? 40;
  final streak = x?.streak ?? 0;
  return _Card(
    color: AppColors.streakEmber,
    kicker: 'BEST DAY',
    field: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            day == null ? 'No best day' : _weekdays[day.weekday - 1],
            style: AppText.display.copyWith(fontSize: 64, height: 70 / 64, letterSpacing: -2, color: AppColors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day == null ? 'Every day starts fresh' : '${_thousands(d.bestDayXp)} XP',
          style: AppText.h2.copyWith(fontSize: 20, color: AppColors.white.withValues(alpha: 0.9)),
        ),
        const Spacer(),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withValues(alpha: 0.18),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 30, color: AppColors.white),
              Text(
                '$streak',
                style: AppText.display.copyWith(fontSize: 26, height: 28 / 26, color: AppColors.white),
              ),
              Text(
                'DAY STREAK',
                style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, color: AppColors.white),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    ),
    label: 'SHOWING UP',
    title: daysMet == null
        ? 'Keep showing up'
        : daysMet == 7
        ? 'Seven days out of seven'
        : '$daysMet ${daysMet == 1 ? 'day' : 'days'} out of seven',
    body: daysMet == null
        ? 'Your streak is $streak ${streak == 1 ? 'day' : 'days'}.'
        : 'You hit the $minimum XP daily minimum on $daysMet ${daysMet == 1 ? 'day' : 'days'}. '
              'Your streak is now $streak ${streak == 1 ? 'day' : 'days'}.',
  );
}

_Card _bossCard(WeeklyResultsPayload d) {
  final n = d.bossesBeaten;
  return _Card(
    color: AppColors.tealLight,
    darkText: true,
    kicker: 'BOSSES',
    field: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(left: 0, top: 10, child: _GreyBoss(tier: 'brute', size: 210, turn: -12)),
        Positioned(right: 0, top: 40, child: _GreyBoss(tier: 'warlord', size: 170, turn: 10)),
        Positioned(
          bottom: 4,
          child: Transform.rotate(
            angle: -4 * math.pi / 180,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.teal, AppColors.tealButtonEnd]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: AppColors.ink.withValues(alpha: 0.25), offset: const Offset(4, 8), blurRadius: 16),
                ],
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  n == 0 ? 'NONE THIS WEEK' : '$n DEFEATED',
                  style: AppText.title.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.4,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    label: 'BOSSES',
    title: n == 0 ? 'No bosses fell this week' : (n == 1 ? 'A boss fell' : '$n bosses fell'),
    body: n == 0
        ? 'Link quests to a deadline boss and every focused minute chips away at it.'
        : 'Every focused minute on a linked quest hit them. Keep it going next week.',
  );
}

_Card _boardCard(WeeklyResultsPayload d, RecapExtras? x) {
  final rows = <(String, int)>[
    if (d.targetHit && d.targetCoins > 0) ('Weekly target reached', d.targetCoins),
    if (d.rank != null && d.rankCoins > 0) ('${_ordinal(d.rank!)} place', d.rankCoins),
    if (d.guildQuestCoins > 0) ('Guild quest cleared', d.guildQuestCoins),
  ];
  final board = x?.board ?? const [];
  return _Card(
    color: AppColors.legendary,
    kicker: 'FRIENDS LEADERBOARD',
    field: Column(
      children: [
        Text(
          d.rank == null ? '—' : '#${d.rank}',
          style: AppText.display.copyWith(fontSize: 96, height: 100 / 96, letterSpacing: -4, color: AppColors.white),
        ),
        Text(
          d.rank == null ? 'Not ranked this week' : 'of ${d.activeFriends + 1} friends',
          style: AppText.h2.copyWith(fontSize: 18, color: AppColors.white),
        ),
        const Spacer(),
        if (board.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final (name, xp, me) in board)
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: me ? AppColors.white : AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.45), width: 1.5),
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '$name ${_thousands(xp)}',
                      style: AppText.title.copyWith(
                        fontSize: 13,
                        color: me ? AppColors.legendaryText : AppColors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        const Spacer(),
      ],
    ),
    label: 'REWARDS',
    title: rows.isEmpty ? 'No coin rewards this week' : 'Your week paid off',
    body: rows.isEmpty
        ? (d.targetHit
              ? 'Rank rewards need ${d.activeFriends < 4 ? 'at least 4 active friends on the board' : 'a top-three finish'}.'
              : 'Reach your weekly target next week to unlock rank rewards.')
        : 'These are already in your coin balance.${d.specialItem != null ? ' You also got a ${d.specialItem!.replaceAll('_', ' ')}.' : ''}',
    extra: rows.isEmpty
        ? null
        : ClayList(
            dividerIndent: 14,
            children: [
              for (final (label, coins) in rows)
                SizedBox(
                  height: 46,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(label, style: AppText.body.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        Image.asset(GameAssets.icon('coin'), width: 18, height: 18),
                        const SizedBox(width: 4),
                        Text(_thousands(coins), style: AppText.numbers.copyWith(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
  );
}

class _DayBars extends StatelessWidget {
  const _DayBars({required this.values});

  final List<int>? values;

  @override
  Widget build(BuildContext context) {
    final data = values ?? List<int>.filled(7, 0);
    final best = data.fold<int>(0, math.max);
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, box) {
          final maxBar = math.max(20.0, box.maxHeight - 22);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: best == 0 ? 8 : math.max(8, maxBar * data[i] / best),
                        decoration: BoxDecoration(
                          color: data[i] == best && best > 0
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: 0.35),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                            bottom: Radius.circular(4),
                          ),
                          boxShadow: data[i] == best && best > 0
                              ? [BoxShadow(color: AppColors.white.withValues(alpha: 0.6), blurRadius: 16)]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        letters[i],
                        style: AppText.label.copyWith(
                          fontSize: 11,
                          height: 14 / 11,
                          color: AppColors.white.withValues(alpha: data[i] == best && best > 0 ? 1 : 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GreyBoss extends StatelessWidget {
  const _GreyBoss({required this.tier, required this.size, required this.turn});

  final String tier;
  final double size;
  final double turn;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.85,
      child: Transform.rotate(
        angle: turn * math.pi / 180,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.42, 0.62, 0.08, 0, 0, //
            0.42, 0.62, 0.08, 0, 0, //
            0.42, 0.62, 0.08, 0, 0, //
            0, 0, 0, 1, 0, //
          ]),
          child: Image.asset(GameAssets.boss(tier), width: size, height: size),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({this.coins, this.text});

  final int? coins;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Clay(
      kind: ClayKind.control,
      radius: 18,
      height: 36,
      padding: EdgeInsets.fromLTRB(coins != null ? 8 : 14, 0, 14, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (coins != null) ...[
            Image.asset(GameAssets.icon('coin'), width: 22, height: 22),
            const SizedBox(width: 6),
            Text('+${_thousands(coins!)} coins', style: AppText.title.copyWith(fontSize: 14)),
          ] else
            Text(text!, style: AppText.title.copyWith(fontSize: 13, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
