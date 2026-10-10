import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase/auth_redirect.dart';
import 'core/supabase/supabase_providers.dart';
import 'core/theme/app_spacing.dart';
import 'core/widgets/floating_tab_bar.dart';
import 'core/widgets/gallery_screen.dart';
import 'core/widgets/placeholder_screen.dart';
import 'features/auth/settings_screen.dart';
import 'features/auth/welcome_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      return authRedirect(
        loading: auth.isLoading,
        signedIn: auth.value?.session != null,
        location: state.uri.path,
      );
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [_screen('/home', 'Home')]),
          StatefulShellBranch(routes: [
            _screen('/quests', 'Quests', routes: [
              _screen('new', 'Add task'),
              _screen(':taskId', 'Task', routes: [
                _screen('challenge', 'Challenge'),
              ]),
            ]),
          ]),
          StatefulShellBranch(routes: [
            _screen('/bosses', 'Bosses', routes: [
              _screen('new', 'Create boss'),
              _screen(':bossId', 'Boss', routes: [
                _screen('result', 'Boss result'),
              ]),
            ]),
          ]),
          StatefulShellBranch(routes: [
            _screen('/social', 'Social', routes: [
              _screen('feed', 'Feed'),
              _screen('friends', 'Friends', routes: [
                _screen(':uid', 'Friend'),
              ]),
              _screen('guild', 'Guild', routes: [
                _screen('new', 'Create or join guild'),
              ]),
            ]),
          ]),
          StatefulShellBranch(routes: [
            _screen('/hero', 'Hero', routes: [
              _screen('gear', 'Gear'),
              _screen('wardrobe', 'Wardrobe'),
              _screen('achievements', 'Achievements'),
              _screen('inventory', 'Inventory'),
              _screen('level-road', 'Level road'),
            ]),
          ]),
        ],
      ),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      _screen('/onboarding/character', 'Character'),
      _screen('/onboarding/story', 'Story'),
      _screen('/onboarding/study', 'Study'),
      _screen('/onboarding/first-task', 'First task'),
      _screen('/focus/start', 'Start focus'),
      _screen('/focus/:sessionId', 'Focus', routes: [
        _screen('complete', 'Session complete'),
      ]),
      _screen('/raids/new', 'Start raid'),
      _screen('/raids/join', 'Join raid'),
      _screen('/raids/:raidId', 'Raid', routes: [
        _screen('invite', 'Invite'),
        _screen('results', 'Raid results'),
      ]),
      _screen('/chests', 'Chests', routes: [
        _screen('open', 'Chest opening'),
      ]),
      _screen('/reward', 'Reward'),
      _screen('/recap/:weekId', 'Weekly recap'),
      _screen('/inbox', 'Inbox'),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          _screen('demo', 'Demo mode'),
        ],
      ),
      GoRoute(
        path: '/dev/gallery',
        builder: (context, state) {
          if (!kDebugMode) return const PlaceholderScreen(title: 'Not available');
          return const GalleryScreen();
        },
      ),
    ],
  );
});

GoRoute _screen(String path, String title, {List<RouteBase> routes = const []}) {
  return GoRoute(
    path: path,
    builder: (context, state) => PlaceholderScreen(title: title),
    routes: routes,
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _sub = ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, _) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AsyncValue<AuthState>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// Five-tab shell. The floating clay bar sits over the current tab.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: AppSpacing.s16,
            right: AppSpacing.s16,
            bottom: AppSpacing.s16,
            child: FloatingTabBar(
              index: navigationShell.currentIndex,
              onSelected: (index) {
                navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
              },
            ),
          ),
        ],
      ),
    );
  }
}
