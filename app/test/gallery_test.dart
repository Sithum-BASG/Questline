import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/empty_state.dart';
import 'package:questline/core/widgets/gallery_screen.dart';
import 'package:questline/core/widgets/timer_display.dart';

void main() {
  test('timer formats minutes and seconds', () {
    expect(TimerDisplay.format(125), '02:05');
    expect(TimerDisplay.format(0), '00:00');
  });

  testWidgets('empty state shows its title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmptyState(title: 'No quests yet', body: 'Add one real task.'),
        ),
      ),
    );
    expect(find.text('No quests yet'), findsOneWidget);
  });

  testWidgets('gallery lists the shared pieces', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const GalleryScreen(),
      ),
    );
    expect(find.text('Start focus'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('The Deadline Shade'), 400);
    expect(find.text('The Deadline Shade'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('02:05'), 400);
    expect(find.text('02:05'), findsOneWidget);
  });
}
