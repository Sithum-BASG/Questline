import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_chip.dart';
import '../quests/providers/task_providers.dart';

final startSessionProvider = Provider<
    Future<StartSessionResult> Function({required String taskId, required String mode, bool usePotion})>((ref) {
  return ({required String taskId, required String mode, bool usePotion = false}) {
    return ref.read(apiClientProvider).startSession(taskId: taskId, mode: mode, usePotion: usePotion);
  };
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
      return const Scaffold(body: EmptyState(title: 'Pick a quest first', body: 'Open a quest, then start a session.'));
    }
    final task = ref.watch(taskProvider(widget.taskId));
    return Scaffold(
      body: SafeArea(
        child: task.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(title: 'Could not open this quest', body: '$error'),
          data: (row) {
            if (row == null) {
              return const EmptyState(title: 'Quest not found', body: 'It may have been discarded.');
            }
            final activity = row.stat == 'vitality' || row.stat == 'charisma';
            final estimate = row.estMinutes ?? 0;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Text(row.title, style: AppText.h1),
                const SizedBox(height: AppSpacing.s16),
                if (activity) ...[
                  Wrap(
                    spacing: AppSpacing.s8,
                    children: [
                      QChip(label: 'Focus', selected: _mode == 'focus', onTap: () => setState(() => _mode = 'focus')),
                      QChip(label: 'Activity', selected: _mode == 'activity', onTap: () => setState(() => _mode = 'activity')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                ],
                if (estimate >= 25)
                  QChip(label: 'Focus potion', selected: _potion, onTap: () => setState(() => _potion = !_potion)),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.s24),
                QButton(
                  label: 'Start',
                  loading: _busy,
                  onPressed: _busy ? null : () => _start(estimate),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _start(int estimate) async {
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
      });
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
