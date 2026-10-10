import 'package:flutter_test/flutter_test.dart';
import 'package:questline/core/assets/game_assets.dart';

void main() {
  test('asset paths come from the pack ids', () {
    expect(
      GameAssets.skin('coder', BodyType.a),
      'assets/images/skins/skin_coder_a.webp',
    );
    expect(GameAssets.background('starter'), 'assets/images/backgrounds/bg_starter.webp');
    expect(GameAssets.skinFeetY, 1490);
    expect(GameAssets.portraitCrop('starter', BodyType.a).left, 207);
    expect(GameAssets.framePortraitRect(1024).left, 182);
  });
}
