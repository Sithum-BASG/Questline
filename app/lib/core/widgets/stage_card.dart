import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum StageCardSize { home, row }

/// Where the stage image sits so the feet line lands on the card bottom.
class StageLayout {
  const StageLayout({required this.imageTop, required this.imageHeight});

  final double imageTop;
  final double imageHeight;

  static StageLayout forCard({required double cardWidth, required double cardHeight}) {
    final scale = cardWidth / GameAssets.stageCanvas.width;
    final imageHeight = GameAssets.stageCanvas.height * scale;
    final feet = GameAssets.skinFeetY * scale;
    return StageLayout(imageTop: cardHeight - feet, imageHeight: imageHeight);
  }
}

/// Background, rarity glow, floor shadow, then the skin. The skin may overflow the top.
class StageCard extends StatelessWidget {
  const StageCard({
    super.key,
    required this.skinId,
    required this.backgroundId,
    required this.body,
    this.glow,
    this.size = StageCardSize.home,
    this.width,
  });

  final String skinId;
  final String backgroundId;
  final BodyType body;
  final Color? glow;
  final StageCardSize size;
  final double? width;

  static const double homeHeight = 280;
  static const double rowExtent = 48;

  @override
  Widget build(BuildContext context) {
    final cardWidth = size == StageCardSize.row ? rowExtent : (width ?? 220);
    final cardHeight = size == StageCardSize.row ? rowExtent : homeHeight;
    final layout = StageLayout.forCard(cardWidth: cardWidth, cardHeight: cardHeight);
    final glowColor = (glow ?? AppColors.awakeningTeal).withValues(alpha: 0.35);

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(size == StageCardSize.row ? AppRadius.button : AppRadius.stage),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _placed(
                  layout,
                  Image.asset(GameAssets.background(backgroundId), fit: BoxFit.fill),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [glowColor, glowColor.withValues(alpha: 0)],
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.82),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: SizedBox(width: cardWidth * 0.36, height: cardHeight * 0.04),
                  ),
                ),
              ],
            ),
          ),
          _placed(
            layout,
            Image.asset(GameAssets.skin(skinId, body), fit: BoxFit.fill),
          ),
        ],
      ),
    );
  }

  Widget _placed(StageLayout layout, Widget image) {
    return Positioned(
      left: 0,
      right: 0,
      top: layout.imageTop,
      height: layout.imageHeight,
      child: image,
    );
  }
}
