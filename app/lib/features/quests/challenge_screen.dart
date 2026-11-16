import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/q_button.dart';
import 'providers/task_providers.dart';
import 'task_screen.dart';

/// The server's limit for the challenge sentence.
const _maxContext = 280;
const _diffWords = ['TRIVIAL', 'LIGHT', 'MODERATE', 'DEMANDING', 'VERY DEMANDING'];

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
  void initState() {
    super.initState();
    _context.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _context.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _context.text.trim();
    if (text.isEmpty || text.length > _maxContext) {
      setState(() => _error = 'Add one sentence, up to $_maxContext characters.');
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
    final task = ref.watch(taskProvider(widget.taskId)).asData?.value;
    final insets = MediaQuery.paddingOf(context);
    final length = _context.text.characters.length;
    final canSend = _context.text.trim().isNotEmpty && length <= _maxContext && !_busy;
    final d = (task?.difficulty ?? 3).clamp(1, 5);
    return Scaffold(
      backgroundColor: Color.alphaBlend(AppColors.scrim, AppColors.paper),
      body: Padding(
        padding: EdgeInsets.only(top: insets.top + 149),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.16), offset: const Offset(0, -12), blurRadius: 32)],
          ),
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            namesRoute: true,
            label: 'Challenge the Judge',
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 10, AppSpacing.screen, 16),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(color: AppColors.handle, borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text('Challenge the Judge', style: AppText.h1.copyWith(fontSize: 22, height: 28 / 22)),
                                ),
                                if (task != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ClayIconButton(
                            icon: Icons.close_rounded,
                            size: 40,
                            iconSize: 18,
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                      if (task != null) ...[
                        const SizedBox(height: 22),
                        Well(
                          radius: 24,
                          height: 72,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  label: 'Difficulty $d of 5',
                                  excludeSemantics: true,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            for (var i = 0; i < 5; i++)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: i < d ? AppColors.ink : AppColors.handle,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(_diffWords[d - 1], style: AppText.label.copyWith(fontSize: 11, letterSpacing: 0.66)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 16), color: AppColors.hairline),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('~${task.estMinutes ?? 0} min', style: AppText.title.copyWith(fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('TIME', style: AppText.label.copyWith(fontSize: 11, letterSpacing: 0.66)),
                                  ],
                                ),
                              ),
                              Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 16), color: AppColors.hairline),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      task.challenged ? 'Final' : 'Judged',
                                      style: AppText.title.copyWith(fontSize: 16, color: AppColors.tealDeep),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('RATING', style: AppText.label.copyWith(fontSize: 11, letterSpacing: 0.66)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'WHAT DID IT MISS?'),
                            TextSpan(
                              text: '  · one sentence',
                              style: AppText.caption.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0, color: AppColors.inkFaint),
                            ),
                          ],
                        ),
                        style: AppText.label,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: _context.text.isNotEmpty ? [const BoxShadow(color: AppColors.tealDeep, spreadRadius: 2)] : null,
                        ),
                        child: Clay(
                          kind: ClayKind.control,
                          radius: 24,
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _context,
                                textCapitalization: TextCapitalization.sentences,
                                minLines: 3,
                                maxLines: 5,
                                style: AppText.body.copyWith(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500),
                                decoration: InputDecoration.collapsed(
                                  hintText: 'e.g. "It’s 20 sources to read and synthesise, not a quick summary."',
                                  hintStyle: AppText.body.copyWith(fontSize: 16, height: 24 / 16, color: AppColors.placeholder),
                                ).copyWith(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$length / $_maxContext',
                                  style: AppText.caption.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: length > _maxContext ? AppColors.errorText : AppColors.inkFaint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _Rule(strong: 'One challenge per quest.', rest: ' Use it when the rating is clearly off.'),
                      const SizedBox(height: 14),
                      const _Rule(strong: 'The new rating is final.', rest: ' It can go up or down.'),
                      const SizedBox(height: 14),
                      const _Rule(strong: 'Facts about the work only.', rest: ' The Judge ignores requests like "make it a 5".'),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.s16),
                        Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, insets.bottom + 16),
                  child: Opacity(
                    opacity: canSend || _busy ? 1 : 0.45,
                    child: QButton(
                      label: _busy ? 'The Judge is re-reading…' : 'Send to the Judge',
                      icon: _busy ? null : Icons.send_rounded,
                      loading: _busy,
                      onPressed: canSend ? _send : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
