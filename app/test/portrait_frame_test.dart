import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/assets/game_assets.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/portrait_frame.dart';

void main() {
  test('the frame window matches the art pack inset', () {
    final window = GameAssets.framePortraitRect(96);
    expect(window.left, closeTo(96 * GameAssets.framePortraitInset, 0.01));
    expect(window.width, closeTo(96 * GameAssets.framePortraitSize, 0.01));
  });

  testWidgets('leaderboard portraits are 48 px', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: PortraitFrame(
            skinId: 'starter',
            backgroundId: 'starter',
            frameId: 'apprentice',
            body: BodyType.a,
            size: PortraitFrameSize.leaderboard,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(PortraitFrame)), const Size(48, 48));
  });

  testWidgets('profile portraits are 96 px', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: PortraitFrame(
            skinId: 'starter',
            backgroundId: 'starter',
            frameId: 'apprentice',
            body: BodyType.a,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(PortraitFrame)), const Size(96, 96));
  });
}
