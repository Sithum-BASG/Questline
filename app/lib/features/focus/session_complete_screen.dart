import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/game_config_reader.dart';
import '../../core/notifications/local_notifications.dart';
import '../../core/notifications/notification_replan.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/reward_overlay.dart';
import '../../core/widgets/timer_display.dart';
import '../onboarding/onboarding_flags.dart';
import 'focus_session_info.dart';

/// After a session: "Quest complete" with how the XP was earned, or "Session ended" when it broke or was too short.
class SessionCompleteScreen extends ConsumerStatefulWidget {
  const SessionCompleteScreen({super.key, required this.summary});

  final Map<String, dynamic> summary;

  @override
  ConsumerState<SessionCompleteScreen> createState() => _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends ConsumerState<SessionCompleteScreen> {
  var _busy = false;
  String? _error;

  int _number(String key) {
    final value = widget.summary[key];
    return value is num ? value.round() : 0;
  }

  List<RewardMoment> _momentsFromSummary() {
    final rewards = widget.summary['rewards'];
    if (rewards is! List) return const [];
    return rewards.whereType<Map>().map((reward) {
      final type = reward['type'] as String? ?? 'item';
      final id = reward['id'] as String?;
      if (type == 'title') {
        return RewardMoment(kind: RewardKind.levelUp, title: 'New title', subtitle: id ?? 'Title unlocked');
      }
      if (type == 'coins') {
        return RewardMoment(
          kind: RewardKind.loot,
          title: '+${reward['amount'] ?? 0} coins',
          subtitle: 'Level reward',
          rarity: 'common',
        );
      }
      return RewardMoment(kind: RewardKind.loot, title: id ?? 'New item', subtitle: 'Level reward', rarity: 'common');
    }).toList();
  }

  Future<void> _continue() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Ask once after the first completed session (overview §18 / plan 13.1).
      // Never block Continue if the plugin/channel is unavailable (tests, cold hosts).
      try {
        await ref.read(localNotificationsProvider).requestPermissionAfterFirstSession();
      } catch (_) {}
      try {
        await replanLocalNotifications(ref);
      } catch (_) {}
      if (widget.summary['onboarding'] == true) {
        await ref.read(completeOnboardingProvider)('first_session');
        ref.invalidate(onboardingStepProvider);
        ref.read(pendingOnboardingChestProvider.notifier).setPending(true);
      }
      final queue = ref.read(rewardQueueProvider);
      queue.add(_momentsFromSummary());
      if (!mounted) return;
      if (queue.pending.isNotEmpty || queue.current != null) {
        queue.next();
        context.go('/reward');
      } else if (widget.summary['onboarding'] == true) {
        context.go('/onboarding/chest');
      } else {
        context.go('/quests');
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = widget.summary['sessionId'] as String?;
    final info = sessionId == null ? null : ref.watch(focusSessionInfoProvider(sessionId)).asData?.value;
    final look = ref.watch(heroLookProvider).asData?.value;
    final rewards = widget.summary['rewards'];
    final lines = rewards is List ? rewards.whereType<Map>().toList() : const <Map>[];
    final broken = widget.summary['broken'] == true;
    final onboarding = widget.summary['onboarding'] == true;
    final counted = widget.summary.containsKey('countedMinutes')
        ? _number('countedMinutes')
        : _number('verifiedMinutes');
    final earned = onboarding || counted > 0 || _number('finalXp') > 0;
    final complete = !broken && earned;
    final title = info?.title;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final header = Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              complete ? Icons.check_rounded : Icons.timer_off_rounded,
              size: 14,
              color: complete ? AppColors.tealDeep : AppColors.errorText,
            ),
            const SizedBox(width: 6),
            Semantics(
              header: true,
              label: complete ? 'Quest complete' : 'Session ended',
              excludeSemantics: true,
              child: Text(
                complete ? 'QUEST COMPLETE' : 'SESSION ENDED',
                style: AppText.label.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: complete ? AppColors.tealDeep : AppColors.errorText,
                ),
              ),
            ),
          ],
        ),
        if (title != null) ...[
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );

    final children = complete
        ? _completeBody(info: info, look: look, counted: counted, onboarding: onboarding)
        : _endedBody(info: info, look: look, counted: counted, broken: broken, earned: earned);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 12, AppSpacing.screen, 12),
                children: [
                  header,
                  const SizedBox(height: 6),
                  ...children,
                  if (lines.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s24),
                    const SectionLabel(label: 'Rewards'),
                    const SizedBox(height: AppSpacing.s12),
                    ClayList(
                      dividerIndent: 58,
                      children: [
                        for (final reward in lines)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                ClayDot(
                                  size: 32,
                                  gradient: dotGradient(
                                    AppColors.legendary.withValues(alpha: 0.6),
                                    AppColors.legendary,
                                  ),
                                  icon: Icons.star_rounded,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('${reward['id'] ?? reward['type'] ?? 'Reward'}', style: AppText.item),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, bottom + 20),
              child: complete || info == null
                  ? QButton(label: complete ? 'Continue' : 'Done', loading: _busy, onPressed: _busy ? null : _continue)
                  : Row(
                      children: [
                        Expanded(
                          flex: 10,
                          child: QButton(
                            label: 'Done',
                            variant: QButtonVariant.secondary,
                            height: 60,
                            loading: _busy,
                            onPressed: _busy ? null : _continue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 16,
                          child: QButton(
                            label: 'Focus again',
                            icon: Icons.play_arrow_rounded,
                            onPressed: _busy ? null : () => context.go('/focus/start?taskId=${info.taskId}'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _progress(FocusTaskInfo? info) {
    final estimate = info?.estMinutes ?? _number('estimateMinutes');
    final elapsed = _number('elapsedSeconds');
    return estimate > 0 ? elapsed / (estimate * 60) : 0;
  }

  List<Widget> _completeBody({
    required FocusTaskInfo? info,
    required HeroLook? look,
    required int counted,
    required bool onboarding,
  }) {
    final bossDamage = _number('bossDamage');
    final raidDamage = _number('raidDamage');
    final damage = bossDamage > 0 ? bossDamage : raidDamage;
    final target = info?.target;
    final tiles = <Widget>[
      if (damage > 0)
        _Tile(
          label: raidDamage > 0 && bossDamage == 0 ? 'RAID DAMAGE' : 'BOSS DAMAGE',
          value: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('−$damage', style: _tileValue.copyWith(color: AppColors.bossHpText)),
              if (target != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${target.hpLeft} HP left',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
          foot: target == null
              ? null
              : ClayBar(
                  height: 6,
                  gradient: hpFillGradient,
                  value: target.maxHp <= 0 ? 0 : target.hpLeft / target.maxHp,
                ),
        ),
      if (info != null && info.streak > 0)
        _Tile(
          label: 'STREAK',
          value: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 20, color: AppColors.streakEmber),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${info.streak} ${info.streak == 1 ? 'day' : 'days'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _tileValue,
                ),
              ),
            ],
          ),
          foot: Text('Day streak', style: AppText.caption.copyWith(fontWeight: FontWeight.w500)),
        ),
      _Tile(
        label: 'LEVEL',
        value: Text('${_number('level')}', style: _tileValue),
        foot: Text('${_number('xpTotal')} XP total', style: AppText.caption.copyWith(fontWeight: FontWeight.w500)),
      ),
    ];
    return [
      Center(
        child: FocusMedallion(size: 170, progress: 1, ring: FocusRing.full, look: look),
      ),
      const SizedBox(height: 2),
      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '+${_number('finalXp')}',
              style: AppText.display.copyWith(fontSize: 52, height: 56 / 52, letterSpacing: -2),
            ),
            const SizedBox(width: 6),
            Text('XP', style: AppText.h2.copyWith(fontSize: 20, color: AppColors.tealDeep)),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _Breakdown(rows: _rows(info, counted), totalLabel: 'Total', total: '${_number('finalXp')} XP'),
      if (onboarding) ...[
        const SizedBox(height: AppSpacing.s16),
        Well(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: AppColors.tealDeep, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Starter XP unlocks level 2 and a free chest.',
                  style: AppText.bodySmall.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          for (final (i, tile) in tiles.take(2).indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: tile),
          ],
        ],
      ),
    ];
  }

  List<Widget> _endedBody({
    required FocusTaskInfo? info,
    required HeroLook? look,
    required int counted,
    required bool broken,
    required bool earned,
  }) {
    final stopAt = TimerDisplay.format(_number('elapsedSeconds'));
    final grace = widget.summary['graceSeconds'] is num ? _number('graceSeconds') : 30;
    final minimum = (info?.rates ?? XpRates.defaults).minEarningMinutes.round();
    final verified = _number('verifiedMinutes');
    final damage = _number('bossDamage') > 0 ? _number('bossDamage') : _number('raidDamage');
    return [
      Center(
        child: FocusMedallion(size: 170, progress: _progress(info), ring: FocusRing.stopped, look: look),
      ),
      const SizedBox(height: 4),
      Semantics(
        header: true,
        child: Text(
          broken ? 'You left for over $grace seconds' : 'Too short to count',
          textAlign: TextAlign.center,
          style: AppText.h1.copyWith(fontSize: 24, height: 30 / 24),
        ),
      ),
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: broken ? 'The timer stopped at ' : 'You ended at '),
            TextSpan(
              text: stopAt,
              style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: '. Your quest is still open.'),
          ],
        ),
        textAlign: TextAlign.center,
        style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14),
      ),
      const SizedBox(height: 20),
      if (earned)
        _Breakdown(
          heading: 'WHAT STILL COUNTS',
          rows: _rows(info, counted, beforeLeaving: broken),
          totalLabel: 'Earned',
          total: '+${_number('finalXp')} XP',
          extra: damage > 0 ? '$damage damage' : null,
        )
      else
        Well(
          radius: 26,
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.emberSoft, shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_bottom_rounded, size: 20, color: AppColors.emberDeep),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verified == 0
                          ? 'Under a minute counted'
                          : 'Only $verified ${verified == 1 ? 'minute' : 'minutes'} counted',
                      style: AppText.title.copyWith(fontSize: 16, height: 21 / 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Sessions under $minimum minutes don't earn XP or deal boss damage. Nothing else is lost.",
                      style: AppText.bodySmall.copyWith(height: 19 / 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      if (broken) ...[
        const SizedBox(height: 16),
        Clay(
          kind: ClayKind.control,
          radius: 22,
          padding: const EdgeInsets.fromLTRB(12, 11, 16, 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                child: const Icon(Icons.do_not_disturb_on_rounded, size: 18, color: AppColors.tealDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Tip: ',
                        style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: "turn on Do Not Disturb before you start, so calls and chats don't pull you out."),
                    ],
                  ),
                  style: AppText.bodySmall.copyWith(height: 18 / 13),
                ),
              ),
            ],
          ),
        ),
      ],
    ];
  }

  /// How the XP was made, from the summary and the quest. The total is always the server's.
  List<(String, String, bool)> _rows(FocusTaskInfo? info, int counted, {bool beforeLeaving = false}) {
    final activity = widget.summary['mode'] == 'activity';
    final rows = <(String, String, bool)>[
      (
        beforeLeaving
            ? '$counted min verified before you left'
            : '$counted min verified ${activity ? 'activity' : 'focus'}',
        '$counted',
        false,
      ),
    ];
    if (info != null) {
      rows.add(('Difficulty ${info.difficulty}', '×${_fmt(info.rates.multiplier(info.difficulty))}', false));
      if (activity) rows.add(('Activity mode', '×${_fmt(info.rates.activityShare)}', false));
      if (info.dueAt != null) {
        final late = info.daysLate(DateTime.now());
        if (late == 0) {
          rows.add(('Finished on time', '+${(info.rates.onTimeBonus * 100).round()}%', false));
        } else {
          final cut = ((1 - info.timing(DateTime.now())) * 100).round();
          rows.add(('$late ${late == 1 ? 'day' : 'days'} late', '−$cut%', false));
        }
      }
      if (info.rescheduled && !info.scrollUsed) {
        rows.add(('Rescheduled', '−${(info.rates.reschedulePenalty * 100).round()}%', false));
      }
    }
    final bonus = _number('finalXp') - _number('rawXp');
    if (bonus > 0) rows.add((info?.potion == true ? 'Focus Potion and gear' : 'Gear and boosts', '+$bonus XP', true));
    return rows;
  }
}

String _fmt(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

final _tileValue = AppText.numbers.copyWith(fontSize: 22, height: 26 / 22, letterSpacing: -0.4);

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.rows, required this.totalLabel, required this.total, this.heading, this.extra});

  final List<(String, String, bool)> rows;
  final String totalLabel;
  final String total;
  final String? heading;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heading != null) ...[FocusTileLabel(heading!), const SizedBox(height: 4)],
          for (final (label, value, accent) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    value,
                    style: AppText.title.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      color: accent ? AppColors.tealDeep : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: AppColors.hairline),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(totalLabel, style: AppText.title.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              if (extra != null) ...[
                Text(extra!, style: AppText.numbers.copyWith(fontSize: 14, color: AppColors.bossHpText)),
                const SizedBox(width: 12),
              ],
              Text(total, style: AppText.numbers.copyWith(fontSize: 17, color: AppColors.tealDeep)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.foot});

  final String label;
  final Widget value;
  final Widget? foot;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 24,
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [FocusTileLabel(label), value, ?foot],
      ),
    );
  }
}
