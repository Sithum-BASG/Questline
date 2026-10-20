import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/stat_radar.dart';

void main() {
  test('radar totals cover the last 7 or 30 days only', () {
    final end = DateTime.utc(2026, 10, 20);
    final rows = [
      (day: DateTime.utc(2026, 10, 20), intellect: 10, vitality: 0, craft: 0, charisma: 0),
      (day: DateTime.utc(2026, 10, 14), intellect: 5, vitality: 0, craft: 0, charisma: 0),
      (day: DateTime.utc(2026, 9, 1), intellect: 100, vitality: 0, craft: 0, charisma: 0),
    ];
    expect(StatRadarValues.fromDailyStats(rows, days: 7, end: end).intellect, 15);
    expect(StatRadarValues.fromDailyStats(rows, days: 30, end: end).intellect, 15);
    expect(
      StatRadarValues.fromDailyStats([
        ...rows,
        (day: DateTime.utc(2026, 9, 25), intellect: 20, vitality: 0, craft: 0, charisma: 0),
      ], days: 30, end: end).intellect,
      35,
    );
  });

  testWidgets('the 7 and 30 day chips swap the chart', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatRadar(
            valuesFor30: const StatRadarValues(intellect: 40, vitality: 10, craft: 20, charisma: 30),
            valuesFor7: const StatRadarValues(intellect: 4, vitality: 1, craft: 2, charisma: 3),
          ),
        ),
      ),
    );
    expect(find.text('30 days'), findsOneWidget);
    await tester.tap(find.text('7 days'));
    await tester.pump();
    expect(find.byType(StatRadar), findsOneWidget);
  });
}
