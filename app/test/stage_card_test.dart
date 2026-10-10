import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/assets/game_assets.dart';
import 'package:questline/core/theme/app_theme.dart';
import 'package:questline/core/widgets/stage_card.dart';

void main() {
  test('feet sit on the bottom edge of the card', () {
    const width = 220.0;
    const height = StageCard.homeHeight;
    final layout = StageLayout.forCard(cardWidth: width, cardHeight: height);
    final scale = width / GameAssets.stageCanvas.width;
    expect(layout.imageTop + GameAssets.skinFeetY * scale, closeTo(height, 0.01));
  });

  testWidgets('row stage card is 48 px', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: StageCard(
            skinId: 'starter',
            backgroundId: 'starter',
            body: BodyType.a,
            size: StageCardSize.row,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(StageCard)), const Size(48, 48));
  });
}
