import 'package:flutter/material.dart';

import '../assets/game_assets.dart';

enum PortraitFrameSize { leaderboard, compact, profile }

/// Head-and-shoulders crop under the equipped frame. Rounded square, not a circle.
class PortraitFrame extends StatelessWidget {
  const PortraitFrame({
    super.key,
    required this.skinId,
    required this.backgroundId,
    required this.frameId,
    required this.body,
    this.size = PortraitFrameSize.profile,
  });

  final String skinId;
  final String backgroundId;
  final String frameId;
  final BodyType body;
  final PortraitFrameSize size;

  static double extentFor(PortraitFrameSize size) {
    switch (size) {
      case PortraitFrameSize.leaderboard:
        return 48;
      case PortraitFrameSize.compact:
        return 64;
      case PortraitFrameSize.profile:
        return 96;
    }
  }

  @override
  Widget build(BuildContext context) {
    final extent = extentFor(size);
    final window = GameAssets.framePortraitRect(extent);
    final radius = extent * GameAssets.framePortraitRadius;
    final crop = GameAssets.portraitCrop(skinId, body);

    return SizedBox(
      width: extent,
      height: extent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fromRect(
            rect: window,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CroppedStageLayer(asset: GameAssets.background(backgroundId), crop: crop),
                  _CroppedStageLayer(asset: GameAssets.skin(skinId, body), crop: crop),
                ],
              ),
            ),
          ),
          Image.asset(GameAssets.frame(frameId), fit: BoxFit.fill, filterQuality: FilterQuality.medium),
        ],
      ),
    );
  }
}

class _CroppedStageLayer extends StatelessWidget {
  const _CroppedStageLayer({required this.asset, required this.crop});

  final String asset;
  final Rect crop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / crop.width;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: GameAssets.stageCanvas.width * scale,
            maxHeight: GameAssets.stageCanvas.height * scale,
            child: Transform.translate(
              offset: Offset(-crop.left * scale, -crop.top * scale),
              child: Image.asset(
                asset,
                width: GameAssets.stageCanvas.width * scale,
                height: GameAssets.stageCanvas.height * scale,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        );
      },
    );
  }
}
