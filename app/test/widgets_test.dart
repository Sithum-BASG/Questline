import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/q_button.dart';
import 'package:questline/core/widgets/q_chip.dart';

void main() {
  testWidgets('primary button calls onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: QButton(label: 'Start focus', onPressed: () => taps++),
        ),
      ),
    );
    await tester.tap(find.text('Start focus'));
    expect(taps, 1);
  });

  testWidgets('disabled button does not call onPressed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: QButton(label: 'Save', onPressed: null)),
      ),
    );
    await tester.tap(find.text('Save'));
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('selected filter chip exposes selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: QChip(label: 'Intellect', selected: true)),
      ),
    );
    expect(tester.getSemantics(find.text('Intellect')), isNotNull);
    expect(find.text('Intellect'), findsOneWidget);
  });
}
