import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/local_notifications.dart';
import '../../core/notifications/notification_replan.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/reward_overlay.dart';
import '../onboarding/onboarding_flags.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/clay.dart';

class SessionCompleteScreen extends ConsumerStatefulWidget {
  const SessionCompleteScreen({super.key, required this.summary});

  final Map<String, dynamic> summary;

  @override
  ConsumerState<SessionCompleteScreen> createState() => _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends ConsumerState<SessionCompleteScreen> {
  var _busy = false;
  String? _error;

  int _number(String key) {
    final value = widget.summary[key];
    return value is num ? value.round() : 0;
  }

  List<RewardMoment> _momentsFromSummary() {
    final rewards = widget.summary['rewards'];
    if (rewards is! List) return const [];
    return rewards.whereType<Map>().map((reward) {
      final type = reward['type'] as String? ?? 'item';
      final id = reward['id'] as String?;
      if (type == 'title') {
        return RewardMoment(kind: RewardKind.levelUp, title: 'New title', subtitle: id ?? 'Title unlocked');
      }
      if (type == 'coins') {
        return RewardMoment(
          kind: RewardKind.loot,
          title: '+${reward['amount'] ?? 0} coins',
          subtitle: 'Level reward',
          rarity: 'common',
        );
      }
      return RewardMoment(
        kind: RewardKind.loot,
        title: id ?? 'New item',
        subtitle: 'Level reward',
        rarity: 'common',
      );
    }).toList();
  }

  Future<void> _continue() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Ask once after the first completed session (overview §18 / plan 13.1).
      // Never block Continue if the plugin/channel is unavailable (tests, cold hosts).
      try {
        await ref.read(localNotificationsProvider).requestPermissionAfterFirstSession();
      } catch (_) {}
      try {
        await replanLocalNotifications(ref);
      } catch (_) {}
      if (widget.summary['onboarding'] == true) {
        await ref.read(completeOnboardingProvider)('first_session');
        ref.invalidate(onboardingStepProvider);
        ref.read(pendingOnboardingChestProvider.notifier).setPending(true);
      }
      final queue = ref.read(rewardQueueProvider);
      queue.add(_momentsFromSummary());
      if (!mounted) return;
      if (queue.pending.isNotEmpty || queue.current != null) {
        queue.next();
        context.go('/reward');
      } else if (widget.summary['onboarding'] == true) {
        context.go('/onboarding/chest');
      } else {
        context.go('/quests');
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewards = widget.summary['rewards'];
    final lines = rewards is List ? rewards.whereType<Map>().toList() : const <Map>[];
    final broken = widget.summary['broken'] == true;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 40, AppSpacing.screen, AppSpacing.s24),
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    broken ? Icons.timer_off_rounded : Icons.check_circle_rounded,
                    size: 14,
                    color: broken ? AppColors.errorText : AppColors.tealDeep,
                  ),
                  const SizedBox(width: 6),
                  Semantics(
                    header: true,
                    label: broken ? 'Session ended' : 'Session complete',
                    excludeSemantics: true,
                    child: Text(
                      broken ? 'SESSION ENDED' : 'SESSION COMPLETE',
                      style: AppText.label.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: broken ? AppColors.errorText : AppColors.tealDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: SizedBox(
                width: 182,
                height: 182,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Clay(circle: true, width: 182, height: 182),
                    Well(
                      circle: true,
                      width: 160,
                      height: 160,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          value: broken ? 0.6 : 1,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          color: broken ? AppColors.inkFaint : AppColors.awakeningTeal,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                    Clay(
                      circle: true,
                      width: 124,
                      height: 124,
                      child: Icon(
                        broken ? Icons.hourglass_bottom_rounded : Icons.auto_awesome_rounded,
                        size: 44,
                        color: broken ? AppColors.inkMuted : AppColors.tealDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('+${_number('rawXp')}', style: AppText.display.copyWith(fontSize: 52, height: 56 / 52, letterSpacing: -2)),
                  const SizedBox(width: 6),
                  Text('XP', style: AppText.h2.copyWith(fontSize: 20, color: AppColors.tealDeep)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Clay(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                children: [
                  _Row(label: '${_number('verifiedMinutes')} minutes verified', value: '${_number('verifiedMinutes')}'),
                  _Row(label: 'Level', value: '${_number('level')}'),
                  const SizedBox(height: 8),
                  const Divider(height: 1, thickness: 1, color: AppColors.hairline),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text('Total', style: AppText.title.copyWith(fontSize: 15, fontWeight: FontWeight.w700))),
                      Text(
                        '${_number('finalXp')} XP',
                        style: AppText.numbers.copyWith(fontSize: 17, color: AppColors.tealDeep),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.summary['onboarding'] == true) ...[
              const SizedBox(height: AppSpacing.s16),
              Well(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: AppColors.tealDeep, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Starter XP unlocks level 2 and a free chest.', style: AppText.bodySmall.copyWith(color: AppColors.ink)),
                    ),
                  ],
                ),
              ),
            ],
            if (lines.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s24),
              const SectionLabel(label: 'Rewards'),
              const SizedBox(height: AppSpacing.s12),
              ClayList(
                dividerIndent: 58,
                children: [
                  for (final reward in lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          ClayDot(
                            size: 32,
                            gradient: dotGradient(AppColors.legendary.withValues(alpha: 0.6), AppColors.legendary),
                            icon: Icons.star_rounded,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('${reward['id'] ?? reward['type'] ?? 'Reward'}', style: AppText.item),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText)),
            ],
          ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s16),
              child: QButton(label: 'Continue', loading: _busy, onPressed: _busy ? null : _continue),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.bodySmall.copyWith(fontSize: 14, color: AppColors.inkMuted))),
          Text(value, style: AppText.numbers.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}
