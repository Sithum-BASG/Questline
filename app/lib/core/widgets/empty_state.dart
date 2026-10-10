import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_button.dart';

/// Illustration, title, body and one action. Used when a list has nothing in it.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.illustration,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration != null) ...[
            illustration!,
            const SizedBox(height: AppSpacing.s16),
          ],
          Text(title, style: AppText.h2, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.s8),
          Text(body, style: AppText.bodySmall, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.s16),
            QButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
