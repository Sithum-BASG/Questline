import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../parent_route.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../theme/shadows.dart';

// -----------------------------------------------------------------------------
// Clay surfaces (phase 17 redesign).
//
// Every raised surface is a soft white (or teal) body lit from the top-left:
// an outer shadow pair (dark bottom-right, white top-left) plus a faint inner
// light. Sunken wells are the reverse. These widgets are the only place the
// recipe lives; screens compose them.
// -----------------------------------------------------------------------------

/// White clay body gradient (145°).
const LinearGradient clayWhiteGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.white, AppColors.clayFace],
);

/// Teal clay body gradient (145°).
const LinearGradient clayTealGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.tealButtonStart, AppColors.tealButtonEnd],
);

/// Destructive clay body gradient (145°).
const LinearGradient clayDangerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFEA580C), AppColors.errorText],
);

/// XP fill (top to bottom).
const LinearGradient xpFillGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.tealLight, AppColors.awakeningTeal],
);

/// Boss HP fill (top to bottom).
const LinearGradient hpFillGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.bossHpLight, AppColors.bossHp],
);

/// Streak fill (top to bottom).
const LinearGradient emberFillGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.emberLight, AppColors.ember],
);

/// Clay dot gradient for a stat (light top-left to the stat colour).
LinearGradient statGradient(String stat) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.statLight(stat), AppColors.stat(stat)],
);

/// Clay dot gradient from any colour pair.
LinearGradient dotGradient(Color light, Color deep) =>
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, deep]);

/// One inner shadow. [offset] follows CSS `inset x y`: a positive offset
/// darkens the top-left inner edge.
class InnerShadow {
  const InnerShadow(this.offset, this.blur, this.color);

  final Offset offset;
  final double blur;
  final Color color;
}

/// Inner light for raised white clay.
const List<InnerShadow> clayInnerLight = [
  InnerShadow(Offset(-3, -4), 10, Color(0x0D101935)),
  InnerShadow(Offset(3, 3), 8, AppColors.white),
];

/// Inner light for raised teal clay.
const List<InnerShadow> tealInnerLight = [
  InnerShadow(Offset(-4, -5), 10, Color(0x2E000000)),
  InnerShadow(Offset(4, 4), 10, Color(0x47FFFFFF)),
];

/// Inner shade for a sunken well.
const List<InnerShadow> wellInnerShade = [
  InnerShadow(Offset(4, 4), 10, Color(0x1A101935)),
  InnerShadow(Offset(-4, -4), 10, Color(0xE6FFFFFF)),
];

/// Small-well variant for bars and tiny slots.
const List<InnerShadow> wellInnerShadeSm = [
  InnerShadow(Offset(2, 2), 4, Color(0x1F101935)),
  InnerShadow(Offset(-2, -2), 4, Color(0xE6FFFFFF)),
];

/// Gloss on clay dots and gems.
const List<InnerShadow> dotGloss = [
  InnerShadow(Offset(-3, -3), 6, Color(0x24000000)),
  InnerShadow(Offset(3, 3), 6, Color(0x66FFFFFF)),
];

/// Paints [shadows] inside a rounded rect (or circle).
class InnerShadowPainter extends CustomPainter {
  const InnerShadowPainter({required this.shadows, this.borderRadius = BorderRadius.zero, this.circle = false});

  final List<InnerShadow> shadows;
  final BorderRadius borderRadius;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = circle
        ? RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide / 2))
        : borderRadius.toRRect(rect);
    canvas.save();
    canvas.clipRRect(shape);
    for (final s in shadows) {
      final path = Path()
        ..addRect(rect.inflate(s.blur * 2 + 40))
        ..addRRect(shape.shift(s.offset))
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.blur / 2),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant InnerShadowPainter oldDelegate) =>
      oldDelegate.shadows != shadows || oldDelegate.borderRadius != borderRadius || oldDelegate.circle != circle;
}

enum ClayKind {
  /// `.c-clay`: raised white card.
  card,

  /// `.c-clay-sm`: small raised white control.
  control,

  /// `.c-teal`: raised teal primary surface.
  teal,

  /// White clay sitting on world art.
  onScene,

  /// Teal clay sitting on world art.
  tealOnScene,

  /// Destructive (red-orange) clay.
  danger,
}

/// A raised clay surface. Tappable when [onTap] is set; the ripple is
/// clipped to the same shape.
class Clay extends StatelessWidget {
  const Clay({
    super.key,
    this.child,
    this.kind = ClayKind.card,
    this.radius = AppRadius.feature,
    this.circle = false,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.semanticLabel,
    this.gradient,
    this.shadows,
    this.border,
  });

  final Widget? child;
  final ClayKind kind;
  final double radius;
  final bool circle;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Overrides the body gradient (e.g. a tinted clay chip).
  final Gradient? gradient;

  /// Overrides the outer shadows.
  final List<BoxShadow>? shadows;

  /// Optional ring (selected states).
  final BoxBorder? border;

  bool get _teal => kind == ClayKind.teal || kind == ClayKind.tealOnScene || kind == ClayKind.danger;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(circle ? 9999 : radius);
    final body =
        gradient ??
        switch (kind) {
          ClayKind.teal || ClayKind.tealOnScene => clayTealGradient,
          ClayKind.danger => clayDangerGradient,
          _ => clayWhiteGradient,
        };
    final outer =
        shadows ??
        switch (kind) {
          ClayKind.card => AppShadows.clayCard,
          ClayKind.control => AppShadows.clayControl,
          ClayKind.teal => AppShadows.clayTeal,
          ClayKind.danger => const [BoxShadow(color: Color(0x4DC2410C), offset: Offset(8, 10), blurRadius: 22)],
          ClayKind.onScene || ClayKind.tealOnScene => AppShadows.onScene,
        };

    Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: circle ? const CircleBorder() : RoundedRectangleBorder(borderRadius: borderRadius),
          child: content,
        ),
      );
    }

    Widget box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: body,
        borderRadius: circle ? null : borderRadius,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: outer,
      ),
      foregroundDecoration: border == null
          ? null
          : BoxDecoration(
              border: border,
              borderRadius: circle ? null : borderRadius,
              shape: circle ? BoxShape.circle : BoxShape.rectangle,
            ),
      child: CustomPaint(
        painter: InnerShadowPainter(
          shadows: _teal ? tealInnerLight : clayInnerLight,
          borderRadius: borderRadius,
          circle: circle,
        ),
        child: ClipRRect(borderRadius: borderRadius, child: content),
      ),
    );

    if (semanticLabel != null) {
      box = Semantics(button: onTap != null, label: semanticLabel, child: box);
    }
    return box;
  }
}

/// A sunken well (inputs, bar tracks, empty slots).
class Well extends StatelessWidget {
  const Well({
    super.key,
    this.child,
    this.radius = AppRadius.field,
    this.circle = false,
    this.padding,
    this.width,
    this.height,
    this.color = AppColors.well,
    this.shade = wellInnerShade,
    this.onTap,
  });

  final Widget? child;
  final double radius;
  final bool circle;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color color;
  final List<InnerShadow> shade;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(circle ? 9999 : radius);
    Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: circle ? const CircleBorder() : RoundedRectangleBorder(borderRadius: borderRadius),
          child: content,
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: circle ? null : borderRadius,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: CustomPaint(
        foregroundPainter: InnerShadowPainter(shadows: shade, borderRadius: borderRadius, circle: circle),
        child: ClipRRect(borderRadius: borderRadius, child: content),
      ),
    );
  }
}

/// Glossy filled bar in a sunken track.
class ClayBar extends StatelessWidget {
  const ClayBar({
    super.key,
    required this.value,
    this.gradient = xpFillGradient,
    this.height = 10,
    this.duration = const Duration(milliseconds: 600),
  });

  final double value;
  final Gradient gradient;
  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Well(
      height: height,
      radius: height / 2,
      shade: wellInnerShadeSm,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: clamped),
        duration: duration,
        curve: Curves.easeOut,
        builder: (context, factor, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: factor,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(height / 2)),
            child: CustomPaint(
              painter: InnerShadowPainter(
                shadows: const [InnerShadow(Offset(0, 2), 2, Color(0x73FFFFFF))],
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glossy colour dot holding an icon (stat gems, row icons).
class ClayDot extends StatelessWidget {
  const ClayDot({
    super.key,
    required this.gradient,
    this.icon,
    this.child,
    this.size = 40,
    this.iconSize,
    this.semanticLabel,
  });

  final Gradient gradient;
  final IconData? icon;
  final Widget? child;
  final double size;
  final double? iconSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient, boxShadow: AppShadows.dot),
      child: CustomPaint(
        painter: const InnerShadowPainter(shadows: dotGloss, circle: true),
        child: Center(
          child: child ?? (icon == null ? null : Icon(icon, size: iconSize ?? size * 0.45, color: AppColors.white)),
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: dot);
    return Semantics(image: true, label: semanticLabel, excludeSemantics: true, child: dot);
  }
}

/// Round clay icon button (44–48 px) with an optional unread dot.
class ClayIconButton extends StatelessWidget {
  const ClayIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 44,
    this.iconSize = 20,
    this.color = AppColors.ink,
    this.badge = false,
    this.kind = ClayKind.control,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final double iconSize;
  final Color color;
  final bool badge;
  final ClayKind kind;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: SizedBox(
          width: size < AppSpacing.minTap ? AppSpacing.minTap : size,
          height: size < AppSpacing.minTap ? AppSpacing.minTap : size,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Clay(
                  kind: kind,
                  circle: true,
                  width: size,
                  height: size,
                  onTap: onPressed,
                  child: Center(
                    child: Icon(icon, size: iconSize, color: color),
                  ),
                ),
                if (badge)
                  Positioned(
                    top: size * 0.19,
                    right: size * 0.21,
                    child: IgnorePointer(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill action ("Edit", "Join", "Claim", "Mark all read").
class ClayPill extends StatelessWidget {
  const ClayPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = ClayKind.control,
    this.height = 40,
    this.color,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ClayKind kind;
  final double height;
  final Color? color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final teal = kind == ClayKind.teal || kind == ClayKind.tealOnScene || kind == ClayKind.danger;
    final enabled = onPressed != null;
    final fg = color ?? (teal ? AppColors.white : AppColors.ink);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
        child: Center(
          widthFactor: 1,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Clay(
              kind: kind,
              radius: height / 2,
              height: height,
              onTap: onPressed,
              padding: EdgeInsets.symmetric(horizontal: height * 0.38),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 6)],
                  if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(fontSize: height >= 44 ? 14 : 13, color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header for pushed screens: clay back button, centred title, optional
/// trailing action. Use as `Scaffold.appBar`.
class ClayHeader extends StatelessWidget implements PreferredSizeWidget {
  const ClayHeader({super.key, this.title, this.trailing, this.onBack, this.showBack = true, this.closeIcon = false});

  final String? title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  /// Use a close (×) instead of a back chevron.
  final bool closeIcon;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    // Screens opened with `go` have nothing to pop, so fall back to the parent route.
    String? parent;
    if (!canPop && onBack == null) {
      try {
        parent = parentRoute(GoRouterState.of(context).uri.path);
      } catch (_) {
        parent = null;
      }
    }
    final back = showBack && (onBack != null || canPop || parent != null);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s8),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: back
                      ? ClayIconButton(
                          icon: closeIcon ? Icons.close_rounded : Icons.chevron_left_rounded,
                          iconSize: closeIcon ? 20 : 24,
                          tooltip: closeIcon ? 'Close' : 'Back',
                          onPressed: onBack ??
                              (canPop || parent == null
                                  ? () => Navigator.of(context).maybePop()
                                  : () => context.go(parent!)),
                        )
                      : null,
                ),
              ),
              Expanded(
                child: title == null
                    ? const SizedBox.shrink()
                    : Semantics(
                        header: true,
                        child: Text(
                          title!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.encounter.copyWith(letterSpacing: -0.17),
                        ),
                      ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 64),
                child: Align(alignment: Alignment.centerRight, child: trailing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big screen title for tab roots, with an optional kicker line above and a
/// trailing control.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title, this.kicker, this.kickerColor, this.trailing});

  final String title;
  final String? kicker;
  final Color? kickerColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kicker != null)
                Text(
                  kicker!,
                  style: AppText.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: kickerColor ?? AppColors.inkMuted,
                  ),
                ),
              Semantics(
                header: true,
                child: Text(title, style: AppText.h1.copyWith(height: 30 / 26)),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: AppSpacing.s12), trailing!],
      ],
    );
  }
}

/// Section title with an optional "View all" style link.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(title, style: AppText.h2)),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              foregroundColor: AppColors.tealDeep,
              textStyle: AppText.link,
            ),
            child: Text(action!),
          ),
      ],
    );
  }
}

/// Spaced CAPS label with a gem and a rule ("NEW ─── 3").
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.label,
    this.count,
    this.gemColor = AppColors.awakeningTeal,
    this.showRule = true,
  });

  final String label;
  final String? count;
  final Color gemColor;
  final bool showRule;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: count == null ? label : '$label, $count',
      excludeSemantics: true,
      child: Row(
        children: [
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: gemColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(width: 10),
          Text(label.toUpperCase(), style: AppText.label),
          if (showRule) ...[
            const SizedBox(width: 10),
            const Expanded(child: Divider(height: 1, thickness: 1, color: AppColors.hairline)),
          ] else
            const Spacer(),
          if (count != null) ...[
            const SizedBox(width: 10),
            Text(count!, style: AppText.label.copyWith(color: AppColors.inkFaint)),
          ],
        ],
      ),
    );
  }
}

/// A clay card holding rows split by inset hairlines.
class ClayList extends StatelessWidget {
  const ClayList({
    super.key,
    required this.children,
    this.dividerIndent = 64,
    this.radius = AppRadius.feature,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  final List<Widget> children;
  final double dividerIndent;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: radius,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsets.only(left: dividerIndent, right: 14),
                child: const Divider(height: 1, thickness: 1, color: AppColors.hairline),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Round soft-teal action used inside rows (start focus, add).
class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 36,
    this.background = AppColors.tealSoft,
    this.color = AppColors.tealDeep,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: SizedBox(
          width: AppSpacing.minTap,
          height: AppSpacing.minTap,
          child: Center(
            child: Material(
              color: background,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Icon(icon, size: size * 0.5, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Docked primary action over a fade, for tab screens with a floating tab bar.
class DockedAction extends StatelessWidget {
  const DockedAction({super.key, required this.child, this.bottom = 118});

  final Widget child;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.paper.withValues(alpha: 0),
                        AppColors.paper.withValues(alpha: 0.94),
                        AppColors.paper,
                      ],
                      stops: const [0, 0.38, 0.62],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: EdgeInsets.fromLTRB(AppSpacing.screen, 72, AppSpacing.screen, bottom), child: child),
          ],
        ),
      ),
    );
  }
}
