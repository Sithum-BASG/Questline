import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';

/// Social hub. Leaderboard / feed / guild fill in later phase tasks.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Text('Social', style: AppText.h1),
            const SizedBox(height: AppSpacing.s16),
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
