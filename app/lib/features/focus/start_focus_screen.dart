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
import '../../core/widgets/task_tile.dart';
import '../../data/models/task.dart';
import '../quests/providers/task_providers.dart';
import '../../core/assets/game_assets.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/stat_icon.dart';

final startSessionProvider = Provider<
    Future<StartSessionResult> Function({required String taskId, required String mode, bool usePotion})>((ref) {
  return ({required String taskId, required String mode, bool usePotion = false}) {
    return ref.read(apiClientProvider).startSession(taskId: taskId, mode: mode, usePotion: usePotion);
  };
});

final potionCountProvider = FutureProvider.autoDispose<int>((ref) async {
  watchAccount(ref);
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
      appBar: const ClayHeader(title: 'Start focus', closeIcon: true),
      body: task.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not open this quest',
          body: 'Check your connection and try again.',
          icon: Icons.cloud_off_rounded,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(taskProvider(widget.taskId)),
        ),
        data: (row) {
          if (row == null) {
            return const EmptyState(
              title: 'Quest not found',
              body: 'It may have been discarded.',
              icon: Icons.search_off_rounded,
            );
          }
          final activity = row.stat == 'vitality' || row.stat == 'charisma';
          final estimate = row.estMinutes ?? 0;
          final canPotion = estimate >= 25 && potions > 0;
          final stat = row.stat ?? 'intellect';
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s12, AppSpacing.screen, AppSpacing.s32),
            children: [
              Text('QUEST', style: AppText.label),
              const SizedBox(height: 10),
              Clay(
                radius: 26,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    StatDot(stat: stat),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.title, style: AppText.title.copyWith(fontSize: 15), softWrap: true),
                          if (estimate > 0) Text('~$estimate min', style: AppText.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, color: AppColors.tealDeep, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'MODE', style: AppText.label),
                    TextSpan(
                      text: activity ? '  · your choice for this stat' : '',
                      style: AppText.caption.copyWith(color: AppColors.inkFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (activity)
                _ModeToggle(value: _mode, onChanged: (m) => setState(() => _mode = m))
              else
                Well(
                  height: 48,
                  radius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.center_focus_strong_rounded, size: 18, color: AppColors.tealDeep),
                      const SizedBox(width: 8),
                      Text('Focus', style: AppText.title.copyWith(fontSize: 14, color: AppColors.tealDeep)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('stay in the app', style: AppText.bodySmall, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  _mode == 'activity'
                      ? 'Activity lets your phone lock while you move or talk.'
                      : 'Leaving the app starts a short grace timer.',
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w400),
                ),
              ),
              if (canPotion) ...[
                const SizedBox(height: 20),
                Semantics(
                  toggled: _potion,
                  label: 'Focus potion',
                  excludeSemantics: true,
                  child: Clay(
                    kind: ClayKind.control,
                    radius: 24,
                    height: 64,
                    onTap: () => setState(() => _potion = !_potion),
                    padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(GameAssets.icon('focus_potion')),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Focus potion', style: AppText.title.copyWith(fontSize: 15)),
                              Text('You have $potions', style: AppText.caption.copyWith(fontWeight: FontWeight.w400)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _potion,
                          onChanged: (v) => setState(() => _potion = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s16),
                Text(
                  _error!,
                  style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: AppSpacing.s32),
              QButton(
                label: 'Start',
                icon: Icons.play_arrow_rounded,
                loading: _busy,
                onPressed: _busy ? null : () => _start(estimate, row.stat ?? 'intellect'),
              ),
            ],
          );
        },
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const modes = [('focus', 'Focus', Icons.center_focus_strong_rounded), ('activity', 'Activity', Icons.directions_run_rounded)];
    final index = value == 'activity' ? 1 : 0;
    return Well(
      height: 48,
      radius: 24,
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: const Clay(kind: ClayKind.control, radius: 20),
              ),
              Row(
                children: [
                  for (final (id, label, icon) in modes)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: value == id,
                        label: label,
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => onChanged(id),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 16, color: value == id ? AppColors.tealDeep : AppColors.inkMuted),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: AppText.title.copyWith(
                                    fontSize: 14,
                                    color: value == id ? AppColors.ink : AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PickerScaffold extends ConsumerWidget {
  const _PickerScaffold({required this.onPick});

  final void Function(String taskId) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tasksProvider);
    return Scaffold(
      appBar: const ClayHeader(title: 'Start focus', closeIcon: true),
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
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
            itemBuilder: (context, index) {
              final task = open[index];
              return TaskTile(
                onTap: () => onPick(task.id),
                title: task.title,
                stat: task.stat ?? 'intellect',
                dueLabel: _dueLabel(task),
                provisional: task.provisional,
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
