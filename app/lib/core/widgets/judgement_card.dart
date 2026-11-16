import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';
import 'q_button.dart';
import 'stat_icon.dart';

/// The Judge's verdict: a stat gem and XP headline (or a too-big warning),
/// three facets (stat is raised and changeable; difficulty and time are
/// recessed), and the reason.
class JudgementCard extends StatelessWidget {
  const JudgementCard({
    super.key,
    required this.stat,
    required this.difficulty,
    required this.minutes,
    required this.xpPreview,
    required this.reason,
    this.provisional = false,
    this.challenged = false,
    this.tooBig = false,
    this.onStatTap,
    this.onSplit,
    this.onMakeBoss,
  });

  final String stat;
  final int difficulty;
  final int minutes;
  final int xpPreview;
  final String reason;
  final bool provisional;
  final bool challenged;
  final bool tooBig;
  final VoidCallback? onStatTap;
  final VoidCallback? onSplit;
  final VoidCallback? onMakeBoss;

  static const _diffWords = ['Easy', 'Light', 'Steady', 'Hard', 'Brutal'];

  @override
  Widget build(BuildContext context) {
    final d = difficulty.clamp(1, 5);
    final statLabel = StatIcon.labelFor(stat);
    return Clay(
      radius: AppRadius.stage,
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.tealDeep),
                const SizedBox(width: 6),
                Expanded(
                  child: Text("THE JUDGE'S VERDICT", style: AppText.label.copyWith(letterSpacing: 0.48)),
                ),
                if (challenged)
                  const _Badge(
                    label: 'Final',
                    icon: Icons.lock_rounded,
                    background: AppColors.tealSoft,
                    color: AppColors.tealDeep,
                  ),
                if (provisional)
                  const _Badge(
                    label: 'Provisional',
                    icon: Icons.hourglass_empty_rounded,
                    background: AppColors.authErrorPill,
                    color: AppColors.errorText,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: tooBig
                ? Row(
                    children: [
                      ClayDot(
                        size: 72,
                        gradient: dotGradient(const Color(0xFFF3B48F), AppColors.error),
                        icon: Icons.warning_amber_rounded,
                        iconSize: 30,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bigger than one sitting', style: AppText.h2.copyWith(height: 23 / 18)),
                            const SizedBox(height: 4),
                            Text('Split it into smaller quests, or make it a boss.', style: AppText.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      StatDot(stat: stat, size: 72),
                      const SizedBox(width: 18),
                      // Saved quests carry no preview; show the stat instead of "0 XP".
                      if (xpPreview <= 0)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$statLabel quest', style: AppText.h2.copyWith(fontSize: 20, height: 26 / 20)),
                              const SizedBox(height: 2),
                              Text('~$minutes min of focus', style: AppText.bodySmall),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Semantics(
                            label: '$xpPreview XP in a full focus session',
                            excludeSemantics: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '$xpPreview',
                                          style: AppText.display.copyWith(
                                            fontSize: 44,
                                            height: 48 / 44,
                                            letterSpacing: -1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('XP', style: AppText.encounter.copyWith(color: AppColors.tealDeep)),
                                  ],
                                ),
                                Text('in a full focus session', style: AppText.bodySmall),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Semantics(
                    button: onStatTap != null,
                    label: 'Stat: $statLabel${onStatTap != null ? '. Change' : ''}',
                    excludeSemantics: true,
                    child: Clay(
                      kind: ClayKind.control,
                      radius: 20,
                      height: 78,
                      onTap: onStatTap,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _Facet(
                        label: 'STAT',
                        value: Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  statLabel,
                                  maxLines: 1,
                                  style: _facetValue.copyWith(color: AppColors.stat(stat)),
                                ),
                              ),
                            ),
                            if (onStatTap != null)
                              const Icon(Icons.unfold_more_rounded, size: 14, color: AppColors.inkMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    label: 'Difficulty $d of 5, ${_diffWords[d - 1]}',
                    excludeSemantics: true,
                    child: Well(
                      height: 78,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _Facet(
                        label: 'DIFFICULTY',
                        value: Row(
                          children: [
                            for (var i = 0; i < 5; i++) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < d ? AppColors.tealDeep : AppColors.handle,
                                ),
                              ),
                              if (i < 4) const SizedBox(width: 4),
                            ],
                          ],
                        ),
                        footer: _diffWords[d - 1],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    label: 'Time about $minutes minutes',
                    excludeSemantics: true,
                    child: Well(
                      height: 78,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _Facet(
                        label: 'TIME',
                        value: Text('~$minutes min', style: _facetValue, maxLines: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why: ',
                  style: AppText.bodySmall.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Expanded(
                  child: Text(reason, style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14)),
                ),
              ],
            ),
          ),
          if (tooBig) ...[
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: QButton(label: 'Split it', variant: QButtonVariant.secondary, onPressed: onSplit),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  flex: 7,
                  child: QButton(label: 'Make it a boss', height: 52, onPressed: onMakeBoss),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static final TextStyle _facetValue = AppText.title.copyWith(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w700,
  );
}

class _Facet extends StatelessWidget {
  const _Facet({required this.label, required this.value, this.footer});

  final String label;
  final Widget value;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: AppText.caption.copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 0.33),
        ),
        const SizedBox(height: 6),
        value,
        if (footer != null) ...[
          const SizedBox(height: 2),
          Text(footer!, style: AppText.caption, maxLines: 1),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.background, required this.color});

  final String label;
  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
