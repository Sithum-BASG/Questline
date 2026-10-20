import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/reward_overlay.dart';

void main() {
  test('the queue plays rewards in order', () {
    final queue = RewardQueue();
    queue.add(const [
      RewardMoment(kind: RewardKind.levelUp, title: 'Level 2', subtitle: 'You grew'),
      RewardMoment(kind: RewardKind.loot, title: 'Frame', subtitle: 'New look', rarity: 'common'),
    ]);
    expect(queue.next()?.title, 'Level 2');
    queue.claim();
    expect(queue.current?.title, 'Frame');
    queue.claim();
    expect(queue.current, isNull);
    expect(queue.pending, isEmpty);
  });

  testWidgets('claim appears after the entrance, and a late tap skips', (tester) async {
    var claimed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RewardOverlay(
          moment: const RewardMoment(kind: RewardKind.levelUp, title: 'Level 2', subtitle: 'You grew'),
          entrance: const Duration(milliseconds: 200),
          skipAfter: const Duration(milliseconds: 50),
          onClaim: () => claimed = true,
        ),
      ),
    );
    expect(find.text('Claim'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byType(RewardOverlay));
    await tester.pump();
    expect(find.text('Claim'), findsOneWidget);
    await tester.tap(find.text('Claim'));
    await tester.pump();
    expect(claimed, isTrue);
  });
}
