import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/floating_tab_bar.dart';
import 'package:questline/features/bosses/providers/boss_providers.dart';
import 'package:questline/features/quests/add_task_screen.dart';
import 'package:questline/router.dart';

void main() {
  testWidgets('a text field inside the tab shell keeps its screen when the keyboard opens', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.reset);

    final router = GoRouter(initialLocation: '/quests/new', routes: [
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (c, s) => const SizedBox())]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/quests', builder: (c, s) => const SizedBox(), routes: [
              GoRoute(path: 'new', builder: (c, s) => const AddTaskScreen()),
            ]),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/bosses', builder: (c, s) => const SizedBox())]),
          StatefulShellBranch(routes: [GoRoute(path: '/social', builder: (c, s) => const SizedBox())]),
          StatefulShellBranch(routes: [GoRoute(path: '/hero', builder: (c, s) => const SizedBox())]),
        ],
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        bossesProvider.overrideWith((ref) async => const []),
        myRaidsProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pump();
    expect(find.byType(FloatingTabBar), findsOneWidget);

    // The keyboard opens: the shell made room for it once, so the screen must not make room again.
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    tester.view.padding = const FakeViewPadding(top: 59);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Write the methodology section');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingTabBar), findsNothing);
    final title = tester.getRect(find.text('Write the methodology section'));
    expect(title.top, greaterThan(59));
    expect(title.bottom, lessThan(852 - 336));
    expect(find.text('Judge quest').hitTestable(), findsOneWidget);
  });
}
