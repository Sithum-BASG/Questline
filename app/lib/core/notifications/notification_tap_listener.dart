import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'notification_routes.dart';
import 'notification_tap_bus.dart';

/// Navigates when a local notification (or cold-start tap) publishes a route.
class NotificationTapListener extends ConsumerStatefulWidget {
  const NotificationTapListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationTapListener> createState() => _NotificationTapListenerState();
}

class _NotificationTapListenerState extends ConsumerState<NotificationTapListener> {
  @override
  void initState() {
    super.initState();
    notificationTapBus.addListener(_onTap);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTap());
  }

  @override
  void dispose() {
    notificationTapBus.removeListener(_onTap);
    super.dispose();
  }

  void _onTap() {
    final route = sanitizeNotificationRoute(notificationTapBus.value);
    if (route == null) return;
    notificationTapBus.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GoRouter.maybeOf(context)?.go(route);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
