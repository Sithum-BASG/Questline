import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import 'providers/friends_providers.dart';
import 'providers/presence_providers.dart';

/// Social hub. Leaderboard / feed / guild fill in later phase tasks.
class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusing = ref.watch(focusingFriendsProvider).asData?.value ?? const {};
    final friends = ref.watch(friendRowsProvider).asData?.value.accepted ?? const [];
    final focusingNames = [
      for (final row in friends)
        if (focusing.containsKey(row.profile.id)) row.profile.displayName,
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Text('Social', style: AppText.h1),
            const SizedBox(height: AppSpacing.s16),
            if (focusingNames.isNotEmpty) ...[
              QCard(
                child: Row(
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      child: SizedBox(width: 12, height: 12),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        'Focusing now: ${focusingNames.join(', ')}',
                        style: AppText.body,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            QCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Friends', style: AppText.h2),
                  const SizedBox(height: AppSpacing.s8),
                  Text('Add by username or friend code, accept requests.', style: AppText.bodySmall),
                  const SizedBox(height: AppSpacing.s12),
                  QButton(
                    label: 'Open friends',
                    onPressed: () => context.go('/social/friends'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            QCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Leaderboard', style: AppText.h2),
                  const SizedBox(height: AppSpacing.s8),
                  Text('Weekly ranks with friends land next.', style: AppText.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            QCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Feed', style: AppText.h2),
                  const SizedBox(height: AppSpacing.s8),
                  Text('Friend activity will show here.', style: AppText.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
