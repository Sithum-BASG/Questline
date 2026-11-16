import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'clay.dart';

/// Clay card placeholders for full-screen loading (App Flow §7).
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.cards = 4});

  final int cards;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s24, AppSpacing.screen, AppSpacing.aboveTabBar),
        itemCount: cards,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s20),
        itemBuilder: (context, index) {
          final wide = index == 0;
          return Clay(
            height: wide ? 180 : 88,
            radius: AppRadius.feature,
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                if (!wide) ...[const Well(circle: true, width: 40, height: 40), const SizedBox(width: AppSpacing.s12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      FractionallySizedBox(
                        widthFactor: wide ? 0.5 : 0.6,
                        child: const Well(height: 14, radius: 7, shade: wellInnerShadeSm),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      const Well(height: 10, radius: 5, shade: wellInnerShadeSm),
                      if (wide) ...[
                        const SizedBox(height: AppSpacing.s8),
                        const FractionallySizedBox(
                          widthFactor: 0.7,
                          child: Well(height: 10, radius: 5, shade: wellInnerShadeSm),
                        ),
                        const Spacer(),
                        const Well(height: 12, radius: 6, shade: wellInnerShadeSm),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
