import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:questline/core/parent_route.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/clay.dart';

void main() {
  test('nested routes go back to their parent', () {
    expect(parentRoute('/bosses/b1'), '/bosses');
    expect(parentRoute('/bosses/b1/result'), '/bosses/b1');
    expect(parentRoute('/hero/gear'), '/hero');
    expect(parentRoute('/quests/t1/challenge'), '/quests/t1');
    expect(parentRoute('/social/friends/scan'), '/social/friends');
    expect(parentRoute('/chests/open'), '/chests');
  });

  test('top-level screens go back to the tab they belong to', () {
    expect(parentRoute('/chests'), '/home');
    expect(parentRoute('/inbox'), '/home');
    expect(parentRoute('/settings'), '/hero');
    expect(parentRoute('/focus/start'), '/home');
    expect(parentRoute('/raids/new'), '/bosses');
    expect(parentRoute('/raids/join'), '/bosses');
    expect(parentRoute('/raids/r1'), '/bosses');
    expect(parentRoute('/raids/r1/invite'), '/raids/r1');
  });

  test('sign-in and onboarding have no back', () {
    expect(parentRoute('/welcome'), isNull);
    expect(parentRoute('/onboarding/first-task'), isNull);
    expect(parentRoute('/auth/reset-password'), isNull);
  });

  testWidgets('a screen opened with go still shows back and returns to its parent', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('home'))),
        GoRoute(
          path: '/chests',
          builder: (context, state) => const Scaffold(appBar: ClayHeader(title: 'Chests')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: router));
    router.go('/chests');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}
