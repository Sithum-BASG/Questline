import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/clay.dart';
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
      appBar: const ClayHeader(closeIcon: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s32),
        children: [
          Semantics(
            header: true,
            child: Text('Disagree?', style: AppText.h1.copyWith(fontSize: 22, height: 28 / 22)),
          ),
          const SizedBox(height: 4),
          Text(
            'Add one sentence about the task. The new rating can go up or down, and it is final.',
            style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'WHAT DID IT MISS?', style: AppText.label),
                TextSpan(text: '  · one sentence', style: AppText.caption.copyWith(color: AppColors.inkFaint)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Clay(
            kind: ClayKind.control,
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: TextField(
              controller: _context,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 5,
              style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              decoration: InputDecoration.collapsed(
                hintText: 'Context',
                hintStyle: AppText.body.copyWith(color: AppColors.placeholder),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          const _Rule(strong: 'One challenge per quest.', rest: ' Use it when the rating is clearly off.'),
          const SizedBox(height: 14),
          const _Rule(strong: 'The new rating is final.', rest: ' It can go up or down.'),
          const SizedBox(height: 14),
          const _Rule(strong: 'Facts about the work only.', rest: ' The Judge ignores requests for a higher score.'),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s16),
            Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: AppSpacing.s32),
          QButton(label: 'Send', icon: Icons.send_rounded, loading: _busy, onPressed: _busy ? null : _send),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.strong, required this.rest});

  final String strong;
  final String rest;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 16, color: AppColors.tealDeep),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(
              TextSpan(
                style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14),
                children: [
                  TextSpan(text: strong, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  TextSpan(text: rest),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
