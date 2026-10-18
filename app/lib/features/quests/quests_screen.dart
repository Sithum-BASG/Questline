import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_chip.dart';
import '../../core/widgets/task_tile.dart';
import 'providers/task_providers.dart';
import 'quest_filters.dart';

/// Today, upcoming and done, with a stat filter. Adding a task opens the draft sheet.
class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key, this.now});

  final DateTime? now;

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  var _bucket = QuestBucket.today;
  String? _stat;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final now = widget.now ?? DateTime.now();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s16, AppSpacing.screen, 0),
              child: Row(
                children: [
                  Text('Quests', style: AppText.h1),
                  const Spacer(),
                  QButton(
                    label: 'Add',
                    onPressed: () => context.push('/quests/new'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Row(
                children: [
                  for (final bucket in QuestBucket.values) ...[
                    QChip(
                      label: _bucketLabel(bucket),
                      selected: _bucket == bucket,
                      onTap: () => setState(() => _bucket = bucket),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Row(
                children: [
                  QChip(label: 'All', selected: _stat == null, onTap: () => setState(() => _stat = null)),
                  const SizedBox(width: AppSpacing.s8),
                  for (final stat in const ['intellect', 'vitality', 'craft', 'charisma']) ...[
                    QChip(
                      label: stat[0].toUpperCase() + stat.substring(1),
                      kind: QChipKind.stat,
                      color: AppColors.stat(stat),
                      selected: _stat == stat,
                      onTap: () => setState(() => _stat = stat),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Expanded(
              child: tasks.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => EmptyState(
                  title: 'Could not load quests',
                  body: 'Check your connection and try again.',
                  actionLabel: 'Try again',
                  onAction: () => ref.invalidate(tasksProvider),
                ),
                data: (rows) {
                  final visible = tasksForBucket(rows, _bucket, _stat, now);
                  if (visible.isEmpty) {
                    return EmptyState(title: _emptyTitle(_bucket), body: _emptyBody(_bucket));
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      0,
                      AppSpacing.screen,
                      AppSpacing.aboveTabBar,
                    ),
                    children: [
                      for (final task in visible) ...[
                        TaskTile(
                          title: task.title,
                          stat: task.stat ?? 'intellect',
                          dueLabel: dueLabel(task, now),
                          late: taskIsLate(task, now),
                          provisional: task.provisional,
                        ),
                        const SizedBox(height: AppSpacing.s8),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _bucketLabel(QuestBucket bucket) {
  switch (bucket) {
    case QuestBucket.today:
      return 'Today';
    case QuestBucket.upcoming:
      return 'Upcoming';
    case QuestBucket.done:
      return 'Done';
  }
}

String _emptyTitle(QuestBucket bucket) {
  switch (bucket) {
    case QuestBucket.today:
      return 'Nothing due today';
    case QuestBucket.upcoming:
      return 'No upcoming quests';
    case QuestBucket.done:
      return 'Nothing done yet';
  }
}

String _emptyBody(QuestBucket bucket) {
  switch (bucket) {
    case QuestBucket.today:
      return 'Add a quest and the judge will rate it.';
    case QuestBucket.upcoming:
      return 'Tasks with a later due date show up here.';
    case QuestBucket.done:
      return 'Finished quests will be listed here.';
  }
}
