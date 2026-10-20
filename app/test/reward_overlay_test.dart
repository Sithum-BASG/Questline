import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_colors.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/reward_overlay.dart';

void main() {
  test('the queue plays rewards in order', () {
    final queue = RewardQueue();
    queue.add([
      RewardMoment.levelUp(title: 'Level 2', subtitle: 'You grew'),
      RewardMoment.loot(title: 'Frame', subtitle: 'New look', rarity: 'common'),
    ]);
    expect(queue.next()?.title, 'Level 2');
    queue.claim();
    expect(queue.current?.title, 'Frame');
    queue.claim();
    expect(queue.current, isNull);
    expect(queue.pending, isEmpty);
  });

  test('each variant uses the brief burst colour', () {
    expect(RewardMoment.levelUp(title: 'L', subtitle: 's').burstColor, AppColors.awakeningTeal);
    expect(RewardMoment.streak(title: 'S', subtitle: 's').burstColor, AppColors.streakEmber);
    expect(RewardMoment.loot(title: 'I', subtitle: 's', rarity: 'epic').burstColor, AppColors.epic);
    expect(RewardMoment.boss(title: 'B', subtitle: 's').burstColor, AppColors.epic);
    expect(RewardMoment.badge(title: 'A', subtitle: 's').burstColor, AppColors.tealDeep);
  });

  test('kind labels match the reward variants', () {
    expect(RewardKind.levelUp.label, 'Level up');
    expect(RewardKind.loot.label, 'Loot');
    expect(RewardKind.boss.label, 'Boss defeated');
    expect(RewardKind.badge.label, 'Badge');
    expect(RewardKind.streak.label, 'Streak');
  });

  testWidgets('claim appears after the entrance, and a late tap skips', (tester) async {
    var claimed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RewardOverlay(
          moment: RewardMoment.levelUp(title: 'Level 2', subtitle: 'You grew'),
          entrance: const Duration(milliseconds: 200),
          skipAfter: const Duration(milliseconds: 50),
          onClaim: () => claimed = true,
        ),
      ),
    );
    expect(find.text('Claim'), findsNothing);
    expect(find.text('LEVEL UP'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byType(RewardOverlay));
    await tester.pump();
    expect(find.text('Claim'), findsOneWidget);
    await tester.tap(find.text('Claim'));
    await tester.pump();
    expect(claimed, isTrue);
  });

  testWidgets('reduced motion fades in 150 ms with no scale burst', (tester) async {
    var claimed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RewardOverlay(
          moment: RewardMoment.loot(title: 'Mythic blade', subtitle: 'Chest drop', rarity: 'mythic'),
          forceReducedMotion: true,
          skipAfter: const Duration(milliseconds: 40),
          onClaim: () => claimed = true,
        ),
      ),
    );
    expect(find.text('Claim'), findsNothing);
    expect(find.text('LOOT'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Claim'), findsOneWidget);
    await tester.tap(find.text('Claim'));
    await tester.pump();
    expect(claimed, isTrue);
  });

  testWidgets('boss, badge and streak variants render their labels', (tester) async {
    for (final moment in [
      RewardMoment.boss(title: 'Deadline down', subtitle: 'Submitted on time'),
      RewardMoment.badge(title: 'Steady Pace', subtitle: 'Week complete'),
      RewardMoment.streak(title: '7-day streak', subtitle: 'Keep going'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RewardOverlay(
            moment: moment,
            forceReducedMotion: true,
            onClaim: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.text(moment.kind.label.toUpperCase()), findsOneWidget);
      expect(find.text(moment.title), findsOneWidget);
      expect(find.text('Claim'), findsOneWidget);
    }
  });
}
