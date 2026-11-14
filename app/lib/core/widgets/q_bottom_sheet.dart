import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'q_button.dart';

/// Sheet on the page colour with a drag handle, title, content and one
/// primary action.
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
      backgroundColor: AppColors.paper,
      barrierColor: AppColors.scrim,
      showDragHandle: false,
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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        10,
        AppSpacing.screen,
        AppSpacing.s24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.s16),
          Text(title, style: AppText.h1.copyWith(fontSize: 22, height: 28 / 22)),
          const SizedBox(height: AppSpacing.s16),
          child,
          const SizedBox(height: AppSpacing.s24),
          QButton(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}

/// The grey pill at the top of a sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(color: AppColors.handle, borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
    );
  }
}
