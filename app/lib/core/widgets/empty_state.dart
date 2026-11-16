import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'clay.dart';
import 'q_button.dart';

/// A clay card with a soft teal icon well, title, body and one action. Used
/// when a list has nothing in it, and for error states.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.auto_awesome_rounded,
  });

  final String title;
  final String body;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Clay(
        radius: 30,
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                Well(
                  circle: true,
                  width: 72,
                  height: 72,
                  color: AppColors.tealSoft,
                  shade: const [
                    InnerShadow(Offset(3, 3), 8, Color(0x1F0F766E)),
                    InnerShadow(Offset(-3, -3), 8, Color(0xD9FFFFFF)),
                  ],
                  child: Center(child: Icon(icon, size: 30, color: AppColors.tealDeep)),
                ),
            const SizedBox(height: 14),
            Text(title, style: AppText.h2, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              body,
              style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.s20),
              QButton(label: actionLabel!, onPressed: onAction, height: 54),
            ],
          ],
        ),
      ),
    );
  }
}
