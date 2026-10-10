import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_button.dart';

/// Sheet with a drag handle, title, content and one primary action.
class QBottomSheet extends StatelessWidget {
  const QBottomSheet({
    super.key,
    required this.title,
    required this.child,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String actionLabel;
  final VoidCallback? onAction;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    required String actionLabel,
    VoidCallback? onAction,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (context) => QBottomSheet(
        title: title,
        actionLabel: actionLabel,
        onAction: onAction,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s12, AppSpacing.screen, AppSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(title, style: AppText.h1),
          const SizedBox(height: AppSpacing.s16),
          child,
          const SizedBox(height: AppSpacing.s20),
          QButton(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
