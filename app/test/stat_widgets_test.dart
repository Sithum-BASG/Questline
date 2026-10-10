import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/progress_bar.dart';
import 'package:questline/core/widgets/stat_tile.dart';

void main() {
  testWidgets('stat tile shows its value and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: StatTile(stat: 'intellect', value: '12', label: 'Streak')),
      ),
    );
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
  });

  testWidgets('progress bar shows both labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProgressBar(value: 0.4, kind: ProgressKind.bossHp, leading: 'HP', trailing: '40%'),
        ),
      ),
    );
    expect(find.text('HP'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
  });
}
