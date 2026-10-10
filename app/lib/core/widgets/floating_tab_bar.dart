import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../theme/shadows.dart';

class TabDestination {
  const TabDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Floating white pill. The active tab gets a clay teal indicator.
class FloatingTabBar extends StatelessWidget {
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
    TabDestination(icon: Icons.home_outlined, label: 'Home'),
    TabDestination(icon: Icons.checklist_outlined, label: 'Quests'),
    TabDestination(icon: Icons.shield_outlined, label: 'Bosses'),
    TabDestination(icon: Icons.people_outline, label: 'Social'),
    TabDestination(icon: Icons.person_outline, label: 'Hero'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s8),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(child: _TabButton(
                destination: destinations[i],
                selected: i == index,
                onTap: () => onSelected(i),
              )),
          ],
        ),
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
    final color = selected ? AppColors.white : AppColors.inkMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? const Duration(milliseconds: 150)
                : const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
            decoration: selected
                ? BoxDecoration(
                    color: AppColors.tealDeep,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.clay,
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(destination.icon, size: 22, color: color),
                Text(destination.label, style: AppText.caption.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
