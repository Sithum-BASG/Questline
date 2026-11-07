import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/supabase/supabase_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/social/deep_link_listener.dart';
import 'router.dart';

/// App shell. Auth redirects arrive with onboarding.
class QuestlineApp extends ConsumerWidget {
  const QuestlineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final router = ref.watch(routerProvider);
    return DeepLinkListener(
      child: MaterialApp.router(
        title: 'Questline',
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}

