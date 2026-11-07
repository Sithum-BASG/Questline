import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/motion/app_motion.dart';

void main() {
  testWidgets('reduced motion shortens fill and ticker durations', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(AppMotion.reduce(captured), isTrue);
    expect(AppMotion.xpFill(captured), const Duration(milliseconds: 150));
    expect(AppMotion.raidTicker(captured), const Duration(milliseconds: 150));
    expect(AppMotion.standard(captured), const Duration(milliseconds: 150));
  });

  testWidgets('full motion keeps brief durations', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(AppMotion.reduce(captured), isFalse);
    expect(AppMotion.xpFill(captured), const Duration(milliseconds: 600));
    expect(AppMotion.bossDamage(captured), const Duration(milliseconds: 400));
    expect(AppMotion.raidTicker(captured), const Duration(milliseconds: 200));
  });
}
