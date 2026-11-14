import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../core/widgets/stat_icon.dart';

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

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskProvider(widget.taskId));
    return Scaffold(
      body: task.when(
        loading: () => const SafeArea(child: LoadingSkeleton()),
        error: (error, _) => SafeArea(
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
        data: (row) {
          if (row == null) {
            return const SafeArea(
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
            );
          }
          final judged = _judgement ?? (row.judgedAt == null ? null : JudgementView.fromTask(row));
          if (judged == null && row.status == 'draft' && !_asked && !_busy) {
            _asked = true;
            Future<void>.microtask(_judge);
          }
          final stat = judged?.stat ?? row.stat;
          final due = row.dueAt?.toLocal();
          final canPop = Navigator.of(context).canPop();
          final list = ListView(
            padding: EdgeInsets.zero,
            children: [
              // Stat-tinted field with the quest's gem as the hero.
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.1,
                    colors: [
                      AppColors.white,
                      Color.lerp(AppColors.white, AppColors.statLight(stat ?? ''), 0.45)!,
                      Color.lerp(AppColors.white, AppColors.statLight(stat ?? ''), 0.9)!,
                    ],
                    stops: const [0, 0.34, 1],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s12, AppSpacing.screen, 72),
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
                            ],
                          ),
                        ),
                        if (stat != null)
                          StatDot(stat: stat, size: 92)
                        else
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8ECF2),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFC3CAD6), width: 1.6),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.inkFaint, size: 30),
                          ),
                        const SizedBox(height: 16),
                        if (row.status == 'draft')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('NEW QUEST', style: AppText.label.copyWith(letterSpacing: 0.48)),
                          ),
                        Semantics(
                          header: true,
                          child: Text(
                            row.title,
                            textAlign: TextAlign.center,
                            style: AppText.h1.copyWith(fontSize: 24, height: 30 / 24, letterSpacing: -0.72),
                          ),
                        ),
                        if ((row.notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            row.notes!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14, color: const Color(0xFF4F5A70)),
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
                              ),
                            _HeaderChip(
                              icon: Icons.calendar_today_rounded,
                              label: due == null ? 'No due date' : 'Due ${due.day} ${_mo[due.month - 1]}',
                              color: AppColors.ink,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_busy && judged == null)
                        const Clay(
                          radius: AppRadius.stage,
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (judged != null)
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
                      const SizedBox(height: AppSpacing.s24),
                      if (widget.onboarding && row.status == 'draft' && judged != null) ...[
                        Clay(
                          kind: ClayKind.control,
                          radius: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            title: Text(
                              'Part of an assignment or exam with a deadline?',
                              style: AppText.item,
                            ),
                            value: _linkBoss,
                            onChanged: _busy ? null : (value) => setState(() => _linkBoss = value),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                      ],
                      if (row.status == 'open' && !widget.onboarding) ...[
                        Row(
                          children: [
                            Expanded(
                              child: QButton(
                                label: 'Reschedule',
                                variant: QButtonVariant.secondary,
                                icon: Icons.event_repeat_rounded,
                                onPressed: _busy ? null : () => _reschedule(false),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: QButton(
                                label: 'Use a scroll',
                                variant: QButtonVariant.secondary,
                                foreground: AppColors.tealDeep,
                                onPressed: _busy ? null : () => _reschedule(true),
                              ),
                            ),
                          ],
                        ),
                        if (judged != null && !judged.challenged) ...[
                          const SizedBox(height: AppSpacing.s8),
                          Center(
                            child: QButton(
                              label: 'Disagree?',
                              variant: QButtonVariant.text,
                              onPressed: () => context.push('/quests/${row.id}/challenge'),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
          final showSave = row.status == 'draft' && judged != null;
          final showFocus = row.status == 'open' && !widget.onboarding;
          final showDiscard = row.status == 'draft';
          return Column(
            children: [
              Expanded(child: list),
              if (showSave || showFocus || showDiscard)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showSave)
                          QButton(label: 'Save', loading: _busy, onPressed: _busy ? null : () => _save(row)),
                        if (showFocus)
                          QButton(
                            label: 'Focus',
                            icon: Icons.play_arrow_rounded,
                            onPressed: _busy ? null : () => context.push('/focus/start?taskId=${row.id}'),
                          ),
                        if (showDiscard) ...[
                          const SizedBox(height: AppSpacing.s4),
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
            ],
          );
        },
      ),
    );
  }

  Future<void> _cycleStat(JudgementView current) async {
    final next = questStats[(questStats.indexOf(current.stat) + 1) % questStats.length];
    setState(() => _judgement = JudgementView(
          stat: next,
          difficulty: current.difficulty,
          minutes: current.minutes,
          xpPreview: current.xpPreview,
          reason: current.reason,
          provisional: current.provisional,
          challenged: current.challenged,
          tooBig: current.tooBig,
        ));
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
        final previewJson = await ref.read(apiClientProvider).createBossPreview(
              title: row.title,
              description: row.notes,
              type: 'assignment',
              deadline: deadline,
            );
        final preview = previewJson['preview'];
        if (preview is! Map) {
          throw const ApiException(code: 'internal', message: 'Could not estimate a boss for this quest.');
        }
        await ref.read(apiClientProvider).createBoss(
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

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Clay(
      kind: ClayKind.onScene,
      radius: 16,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
