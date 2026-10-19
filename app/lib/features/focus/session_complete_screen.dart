import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';

/// Rewards waiting for the reward moment. The overlay itself arrives with the chest work.
class RewardQueue {
  final List<Map<String, dynamic>> pending = [];

  void add(Iterable<Map<String, dynamic>> rewards) {
    pending.addAll(rewards);
  }
}

final rewardQueueProvider = Provider<RewardQueue>((ref) => RewardQueue());

class SessionCompleteScreen extends ConsumerWidget {
  const SessionCompleteScreen({super.key, required this.summary});

  final Map<String, dynamic> summary;

  int _number(String key) {
    final value = summary[key];
    return value is num ? value.round() : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = summary['rewards'];
    final lines = rewards is List ? rewards.whereType<Map>().toList() : const <Map>[];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary['broken'] == true ? 'Session ended' : 'Session complete', style: AppText.h1),
              const SizedBox(height: AppSpacing.s16),
              Text('${_number('verifiedMinutes')} minutes verified', style: AppText.body),
              const SizedBox(height: AppSpacing.s8),
              Text('${_number('rawXp')} XP', style: AppText.display),
              const SizedBox(height: AppSpacing.s8),
              Text('Final ${_number('finalXp')} XP · level ${_number('level')}', style: AppText.body),
              if (lines.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s20),
                Text('Rewards', style: AppText.h2),
                for (final reward in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s8),
                    child: Text('${reward['id'] ?? reward['type'] ?? 'Reward'}', style: AppText.body),
                  ),
              ],
              const Spacer(),
              QButton(
                label: 'Continue',
                onPressed: () {
                  ref.read(rewardQueueProvider).add(lines.map(Map<String, dynamic>.from));
                  context.go('/quests');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
