import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_card.dart';
import 'providers/profile_providers.dart';

class LevelRoadRow {
  const LevelRoadRow({required this.level, required this.label, required this.reached});

  final int level;
  final String label;
  final bool reached;
}

final levelRoadProvider = FutureProvider<List<LevelRoadRow>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final profile = await ref.watch(profileViewProvider.future);
  final rows = await client.from('level_rewards').select('level, rewards').order('level');
  return [
    for (final row in rows)
      LevelRoadRow(
        level: (row['level'] as num).toInt(),
        label: _labelFor(row['rewards']),
        reached: profile.profile.level >= (row['level'] as num).toInt(),
      ),
  ];
});

String _labelFor(dynamic rewards) {
  if (rewards is! List || rewards.isEmpty) return 'Reward';
  final parts = <String>[];
  for (final entry in rewards) {
    if (entry is! Map) continue;
    final type = entry['type'] as String? ?? 'item';
    if (type == 'coins') {
      parts.add('${entry['amount'] ?? 0} coins');
    } else if (type == 'title') {
      parts.add((entry['id'] as String? ?? 'title').replaceAll('_', ' '));
    } else {
      parts.add((entry['id'] as String? ?? 'item').replaceAll('_', ' '));
    }
  }
  return parts.isEmpty ? 'Reward' : parts.join(' · ');
}

/// Levels 1–50 rewards list. Reached levels are teal.
class LevelRoadScreen extends ConsumerWidget {
  const LevelRoadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(levelRoadProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Level road', style: AppText.h2)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load level road',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(levelRoadProvider),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyState(title: 'No rewards yet', body: 'Level rewards will show here.');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s16,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            itemCount: rows.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s8),
            itemBuilder: (context, index) {
              final row = rows[index];
              return QCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: row.reached ? AppColors.awakeningTeal.withValues(alpha: 0.2) : AppColors.line,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Text(
                        '${row.level}',
                        style: AppText.numbers.copyWith(
                          color: row.reached ? AppColors.tealDeep : AppColors.inkMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        row.label,
                        style: AppText.body.copyWith(
                          color: row.reached ? AppColors.ink : AppColors.inkMuted,
                        ),
                      ),
                    ),
                    if (row.reached) Icon(Icons.check, color: AppColors.success, size: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
