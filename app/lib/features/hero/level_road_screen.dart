import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/game_assets.dart';
import '../../core/game/level_curve.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/shadows.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/gear_socket.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/portrait_frame.dart';
import 'providers/profile_providers.dart';

/// One reward on a level: coins, a catalog item or a title.
class RoadReward {
  const RoadReward({required this.type, this.id, this.amount, this.name, this.rarity, this.slot, this.itemType});

  /// coins, item or title.
  final String type;
  final String? id;
  final int? amount;
  final String? name;
  final String? rarity;
  final String? slot;

  /// Catalog type for items: skin, background, frame, gear.
  final String? itemType;

  String get kind {
    if (type == 'coins') return 'COINS';
    if (type == 'title') return 'TITLE';
    if (itemType == 'gear') return (slot ?? 'gear').toUpperCase();
    return (itemType ?? 'item').toUpperCase();
  }

  String get label => type == 'coins' ? '${amount ?? 0} coins' : (name ?? (id ?? '').replaceAll('_', ' '));

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'amount': amount,
        'name': name,
        'rarity': rarity,
        'slot': slot,
        'itemType': itemType,
      };

  factory RoadReward.fromJson(Map<String, dynamic> json) => RoadReward(
        type: json['type'] as String? ?? 'item',
        id: json['id'] as String?,
        amount: (json['amount'] as num?)?.toInt(),
        name: json['name'] as String?,
        rarity: json['rarity'] as String?,
        slot: json['slot'] as String?,
        itemType: json['itemType'] as String?,
      );
}

class LevelRoadRow {
  const LevelRoadRow({required this.level, required this.rewards, required this.reached});

  final int level;
  final List<RoadReward> rewards;
  final bool reached;

  bool get hasItem => rewards.any((r) => r.type != 'coins');

  /// Kept for older callers: a one-line summary of the rewards.
  String get label => rewards.map((r) => r.label).join(' · ');
}

class LevelRoadData {
  const LevelRoadData({
    required this.rows,
    required this.level,
    required this.xpTotal,
    required this.skinId,
    required this.backgroundId,
    required this.frameId,
    required this.body,
  });

  final List<LevelRoadRow> rows;
  final int level;
  final int? xpTotal;
  final String skinId;
  final String backgroundId;
  final String frameId;
  final BodyType body;
}

String _short(String id, String prefix) => id.startsWith(prefix) ? id.substring(prefix.length) : id;

final levelRoadProvider = FutureProvider<LevelRoadData>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final view = await ref.watch(profileViewProvider.future);
  final profile = view.profile;
  final rows = await client.from('level_rewards').select('level, rewards').order('level');
  final ids = <String>{
    for (final row in rows)
      if (row['rewards'] is List)
        for (final r in row['rewards'] as List)
          if (r is Map && r['id'] is String) r['id'] as String,
  };
  final catalog = <String, Map<String, dynamic>>{};
  if (ids.isNotEmpty) {
    final items = await client.from('catalog_items').select('id, name, type, rarity, slot').inFilter('id', ids.toList());
    for (final item in items) {
      catalog[item['id'] as String] = item;
    }
  }
  return LevelRoadData(
    level: profile.level,
    xpTotal: view.xpTotal,
    skinId: _short(profile.equippedSkinId, 'skin_'),
    backgroundId: _short(profile.equippedBackgroundId, 'bg_'),
    frameId: _short(profile.equippedFrameId, 'frame_'),
    body: profile.bodyType == 'b' ? BodyType.b : BodyType.a,
    rows: [
      for (final row in rows)
        LevelRoadRow(
          level: (row['level'] as num).toInt(),
          reached: profile.level >= (row['level'] as num).toInt(),
          rewards: [
            if (row['rewards'] is List)
              for (final r in row['rewards'] as List)
                if (r is Map)
                  RoadReward(
                    type: r['type'] as String? ?? 'item',
                    id: r['id'] as String?,
                    amount: (r['amount'] as num?)?.toInt(),
                    name: catalog[r['id']]?['name'] as String?,
                    rarity: catalog[r['id']]?['rarity'] as String?,
                    slot: catalog[r['id']]?['slot'] as String?,
                    itemType: catalog[r['id']]?['type'] as String?,
                  ),
          ],
        ),
    ],
  );
});

const double _rowHeight = 104;
const double _node = 44;

/// The level road: future levels climb upward, reached ones are teal below you.
class LevelRoadScreen extends ConsumerStatefulWidget {
  const LevelRoadScreen({super.key});

  @override
  ConsumerState<LevelRoadScreen> createState() => _LevelRoadScreenState();
}

class _LevelRoadScreenState extends ConsumerState<LevelRoadScreen> {
  final _here = GlobalKey();
  var _scrolled = false;

  void _scrollToHere() {
    if (_scrolled) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _here.currentContext;
      if (target != null) Scrollable.ensureVisible(target, alignment: 0.6);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(levelRoadProvider);
    return Scaffold(
      appBar: const ClayHeader(title: 'Level road'),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load level road',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(levelRoadProvider),
        ),
        data: (data) {
          if (data.rows.isEmpty) {
            return const EmptyState(title: 'No rewards yet', body: 'Level rewards will show here.');
          }
          _scrollToHere();
          final road = data.rows.reversed.toList();
          final maxLevel = data.rows.last.level;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, 0),
                child: _WhereCard(data: data),
              ),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment(0, -0.85),
                    colors: [Color(0x00000000), Color(0xFF000000)],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, bottomClearance(context)),
                    child: Column(
                      children: [
                        for (var i = 0; i < road.length; i++)
                          _RoadRow(
                            key: road[i].level == data.level ? _here : null,
                            row: road[i],
                            current: data.level,
                            nextLevel: i > 0 ? road[i - 1].level : null,
                            last: i == road.length - 1,
                            left: i.isOdd,
                          ),
                        const SizedBox(height: AppSpacing.s16),
                        Text(
                          'Rewards continue to level $maxLevel',
                          style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WhereCard extends StatelessWidget {
  const _WhereCard({required this.data});

  final LevelRoadData data;

  @override
  Widget build(BuildContext context) {
    const curve = LevelCurve.defaults;
    final level = data.level;
    final maxed = level >= curve.maxLevel;
    final floor = curve.totalForLevel(level);
    final span = curve.totalForLevel(level + 1) - floor;
    final xp = data.xpTotal;
    final inLevel = xp == null ? 0 : (xp - floor).clamp(0, span < 1 ? 1 : span);
    int? nextReward;
    for (final row in data.rows) {
      if (row.level > level && row.hasItem) {
        nextReward = row.level;
        break;
      }
    }
    return Clay(
      radius: 26,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: FittedBox(
              child: PortraitFrame(
                skinId: data.skinId,
                backgroundId: data.backgroundId,
                frameId: data.frameId,
                body: data.body,
                size: PortraitFrameSize.compact,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: AppText.title.copyWith(fontSize: 14, height: 18 / 14),
                    children: [
                      TextSpan(text: 'Level $level'),
                      if (nextReward != null)
                        TextSpan(
                          text: ' · next reward at $nextReward',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.inkMuted),
                        ),
                    ],
                  ),
                ),
                if (xp != null) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ClayBar(value: maxed ? 1 : curve.progressInLevel(xp, level), height: 8),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      style: AppText.caption,
                      children: maxed
                          ? [const TextSpan(text: 'Top level reached')]
                          : [
                              TextSpan(
                                text: formatThousands(inLevel),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                              TextSpan(text: ' / ${formatThousands(span)} XP to level ${level + 1}'),
                            ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadRow extends StatelessWidget {
  const _RoadRow({
    super.key,
    required this.row,
    required this.current,
    required this.nextLevel,
    required this.left,
    this.last = false,
  });

  final LevelRoadRow row;
  final int current;

  /// The level drawn above this one, if any.
  final int? nextLevel;
  final bool left;

  /// The lowest level: the road stops at its node.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final here = row.level == current;
    final upperTeal = nextLevel != null && nextLevel! <= current;
    final lowerTeal = row.level <= current;
    final milestone = row.level % 5 == 0 || row.rewards.any((r) => r.itemType == 'skin');
    return SizedBox(
      height: _rowHeight,
      child: LayoutBuilder(
        builder: (context, box) {
          final center = box.maxWidth / 2;
          final cardWidth = center - _node / 2 - 10;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Road segments above and below the node.
              if (nextLevel != null)
                Positioned(
                  left: center - 3,
                  top: 0,
                  width: 6,
                  height: _rowHeight / 2,
                  child: CustomPaint(painter: _RoadPainter(teal: upperTeal)),
                ),
              if (!last)
              Positioned(
                left: center - 3,
                top: _rowHeight / 2,
                width: 6,
                height: _rowHeight / 2,
                child: CustomPaint(painter: _RoadPainter(teal: lowerTeal)),
              ),
              Positioned(
                left: left ? 0 : center + _node / 2 + 10,
                top: (_rowHeight - 76) / 2 - 18,
                width: cardWidth,
                height: 76,
                child: Opacity(
                  opacity: row.level < current ? 0.6 : 1,
                  child: _RewardCard(row: row, claimed: row.reached),
                ),
              ),
              Positioned(
                left: center - (here ? 30 : _node / 2),
                top: _rowHeight / 2 - (here ? 30 : _node / 2),
                child: _LevelNode(level: row.level, here: here, reached: row.reached, milestone: milestone),
              ),
              if (here)
                Positioned(
                  left: left ? center + 40 : null,
                  right: left ? null : center + 40,
                  top: _rowHeight / 2 - 14,
                  child: Clay(
                    kind: ClayKind.onScene,
                    radius: 14,
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(color: AppColors.awakeningTeal, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'You are here',
                          style: AppText.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.tealDeep),
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
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({required this.teal});

  final bool teal;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = teal ? AppColors.awakeningTeal : AppColors.handle;
    if (teal) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      return;
    }
    for (var y = 3.0; y < size.height; y += 16) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 2), paint);
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.teal != teal;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.level, required this.here, required this.reached, required this.milestone});

  final int level;
  final bool here;
  final bool reached;
  final bool milestone;

  @override
  Widget build(BuildContext context) {
    final label = here
        ? 'Level $level, you are here'
        : '${reached ? 'Level $level, reached' : 'Level $level'}${milestone ? ', milestone' : ''}';
    if (here) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: clayTealGradient,
            border: Border.all(color: AppColors.white, width: 4),
            boxShadow: AppShadows.tealButton,
          ),
          alignment: Alignment.center,
          child: Text('$level', style: AppText.title.copyWith(fontSize: 22, height: 24 / 22, color: AppColors.white)),
        ),
      );
    }
    if (reached) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: Container(
          width: _node,
          height: _node,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: xpFillGradient,
            border: Border.all(color: AppColors.white, width: 3),
          ),
          alignment: Alignment.center,
          child: Text('$level', style: AppText.title.copyWith(fontSize: 15, height: 18 / 15, color: AppColors.white)),
        ),
      );
    }
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        width: _node,
        height: _node,
        decoration: milestone
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.raritySoft('epic'), width: 2),
              )
            : null,
        padding: milestone ? const EdgeInsets.all(2) : EdgeInsets.zero,
        child: Clay(
          kind: ClayKind.control,
          circle: true,
          child: Center(
            child: Text('$level', style: AppText.title.copyWith(fontSize: 15, height: 18 / 15, color: AppColors.inkMuted)),
          ),
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.row, required this.claimed});

  final LevelRoadRow row;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final main = row.rewards.firstWhere((r) => r.type == 'item', orElse: () => row.rewards.first);
    final kinds = row.rewards.map((r) => r.kind).toSet().join(' + ');
    final names = row.rewards.map((r) => r.label).join(', ');
    final rarity = main.rarity;
    final showTag = !claimed && main.itemType == 'gear' && rarity != null && rarity != 'common';
    // The card is a fixed 76 px tall: with a status line under the name, the name gets one line.
    final hasStatus = claimed || showTag;
    return Semantics(
      label: 'Level ${row.level}: $names${claimed ? ', claimed' : ''}',
      excludeSemantics: true,
      child: Clay(
        radius: 22,
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: SizedBox(
                width: 50,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      colors: [
                        AppColors.white,
                        main.type == 'coins' ? AppColors.legendarySoft : AppColors.raritySoft(rarity ?? 'common'),
                      ],
                    ),
                  ),
                  child: RewardArt(reward: main, claimed: claimed),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kinds,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(fontSize: 9, height: 12 / 9, letterSpacing: 0.9),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      names,
                      maxLines: hasStatus ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(fontSize: 12, height: 15 / 12),
                    ),
                  ),
                  if (claimed)
                    Text(
                      'CLAIMED',
                      style: AppText.label.copyWith(
                        fontSize: 9,
                        height: 12 / 9,
                        letterSpacing: 0.7,
                        color: AppColors.tealDeep,
                      ),
                    )
                  else if (showTag)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: AppColors.rarity(rarity),
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          rarity.toUpperCase(),
                          style: AppText.label.copyWith(fontSize: 9, height: 10 / 9, color: AppColors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picture for one level reward: coins, a title, gear, a background, a frame,
/// or a skin (a silhouette until it is claimed).
class RewardArt extends StatelessWidget {
  const RewardArt({super.key, required this.reward, this.claimed = false});

  final RoadReward reward;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final id = reward.id ?? '';
    switch (reward.type) {
      case 'coins':
        return Center(child: Image.asset(GameAssets.icon('coin'), width: 36, height: 36));
      case 'title':
        return const Center(child: Icon(Icons.auto_awesome_rounded, size: 24, color: AppColors.tealDeep));
    }
    switch (reward.itemType) {
      case 'gear':
        return Center(child: Image.asset(GameAssets.gear(_short(id, 'gear_')), width: 40, height: 40));
      case 'background':
        return Image.asset(GameAssets.background(_short(id, 'bg_')), fit: BoxFit.cover);
      case 'frame':
        return Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(GameAssets.frame(_short(id, 'frame_')), fit: BoxFit.contain),
        );
      case 'skin':
        final skin = Image.asset(
          GameAssets.skin(_short(id, 'skin_'), BodyType.a),
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.75),
        );
        if (claimed) return skin;
        // Future skins stay a silhouette until you reach them.
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.28,
              child: ColorFiltered(colorFilter: const ColorFilter.mode(AppColors.ink, BlendMode.srcIn), child: skin),
            ),
            Center(
              child: Text('?', style: AppText.title.copyWith(fontSize: 22, color: AppColors.raritySoft('epic').withValues(alpha: 1))),
            ),
          ],
        );
      default:
        return const Center(child: Icon(Icons.card_giftcard_rounded, size: 22, color: AppColors.inkMuted));
    }
  }
}
