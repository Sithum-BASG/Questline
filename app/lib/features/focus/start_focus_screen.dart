import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_chip.dart';
import '../../core/widgets/task_tile.dart';
import '../../data/models/task.dart';
import '../quests/providers/task_providers.dart';

final startSessionProvider = Provider<
    Future<StartSessionResult> Function({required String taskId, required String mode, bool usePotion})>((ref) {
  return ({required String taskId, required String mode, bool usePotion = false}) {
    return ref.read(apiClientProvider).startSession(taskId: taskId, mode: mode, usePotion: usePotion);
  };
});

final potionCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final row = await client.from('player_state').select('potions').maybeSingle();
  return (row?['potions'] as num?)?.toInt() ?? 0;
});

class StartFocusScreen extends ConsumerStatefulWidget {
  const StartFocusScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<StartFocusScreen> createState() => _StartFocusScreenState();
}

class _StartFocusScreenState extends ConsumerState<StartFocusScreen> {
  var _mode = 'focus';
  var _potion = false;
  var _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (widget.taskId.isEmpty) {
      return _PickerScaffold(onPick: (id) => context.go('/focus/start?taskId=$id'));
    }
    final task = ref.watch(taskProvider(widget.taskId));
    final potions = ref.watch(potionCountProvider).asData?.value ?? 0;
    return Scaffold(
      body: SafeArea(
        child: task.when(
          loading: () => const LoadingSkeleton(),
          error: (error, _) => EmptyState(
            title: 'Could not open this quest',
            body: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(taskProvider(widget.taskId)),
          ),
          data: (row) {
            if (row == null) {
              return const EmptyState(title: 'Quest not found', body: 'It may have been discarded.');
            }
            final activity = row.stat == 'vitality' || row.stat == 'charisma';
            final estimate = row.estMinutes ?? 0;
            final canPotion = estimate >= 25 && potions > 0;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Text(row.title, style: AppText.h1, softWrap: true),
                const SizedBox(height: AppSpacing.s16),
                if (activity) ...[
                  Wrap(
                    spacing: AppSpacing.s8,
                    children: [
                      QChip(label: 'Focus', selected: _mode == 'focus', onTap: () => setState(() => _mode = 'focus')),
                      QChip(
                        label: 'Activity',
                        selected: _mode == 'activity',
                        onTap: () => setState(() => _mode = 'activity'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                ],
                if (canPotion)
                  QChip(
                    label: 'Focus potion',
                    selected: _potion,
                    onTap: () => setState(() => _potion = !_potion),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.s24),
                QButton(
                  label: 'Start',
                  loading: _busy,
                  onPressed: _busy ? null : () => _start(estimate, row.stat ?? 'intellect'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _start(int estimate, String stat) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final started = await ref.read(startSessionProvider)(
        taskId: widget.taskId,
        mode: _mode,
        usePotion: _potion,
      );
      if (!mounted) return;
      context.push('/focus/${started.sessionId}', extra: {
        'startedAt': started.startedAt,
        'estimateMinutes': estimate,
        'mode': _mode,
        'stat': stat,
      });
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PickerScaffold extends ConsumerWidget {
  const _PickerScaffold({required this.onPick});

  final void Function(String taskId) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Start focus', style: AppText.h2)),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load quests',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(tasksProvider),
        ),
        data: (rows) {
          final open = rows.where((task) => task.status == 'open').toList();
          if (open.isEmpty) {
            return EmptyState(
              title: 'No open quests',
              body: 'Add a quest and open it before starting focus.',
              actionLabel: 'Add quest',
              onAction: () => context.go('/quests/new'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s8,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            itemCount: open.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s8),
            itemBuilder: (context, index) {
              final task = open[index];
              return GestureDetector(
                onTap: () => onPick(task.id),
                child: TaskTile(
                  title: task.title,
                  stat: task.stat ?? 'intellect',
                  dueLabel: _dueLabel(task),
                  provisional: task.provisional,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _dueLabel(Task task) {
    final due = task.dueAt;
    if (due == null) return 'No due date';
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays >= 1) return '${diff.inDays}d left';
    if (diff.inHours >= 1) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }
}
