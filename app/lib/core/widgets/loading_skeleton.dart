import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/shadows.dart';

/// Card-shaped placeholders for full-screen loading (App Flow §7).
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.cards = 4});

  final int cards;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s16,
        AppSpacing.screen,
        AppSpacing.aboveTabBar,
      ),
      itemCount: cards,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        final wide = index == 0;
        return Container(
          height: wide ? 160 : 88,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bone(width: wide ? 180 : 120, height: 14),
              const SizedBox(height: AppSpacing.s12),
              const _Bone(width: double.infinity, height: 10),
              if (wide) ...[
                const SizedBox(height: AppSpacing.s8),
                const _Bone(width: 220, height: 10),
                const Spacer(),
                const _Bone(width: double.infinity, height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bone = Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
    if (width == double.infinity) {
      return SizedBox(width: double.infinity, child: bone);
    }
    return bone;
  }
}
