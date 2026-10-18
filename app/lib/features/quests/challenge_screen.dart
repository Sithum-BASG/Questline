import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import 'providers/task_providers.dart';
import 'task_screen.dart';

/// One sentence of extra context. The result replaces the judgement and is final.
class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  final _context = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _context.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _context.text.trim();
    if (text.isEmpty || text.length > 280) {
      setState(() => _error = 'Add one sentence, up to 280 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(challengeActionProvider)(widget.taskId, text);
      ref.invalidate(taskProvider(widget.taskId));
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/quests/${widget.taskId}');
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not send the challenge. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Text('Disagree?', style: AppText.h1),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Add one sentence about the task. The new rating can go up or down, and it is final.',
              style: AppText.body.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _context,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Context'),
              style: AppText.body,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.s20),
            QButton(label: 'Send', loading: _busy, onPressed: _busy ? null : _send),
          ],
        ),
      ),
    );
  }
}
