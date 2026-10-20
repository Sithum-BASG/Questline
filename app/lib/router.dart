import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase/auth_providers.dart';
import 'core/supabase/auth_redirect.dart';
import 'core/supabase/supabase_providers.dart';
import 'core/theme/app_spacing.dart';
import 'core/widgets/floating_tab_bar.dart';
import 'core/widgets/gallery_screen.dart';
import 'core/widgets/placeholder_screen.dart';
import 'features/auth/settings_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/focus/focus_screen.dart';
import 'features/focus/session_complete_screen.dart';
import 'features/focus/start_focus_screen.dart';
import 'features/rewards/reward_screen.dart';
import 'features/onboarding/character_screen.dart';
import 'features/onboarding/first_session_screen.dart';
import 'features/onboarding/first_task_screen.dart';
import 'features/onboarding/story_screen.dart';
import 'features/onboarding/study_screen.dart';
import 'features/quests/add_task_screen.dart';
import 'features/quests/challenge_screen.dart';
import 'features/quests/quests_screen.dart';
import 'features/quests/task_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final step = ref.read(onboardingStepProvider);
      final signedIn = auth.value?.session != null;
      return authRedirect(
        loading: auth.isLoading,
        signedIn: signedIn,
        location: state.uri.path,
        onboardingStep: step.asData?.value,
        stepLoading: signedIn && step.isLoading,
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
            GoRoute(
              path: '/quests',
              builder: (context, state) => const QuestsScreen(),
              routes: [
                GoRoute(path: 'new', builder: (context, state) => const AddTaskScreen()),
                GoRoute(
                  path: ':taskId',
                  builder: (context, state) => TaskScreen(taskId: state.pathParameters['taskId']!),
                  routes: [
                    GoRoute(
                      path: 'challenge',
                      builder: (context, state) => ChallengeScreen(taskId: state.pathParameters['taskId']!),
                    ),
                  ],
                ),
              ],
            ),
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
      GoRoute(path: '/onboarding/character', builder: (context, state) => const CharacterScreen()),
      GoRoute(path: '/onboarding/story', builder: (context, state) => const StoryScreen()),
      GoRoute(path: '/onboarding/study', builder: (context, state) => const StudyScreen()),
      GoRoute(path: '/onboarding/first-task', builder: (context, state) => const FirstTaskScreen()),
      GoRoute(path: '/onboarding/first-session', builder: (context, state) => const FirstSessionScreen()),
      GoRoute(
        path: '/focus/start',
        builder: (context, state) => StartFocusScreen(taskId: state.uri.queryParameters['taskId'] ?? ''),
      ),
      GoRoute(
        path: '/focus/:sessionId',
        builder: (context, state) {
          final extra = state.extra;
          final startedAt = extra is Map ? extra['startedAt'] as DateTime? : null;
          final estimate = extra is Map ? extra['estimateMinutes'] as int? : null;
          final mode = extra is Map ? extra['mode'] as String? : null;
          final stat = extra is Map ? extra['stat'] as String? : null;
          final onboarding = extra is Map && extra['onboarding'] == true;
          return FocusScreen(
            sessionId: state.pathParameters['sessionId']!,
            startedAt: startedAt ?? DateTime.now(),
            estimateMinutes: estimate ?? 25,
            mode: mode ?? 'focus',
            stat: stat ?? 'intellect',
            onboarding: onboarding,
          );
        },
        routes: [
          GoRoute(
            path: 'complete',
            builder: (context, state) {
              final extra = state.extra;
              final summary = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
              return SessionCompleteScreen(summary: summary);
            },
          ),
        ],
      ),
      _screen('/raids/new', 'Start raid'),
      _screen('/raids/join', 'Join raid'),
      _screen('/raids/:raidId', 'Raid', routes: [
        _screen('invite', 'Invite'),
        _screen('results', 'Raid results'),
      ]),
      _screen('/chests', 'Chests', routes: [
        _screen('open', 'Chest opening'),
      ]),
      GoRoute(path: '/reward', builder: (context, state) => const RewardScreen()),
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
    _step = ref.listen<AsyncValue<String?>>(onboardingStepProvider, (_, _) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AsyncValue<AuthState>> _sub;
  late final ProviderSubscription<AsyncValue<String?>> _step;

  @override
  void dispose() {
    _sub.close();
    _step.close();
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
