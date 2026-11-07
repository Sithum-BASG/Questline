import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_providers.dart';
import 'notification_replan.dart';

/// Re-plans local notifications on cold start and every resume while signed in.
class NotificationLifecycle extends ConsumerStatefulWidget {
  const NotificationLifecycle({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationLifecycle> createState() => _NotificationLifecycleState();
}

class _NotificationLifecycleState extends ConsumerState<NotificationLifecycle> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _replan());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _replan();
    }
  }

  Future<void> _replan() async {
    final signedIn = ref.read(authStateProvider).asData?.value.session != null;
    if (!signedIn) return;
    try {
      await replanLocalNotifications(ref);
    } catch (_) {
      // Planner is best-effort; never block the UI shell.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
