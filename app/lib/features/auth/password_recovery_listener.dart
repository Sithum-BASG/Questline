import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../router.dart';
import 'providers/password_recovery_provider.dart';

/// Sends the player to the reset-password screen when Supabase emits recovery.
class PasswordRecoveryListener extends ConsumerWidget {
  const PasswordRecoveryListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      final event = next.asData?.value.event;
      if (event != AuthChangeEvent.passwordRecovery) return;
      ref.read(passwordRecoveryProvider.notifier).begin();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(routerProvider).go('/auth/reset-password');
      });
    });
    return child;
  }
}
