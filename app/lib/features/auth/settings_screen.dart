import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/auth_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/q_button.dart';

/// Sign-out lives here until the rest of Settings is built.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Align(
          alignment: Alignment.topCenter,
          child: QButton(
            label: 'Sign out',
            variant: QButtonVariant.secondary,
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ),
      ),
    );
  }
}
