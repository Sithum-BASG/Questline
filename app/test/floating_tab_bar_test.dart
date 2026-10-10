import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/floating_tab_bar.dart';

void main() {
  testWidgets('selecting a tab reports its index', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FloatingTabBar(index: selected, onSelected: (index) => selected = index),
        ),
      ),
    );
    await tester.tap(find.text('Quests'));
    expect(selected, 1);
  });
}
