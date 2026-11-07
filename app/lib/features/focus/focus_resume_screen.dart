import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import 'focus_screen.dart';

class FocusResumeArgs {
  const FocusResumeArgs({
    required this.startedAt,
    required this.estimateMinutes,
    required this.mode,
    required this.stat,
    this.onboarding = false,
  });

  final DateTime startedAt;
  final int estimateMinutes;
  final String mode;
  final String stat;
  final bool onboarding;
}

/// Loads session + task when the route was opened without `extra` (notification tap).
class FocusResumeScreen extends ConsumerWidget {
  const FocusResumeScreen({
    super.key,
    required this.sessionId,
    this.args,
  });

  final String sessionId;
  final FocusResumeArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (args != null) {
      return FocusScreen(
        sessionId: sessionId,
        startedAt: args!.startedAt,
        estimateMinutes: args!.estimateMinutes,
        mode: args!.mode,
        stat: args!.stat,
        onboarding: args!.onboarding,
      );
    }

    final async = ref.watch(_resumeProvider(sessionId));
    return async.when(
      loading: () => const Scaffold(body: LoadingSkeleton()),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text('Focus', style: AppText.h2)),
        body: EmptyState(
          title: 'Could not resume session',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(_resumeProvider(sessionId)),
        ),
      ),
      data: (loaded) {
        if (loaded == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Focus', style: AppText.h2)),
            body: const EmptyState(
              title: 'Session not found',
              body: 'It may have already ended.',
            ),
          );
        }
        return FocusScreen(
          sessionId: sessionId,
          startedAt: loaded.startedAt,
          estimateMinutes: loaded.estimateMinutes,
          mode: loaded.mode,
          stat: loaded.stat,
        );
      },
    );
  }
}

class _LoadedFocus {
  const _LoadedFocus({
    required this.startedAt,
    required this.estimateMinutes,
    required this.mode,
    required this.stat,
  });

  final DateTime startedAt;
  final int estimateMinutes;
  final String mode;
  final String stat;
}

final _resumeProvider = FutureProvider.autoDispose.family<_LoadedFocus?, String>((ref, sessionId) async {
  final client = ref.watch(supabaseClientProvider);
  final session = await client.from('sessions').select().eq('id', sessionId).maybeSingle();
  if (session == null) return null;
  if (session['status'] != 'active') return null;
  final startedRaw = session['started_at'];
  final startedAt = startedRaw is String ? DateTime.parse(startedRaw) : DateTime.now();
  final mode = session['mode'] as String? ?? 'focus';
  final taskId = session['task_id'] as String?;
  var estimate = 25;
  var stat = 'intellect';
  if (taskId != null) {
    final task = await client.from('tasks').select('est_minutes, stat').eq('id', taskId).maybeSingle();
    estimate = (task?['est_minutes'] as num?)?.toInt() ?? 25;
    stat = task?['stat'] as String? ?? 'intellect';
  }
  return _LoadedFocus(
    startedAt: startedAt.toLocal(),
    estimateMinutes: estimate,
    mode: mode,
    stat: stat,
  );
});
