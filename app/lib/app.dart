import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/supabase/supabase_providers.dart';
import 'core/theme/app_theme.dart';

/// App shell. Routing arrives in the router task; this only holds providers.
class QuestlineApp extends ConsumerWidget {
  const QuestlineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    return MaterialApp(
      title: 'Questline',
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(child: Text('Questline')),
      ),
    );
  }
}
