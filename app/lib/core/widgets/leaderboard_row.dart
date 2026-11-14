import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';
import 'portrait_frame.dart';

/// One leaderboard line: rank, framed portrait, name and title, weekly XP.
/// "You" sits in a teal-ringed clay row; others are clay rows, or bare rows
/// for stacking inside a [ClayList] when [card] is false.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.name,
    required this.title,
    required this.xp,
    required this.skinId,
    required this.backgroundId,
    required this.frameId,
    required this.body,
    this.isYou = false,
    this.onTap,
    this.card = true,
    this.subtitle,
  });

  final int rank;
  final String name;
  final String title;
  final int xp;
  final String skinId;
  final String backgroundId;
  final String frameId;
  final BodyType body;
  final bool isYou;
  final VoidCallback? onTap;

  /// Wrap the row in its own clay card.
  final bool card;

  /// Optional extra line (e.g. rank movement).
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => AppColors.legendary,
      2 => AppColors.common,
      3 => const Color(0xFFCD8B4E),
      _ => null,
    };

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: medal == null
                  ? Text(
                      '$rank',
                      textAlign: TextAlign.center,
                      style: AppText.numbers.copyWith(color: isYou ? AppColors.tealDeep : AppColors.inkMuted),
                    )
                  : Center(
                      child: ClayDot(
                        size: 26,
                        gradient: dotGradient(Color.lerp(medal, AppColors.white, 0.45)!, medal),
                        child: Text(
                          '$rank',
                          style: AppText.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            PortraitFrame(
              skinId: skinId,
              backgroundId: backgroundId,
              frameId: frameId,
              body: body,
              size: PortraitFrameSize.leaderboard,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppText.title.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isYou) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.tealSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'You',
                            style: AppText.caption.copyWith(color: AppColors.tealDeep, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle ?? title, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$xp', style: AppText.numbers),
                  TextSpan(text: ' XP', style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    Widget child;
    if (card || isYou) {
      child = Clay(
        radius: AppRadius.card,
        onTap: onTap,
        gradient: isYou
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.tealWash, AppColors.white],
              )
            : null,
        border: isYou ? Border.all(color: AppColors.awakeningTeal, width: 2) : null,
        child: row,
      );
    } else {
      child = onTap == null
          ? row
          : Material(type: MaterialType.transparency, child: InkWell(onTap: onTap, child: row));
    }

    return Semantics(
      button: onTap != null,
      label: '$name, rank $rank, $xp XP${isYou ? ', you' : ''}',
      child: child,
    );
  }
}
