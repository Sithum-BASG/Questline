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
import 'features/bosses/boss_detail_screen.dart';
import 'features/bosses/boss_result_screen.dart';
import 'features/bosses/bosses_screen.dart';
import 'features/bosses/create_boss_screen.dart';
import 'features/focus/focus_screen.dart';
import 'features/focus/session_complete_screen.dart';
import 'features/focus/start_focus_screen.dart';
import 'features/chests/chest_open_screen.dart';
import 'features/chests/chests_screen.dart';
import 'features/hero/achievements_screen.dart';
import 'features/hero/gear_screen.dart';
import 'features/hero/inventory_screen.dart';
import 'features/hero/level_road_screen.dart';
import 'features/hero/profile_screen.dart';
import 'features/hero/wardrobe_screen.dart';
import 'features/home/home_screen.dart';
import 'features/recap/recap_screen.dart';
import 'features/rewards/reward_screen.dart';
import 'features/onboarding/character_screen.dart';
import 'features/onboarding/first_session_screen.dart';
import 'features/onboarding/first_task_screen.dart';
import 'features/onboarding/onboarding_chest_screen.dart';
import 'features/onboarding/story_screen.dart';
import 'features/onboarding/study_screen.dart';
import 'features/quests/add_task_screen.dart';
import 'features/quests/challenge_screen.dart';
import 'features/quests/quests_screen.dart';
import 'features/quests/task_screen.dart';
import 'features/raids/create_raid_screen.dart';
import 'features/raids/join_raid_screen.dart';
import 'features/raids/raid_detail_screen.dart';
import 'features/raids/raid_invite_screen.dart';
import 'features/raids/raid_results_screen.dart';
import 'features/social/feed_screen.dart';
import 'features/social/friend_profile_screen.dart';
import 'features/social/friends_screen.dart';
import 'features/social/guild_home_screen.dart';
import 'features/social/guild_new_screen.dart';
import 'features/social/scan_friend_screen.dart';
import 'features/social/social_screen.dart';

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
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ]),
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
            GoRoute(
              path: '/bosses',
              builder: (context, state) => const BossesScreen(),
              routes: [
                GoRoute(path: 'new', builder: (context, state) => const CreateBossScreen()),
                GoRoute(
                  path: ':bossId',
                  builder: (context, state) => BossDetailScreen(
                    bossId: state.pathParameters['bossId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'result',
                      builder: (context, state) {
                        final extra = state.extra;
                        return BossResultScreen(
                          bossId: state.pathParameters['bossId']!,
                          submitResult: extra is Map<String, dynamic> ? extra : null,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/social',
              builder: (context, state) => const SocialScreen(),
              routes: [
                GoRoute(
                  path: 'feed',
                  builder: (context, state) => const FeedScreen(),
                ),
                GoRoute(
                  path: 'friends',
                  builder: (context, state) => const FriendsScreen(),
                  routes: [
                    GoRoute(
                      path: 'scan',
                      builder: (context, state) => const ScanFriendScreen(),
                    ),
                    GoRoute(
                      path: ':uid',
                      builder: (context, state) => FriendProfileScreen(
                        userId: state.pathParameters['uid']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'guild',
                  builder: (context, state) => const GuildHomeScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const GuildNewScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/hero',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'gear', builder: (context, state) => const GearScreen()),
                GoRoute(path: 'wardrobe', builder: (context, state) => const WardrobeScreen()),
                GoRoute(path: 'achievements', builder: (context, state) => const AchievementsScreen()),
                GoRoute(path: 'inventory', builder: (context, state) => const InventoryScreen()),
                GoRoute(path: 'level-road', builder: (context, state) => const LevelRoadScreen()),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/character', builder: (context, state) => const CharacterScreen()),
      GoRoute(path: '/onboarding/story', builder: (context, state) => const StoryScreen()),
      GoRoute(path: '/onboarding/study', builder: (context, state) => const StudyScreen()),
      GoRoute(path: '/onboarding/first-task', builder: (context, state) => const FirstTaskScreen()),
      GoRoute(path: '/onboarding/first-session', builder: (context, state) => const FirstSessionScreen()),
      GoRoute(path: '/onboarding/chest', builder: (context, state) => const OnboardingChestScreen()),
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
      GoRoute(
        path: '/raids/new',
        builder: (context, state) => const CreateRaidScreen(),
      ),
      GoRoute(
        path: '/raids/join',
        builder: (context, state) => JoinRaidScreen(
          initialCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/raids/:raidId',
        builder: (context, state) => RaidDetailScreen(
          raidId: state.pathParameters['raidId']!,
        ),
        routes: [
          GoRoute(
            path: 'invite',
            builder: (context, state) => RaidInviteScreen(
              raidId: state.pathParameters['raidId']!,
            ),
          ),
          GoRoute(
            path: 'results',
            builder: (context, state) => RaidResultsScreen(
              raidId: state.pathParameters['raidId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/chests',
        builder: (context, state) => const ChestsScreen(),
        routes: [
          GoRoute(
            path: 'open',
            builder: (context, state) {
              final extra = state.extra;
              final result = extra is Map<String, dynamic> ? extra : <String, dynamic>{};
              return ChestOpenScreen(result: result);
            },
          ),
        ],
      ),
      GoRoute(path: '/reward', builder: (context, state) => const RewardScreen()),
      GoRoute(
        path: '/recap/:weekId',
        builder: (context, state) => RecapScreen(weekId: state.pathParameters['weekId'] ?? ''),
      ),
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
