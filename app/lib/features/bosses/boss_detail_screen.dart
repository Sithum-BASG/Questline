import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/widgets/clay.dart';

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
      appBar: const ClayHeader(title: 'Boss'),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load boss',
          body: 'Check your connection and try again.',
          icon: Icons.cloud_off_rounded,
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(bossDetailProvider(widget.bossId)),
        ),
        data: (boss) {
          if (boss == null) {
            return const EmptyState(
              title: 'Boss not found',
              body: 'It may have escaped or been removed.',
              icon: Icons.search_off_rounded,
            );
          }
          final remaining = (boss.maxHp - boss.damage).clamp(0, boss.maxHp);
          final hp = boss.maxHp <= 0 ? 0.0 : remaining / boss.maxHp;
          final canSubmit = boss.status == 'active' || boss.status == 'staggered';

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 64, AppSpacing.screen, 48),
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Clay(
                    radius: AppRadius.stage,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 170,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const RadialGradient(
                              center: Alignment(0, 0.4),
                              radius: 0.9,
                              colors: [Color(0xFFF4F3FF), Color(0xFFD9DBF7), Color(0xFF9EA3DA)],
                              stops: [0, 0.42, 1],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  boss.name,
                                  style: AppText.h1.copyWith(fontSize: 24, height: 30 / 24),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.s8,
                                runSpacing: AppSpacing.s8,
                                children: [
                                  _Tag(
                                    label: bossStatusLabel(boss.status),
                                    background: boss.status == 'staggered' ? AppColors.ink : AppColors.well,
                                    color: boss.status == 'staggered' ? AppColors.white : AppColors.inkMuted,
                                  ),
                                  _Tag(
                                    label: boss.tier[0].toUpperCase() + boss.tier.substring(1),
                                    background: AppColors.bossHpSoft,
                                    color: AppColors.bossHpText,
                                  ),
                                  _Tag(
                                    label: bossTimeLeft(boss.deadline, now),
                                    icon: Icons.schedule_rounded,
                                    background: AppColors.bossHpSoft,
                                    color: AppColors.bossHpText,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s20),
                              ProgressBar(
                                value: hp.clamp(0.0, 1.0),
                                kind: ProgressKind.bossHp,
                                height: 18,
                                leading: 'HP',
                                trailing: '$remaining / ${boss.maxHp} HP',
                                trailingColor: AppColors.ink,
                              ),
                              if (boss.status == 'staggered') ...[
                                const SizedBox(height: AppSpacing.s12),
                                Text(
                                  'Staggered — submit to finish it.',
                                  style: AppText.bodySmall.copyWith(color: AppColors.tealDeep, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (!boss.coinsEligible) ...[
                                const SizedBox(height: AppSpacing.s8),
                                Text(
                                  'No coins on defeat (created under 48 hours).',
                                  style: AppText.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -58,
                    child: IgnorePointer(child: Center(child: BossArt(tier: boss.tier, size: 220))),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: Semantics(header: true, child: Text('Tasks', style: AppText.h2))),
                  if (canSubmit)
                    ClayPill(
                      label: 'Add task',
                      icon: Icons.add_rounded,
                      color: AppColors.tealDeep,
                      onPressed: () => context.go('/quests/new?bossId=${boss.id}'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              tasks.when(
                loading: () => Text('Loading tasks…', style: AppText.bodySmall),
                error: (error, _) => Text('Could not load tasks.', style: AppText.bodySmall),
                data: (rows) {
                  if (rows.isEmpty) {
                    return Well(
                      radius: 24,
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'No tasks under this boss yet.',
                        style: AppText.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ClayList(
                    children: [
                      for (final task in rows)
                        TaskTile(
                          bare: true,
                          onTap: () => context.go('/quests/${task.id}'),
                          title: task.title,
                          dueLabel: task.status == 'done'
                              ? 'Done'
                              : task.dueAt == null
                                  ? 'No due date'
                                  : bossTimeLeft(task.dueAt!, now),
                          stat: task.stat ?? 'intellect',
                        ),
                    ],
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500)),
              ],
              if (canSubmit) ...[
                const SizedBox(height: AppSpacing.s32),
                QButton(
                  label: _busy ? 'Submitting…' : 'Mark submitted',
                  icon: Icons.flag_rounded,
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.background, required this.color, this.icon});

  final String label;
  final Color background;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
