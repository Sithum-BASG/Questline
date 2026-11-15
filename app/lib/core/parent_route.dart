/// Where "back" goes when a screen was opened with `go` (no history to pop).
/// Mirrors the route tree in `router.dart`: nested routes go to their parent,
/// top-level detail routes go to the tab they belong to. Null for the
/// sign-in and onboarding flows, which have no back.
String? parentRoute(String path) {
  final segments = Uri.parse(path).pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return '/home';
  switch (segments.first) {
    case 'welcome':
    case 'auth':
    case 'onboarding':
      return null;
    case 'settings':
      return '/hero';
    case 'raids':
      // /raids/new, /raids/join and /raids/:id belong to the Bosses tab.
      if (segments.length >= 3) return '/raids/${segments[1]}';
      return '/bosses';
    case 'focus':
    case 'recap':
    case 'inbox':
    case 'dev':
      return '/home';
  }
  if (segments.length == 1) return '/home';
  return '/${segments.sublist(0, segments.length - 1).join('/')}';
}
