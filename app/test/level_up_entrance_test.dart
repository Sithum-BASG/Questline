import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/level_up_entrance.dart';
import 'package:questline/core/widgets/reward_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('level-up entrance finishes and is skippable after 0.6 s', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LevelUpEntrance(
          duration: const Duration(milliseconds: 1400),
          skipAfter: const Duration(milliseconds: 600),
          forceReducedMotion: true,
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(finished, isTrue);
  });

  testWidgets('level-up reward moment plays the Lottie entrance', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RewardOverlay(
          moment: RewardMoment.levelUp(title: 'Level 2', subtitle: 'You grew'),
          entrance: const Duration(milliseconds: 200),
          skipAfter: const Duration(milliseconds: 50),
          onClaim: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('LEVEL UP'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byType(RewardOverlay));
    await tester.pump();
    expect(find.text('Claim'), findsOneWidget);
  });
}
