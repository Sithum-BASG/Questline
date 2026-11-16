import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../focus/focus_session_info.dart';
import '../focus/start_focus_screen.dart';
import '../quests/providers/task_providers.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/clay.dart';
import 'onboarding_skip_button.dart';

/// Starter XP for the first session, and the starter XP already earned before it.
final _starterBonusProvider = FutureProvider.autoDispose<(int, int)>((ref) async {
  final map = await ref.read(gameConfigReaderProvider).load();
  final raw = map['starter_bonus'];
  int pick(String key, int fallback) => raw is Map && raw[key] is num ? (raw[key] as num).round() : fallback;
  return (pick('first_session', 40), pick('character', 20) + pick('first_task', 20));
});

final _graceProvider = FutureProvider.autoDispose<int>(
  (ref) async => (await ref.read(gameConfigReaderProvider).xpRates()).graceSeconds,
);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.s8, 0),
              child: Align(alignment: Alignment.centerRight, child: OnboardingSkipButton()),
            ),
            Expanded(
              child: tasks.when(
                loading: () => const LoadingSkeleton(),
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
                  return _FirstFocusBody(
                    title: task.title,
                    busy: _busy,
                    error: _error,
                    onStart: () => _start(taskId: task.id, estimate: minutes, stat: task.stat ?? 'intellect'),
                  );
                },
              ),
            ),
          ],
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

class _FirstFocusBody extends ConsumerWidget {
  const _FirstFocusBody({required this.title, required this.busy, required this.error, required this.onStart});

  final String title;
  final bool busy;
  final String? error;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(heroLookProvider).asData?.value;
    final (sessionXp, soFar) = ref.watch(_starterBonusProvider).asData?.value ?? (40, 40);
    final grace = ref.watch(_graceProvider).asData?.value ?? 30;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.maxHeight < 640 ? 170.0 : 214.0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.s16),
          children: [
            Center(
              child: Clay(
                kind: ClayKind.control,
                radius: 15,
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, size: 13, color: AppColors.tealDeep),
                    const SizedBox(width: 6),
                    Text(
                      'LAST STEP',
                      style: AppText.label.copyWith(fontSize: 11, letterSpacing: 1.3, color: AppColors.tealDeep),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: FocusMedallion(
                size: size,
                progress: 0,
                ring: FocusRing.idle,
                look: look,
                faceGlow: AppColors.awakeningTeal,
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              header: true,
              child: Text(
                'Five minutes. That’s it.',
                textAlign: TextAlign.center,
                style: AppText.h1.copyWith(fontSize: 26, height: 32 / 26),
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Spend about five minutes on '),
                TextSpan(text: title, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600)),
                const TextSpan(text: '. Finishing unlocks:'),
              ]),
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(fontSize: 15, height: 22 / 15, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Gift(
                    top: Text(
                      '+$sessionXp',
                      style: AppText.numbers.copyWith(fontSize: 22, height: 26 / 22, color: AppColors.tealDeep),
                    ),
                    title: 'Starter XP',
                    note: 'on top of $soFar so far',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Gift(
                    top: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.tealLight, AppColors.tealDeep],
                        ),
                      ),
                      child: Text('2', style: AppText.numbers.copyWith(fontSize: 15, color: AppColors.white)),
                    ),
                    title: 'Level 2',
                    note: 'new rewards',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Gift(
                    top: Image.asset(
                      GameAssets.icon('chest'),
                      width: 36,
                      height: 36,
                      errorBuilder: (context, error, stack) => const Icon(Icons.redeem_rounded, color: AppColors.tealDeep),
                    ),
                    title: 'Free chest',
                    note: 'your first loot',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Well(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: AppColors.emberSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.phonelink_lock_rounded, size: 17, color: AppColors.emberDeep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(
                          text: 'Stay in Questline. ',
                          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: 'Leaving for over $grace seconds ends the session.'),
                      ]),
                      style: AppText.bodySmall.copyWith(height: 18 / 13),
                    ),
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText)),
            ],
            const SizedBox(height: 22),
            QButton(
              label: 'Start 5-minute focus',
              icon: Icons.play_arrow_rounded,
              loading: busy,
              onPressed: busy ? null : onStart,
            ),
          ],
        );
      },
    );
  }
}

class _Gift extends StatelessWidget {
  const _Gift({required this.top, required this.title, required this.note});

  final Widget top;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 22,
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 36, child: Center(child: top)),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title.copyWith(fontSize: 13, height: 17 / 13),
          ),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
