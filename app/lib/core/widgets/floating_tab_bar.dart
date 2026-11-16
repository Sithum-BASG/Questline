import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';

class TabDestination {
  const TabDestination({required this.icon, required this.label, this.activeIcon});

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

/// Floating clay bar. The active tab's icon sits in a teal clay pill with a
/// teal label under it.
class FloatingTabBar extends StatelessWidget {
  /// Height of the bar itself.
  static const double height = 76;

  const FloatingTabBar({
    super.key,
    required this.index,
    required this.onSelected,
    this.destinations = defaultDestinations,
  });

  final int index;
  final ValueChanged<int> onSelected;
  final List<TabDestination> destinations;

  static const defaultDestinations = [
    TabDestination(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    TabDestination(icon: Icons.checklist_rounded, label: 'Quests'),
    TabDestination(icon: Icons.shield_outlined, activeIcon: Icons.shield_rounded, label: 'Bosses'),
    TabDestination(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Social'),
    TabDestination(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Hero'),
  ];

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 38,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      child: Row(
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: _TabButton(destination: destinations[i], selected: i == index, onTap: () => onSelected(i)),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.destination, required this.selected, required this.onTap});

  final TabDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? (destination.activeIcon ?? destination.icon) : destination.icon;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.standard(context),
                child: selected
                    ? Clay(
                        key: const ValueKey('on'),
                        kind: ClayKind.teal,
                        radius: 18,
                        width: 44,
                        height: 36,
                        child: Icon(icon, size: 22, color: AppColors.white),
                      )
                    : SizedBox(
                        key: const ValueKey('off'),
                        width: 44,
                        height: 36,
                        child: Icon(icon, size: 22, color: AppColors.inkMuted),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: AppText.caption.copyWith(
                  color: selected ? AppColors.tealDeep : AppColors.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
