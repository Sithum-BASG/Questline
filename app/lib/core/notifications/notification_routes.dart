/// Normalizes a notification/inbox payload into an in-app go_router location.
String? sanitizeNotificationRoute(String? payload) {
  if (payload == null) return null;
  final route = payload.trim();
  if (route.isEmpty || !route.startsWith('/')) return null;
  // Block anything that looks like a scheme or absolute URL.
  if (route.contains('://')) return null;
  return route;
}

/// Allowed route prefixes used by the planner and inbox (for tests / docs).
const notificationRoutePrefixes = <String>[
  '/home',
  '/bosses/',
  '/raids/',
  '/recap/',
  '/social',
  '/focus/',
  '/inbox',
];
