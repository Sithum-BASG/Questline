import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../focus/start_focus_screen.dart';
import '../quests/providers/task_providers.dart';

/// Onboarding step 5–6. A short first session unlocks the starter XP for level 2.
class FirstSessionScreen extends ConsumerStatefulWidget {
  const FirstSessionScreen({super.key});

  @override
  ConsumerState<FirstSessionScreen> createState() => _FirstSessionScreenState();
}

class _FirstSessionScreenState extends ConsumerState<FirstSessionScreen> {
  var _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    return Scaffold(
      body: SafeArea(
        child: tasks.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            title: 'Could not load your quest',
            body: '$error',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(tasksProvider),
          ),
          data: (rows) {
            final open = rows.where((task) => task.status == 'open');
            if (open.isEmpty) {
              return const EmptyState(
                title: 'Save a quest first',
                body: 'Your first judged quest becomes the first focus session.',
              );
            }
            final task = open.first;
            final minutes = task.estMinutes ?? 5;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('First focus', style: AppText.h1),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'Spend about five minutes on "${task.title}". Finishing unlocks your starter XP and level 2.',
                    style: AppText.body,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text('About $minutes minutes', style: AppText.caption),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
                  ],
                  const Spacer(),
                  QButton(
                    label: 'Start focus',
                    loading: _busy,
                    onPressed: _busy
                        ? null
                        : () => _start(
                              taskId: task.id,
                              estimate: minutes,
                              stat: task.stat ?? 'intellect',
                            ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _start({required String taskId, required int estimate, required String stat}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final started = await ref.read(startSessionProvider)(taskId: taskId, mode: 'focus');
      if (!mounted) return;
      context.go('/focus/${started.sessionId}', extra: {
        'startedAt': started.startedAt,
        'estimateMinutes': estimate,
        'mode': 'focus',
        'stat': stat,
        'onboarding': true,
      });
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
