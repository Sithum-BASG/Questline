import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/config/game_config_reader.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/shadows.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/portrait_frame.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/reward_overlay.dart';
import '../hero/providers/profile_providers.dart';
import '../hero/wardrobe_screen.dart';
import '../home/providers/home_providers.dart';

/// Chests between guaranteed Legendaries, from game_config.
final legendaryPityProvider = FutureProvider<int>((ref) => ref.watch(gameConfigReaderProvider).legendaryPity());

const _consumableNames = {
  'streak_shield': 'Streak Shield',
  'focus_potion': 'Focus Potion',
  'reschedule_scroll': 'Reschedule Scroll',
};

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
String _short(String id) => id.contains('_') ? id.substring(id.indexOf('_') + 1) : id;
String _pretty(String id) => _short(id).split('_').where((w) => w.isNotEmpty).map(_cap).join(' ');

/// What one `openChest` result means for the reveal.
class ChestDrop {
  ChestDrop(Map<String, dynamic> result)
      : rarity = (result['rarity'] as String?) ?? 'common',
        pity = (result['pityCounter'] as num?)?.toInt(),
        _drop = result['drop'] is Map ? Map<String, dynamic>.from(result['drop'] as Map) : const {},
        refund = (result['refund'] as num?)?.toInt();

  final String rarity;
  final int? pity;
  final Map<String, dynamic> _drop;
  final int? refund;

  String get kind => _drop['kind'] as String? ?? 'item';
  String? get id => _drop['id'] as String?;
  List<String> get setIds => [for (final id in (_drop['ids'] as List? ?? const [])) if (id is String) id];
  int get coins => (_drop['coins'] as num?)?.toInt() ?? 0;

  bool get isPouch => kind == 'pouch';
  bool get isDuplicate => kind == 'coins';
  bool get isSet => kind == 'set';
  bool get isConsumable => kind == 'consumable';
  bool get isItem => kind == 'item';

  /// skin, bg or frame for a cosmetic item.
  String? get itemPrefix {
    final value = id;
    if (!isItem || value == null) return null;
    if (value.startsWith('skin_')) return 'skin';
    if (value.startsWith('bg_')) return 'bg';
    if (value.startsWith('frame_')) return 'frame';
    return null;
  }

  bool get canEquip => (isItem && itemPrefix != null) || isSet;
}

/// The chest bursts open, then the drop rises out of it.
class ChestOpenScreen extends ConsumerStatefulWidget {
  const ChestOpenScreen({super.key, required this.result});

  final Map<String, dynamic> result;

  /// Summary of a result as a reward moment (used by tests and older callers).
  static RewardMoment momentFromResult(Map<String, dynamic> result) {
    final rarity = (result['rarity'] as String?) ?? 'common';
    final drop = result['drop'];
    final refund = result['refund'];
    var title = 'Chest opened';
    var subtitle = _cap(rarity);
    if (drop is Map) {
      final kind = drop['kind'] as String? ?? 'item';
      if (kind == 'pouch' || kind == 'coins') {
        title = '+${drop['coins'] ?? 0} coins';
        subtitle = kind == 'coins' ? 'Duplicate refund · $subtitle' : 'Coin pouch · $subtitle';
      } else if (kind == 'consumable') {
        title = (drop['id'] as String?)?.replaceAll('_', ' ') ?? 'Consumable';
        subtitle = 'Consumable · $subtitle';
      } else if (kind == 'set') {
        title = 'Mythic set';
        subtitle = 'Skin, background and frame';
      } else {
        title = (drop['id'] as String?)?.replaceAll('_', ' ') ?? 'New item';
        subtitle = 'Loot · $subtitle';
      }
    }
    if (refund is num && refund > 0) {
      subtitle = 'Duplicate · +$refund coins';
    }
    return RewardMoment.loot(title: title, subtitle: subtitle, rarity: rarity);
  }

  @override
  ConsumerState<ChestOpenScreen> createState() => _ChestOpenScreenState();
}

class _ChestOpenScreenState extends ConsumerState<ChestOpenScreen> with SingleTickerProviderStateMixin {
  late final ChestDrop _drop = ChestDrop(widget.result);
  late final AnimationController _opening =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  var _revealed = false;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _opening.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() => _revealed = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        setState(() => _revealed = true);
      } else {
        _opening.forward();
      }
    });
  }

  @override
  void dispose() {
    _opening.dispose();
    super.dispose();
  }

  void _skip() {
    if (_revealed) return;
    _opening.stop();
    setState(() => _revealed = true);
  }

  void _done() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chests');
    }
  }

  Future<void> _equip() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final patch = <String, String>{};
    if (_drop.isSet) {
      for (final id in _drop.setIds) {
        if (id.startsWith('skin_')) patch['equipped_skin_id'] = id;
        if (id.startsWith('bg_')) patch['equipped_background_id'] = id;
        if (id.startsWith('frame_')) patch['equipped_frame_id'] = id;
      }
    } else {
      final id = _drop.id!;
      final column = switch (_drop.itemPrefix) {
        'skin' => 'equipped_skin_id',
        'bg' => 'equipped_background_id',
        _ => 'equipped_frame_id',
      };
      patch[column] = id;
    }
    try {
      final client = ref.read(supabaseClientProvider);
      final uid = client.auth.currentUser?.id;
      if (uid == null) throw StateError('Not signed in');
      await client.from('profiles').update(patch).eq('id', uid);
      ref.invalidate(profileViewProvider);
      ref.invalidate(homeSnapshotProvider);
      ref.invalidate(wardrobeProvider);
      if (mounted) _done();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not equip it. It is in your wardrobe.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _RarityPalette(_drop.rarity);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: _revealed
          ? TweenAnimationBuilder<double>(
              key: const ValueKey('revealed'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 280),
              builder: (context, t, child) => Opacity(opacity: t, child: child),
              child: _Revealed(
                drop: _drop,
                palette: palette,
                busy: _busy,
                error: _error,
                onDone: _done,
                onEquip: _equip,
              ),
            )
          : GestureDetector(
              key: const ValueKey('opening'),
              behavior: HitTestBehavior.opaque,
              onTap: _skip,
              child: _Opening(animation: _opening, palette: palette),
            ),
    );
  }
}

/// Field colours for a rarity: light centre, rarity colour, deep edge.
class _RarityPalette {
  _RarityPalette(this.rarity)
      : main = AppColors.rarity(rarity),
        soft = AppColors.raritySoft(rarity),
        ink = AppColors.rarityText(rarity);

  final String rarity;
  final Color main;
  final Color soft;
  final Color ink;

  bool get mythic => rarity == 'mythic';
  Color get light => Color.lerp(main, AppColors.white, 0.55)!;
  Color get deep => Color.lerp(main, AppColors.ink, 0.62)!;
  Gradient get border => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: mythic
            ? [light, main, AppColors.rarity('epic'), light]
            : [Color.lerp(main, AppColors.white, 0.7)!, main, Color.lerp(main, AppColors.ink, 0.3)!],
      );
}

class _Field extends StatelessWidget {
  const _Field({required this.palette, required this.center, this.rays = 0.16});

  final _RarityPalette palette;
  final Alignment center;
  final double rays;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: 1.1,
              colors: [palette.light, palette.main, palette.deep],
              stops: const [0, 0.42, 1],
            ),
          ),
        ),
        if (palette.mythic)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -0.6),
                end: const Alignment(1, 0.6),
                colors: [
                  AppColors.white.withValues(alpha: 0),
                  AppColors.raritySoft('mythic').withValues(alpha: 0.30),
                  AppColors.rarity('epic').withValues(alpha: 0.22),
                  AppColors.white.withValues(alpha: 0),
                ],
                stops: const [0.28, 0.42, 0.52, 0.64],
              ),
            ),
          ),
        CustomPaint(painter: _RaysPainter(center: center, alpha: rays)),
        for (final s in _sparkles)
          Align(
            alignment: Alignment(s.$1, s.$2),
            child: Icon(Icons.auto_awesome, size: s.$3, color: AppColors.white.withValues(alpha: s.$4)),
          ),
      ],
    );
  }
}

/// (x, y alignment, size, opacity) of the stars on the field.
const _sparkles = [
  (-0.85, -0.55, 14.0, 0.85),
  (0.8, -0.62, 16.0, 0.8),
  (-0.72, 0.1, 9.0, 0.6),
  (0.86, 0.05, 11.0, 0.7),
  (-0.3, -0.85, 7.0, 0.6),
  (0.35, -0.8, 7.0, 0.6),
];

class _RaysPainter extends CustomPainter {
  const _RaysPainter({required this.center, required this.alpha});

  final Alignment center;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final c = center.alongSize(size);
    final radius = size.longestSide * 0.65;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.white.withValues(alpha: alpha), AppColors.white.withValues(alpha: 0)],
        stops: const [0.2, 1],
      ).createShader(Rect.fromCircle(center: c, radius: radius));
    const rays = 20;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + radius * math.cos(a), c.dy + radius * math.sin(a))
        ..lineTo(c.dx + radius * math.cos(a + 0.11), c.dy + radius * math.sin(a + 0.11))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.alpha != alpha || old.center != center;
}

/// Shake, flash, lid swap. Tap anywhere to skip.
class _Opening extends StatelessWidget {
  const _Opening({required this.animation, required this.palette});

  final Animation<double> animation;
  final _RarityPalette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final shaking = t < 0.5;
        final shake = shaking ? math.sin(t * 60) * 0.09 * (t / 0.5) : 0.0;
        final flash = t < 0.45 ? 0.0 : t < 0.62 ? (t - 0.45) / 0.17 : 1 - (t - 0.62) / 0.38;
        return Stack(
          fit: StackFit.expand,
          children: [
            _Field(palette: palette, center: const Alignment(0, 0.1), rays: 0.20),
            // Beam out of the chest mouth.
            Align(
              alignment: const Alignment(0, -0.4),
              child: Opacity(
                opacity: (flash * 1.2).clamp(0, 1),
                child: ClipPath(
                  clipper: _BeamClipper(),
                  child: Container(
                    width: 200,
                    height: 470,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.white.withValues(alpha: 0.95),
                          AppColors.white.withValues(alpha: 0.35),
                          AppColors.white.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.45),
              child: Transform.rotate(
                angle: shake,
                child: Image.asset(
                  GameAssets.icon(shaking ? 'chest_large' : 'chest_open_large'),
                  width: 270,
                  height: 270,
                  semanticLabel: shaking ? 'The chest shakes' : 'The chest bursts open',
                ),
              ),
            ),
            // The white flash.
            Align(
              alignment: const Alignment(0, 0.3),
              child: IgnorePointer(
                child: Opacity(
                  opacity: flash.clamp(0, 1),
                  child: Container(
                    width: 320 + 140 * flash,
                    height: 320 + 140 * flash,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.white,
                          AppColors.white.withValues(alpha: 0.85),
                          AppColors.white.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.25, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 48 + MediaQuery.paddingOf(context).bottom,
              child: Text(
                'Tap to skip',
                textAlign: TextAlign.center,
                style: AppText.bodySmall.copyWith(fontSize: 13, color: AppColors.white.withValues(alpha: 0.8)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BeamClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width * 0.68, size.height)
    ..lineTo(size.width * 0.32, size.height)
    ..close();

  @override
  bool shouldReclip(_BeamClipper old) => false;
}

/// The item card above the open chest, its name, what it did, and the actions.
class _Revealed extends ConsumerWidget {
  const _Revealed({
    required this.drop,
    required this.palette,
    required this.busy,
    required this.error,
    required this.onDone,
    required this.onEquip,
  });

  final ChestDrop drop;
  final _RarityPalette palette;
  final bool busy;
  final String? error;
  final VoidCallback onDone;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobe = ref.watch(wardrobeProvider).asData?.value;
    final pityLimit = ref.watch(legendaryPityProvider).asData?.value;
    String nameOf(String id) {
      for (final item in wardrobe?.items ?? const <WardrobeItem>[]) {
        if (item.id == id) return item.name;
      }
      return _pretty(id);
    }

    final name = drop.isPouch
        ? 'Coin pouch'
        : drop.isDuplicate
            ? 'Duplicate'
            : drop.isConsumable
                ? (_consumableNames[drop.id] ?? _pretty(drop.id ?? 'consumable'))
                : drop.isSet
                    ? '${nameOf(drop.setIds.firstWhere((i) => i.startsWith('skin_'), orElse: () => drop.setIds.first))} set'
                    : nameOf(drop.id ?? 'item');
    final kindLabel = drop.isPouch
        ? 'COMMON · COIN POUCH'
        : drop.isDuplicate
            ? '${drop.rarity.toUpperCase()} · DUPLICATE'
            : drop.isConsumable
                ? '${drop.rarity.toUpperCase()} · CONSUMABLE'
                : drop.isSet
                    ? 'MYTHIC · FULL SET'
                    : '${drop.rarity.toUpperCase()} · ${switch (drop.itemPrefix) {
                        'skin' => 'SKIN',
                        'bg' => 'BACKGROUND',
                        'frame' => 'PROFILE FRAME',
                        _ => 'ITEM',
                      }}';
    final sticker = drop.isPouch ? '+${drop.coins}' : drop.isDuplicate ? 'OWNED' : 'NEW!';
    final body = wardrobe?.body ?? BodyType.a;

    return LayoutBuilder(
      builder: (context, box) {
        final height = box.maxHeight;
        final sheetTop = (height - 310).clamp(420.0, height);
        final top = MediaQuery.paddingOf(context).top;
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: sheetTop + 66,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Field(palette: palette, center: const Alignment(0, -0.2)),
                  if (drop.isPouch || drop.isDuplicate) ..._scatteredCoins,
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: sheetTop,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
                  boxShadow: AppShadows.sheet,
                ),
              ),
            ),
            // The open chest the drop came out of, resting on the sheet's lip.
            Positioned(
              left: 0,
              right: 0,
              top: sheetTop - 130,
              child: Center(
                child: Image.asset(GameAssets.icon('chest_open_large'), width: 196, height: 196),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: top + 12,
              child: Center(child: _RarityPill(palette: palette)),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: top + 58,
              child: Center(
                child: _ItemCard(
                  drop: drop,
                  palette: palette,
                  body: body,
                  kindLabel: kindLabel,
                  sticker: sticker,
                  skinId: wardrobe == null ? 'starter' : _short(wardrobe.skinId),
                  backgroundId: wardrobe == null ? 'starter' : _short(wardrobe.backgroundId),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              top: sheetTop + 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NameRow(name: name, palette: palette),
                  const SizedBox(height: 14),
                  if (drop.isDuplicate)
                    _DuplicateCard(drop: drop)
                  else if (drop.isSet)
                    _SetChips(drop: drop, body: body)
                  else
                    _Tiles(drop: drop, pityLimit: pityLimit),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, textAlign: TextAlign.center, style: AppText.bodySmall.copyWith(color: AppColors.errorText)),
                  ],
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              bottom: 30 + MediaQuery.paddingOf(context).bottom,
              child: drop.canEquip && !drop.isDuplicate
                  ? Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: QButton(
                            label: 'Done',
                            variant: QButtonVariant.secondary,
                            height: 60,
                            onPressed: busy ? null : onDone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: QButton(
                            label: drop.isSet ? 'Equip set' : 'Equip now',
                            height: 60,
                            loading: busy,
                            onPressed: busy ? null : onEquip,
                          ),
                        ),
                      ],
                    )
                  : QButton(label: drop.isPouch ? 'Collect' : 'Done', height: 60, onPressed: onDone),
            ),
          ],
        );
      },
    );
  }
}

List<Widget> get _scatteredCoins => [
      for (final c in const [
        (-0.83, -0.42, 30.0, -0.3),
        (0.82, -0.5, 36.0, 0.25),
        (-0.8, 0.12, 26.0, 0.4),
        (0.84, 0.02, 28.0, -0.18),
      ])
        Align(
          alignment: Alignment(c.$1, c.$2),
          child: Transform.rotate(
            angle: c.$4,
            child: Image.asset(GameAssets.icon('coin'), width: c.$3, height: c.$3),
          ),
        ),
    ];

class _RarityPill extends StatelessWidget {
  const _RarityPill({required this.palette});

  final _RarityPalette palette;

  @override
  Widget build(BuildContext context) {
    return Clay(
      kind: ClayKind.onScene,
      radius: 15,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: palette.main, borderRadius: const BorderRadius.all(Radius.circular(3))),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            palette.rarity.toUpperCase(),
            style: AppText.label.copyWith(fontSize: 12, height: 16 / 12, letterSpacing: 1.9, color: palette.ink),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.drop,
    required this.palette,
    required this.body,
    required this.kindLabel,
    required this.sticker,
    required this.skinId,
    required this.backgroundId,
  });

  final ChestDrop drop;
  final _RarityPalette palette;
  final BodyType body;
  final String kindLabel;
  final String sticker;
  final String skinId;
  final String backgroundId;

  Widget _art() {
    if (drop.isPouch || drop.isDuplicate) {
      return Stack(
        children: [
          Positioned(left: 22, top: 70, child: Transform.rotate(angle: -0.24, child: _coin(92))),
          Positioned(left: 96, top: 64, child: Transform.rotate(angle: 0.21, child: _coin(92))),
          Positioned(left: 50, top: 38, child: _coin(110)),
          Positioned(
            left: 0,
            right: 0,
            top: 160,
            child: Text(
              '+${drop.coins}',
              textAlign: TextAlign.center,
              style: AppText.h1.copyWith(fontSize: 34, height: 40 / 34, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    }
    if (drop.isConsumable) {
      return Center(child: Image.asset(GameAssets.icon(drop.id ?? 'focus_potion'), width: 172, height: 172));
    }
    final id = drop.isSet ? drop.setIds.firstWhere((i) => i.startsWith('skin_'), orElse: () => '') : drop.id ?? '';
    final prefix = drop.isSet ? 'skin' : drop.itemPrefix;
    switch (prefix) {
      case 'skin':
        return Stack(
          children: [
            Positioned(
              left: 50,
              top: 180,
              child: Container(
                width: 110,
                height: 22,
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [AppColors.ink.withValues(alpha: 0.2), AppColors.ink.withValues(alpha: 0)]),
                  borderRadius: const BorderRadius.all(Radius.elliptical(55, 11)),
                ),
              ),
            ),
            Positioned(
              left: 46,
              top: 7,
              width: 127,
              height: 190,
              child: Image.asset(GameAssets.skin(_short(id), body), fit: BoxFit.fill),
            ),
          ],
        );
      case 'bg':
        return Image.asset(GameAssets.background(_short(id)), fit: BoxFit.cover);
      case 'frame':
        return Center(
          child: SizedBox(
            width: 150,
            height: 150,
            child: FittedBox(
              child: PortraitFrame(skinId: skinId, backgroundId: backgroundId, frameId: _short(id), body: body),
            ),
          ),
        );
    }
    return Center(child: Icon(Icons.card_giftcard_rounded, size: 72, color: palette.main));
  }

  static Widget _coin(double size) => Image.asset(GameAssets.icon('coin'), width: size, height: size);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 234,
      height: 276,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 7,
            top: 7,
            child: Container(
              width: 220,
              height: 262,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: palette.border,
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: AppColors.white.withValues(alpha: 0.22), spreadRadius: 6),
                  BoxShadow(color: AppColors.ink.withValues(alpha: 0.32), offset: const Offset(0, 22), blurRadius: 36),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(25)),
                child: Container(
                  color: AppColors.white,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 218,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.08),
                              colors: [AppColors.white, palette.soft],
                              stops: const [0, 0.78],
                            ),
                          ),
                          child: SizedBox.expand(child: _art()),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: palette.mythic
                                ? LinearGradient(colors: [palette.main, AppColors.rarity('epic')])
                                : null,
                            color: palette.mythic ? null : palette.main,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            kindLabel,
                            style: AppText.label.copyWith(
                              fontSize: 10,
                              height: 12 / 10,
                              letterSpacing: 1.4,
                              color: palette.rarity == 'legendary' ? AppColors.ink : AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -7,
            top: -5,
            child: Transform.rotate(
              angle: 0.14,
              child: Clay(
                kind: ClayKind.onScene,
                radius: 14,
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    sticker,
                    style: AppText.title.copyWith(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: drop.isDuplicate ? AppColors.inkMuted : AppColors.tealDeep,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.name, required this.palette});

  final String name;
  final _RarityPalette palette;

  @override
  Widget build(BuildContext context) {
    Widget gem() => Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: palette.main, borderRadius: const BorderRadius.all(Radius.circular(3))),
          ),
        );
    Widget rule() => Container(width: 28, height: 2, color: palette.main.withValues(alpha: 0.6));
    // Long names drop the side rules so the whole name fits.
    final rules = name.length <= 12;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (rules) ...[rule(), const SizedBox(width: 12)],
        gem(),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.h1.copyWith(fontSize: 26, height: 32 / 26),
          ),
        ),
        const SizedBox(width: 12),
        gem(),
        if (rules) ...[const SizedBox(width: 12), rule()],
      ],
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.drop, required this.pityLimit});

  final ChestDrop drop;
  final int? pityLimit;

  @override
  Widget build(BuildContext context) {
    final resetPity = drop.rarity == 'legendary' || drop.rarity == 'mythic';
    final pity = drop.pity;
    final added = drop.isPouch
        ? (value: 'Balance', note: '+${drop.coins} coins added')
        : drop.isConsumable
            ? (value: 'Inventory', note: 'ready to use')
            : (value: 'Wardrobe', note: 'yours to wear');
    return Row(
      children: [
        Expanded(child: _Tile(label: 'ADDED TO', value: added.value, note: added.note)),
        const SizedBox(width: 12),
        Expanded(
          child: resetPity
              ? _Tile(
                  label: 'GUARANTEE',
                  value: 'Reset',
                  note: pityLimit == null ? 'starts again' : 'next within $pityLimit chests',
                )
              : _Tile(
                  label: 'GUARANTEE',
                  value: pity == null ? '–' : (pityLimit == null ? '$pity' : '$pity / $pityLimit'),
                  bar: pity != null && pityLimit != null && pityLimit! > 0 ? pity / pityLimit! : null,
                ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.note, this.bar});

  final String label;
  final String value;
  final String? note;
  final double? bar;

  @override
  Widget build(BuildContext context) {
    return Clay(
      kind: ClayKind.control,
      radius: 22,
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1.4)),
          Text(value, maxLines: 1, style: AppText.title.copyWith(fontSize: 18, height: 22 / 18)),
          if (bar != null)
            ClayBar(
              value: bar!,
              height: 6,
              gradient: LinearGradient(
                colors: [Color.lerp(AppColors.legendary, AppColors.white, 0.4)!, AppColors.legendary],
              ),
            )
          else if (note != null)
            Text(note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(height: 14 / 12)),
        ],
      ),
    );
  }
}

class _DuplicateCard extends StatelessWidget {
  const _DuplicateCard({required this.drop});

  final ChestDrop drop;

  @override
  Widget build(BuildContext context) {
    final reason = drop.rarity == 'rare'
        ? 'You already hold the most of that item you can carry.'
        : 'You already own every ${_cap(drop.rarity)} item.';
    return Clay(
      radius: 24,
      height: 84,
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 52,
            child: Stack(
              children: [
                Positioned(left: 0, top: 10, child: Image.asset(GameAssets.icon('coin'), width: 40, height: 40)),
                Positioned(right: 0, top: 0, child: Image.asset(GameAssets.icon('coin'), width: 34, height: 34)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('+${drop.refund ?? drop.coins} coins', style: AppText.title.copyWith(fontSize: 18, height: 22 / 18)),
                const SizedBox(height: 2),
                Text(reason, maxLines: 2, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetChips extends StatelessWidget {
  const _SetChips({required this.drop, required this.body});

  final ChestDrop drop;
  final BodyType body;

  @override
  Widget build(BuildContext context) {
    String? find(String prefix) {
      for (final id in drop.setIds) {
        if (id.startsWith(prefix)) return id;
      }
      return null;
    }

    final skin = find('skin_');
    final bg = find('bg_');
    final frame = find('frame_');
    Widget chip(String label, Widget art) => Expanded(
          child: Clay(
            kind: ClayKind.control,
            radius: 20,
            height: 84,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(12)), child: SizedBox(width: 40, height: 40, child: art)),
                const SizedBox(height: 4),
                Text(label, style: AppText.title.copyWith(fontSize: 12, height: 16 / 12)),
              ],
            ),
          ),
        );
    return Row(
      children: [
        chip(
          'Skin',
          skin == null
              ? const SizedBox()
              : Image.asset(GameAssets.skin(_short(skin), body), fit: BoxFit.cover, alignment: const Alignment(0, -0.8)),
        ),
        const SizedBox(width: 10),
        chip('Background', bg == null ? const SizedBox() : Image.asset(GameAssets.background(_short(bg)), fit: BoxFit.cover)),
        const SizedBox(width: 10),
        chip('Frame', frame == null ? const SizedBox() : Image.asset(GameAssets.frame(_short(frame)), fit: BoxFit.contain)),
      ],
    );
  }
}
