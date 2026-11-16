import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/judgement_card.dart';
import '../../core/widgets/q_button.dart';
import '../../data/models/task.dart';
import 'providers/task_providers.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/quest_seal.dart';
import '../../core/widgets/stat_icon.dart';
import '../focus/focus_session_info.dart';
import '../onboarding/onboarding_skip_button.dart';
import 'package:questline/core/assets/decode_size.dart';

const questStats = ['intellect', 'vitality', 'craft', 'charisma'];

class JudgementView {
  const JudgementView({
    required this.stat,
    required this.difficulty,
    required this.minutes,
    required this.xpPreview,
    required this.reason,
    required this.provisional,
    required this.challenged,
    required this.tooBig,
  });

  final String stat;
  final int difficulty;
  final int minutes;
  final int xpPreview;
  final String reason;
  final bool provisional;
  final bool challenged;
  final bool tooBig;

  factory JudgementView.fromJson(Map<String, dynamic> json) {
    return JudgementView(
      stat: json['stat'] as String? ?? 'intellect',
      difficulty: json['difficulty'] as int? ?? 3,
      minutes: json['estimatedMinutes'] as int? ?? 30,
      xpPreview: json['xpPreview'] as int? ?? 0,
      reason: json['reason'] as String? ?? '',
      provisional: json['provisional'] == true,
      challenged: json['challenged'] == true,
      tooBig: json['tooBig'] == true,
    );
  }

  factory JudgementView.fromTask(Task task) {
    return JudgementView(
      stat: task.stat ?? 'intellect',
      difficulty: task.difficulty ?? 3,
      minutes: task.estMinutes ?? 30,
      xpPreview: 0,
      reason: task.reason ?? '',
      provisional: task.provisional,
      challenged: task.challenged,
      tooBig: task.tooBig ?? false,
    );
  }
}

final judgeTaskProvider = Provider<Future<Map<String, dynamic>> Function(String taskId)>((ref) {
  return (taskId) => ref.read(apiClientProvider).judgeTask(taskId);
});

final challengeActionProvider = Provider<Future<Map<String, dynamic>> Function(String taskId, String context)>((ref) {
  return (taskId, context) => ref.read(apiClientProvider).challengeTask(taskId, context);
});

final saveTaskProvider = Provider<Future<void> Function(String taskId)>((ref) {
  return (taskId) => ref.read(taskRepositoryProvider).saveOpen(taskId);
});

final discardTaskProvider = Provider<Future<void> Function(String taskId)>((ref) {
  return (taskId) => ref.read(taskRepositoryProvider).discard(taskId);
});

final setStatProvider = Provider<Future<void> Function(String taskId, String stat)>((ref) {
  return (taskId, stat) => ref.read(taskRepositoryProvider).setStat(taskId, stat);
});

final tickTaskProvider = Provider<Future<Map<String, dynamic>> Function(String taskId)>((ref) {
  return (taskId) => ref.read(apiClientProvider).tickTask(taskId);
});

final rescheduleProvider = Provider<Future<void> Function(String taskId, String newDueAt, bool useScroll)>((ref) {
  return (taskId, newDueAt, useScroll) async {
    await ref.read(apiClientProvider).rescheduleTask(taskId, newDueAt, useScroll: useScroll);
  };
});

/// Shows the judgement for one task. Save opens it. Discard deletes a draft.
class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key, required this.taskId, this.onboarding = false});

  final String taskId;

  /// The first quest. Save also stores the first_task onboarding step.
  final bool onboarding;

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  JudgementView? _judgement;
  var _busy = false;
  String? _error;
  var _asked = false;
  var _linkBoss = false;

  Future<void> _judge() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final json = await ref.read(judgeTaskProvider)(widget.taskId);
      setState(() => _judgement = JudgementView.fromJson(json));
      ref.invalidate(taskProvider(widget.taskId));
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not judge this quest. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _dueText(DateTime? at) {
    final due = at?.toLocal();
    if (due == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    if (day == today) return 'Due today';
    if (day == today.add(const Duration(days: 1))) return 'Due tomorrow';
    if (day.isBefore(today)) return 'Overdue';
    return 'Due ${_wd[due.weekday - 1]}, ${due.day} ${_mo[due.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskProvider(widget.taskId));
    return task.when(
      loading: () => const Scaffold(body: SafeArea(child: LoadingSkeleton())),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ClayHeader(),
              EmptyState(
                title: 'Could not load this quest',
                body: 'Check your connection and try again.',
                icon: Icons.cloud_off_rounded,
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(taskProvider(widget.taskId)),
              ),
            ],
          ),
        ),
      ),
      data: (row) {
        if (row == null) {
          return const Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  ClayHeader(),
                  EmptyState(
                    title: 'Quest not found',
                    body: 'It may have been deleted.',
                    icon: Icons.search_off_rounded,
                  ),
                ],
              ),
            ),
          );
        }
        final judged = _judgement ?? (row.judgedAt == null ? null : JudgementView.fromTask(row));
        if (judged == null && row.status == 'draft' && !_asked && !_busy) {
          _asked = true;
          Future<void>.microtask(_judge);
        }
        return row.status == 'draft' ? _draft(row, judged) : _detail(row, judged);
      },
    );
  }

  /// A new quest: the Judge's verdict on a sheet.
  Widget _draft(Task row, JudgementView? judged) {
    final insets = MediaQuery.paddingOf(context);
    final canChallenge = judged != null && !judged.challenged && !judged.provisional && !widget.onboarding;
    return Scaffold(
      backgroundColor: Color.alphaBlend(AppColors.scrim, AppColors.paper),
      body: Padding(
        padding: EdgeInsets.only(top: insets.top + 103),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(color: AppColors.ink.withValues(alpha: 0.16), offset: const Offset(0, -12), blurRadius: 32),
            ],
          ),
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            namesRoute: true,
            label: 'AI judgement',
            child: ListView(
              padding: EdgeInsets.fromLTRB(AppSpacing.screen, 10, AppSpacing.screen, insets.bottom + 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.handle, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEW QUEST', style: AppText.label.copyWith(letterSpacing: 0.48)),
                          const SizedBox(height: 6),
                          Semantics(
                            header: true,
                            child: Text(row.title, style: AppText.h1.copyWith(fontSize: 21, height: 27 / 21)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.inkMuted),
                              const SizedBox(width: 6),
                              Text(_dueText(row.dueAt), style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (widget.onboarding)
                      const OnboardingSkipButton(foreground: AppColors.ink)
                    else
                      ClayIconButton(
                        icon: Icons.close_rounded,
                        size: 40,
                        iconSize: 18,
                        tooltip: 'Discard',
                        onPressed: _busy ? null : () => _discard(row.id),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                if (judged == null)
                  Clay(
                    radius: 32,
                    height: 200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_busy) const CircularProgressIndicator(),
                        const SizedBox(height: 14),
                        Text(_busy ? 'The Judge is reading…' : 'Waiting for the Judge', style: AppText.bodySmall),
                      ],
                    ),
                  )
                else
                  JudgementCard(
                    stat: judged.stat,
                    difficulty: judged.difficulty,
                    minutes: judged.minutes,
                    xpPreview: judged.xpPreview,
                    reason: judged.reason.isNotEmpty
                        ? judged.reason
                        : (judged.provisional ? 'Provisional rating, we\'ll re-check it soon' : ''),
                    provisional: judged.provisional,
                    challenged: judged.challenged,
                    tooBig: judged.tooBig,
                    onStatTap: () => _cycleStat(judged),
                    onSplit: () => context.go('/quests/new'),
                    onMakeBoss: () => context.go('/bosses/new'),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  QButton(label: 'Try again', variant: QButtonVariant.secondary, onPressed: _judge),
                ],
                if (widget.onboarding && judged != null) ...[
                  const SizedBox(height: AppSpacing.s20),
                  Clay(
                    kind: ClayKind.control,
                    radius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        title: Text('Part of an assignment or exam with a deadline?', style: AppText.item),
                        value: _linkBoss,
                        onChanged: _busy ? null : (value) => setState(() => _linkBoss = value),
                      ),
                    ),
                  ),
                ],
                if (judged != null) ...[
                  const SizedBox(height: 24),
                  QButton(label: 'Save quest', height: 58, loading: _busy, onPressed: _busy ? null : () => _save(row)),
                  const SizedBox(height: 16),
                  Center(
                    child: canChallenge
                        ? GestureDetector(
                            onTap: () => context.push('/quests/${row.id}/challenge'),
                            child: Text.rich(
                              TextSpan(
                                style: AppText.body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.tealDeep,
                                ),
                                children: [
                                  const TextSpan(text: 'Disagree? '),
                                  const TextSpan(
                                    text: 'Challenge it',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: ' · 1 left',
                                    style: TextStyle(color: AppColors.inkMuted, fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Text(
                            judged.challenged
                                ? 'Challenge used. This rating is final.'
                                : judged.provisional
                                ? 'The judge is resting. We\'ll re-check it soon.'
                                : '',
                            style: AppText.bodySmall.copyWith(fontSize: 14),
                          ),
                  ),
                ],
                if (!widget.onboarding) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: QButton(
                      label: 'Discard',
                      variant: QButtonVariant.text,
                      foreground: AppColors.inkMuted,
                      onPressed: _busy ? null : () => _discard(row.id),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// An open or cleared quest.
  Widget _detail(Task row, JudgementView? judged) {
    final info = ref.watch(focusTaskInfoProvider(row.id)).asData?.value;
    final stat = judged?.stat ?? row.stat;
    final open = row.status == 'open';
    final done = row.status == 'done';
    final canPop = Navigator.of(context).canPop();
    final rates = info?.rates ?? XpRates.defaults;
    final estimate = judged?.minutes ?? row.estMinutes ?? 0;
    final capMinutes = (rates.focusCapRatio * estimate).round();
    final upTo = info?.previewXp(capMinutes.toDouble(), activity: false, usePotion: false);
    final target = info?.target;
    final insets = MediaQuery.paddingOf(context);
    final focusDamage = row.completionMode == 'focus' ? row.completionMinutes : null;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: insets.bottom + 120),
            children: [
              SizedBox(
                height: insets.top + 304,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _StatField(stat: stat ?? ''),
                    Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.screen, insets.top + 9, AppSpacing.screen, 0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 44,
                            child: Row(
                              children: [
                                if (canPop)
                                  ClayIconButton(
                                    kind: ClayKind.onScene,
                                    icon: Icons.chevron_left_rounded,
                                    iconSize: 24,
                                    tooltip: 'Back',
                                    onPressed: () => Navigator.of(context).maybePop(),
                                  ),
                                const Spacer(),
                                if (open && !widget.onboarding)
                                  ClayIconButton(
                                    kind: ClayKind.onScene,
                                    icon: Icons.more_horiz_rounded,
                                    iconSize: 22,
                                    tooltip: 'More: move due date',
                                    onPressed: _busy ? null : _more,
                                  ),
                              ],
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -36),
                            child: QuestSeal(stat: stat, size: 100, done: done),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: Column(
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    row.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.h1.copyWith(fontSize: 24, height: 30 / 24, letterSpacing: -0.72),
                                  ),
                                ),
                                if ((row.notes ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    row.notes!,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.bodySmall.copyWith(
                                      fontSize: 14,
                                      height: 20 / 14,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (stat != null)
                                      _HeaderChip(
                                        icon: StatIcon.iconFor(stat),
                                        label: StatIcon.labelFor(stat),
                                        color: AppColors.stat(stat),
                                        dropdown: open && judged != null,
                                        onTap: open && judged != null ? () => _cycleStat(judged) : null,
                                      ),
                                    _HeaderChip(
                                      icon: done ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                                      label: done ? 'Cleared' : _dueText(row.dueAt),
                                      color: done ? AppColors.successText : AppColors.ink,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -38),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (judged != null)
                        _VerdictCard(
                          judged: judged,
                          upTo: upTo,
                          onChallenge: open && !judged.challenged && !judged.provisional
                              ? () => context.push('/quests/${row.id}/challenge')
                              : null,
                        ),
                      if (target != null) ...[
                        const SizedBox(height: 16),
                        _BossStrip(
                          target: target,
                          line: done
                              ? (focusDamage != null && focusDamage > 0
                                    ? 'Took $focusDamage damage'
                                    : 'No damage from this quest')
                              : 'Up to $capMinutes damage from this quest',
                          onTap: () => context.push(target.raid ? '/raids/${row.raidId}' : '/bosses/${row.bossId}'),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.s16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (open && !widget.onboarding)
            Positioned(
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              bottom: insets.bottom + 20,
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Tick off: ${(rates.tickShare * 100).round()}% XP, no boss damage',
                    excludeSemantics: true,
                    child: Clay(
                      circle: true,
                      width: 60,
                      height: 60,
                      onTap: _busy ? null : () => _tick(row, rates),
                      child: const Icon(Icons.check_rounded, size: 24, color: AppColors.successText),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QButton(
                      label: 'Start focus',
                      icon: Icons.play_arrow_rounded,
                      onPressed: _busy ? null : () => context.push('/focus/start?taskId=${row.id}'),
                    ),
                  ),
                ],
              ),
            ),
          if (done)
            Positioned(
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              bottom: insets.bottom + 20,
              child: Clay(
                radius: 26,
                height: 76,
                child: Row(
                  children: [
                    _Cell(value: '+${row.xpFinal ?? 0}', unit: 'XP', label: 'EARNED', color: AppColors.tealDeep),
                    const _CellDivider(),
                    if (row.completionMode == 'tick')
                      const _Cell(value: 'Ticked', label: 'OFF')
                    else
                      _Cell(
                        value: '${row.completionMinutes ?? 0}',
                        unit: 'min',
                        label: row.completionMode == 'activity' ? 'ACTIVITY' : 'FOCUS',
                      ),
                    if (target != null && focusDamage != null) ...[
                      const _CellDivider(),
                      _Cell(value: '$focusDamage', label: 'DAMAGE', color: AppColors.bossHpText),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Move the due date, with or without a reschedule scroll.
  Future<void> _more() async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.paper,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 10, AppSpacing.screen, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.handle, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Move the due date', style: AppText.h2.copyWith(fontSize: 20)),
              const SizedBox(height: 4),
              Text('Rescheduling costs 20% of the XP unless you use a scroll.', style: AppText.bodySmall),
              const SizedBox(height: 18),
              QButton(
                label: 'Reschedule',
                icon: Icons.event_repeat_rounded,
                variant: QButtonVariant.secondary,
                onPressed: () => Navigator.pop(context, false),
              ),
              const SizedBox(height: 12),
              QButton(
                label: 'Use a scroll',
                variant: QButtonVariant.secondary,
                foreground: AppColors.tealDeep,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice != null) await _reschedule(choice);
  }

  Future<void> _tick(Task row, XpRates rates) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (context) => Dialog(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tick it off?', textAlign: TextAlign.center, style: AppText.h2.copyWith(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                'Ticking off earns ${(rates.tickShare * 100).round()}% of the XP and deals no boss damage. '
                'A focus session earns the full amount.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 15, height: 22 / 15, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 22),
              QButton(label: 'Tick it off', height: 56, onPressed: () => Navigator.pop(context, true)),
              const SizedBox(height: 12),
              QButton(
                label: 'Keep it open',
                height: 56,
                variant: QButtonVariant.secondary,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final summary = await ref.read(tickTaskProvider)(row.id);
      ref.invalidate(tasksProvider);
      ref.invalidate(taskProvider(row.id));
      if (!mounted) return;
      final xp = summary['finalXp'];
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(xp is num && xp > 0 ? 'Ticked off · +${xp.round()} XP' : 'Ticked off')));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cycleStat(JudgementView current) async {
    final next = questStats[(questStats.indexOf(current.stat) + 1) % questStats.length];
    setState(
      () => _judgement = JudgementView(
        stat: next,
        difficulty: current.difficulty,
        minutes: current.minutes,
        xpPreview: current.xpPreview,
        reason: current.reason,
        provisional: current.provisional,
        challenged: current.challenged,
        tooBig: current.tooBig,
      ),
    );
    try {
      await ref.read(setStatProvider)(widget.taskId, next);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _save(Task row) async {
    setState(() => _busy = true);
    try {
      if (widget.onboarding && _linkBoss) {
        var deadline = row.dueAt;
        if (deadline == null || !deadline.isAfter(DateTime.now())) {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime.now().add(const Duration(days: 2)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            initialDate: DateTime.now().add(const Duration(days: 3)),
          );
          if (picked == null || !mounted) {
            setState(() => _busy = false);
            return;
          }
          deadline = DateTime(picked.year, picked.month, picked.day, 17);
        }
        final previewJson = await ref
            .read(apiClientProvider)
            .createBossPreview(title: row.title, description: row.notes, type: 'assignment', deadline: deadline);
        final preview = previewJson['preview'];
        if (preview is! Map) {
          throw const ApiException(code: 'internal', message: 'Could not estimate a boss for this quest.');
        }
        await ref
            .read(apiClientProvider)
            .createBoss(
              title: row.title,
              description: row.notes,
              type: 'assignment',
              deadline: deadline,
              hours: (preview['hours'] as num?)?.toDouble() ?? 6,
              name: preview['name'] as String? ?? 'The Deadline Shade',
              taskId: row.id,
            );
      }
      await ref.read(saveTaskProvider)(row.id);
      if (widget.onboarding) {
        await ref.read(completeOnboardingProvider)('first_task');
        ref.invalidate(onboardingStepProvider);
      }
      ref.invalidate(tasksProvider);
      if (mounted) context.go(widget.onboarding ? '/onboarding/first-session' : '/quests');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard(String id) async {
    setState(() => _busy = true);
    try {
      await ref.read(discardTaskProvider)(id);
      ref.invalidate(tasksProvider);
      if (mounted) context.go('/quests');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reschedule(bool useScroll) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    final due = DateTime.utc(picked.year, picked.month, picked.day, 12).toIso8601String();
    setState(() => _busy = true);
    try {
      await ref.read(rescheduleProvider)(widget.taskId, due, useScroll);
      ref.invalidate(taskProvider(widget.taskId));
      ref.invalidate(tasksProvider);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// The stat-tinted field behind a quest's seal, with soft white rays.
class _StatField extends StatelessWidget {
  const _StatField({required this.stat});

  final String stat;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.statLight(stat);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.1,
                colors: [
                  AppColors.white,
                  Color.lerp(AppColors.white, tint, 0.45)!,
                  Color.lerp(AppColors.white, tint, 0.9)!,
                ],
                stops: const [0, 0.34, 1],
              ),
            ),
          ),
          const CustomPaint(painter: _SoftRays()),
        ],
      ),
    );
  }
}

class _SoftRays extends CustomPainter {
  const _SoftRays();

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.3);
    final radius = size.longestSide * 0.7;
    final rect = Rect.fromCircle(center: origin, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.white.withValues(alpha: 0.45), AppColors.white.withValues(alpha: 0)],
        stops: const [0.15, 0.6],
      ).createShader(rect);
    const on = 7 * math.pi / 180;
    const step = 20 * math.pi / 180;
    for (var a = 0.0; a < math.pi * 2; a += step) {
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..arcTo(rect, a, on, false)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SoftRays oldDelegate) => false;
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label, required this.color, this.dropdown = false, this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final bool dropdown;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: onTap != null ? 'Stat: $label. Change' : label,
      excludeSemantics: true,
      child: Clay(
        kind: ClayKind.onScene,
        radius: 15,
        height: 30,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.title.copyWith(fontSize: 12, height: 16 / 12, color: color),
            ),
            if (dropdown) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

/// The Judge's verdict on an open or cleared quest: difficulty, estimate, the XP it can earn, and why.
class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.judged, required this.upTo, this.onChallenge});

  final JudgementView judged;
  final int? upTo;
  final VoidCallback? onChallenge;

  @override
  Widget build(BuildContext context) {
    final d = judged.difficulty.clamp(1, 5);
    final (chip, chipWash, chipInk) = judged.provisional
        ? ('Provisional', AppColors.errorSoft, AppColors.errorText)
        : judged.challenged
        ? ('Final', AppColors.tealSoft, AppColors.tealDeep)
        : ('Judged', AppColors.tealSoft, AppColors.tealDeep);
    final starColor = AppColors.stat(judged.stat);
    final reason = judged.reason.isNotEmpty
        ? judged.reason
        : (judged.provisional
              ? 'The Judge was offline, so this rating is provisional. It will be re-checked soon.'
              : '');
    return Clay(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.tealDeep),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "THE JUDGE'S VERDICT",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 1.1),
                ),
              ),
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(color: chipWash, borderRadius: BorderRadius.circular(11)),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    chip,
                    style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 0, color: chipInk),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Difficulty $d of 5',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 22,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < 5; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: CustomPaint(
                                    size: const Size.square(13),
                                    painter: _StarPainter(i < d ? starColor : AppColors.focusRingIdle),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'DIFFICULTY $d',
                            style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 0.66),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.hairline),
                _Cell(value: '${judged.minutes}', unit: 'min', label: 'ESTIMATE'),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.hairline),
                _Cell(
                  value: upTo == null ? '—' : '$upTo',
                  unit: upTo == null ? null : 'XP',
                  label: 'UP TO',
                  color: AppColors.tealDeep,
                ),
              ],
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 16),
            Well(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                judged.provisional ? reason : '“$reason”',
                style: AppText.bodySmall.copyWith(height: 19 / 13),
              ),
            ),
          ],
          if (onChallenge != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onChallenge,
                child: Text(
                  'Disagree? Challenge once',
                  style: AppText.title.copyWith(fontSize: 13, height: 18 / 13, color: AppColors.tealDeep),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The boss this quest strikes.
class _BossStrip extends StatelessWidget {
  const _BossStrip({required this.target, required this.line, required this.onTap});

  final FocusTarget target;
  final String line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tier = GameAssets.bossTiers.contains(target.tier) ? target.tier : 'brute';
    return Semantics(
      button: true,
      label: '${target.name}, ${target.hpLeft} HP left. $line',
      excludeSemantics: true,
      child: Clay(
        radius: 26,
        height: 84,
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(26)),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, 0.6),
                            colors: target.raid
                                ? const [Color(0xFF8EA2FF), Color(0xFF3B3F96), Color(0xFF1B1D4F)]
                                : const [Color(0xFFF59BB4), Color(0xFF6B2A6E), Color(0xFF2A2D74)],
                            stops: const [0, 0.55, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(left: -2, top: -22, child: Image.asset(GameAssets.boss(tier), width: 92, height: 92, cacheWidth: decodeWidth(context, 92))),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            target.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title.copyWith(fontSize: 15, height: 20 / 15),
                          ),
                        ),
                        Text('${target.hpLeft} HP', style: AppText.caption.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClayBar(
                      height: 6,
                      gradient: hpFillGradient,
                      value: target.maxHp <= 0 ? 0 : target.hpLeft / target.maxHp,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.gavel_rounded, size: 13, color: AppColors.bossHpText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.bossHpText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.label, this.unit, this.color = AppColors.ink});

  final String value;
  final String? unit;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = AppText.numbers.copyWith(fontSize: 18, height: 22 / 18, letterSpacing: -0.36, color: color);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: value),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: style.copyWith(fontSize: 13, color: color == AppColors.ink ? AppColors.inkMuted : color),
                    ),
                ],
              ),
              style: style,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppText.label.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 0.66)),
          ),
        ],
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 16), color: AppColors.hairline);
  }
}

/// A four-point star for the difficulty row.
class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = w / 2;
    final i = w * 0.11;
    canvas.drawPath(
      Path()
        ..moveTo(c, 0)
        ..lineTo(c + i, c - i)
        ..lineTo(w, c)
        ..lineTo(c + i, c + i)
        ..lineTo(c, w)
        ..lineTo(c - i, c + i)
        ..lineTo(0, c)
        ..lineTo(c - i, c - i)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}
