import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/motion/app_haptics.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gear_socket.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/q_button.dart';
import '../hero/inventory_screen.dart';
import '../hero/wardrobe_screen.dart';
import 'providers/chest_providers.dart';

const _rarities = ['common', 'rare', 'epic', 'legendary', 'mythic'];

const _rarityContents = {
  'rare': 'Frame, background or consumable',
  'epic': 'Frame or background',
  'legendary': 'Skin, background or frame',
  'mythic': 'A full set: skin, background, frame',
};

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

/// The chest on its pedestal, the Legendary guarantee, drop rates and open actions.
class ChestsScreen extends ConsumerStatefulWidget {
  const ChestsScreen({super.key});

  @override
  ConsumerState<ChestsScreen> createState() => _ChestsScreenState();
}

class _ChestsScreenState extends ConsumerState<ChestsScreen> {
  var _busy = false;
  String? _error;

  Future<void> _open({required bool useFree}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppHaptics.chestOpen();
      final requestId = 'chest-${DateTime.now().millisecondsSinceEpoch}';
      final result = await ref.read(apiClientProvider).openChest(
            requestId: requestId,
            useFreeChest: useFree,
          );
      if (!mounted) return;
      ref.invalidate(chestScreenProvider);
      ref.invalidate(wardrobeProvider);
      ref.invalidate(inventoryCountsProvider);
      context.push('/chests/open', extra: result);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chestScreenProvider);
    final wardrobe = ref.watch(wardrobeProvider).asData?.value;
    final coins = async.asData?.value.coins;
    return Scaffold(
      appBar: ClayHeader(title: 'Chests', trailing: coins == null ? null : CoinPill(coins: coins)),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load chests',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(chestScreenProvider),
        ),
        data: (data) {
          final need = data.chestCost - data.coins;
          final canPay = data.coins >= data.chestCost;
          final canFree = data.freeChests > 0;
          final refunds = [
            for (final r in const ['rare', 'epic', 'legendary', 'mythic'])
              if (data.duplicateRefund[r] != null) '${_cap(r)} ${data.duplicateRefund[r]!.round()}',
          ];
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s24),
                  children: [
                    _ChestStage(data: data),
                    const SizedBox(height: AppSpacing.s24),
                    const SectionLabel(label: "What's inside", count: 'drop rates', gemColor: AppColors.epic),
                    const SizedBox(height: AppSpacing.s12),
                    ClayList(
                      dividerIndent: 58,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: [
                        for (final rarity in _rarities)
                          _RateRow(
                            rarity: rarity,
                            rate: data.rates[rarity] ?? 0,
                            contents: rarity == 'common'
                                ? 'Coin pouch: ${_joinOr(data.pouchAmounts)}'
                                : _rarityContents[rarity] ?? '',
                            owned: rarity == 'common' ? null : _owned(wardrobe, rarity),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      'Duplicates only drop once you own every item of a rarity, and turn into coins'
                      '${refunds.isEmpty ? '' : ': ${refunds.join(' · ')}'}. Coins only, never real money.',
                      textAlign: TextAlign.center,
                      style: AppText.caption,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s16),
                  child: canFree
                      ? Row(
                          children: [
                            Expanded(
                              child: QButton(
                                label: '${data.chestCost}',
                                variant: QButtonVariant.secondary,
                                height: 60,
                                onPressed: _busy || !canPay ? null : () => _open(useFree: false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: QButton(
                                label: 'Open free chest',
                                icon: Icons.card_giftcard_rounded,
                                height: 60,
                                loading: _busy,
                                onPressed: _busy ? null : () => _open(useFree: true),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!canPay) ...[
                              Text(
                                'Earn coins from the weekly target, bosses and streak milestones.',
                                textAlign: TextAlign.center,
                                style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: AppSpacing.s12),
                            ],
                            QButton(
                              label: canPay ? 'Open for ${data.chestCost}' : 'Need $need more coins',
                              height: 60,
                              loading: _busy,
                              onPressed: _busy || !canPay ? null : () => _open(useFree: false),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ({int owned, int total})? _owned(WardrobeData? wardrobe, String rarity) {
    if (wardrobe == null) return null;
    final pool = [
      for (final item in wardrobe.items)
        if (item.source == 'chest' && item.rarity == rarity && item.type != 'title') item,
    ];
    if (pool.isEmpty) return null;
    return (owned: pool.where((i) => i.owned).length, total: pool.length);
  }
}

String _joinOr(List<int> values) {
  if (values.isEmpty) return 'coins';
  if (values.length == 1) return '${values.first}';
  return '${values.sublist(0, values.length - 1).join(', ')} or ${values.last}';
}

class _ChestStage extends StatelessWidget {
  const _ChestStage({required this.data});

  final ChestScreenData data;

  @override
  Widget build(BuildContext context) {
    final pity = data.pityCounter.clamp(0, data.pityLimit);
    return Clay(
      radius: AppRadius.stage,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(26)),
            child: SizedBox(
              height: 236,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [AppColors.sceneTop, AppColors.sceneMid, AppColors.sceneDeep],
                          stops: [0, 0.44, 1],
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(child: CustomPaint(painter: _RaysPainter())),
                  for (final s in _sparkles)
                    Positioned(
                      left: s.$1,
                      top: s.$2,
                      child: Opacity(
                        opacity: s.$4,
                        child: Icon(Icons.auto_awesome, size: s.$3, color: AppColors.white),
                      ),
                    ),
                  Align(
                    alignment: const Alignment(0, 0.9),
                    child: Container(
                      width: 220,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(colors: [Color(0x8CA5AAFF), Color(0x00A5AAFF)]),
                        borderRadius: BorderRadius.all(Radius.elliptical(110, 22)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.1),
                    child: Image.asset(
                      GameAssets.icon('chest_large'),
                      width: 170,
                      height: 170,
                      semanticLabel: 'Standard chest',
                    ),
                  ),
                  const Positioned(left: 14, top: 14, child: _GlassTag(child: Text('STANDARD CHEST'))),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: _GlassTag(
                      leading: Image.asset(GameAssets.icon('coin'), width: 22, height: 22),
                      child: Text('${data.chestCost}'),
                    ),
                  ),
                  if (data.freeChests > 0)
                    Align(
                      alignment: const Alignment(0, 0.92),
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.legendary,
                          borderRadius: const BorderRadius.all(Radius.circular(14)),
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard_rounded, size: 14, color: AppColors.legendaryText),
                            const SizedBox(width: 6),
                            Text(
                              '${data.freeChests} free chest${data.freeChests == 1 ? '' : 's'} waiting',
                              style: AppText.title.copyWith(fontSize: 12, height: 16 / 12, color: AppColors.legendaryText),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.legendary,
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Legendary guarantee', style: AppText.title.copyWith(fontSize: 14))),
                    Text.rich(
                      TextSpan(
                        style: AppText.title.copyWith(fontSize: 13, color: AppColors.inkMuted),
                        children: [
                          TextSpan(text: '$pity', style: const TextStyle(color: AppColors.ink)),
                          TextSpan(text: ' / ${data.pityLimit}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClayBar(
                  value: data.pityLimit == 0 ? 0 : pity / data.pityLimit,
                  height: 8,
                  gradient: LinearGradient(
                    colors: [Color.lerp(AppColors.legendary, AppColors.white, 0.4)!, AppColors.legendary],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A Legendary drops within the next ${data.untilLegendary} '
                  'chest${data.untilLegendary == 1 ? '' : 's'}. Free chests count too.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// (left, top, size, opacity) for the stars on the night field.
const _sparkles = [
  (24.0, 60.0, 12.0, 0.9),
  (290.0, 74.0, 14.0, 0.85),
  (40.0, 170.0, 8.0, 0.6),
  (300.0, 168.0, 10.0, 0.75),
  (120.0, 30.0, 6.0, 0.6),
  (240.0, 40.0, 6.0, 0.6),
];

class _RaysPainter extends CustomPainter {
  const _RaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.longestSide * 0.6;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.white.withValues(alpha: 0.08), AppColors.white.withValues(alpha: 0)],
        stops: const [0.25, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    const rays = 18;
    for (var i = 0; i < rays; i++) {
      final a = i * 2 * math.pi / rays;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + radius * math.cos(a), center.dy + radius * math.sin(a))
        ..lineTo(center.dx + radius * math.cos(a + 0.12), center.dy + radius * math.sin(a + 0.12))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => false;
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.child, this.leading});

  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: leading == null ? 26 : 30,
      padding: EdgeInsets.fromLTRB(leading == null ? 11 : 5, 0, leading == null ? 11 : 12, 0),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 5)],
          DefaultTextStyle(
            style: leading == null
                ? AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1.4, color: AppColors.white)
                : AppText.title.copyWith(fontSize: 14, height: 18 / 14, color: AppColors.white),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.rarity, required this.rate, required this.contents, this.owned});

  final String rarity;
  final double rate;
  final String contents;
  final ({int owned, int total})? owned;

  @override
  Widget build(BuildContext context) {
    final pct = rate * 100;
    final fixed = pct.toStringAsFixed(1);
    final pctText = '${fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed}%';
    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
        child: Row(
          children: [
            Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(9)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(AppColors.rarity(rarity), AppColors.white, 0.4)!, AppColors.rarity(rarity)],
                  ),
                  boxShadow: const [BoxShadow(color: Color(0x29101935), offset: Offset(2, 3), blurRadius: 6)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cap(rarity),
                    style: AppText.title.copyWith(fontSize: 14, height: 18 / 14, color: AppColors.rarityText(rarity)),
                  ),
                  const SizedBox(height: 2),
                  Text(contents, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(pctText, style: AppText.title.copyWith(fontSize: 16, height: 20 / 16)),
                if (owned != null)
                  Text(
                    '${owned!.owned} / ${owned!.total} owned',
                    style: AppText.caption.copyWith(fontSize: 11, height: 14 / 11, color: AppColors.placeholder),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
