import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/api_client.dart';
import '../../core/supabase/auth_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/reward_overlay.dart';
import '../onboarding/onboarding_flags.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.summary['broken'] == true ? 'Session ended' : 'Session complete', style: AppText.h1),
              const SizedBox(height: AppSpacing.s16),
              Text('${_number('verifiedMinutes')} minutes verified', style: AppText.body),
              const SizedBox(height: AppSpacing.s8),
              Text('${_number('rawXp')} XP', style: AppText.display),
              const SizedBox(height: AppSpacing.s8),
              Text('Final ${_number('finalXp')} XP · level ${_number('level')}', style: AppText.body),
              if (widget.summary['onboarding'] == true) ...[
                const SizedBox(height: AppSpacing.s12),
                const Text('Starter XP unlocks level 2 and a free chest.', style: AppText.body),
              ],
              if (lines.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s20),
                Text('Rewards', style: AppText.h2),
                for (final reward in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s8),
                    child: Text('${reward['id'] ?? reward['type'] ?? 'Reward'}', style: AppText.body),
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(_error!, style: AppText.bodySmall),
              ],
              const Spacer(),
              QButton(label: 'Continue', loading: _busy, onPressed: _busy ? null : _continue),
            ],
          ),
        ),
      ),
    );
  }
}
