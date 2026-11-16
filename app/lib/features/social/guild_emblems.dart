import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Preset guild crest ids accepted by `createGuild`.
const guildEmblemIds = <String>[
  'crest_1',
  'crest_2',
  'crest_3',
  'crest_4',
  'crest_5',
  'crest_6',
  'crest_7',
  'crest_8',
];

const _crestIcons = <IconData>[
  Icons.nightlight_round,
  Icons.star_rounded,
  Icons.menu_book_rounded,
  Icons.local_fire_department_rounded,
  Icons.eco_rounded,
  Icons.bolt_rounded,
  Icons.workspace_premium_rounded,
  Icons.diamond_rounded,
];

const _crestNames = <String>['Moon', 'Star', 'Book', 'Flame', 'Leaf', 'Bolt', 'Crown', 'Gem'];

int _index(String id) {
  final i = guildEmblemIds.indexOf(id);
  return i < 0 ? 0 : i;
}

String guildEmblemLabel(String id) => '${_crestNames[_index(id)]} crest';

/// A guild crest: a shield in the crest's colours with its symbol.
class GuildEmblem extends StatelessWidget {
  const GuildEmblem({super.key, required this.id, this.width = 46});

  final String id;

  /// Shield width; the height follows the 40:44 shield shape.
  final double width;

  @override
  Widget build(BuildContext context) {
    final i = _index(id);
    final colors = AppColors.guildCrests[i % AppColors.guildCrests.length];
    final height = width * 44 / 40;
    return Semantics(
      label: guildEmblemLabel(id),
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _ShieldPainter(light: colors.$1, deep: colors.$2),
          child: Padding(
            padding: EdgeInsets.only(bottom: height * 0.08),
            child: Center(child: Icon(_crestIcons[i], size: width * 0.42, color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter({required this.light, required this.deep});

  final Color light;
  final Color deep;

  Path _shield(Size size, double inset) {
    final sx = size.width / 40;
    final sy = size.height / 44;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final top = 1.5 + inset;
    final side = 3 + inset;
    final right = 37 - inset;
    final bottom = 42.5 - inset;
    return Path()
      ..moveTo(p(20, top).dx, p(20, top).dy)
      ..lineTo(p(right, 7 + inset * 0.6).dx, p(right, 7 + inset * 0.6).dy)
      ..lineTo(p(right, 20).dx, p(right, 20).dy)
      ..cubicTo(p(right, 31).dx, p(right, 31).dy, p(29.5, 38.5).dx, p(29.5, 38.5).dy, p(20, bottom).dx, p(20, bottom).dy)
      ..cubicTo(p(10.5, 38.5).dx, p(10.5, 38.5).dy, p(side, 31).dx, p(side, 31).dy, p(side, 20).dx, p(side, 20).dy)
      ..lineTo(p(side, 7 + inset * 0.6).dx, p(side, 7 + inset * 0.6).dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _shield(size, 0);
    canvas.drawShadow(outer, AppColors.ink.withValues(alpha: 0.5), 4, false);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, deep],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width / 20
        ..color = AppColors.white,
    );
    canvas.drawPath(
      _shield(size, 3.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width / 40
        ..color = AppColors.white.withValues(alpha: 0.45),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.35, size.height * 0.25), width: size.width * 0.35, height: size.height * 0.16),
      Paint()..color = AppColors.white.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.light != light || old.deep != deep;
}
