import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_state.dart';
import '../quests/add_task_screen.dart';
import '../quests/providers/task_providers.dart';
import '../quests/task_screen.dart';

/// Onboarding step 4. The boss toggle stays hidden until bosses exist.
class FirstTaskScreen extends ConsumerWidget {
  const FirstTaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    return tasks.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: EmptyState(
          title: 'Could not load your quest',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(tasksProvider),
        ),
      ),
      data: (rows) {
        final draft = rows.where((task) => task.status == 'draft');
        if (draft.isNotEmpty) {
          return TaskScreen(taskId: draft.first.id, onboarding: true);
        }
        return const AddTaskScreen(onboarding: true);
      },
    );
  }
}
