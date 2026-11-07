import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/task_tile.dart';
import '../../data/models/boss.dart';
import '../../data/models/task.dart';
import 'boss_time.dart';
import 'providers/boss_providers.dart';

final bossDetailProvider = FutureProvider.autoDispose.family<Boss?, String>((ref, id) async {
  final client = ref.watch(supabaseClientProvider);
  final row = await client.from('bosses').select().eq('id', id).maybeSingle();
  if (row == null) return null;
  return Boss.fromJson(Map<String, dynamic>.from(row));
});

final bossTasksProvider = FutureProvider.autoDispose.family<List<Task>, String>((ref, bossId) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('tasks')
      .select()
      .eq('boss_id', bossId)
      .order('created_at');
  return [
    for (final row in rows) Task.fromJson(Map<String, dynamic>.from(row as Map)),
  ];
});

/// HP, tasks under the boss, mark submitted.
class BossDetailScreen extends ConsumerStatefulWidget {
  const BossDetailScreen({super.key, required this.bossId});

  final String bossId;

  @override
  ConsumerState<BossDetailScreen> createState() => _BossDetailScreenState();
}

class _BossDetailScreenState extends ConsumerState<BossDetailScreen> {
  var _busy = false;
  String? _error;

  Future<void> _submit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark submitted?', style: AppText.h2),
        content: Text(
          'This finishes the boss and pays loot based on damage dealt.',
          style: AppText.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(apiClientProvider).submitBoss(widget.bossId);
      ref.invalidate(bossesProvider);
      ref.invalidate(bossDetailProvider(widget.bossId));
      if (!mounted) return;
      context.go('/bosses/${widget.bossId}/result', extra: result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not submit this boss.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bossDetailProvider(widget.bossId));
    final tasks = ref.watch(bossTasksProvider(widget.bossId));
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text('Boss', style: AppText.h2)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load boss',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(bossDetailProvider(widget.bossId)),
        ),
        data: (boss) {
          if (boss == null) {
            return const EmptyState(title: 'Boss not found', body: 'It may have escaped or been removed.');
          }
          final remaining = (boss.maxHp - boss.damage).clamp(0, boss.maxHp);
          final hp = boss.maxHp <= 0 ? 0.0 : remaining / boss.maxHp;
          final canSubmit = boss.status == 'active' || boss.status == 'staggered';

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s8,
              AppSpacing.screen,
              120,
            ),
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Image.asset(
                    GameAssets.boss(boss.tier),
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(boss.name, style: AppText.h1, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s8),
              Text(
                '${bossStatusLabel(boss.status)} · ${bossTimeLeft(boss.deadline, now)}',
                style: AppText.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s16),
              ProgressBar(
                value: hp.clamp(0.0, 1.0),
                kind: ProgressKind.bossHp,
                leading: 'HP',
                trailing: '$remaining / ${boss.maxHp}',
              ),
              if (boss.status == 'staggered') ...[
                const SizedBox(height: AppSpacing.s8),
                Text('Staggered — submit to finish it.', style: AppText.bodySmall),
              ],
              if (!boss.coinsEligible) ...[
                const SizedBox(height: AppSpacing.s8),
                Text('No coins on defeat (created under 48 hours).', style: AppText.bodySmall),
              ],
              const SizedBox(height: AppSpacing.s24),
              Row(
                children: [
                  Expanded(child: Text('Tasks', style: AppText.h2)),
                  if (canSubmit)
                    QButton(
                      label: 'Add task',
                      variant: QButtonVariant.secondary,
                      onPressed: () => context.go('/quests/new?bossId=${boss.id}'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              tasks.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Could not load tasks.', style: AppText.bodySmall),
                data: (rows) {
                  if (rows.isEmpty) {
                    return Text('No tasks under this boss yet.', style: AppText.bodySmall);
                  }
                  return Column(
                    children: [
                      for (final task in rows) ...[
                        GestureDetector(
                          onTap: () => context.go('/quests/${task.id}'),
                          child: TaskTile(
                            title: task.title,
                            dueLabel: task.status == 'done'
                                ? 'Done'
                                : task.dueAt == null
                                    ? 'No due date'
                                    : bossTimeLeft(task.dueAt!, now),
                            stat: task.stat ?? 'intellect',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                      ],
                    ],
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
              ],
              if (canSubmit) ...[
                const SizedBox(height: AppSpacing.s24),
                QButton(
                  label: _busy ? 'Submitting…' : 'Mark submitted',
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
