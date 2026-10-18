import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/judgement_card.dart';
import '../../core/widgets/q_button.dart';
import '../../data/models/task.dart';
import 'providers/task_providers.dart';

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

/// Shows the judgement for one task. Save opens it. Discard deletes a draft.
class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  JudgementView? _judgement;
  var _busy = false;
  String? _error;
  var _asked = false;

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

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskProvider(widget.taskId));
    return Scaffold(
      body: SafeArea(
        child: task.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            title: 'Could not load this quest',
            body: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(taskProvider(widget.taskId)),
          ),
          data: (row) {
            if (row == null) {
              return const EmptyState(title: 'Quest not found', body: 'It may have been deleted.');
            }
            final judged = _judgement ?? (row.judgedAt == null ? null : JudgementView.fromTask(row));
            if (judged == null && row.status == 'draft' && !_asked && !_busy) {
              _asked = true;
              Future<void>.microtask(_judge);
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Text(row.title, style: AppText.h1),
                const SizedBox(height: AppSpacing.s16),
                if (_busy) const Center(child: CircularProgressIndicator()),
                if (judged != null)
                  JudgementCard(
                    stat: judged.stat,
                    difficulty: judged.difficulty,
                    minutes: judged.minutes,
                    xpPreview: judged.xpPreview,
                    reason: judged.provisional ? 'Provisional rating, we\'ll re-check it soon' : judged.reason,
                    provisional: judged.provisional,
                    challenged: judged.challenged,
                    tooBig: judged.tooBig,
                    onStatTap: () => _cycleStat(judged),
                    onSplit: () => context.go('/quests/new'),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
                  const SizedBox(height: AppSpacing.s12),
                  QButton(label: 'Try again', onPressed: _judge),
                ],
                const SizedBox(height: AppSpacing.s20),
                if (row.status == 'draft' && judged != null)
                  QButton(label: 'Save', onPressed: _busy ? null : () => _save(row.id)),
                if (row.status == 'open' && judged != null && !judged.challenged) ...[
                  const SizedBox(height: AppSpacing.s8),
                  QButton(
                    label: 'Disagree?',
                    variant: QButtonVariant.secondary,
                    onPressed: () => context.push('/quests/${row.id}/challenge'),
                  ),
                ],
                if (row.status == 'draft') ...[
                  const SizedBox(height: AppSpacing.s8),
                  QButton(
                    label: 'Discard',
                    variant: QButtonVariant.text,
                    onPressed: _busy ? null : () => _discard(row.id),
                  ),
                ],
              ],
            );
          },
        ),
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

  Future<void> _save(String id) async {
    setState(() => _busy = true);
    try {
      await ref.read(saveTaskProvider)(id);
      ref.invalidate(tasksProvider);
      if (mounted) context.go('/quests');
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
}
