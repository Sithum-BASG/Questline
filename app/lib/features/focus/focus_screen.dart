import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/timer_display.dart';
import 'focus_clock.dart';
import 'session_alerts.dart';

final endSessionProvider = Provider<
    Future<void> Function(String sessionId, List<Map<String, String>> interruptions, {required bool broken})>((ref) {
  return (sessionId, interruptions, {required bool broken}) {
    return ref.read(apiClientProvider).endSession(sessionId, interruptions, broken: broken);
  };
});

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({
    super.key,
    required this.sessionId,
    required this.startedAt,
    required this.estimateMinutes,
    this.mode = 'focus',
    this.grace = const Duration(seconds: 30),
  });

  final String sessionId;
  final DateTime startedAt;
  final int estimateMinutes;
  final String mode;
  final Duration grace;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> with WidgetsBindingObserver {
  late final FocusClock _clock;
  late final SessionAlerts _alerts;
  Timer? _tick;
  String? _error;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _clock = FocusClock(startedAt: widget.startedAt, grace: widget.grace);
    _alerts = ref.read(sessionAlertsProvider);
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (widget.mode == 'activity') {
        _alerts.showOngoing(TimerDisplay.format(_clock.elapsedSeconds(DateTime.now())));
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _alerts.clearOngoing();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _activity => widget.mode == 'activity';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_activity) return;
    final now = DateTime.now();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_clock.leave(now)) {
        _alerts.showReturnPrompt();
      }
    } else if (state == AppLifecycleState.resumed) {
      _clock.returned(now);
      _alerts.clearReturnPrompt();
      if (_clock.broken) {
        _finish(broken: true);
      } else if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _confirmEnd() async {
    final end = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('End session?'),
          content: const Text('Ending now keeps the minutes you have already focused.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep going')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('End')),
          ],
        );
      },
    );
    if (end == true) await _finish(broken: false);
  }

  Future<void> _finish({required bool broken}) async {
    if (_ending) return;
    setState(() {
      _ending = true;
      _error = null;
    });
    try {
      final interruptions = _clock.interruptions.map((item) => item.toJson()).toList();
      final left = _clock.leftAt;
      if (left != null) interruptions.add({'leftAt': left.toUtc().toIso8601String()});
      await ref.read(endSessionProvider)(widget.sessionId, interruptions, broken: broken);
      if (mounted) context.go('/quests');
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _ending = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _clock.elapsedSeconds(DateTime.now());
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmEnd();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              children: [
                const Spacer(),
                Text(_activity ? 'Activity' : 'Focus', style: AppText.h1),
                const SizedBox(height: AppSpacing.s24),
                TimerDisplay(elapsedSeconds: elapsed, estimateSeconds: widget.estimateMinutes * 60),
                if (_clock.broken) ...[
                  const SizedBox(height: AppSpacing.s16),
                  Text('Session ended', style: AppText.body.copyWith(color: AppColors.ink)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
                ],
                const Spacer(),
                QButton(label: 'End session', loading: _ending, onPressed: _ending ? null : _confirmEnd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
