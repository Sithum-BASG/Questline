import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/widgets/judgement_card.dart';

void main() {
  testWidgets('shows Make it a boss when too big', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JudgementCard(
            stat: 'intellect',
            difficulty: 5,
            minutes: 180,
            xpPreview: 120,
            reason: 'Looks large.',
            tooBig: true,
          ),
        ),
      ),
    );
    expect(find.text('This looks bigger than one sitting.'), findsOneWidget);
    expect(find.text('Make it a boss'), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
    expect(find.text('86 XP'), findsNothing);
    expect(find.text('120 XP'), findsOneWidget);
  });
}
