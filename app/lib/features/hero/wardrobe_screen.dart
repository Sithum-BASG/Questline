import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/shadows.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/portrait_frame.dart';
import '../home/providers/home_providers.dart';
import 'providers/achievements_providers.dart';
import 'providers/profile_providers.dart';

/// One cosmetic from the catalog, owned or not.
class WardrobeItem {
  const WardrobeItem({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.source,
    required this.owned,
    this.level,
  });

  final String id;
  final String name;

  /// skin, background, frame or title.
  final String type;
  final String rarity;

  /// starter, level, chest, streak or special.
  final String source;
  final int? level;
  final bool owned;

  /// Where it comes from, or "Owned" once you have it.
  String get sourceLabel {
    if (owned) return source == 'starter' ? 'Starter' : 'Owned';
    switch (source) {
      case 'level':
        return level == null ? 'Level road' : 'Lv $level';
      case 'chest':
        return 'Chest';
      case 'streak':
        return 'Streak';
      default:
        return 'Special';
    }
  }
}

class WardrobeData {
  const WardrobeData({
    required this.skinId,
    required this.backgroundId,
    required this.frameId,
    required this.titleId,
    required this.body,
    required this.items,
  });

  final String skinId;
  final String backgroundId;
  final String frameId;
  final String? titleId;
  final BodyType body;
  final List<WardrobeItem> items;

  List<WardrobeItem> ofType(String type) => [for (final item in items) if (item.type == type) item];

  String? nameOf(String? id) {
    if (id == null) return null;
    for (final item in items) {
      if (item.id == id) return item.name;
    }
    return null;
  }

  bool isEquipped(WardrobeItem item) =>
      item.id == skinId || item.id == backgroundId || item.id == frameId || item.id == titleId;
}

const _rarityRank = {'common': 0, 'rare': 1, 'epic': 2, 'legendary': 3, 'mythic': 4, 'special': 5};

final wardrobeProvider = FutureProvider<WardrobeData>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final profile = (await ref.watch(profileViewProvider.future)).profile;
  final inv = await client.from('inventory').select('catalog_id');
  final player = await client.from('player_state').select('owned_titles').maybeSingle();
  final owned = <String>{
    for (final row in inv) row['catalog_id'] as String,
    for (final id in (player?['owned_titles'] as List? ?? const []))
      if (id is String) id,
  };
  final rows = await client
      .from('catalog_items')
      .select('id, name, type, rarity, source, level')
      .inFilter('type', const ['skin', 'background', 'frame', 'title']);
  final items = [
    for (final row in rows)
      WardrobeItem(
        id: row['id'] as String,
        name: row['name'] as String? ?? row['id'] as String,
        type: row['type'] as String,
        rarity: row['rarity'] as String? ?? 'common',
        source: row['source'] as String? ?? 'special',
        level: (row['level'] as num?)?.toInt(),
        owned: owned.contains(row['id']),
      ),
  ]..sort((a, b) {
      final byRarity = (_rarityRank[a.rarity] ?? 9).compareTo(_rarityRank[b.rarity] ?? 9);
      if (byRarity != 0) return byRarity;
      final byLevel = (a.level ?? 999).compareTo(b.level ?? 999);
      if (byLevel != 0) return byLevel;
      return a.name.compareTo(b.name);
    });
  return WardrobeData(
    skinId: profile.equippedSkinId,
    backgroundId: profile.equippedBackgroundId,
    frameId: profile.equippedFrameId,
    titleId: profile.titleId,
    body: profile.bodyType == 'b' ? BodyType.b : BodyType.a,
    items: items,
  );
});

String _short(String id, String prefix) => id.startsWith(prefix) ? id.substring(prefix.length) : id;

const _tabs = [
  (type: 'skin', label: 'Skins', note: 'Locked skins come from the level road or chests. Each skin has a version for both looks.'),
  (type: 'background', label: 'Backgrounds', note: 'Legendary and Mythic backgrounds only come from chests.'),
  (type: 'frame', label: 'Frames', note: 'Your frame wraps your portrait on your profile, the leaderboard and raids.'),
  (type: 'title', label: 'Titles', note: 'One title at a time. It shows on your profile, the leaderboard and party cards.'),
];

/// Client updates equipped cosmetics; the ownership trigger rejects unowned ids.
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String? _error;
  var _busy = false;
  var _tab = 0;

  Future<void> _equip(WardrobeItem item) async {
    if (_busy || !item.owned) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (item.type == 'title') {
        await ref.read(achievementsRepositoryProvider).setTitleId(item.id);
        invalidateAchievementViews(ref);
      } else {
        final column = switch (item.type) {
          'skin' => 'equipped_skin_id',
          'background' => 'equipped_background_id',
          _ => 'equipped_frame_id',
        };
        await ref.read(supabaseClientProvider).from('profiles').update({column: item.id});
        ref.invalidate(profileViewProvider);
      }
      ref.invalidate(wardrobeProvider);
      ref.invalidate(homeSnapshotProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not equip that look. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearTitle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(achievementsRepositoryProvider).setTitleId(null);
      invalidateAchievementViews(ref);
      ref.invalidate(wardrobeProvider);
      ref.invalidate(homeSnapshotProvider);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not remove the title. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wardrobeProvider);
    return Scaffold(
      appBar: const ClayHeader(title: 'Wardrobe'),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load wardrobe',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(wardrobeProvider),
        ),
        data: (data) {
          final tab = _tabs[_tab];
          final items = data.ofType(tab.type);
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s32),
            children: [
              _WearingCard(data: data),
              const SizedBox(height: 20),
              _TypeTabs(
                selected: _tab,
                counts: [
                  for (final t in _tabs)
                    (owned: data.ofType(t.type).where((i) => i.owned).length, total: data.ofType(t.type).length),
                ],
                onSelect: (i) => setState(() => _tab = i),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.errorText)),
              ],
              const SizedBox(height: AppSpacing.s24),
              if (items.isEmpty)
                Text('Nothing here yet.', style: AppText.bodySmall, textAlign: TextAlign.center)
              else if (tab.type == 'title')
                _TitleList(
                  titles: items,
                  equippedId: data.titleId,
                  onEquip: _busy ? null : _equip,
                  onClear: _busy ? null : _clearTitle,
                )
              else
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.none,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: _photoHeight(tab.type) + 70,
                  ),
                  children: [
                    for (final item in items)
                      _ItemTile(
                        item: item,
                        equipped: data.isEquipped(item),
                        photoHeight: _photoHeight(tab.type),
                        photo: _photo(item, data),
                        onTap: item.owned && !_busy ? () => _equip(item) : null,
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.s16),
              Text(tab.note, style: AppText.caption, textAlign: TextAlign.center),
            ],
          );
        },
      ),
    );
  }

  double _photoHeight(String type) => switch (type) {
        'skin' => 150,
        'background' => 120,
        _ => 104,
      };

  Widget _photo(WardrobeItem item, WardrobeData data) {
    switch (item.type) {
      case 'skin':
        return _SkinPhoto(id: _short(item.id, 'skin_'), body: data.body, rarity: item.rarity);
      case 'background':
        return _BackgroundPhoto(id: _short(item.id, 'bg_'));
      default:
        return ColoredBox(
          color: AppColors.well,
          child: Center(
            child: SizedBox(
              width: 84,
              height: 84,
              child: FittedBox(
                child: PortraitFrame(
                  skinId: _short(data.skinId, 'skin_'),
                  backgroundId: _short(data.backgroundId, 'bg_'),
                  frameId: _short(item.id, 'frame_'),
                  body: data.body,
                ),
              ),
            ),
          ),
        );
    }
  }
}

/// Your look right now: portrait on the left, what you are wearing on the right.
class _WearingCard extends StatelessWidget {
  const _WearingCard({required this.data});

  final WardrobeData data;

  @override
  Widget build(BuildContext context) {
    const inner = BorderRadius.all(Radius.circular(26));
    final skin = _short(data.skinId, 'skin_');
    final background = _short(data.backgroundId, 'bg_');
    return Clay(
      radius: AppRadius.stage,
      height: 236,
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: inner,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned.fill(child: ColoredBox(color: AppColors.well)),
                  Positioned.fill(
                    child: Image.asset(
                      GameAssets.background(background),
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.4),
                    ),
                  ),
                  Positioned(
                    left: -12,
                    top: 12,
                    width: 180,
                    height: 270,
                    child: Image.asset(GameAssets.skin(skin, data.body), fit: BoxFit.fill),
                  ),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: InnerShadowPainter(shadows: stageInnerShade, borderRadius: inner)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WEARING', style: AppText.label.copyWith(fontSize: 11, height: 14 / 11)),
                  const SizedBox(height: 10),
                  _WearingLine(label: 'Skin', value: data.nameOf(data.skinId) ?? _pretty(skin)),
                  _WearingLine(label: 'Background', value: data.nameOf(data.backgroundId) ?? _pretty(background)),
                  _WearingLine(
                    label: 'Frame',
                    value: data.nameOf(data.frameId) ?? _pretty(_short(data.frameId, 'frame_')),
                  ),
                  _WearingLine(
                    label: 'Title',
                    value: data.nameOf(data.titleId) ?? 'None',
                    color: data.titleId == null ? AppColors.inkMuted : AppColors.tealDeep,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _pretty(String id) {
  final words = id.split('_').where((w) => w.isNotEmpty);
  return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

class _WearingLine extends StatelessWidget {
  const _WearingLine({required this.label, required this.value, this.color = AppColors.ink});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(fontSize: 11, height: 14 / 11)),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title.copyWith(fontSize: 14, height: 18 / 14, color: color),
          ),
        ],
      ),
    );
  }
}

/// Skins / Backgrounds / Frames / Titles, each with owned / total.
class _TypeTabs extends StatelessWidget {
  const _TypeTabs({required this.selected, required this.counts, required this.onSelect});

  final int selected;
  final List<({int owned, int total})> counts;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Well(
      height: 50,
      radius: 25,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label: '${_tabs[i].label}, ${counts[i].owned} of ${counts[i].total}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: i == selected
                        ? const BoxDecoration(
                            gradient: clayWhiteGradient,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            boxShadow: AppShadows.clayControl,
                          )
                        : const BoxDecoration(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _tabs[i].label,
                            style: AppText.title.copyWith(
                              fontSize: 12,
                              height: 14 / 12,
                              color: i == selected ? AppColors.tealDeep : AppColors.inkMuted,
                            ),
                          ),
                        ),
                        Text(
                          '${counts[i].owned} / ${counts[i].total}',
                          style: AppText.caption.copyWith(fontSize: 10, height: 12 / 10, color: AppColors.placeholder),
                        ),
                      ],
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

class _SkinPhoto extends StatelessWidget {
  const _SkinPhoto({required this.id, required this.body, required this.rarity});

  final String id;
  final BodyType body;
  final String rarity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, 0.4),
          radius: 0.9,
          colors: [AppColors.raritySoft(rarity), AppColors.well],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: (box.maxWidth - 140) / 2,
              top: 6,
              width: 140,
              height: 210,
              child: Image.asset(GameAssets.skin(id, body), fit: BoxFit.fill),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundPhoto extends StatelessWidget {
  const _BackgroundPhoto({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: -20,
          child: Image.asset(GameAssets.background(id), fit: BoxFit.fitWidth),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.equipped,
    required this.photoHeight,
    required this.photo,
    required this.onTap,
  });

  final WardrobeItem item;
  final bool equipped;
  final double photoHeight;
  final Widget photo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !item.owned;
    return Semantics(
      button: item.owned,
      selected: equipped,
      label: '${item.name}, ${item.rarity}${locked ? ', locked' : equipped ? ', equipped' : ''}',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Clay(
              kind: ClayKind.control,
              radius: 22,
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(17)),
                      child: SizedBox(
                        height: photoHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (locked)
                              Opacity(
                                opacity: 0.45,
                                child: ColorFiltered(colorFilter: _greyscale, child: photo),
                              )
                            else
                              photo,
                            if (locked)
                              Center(
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.ink.withValues(alpha: 0.55),
                                  ),
                                  child: const Icon(Icons.lock_rounded, size: 16, color: AppColors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(fontSize: 13, height: 17 / 13),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                    child: Row(
                      children: [
                        Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(2)),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.raritySoft(item.rarity), AppColors.rarity(item.rarity)],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _pretty(item.rarity),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(
                              fontSize: 10,
                              height: 14 / 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rarityText(item.rarity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 1, 10, 0),
                    child: Text(
                      item.sourceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(fontSize: 10, height: 14 / 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (equipped) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(22)),
                    border: Border.all(color: AppColors.tealDeep, width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -5,
              top: -7,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tealDeep,
                  border: Border.all(color: AppColors.white, width: 3),
                ),
                child: const Icon(Icons.check_rounded, size: 13, color: AppColors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

class _TitleList extends StatelessWidget {
  const _TitleList({required this.titles, required this.equippedId, required this.onEquip, required this.onClear});

  final List<WardrobeItem> titles;
  final String? equippedId;
  final void Function(WardrobeItem)? onEquip;

  /// Removes the equipped title.
  final VoidCallback? onClear;

  String _source(WardrobeItem t) {
    switch (t.source) {
      case 'level':
        return t.level == null ? 'Level road' : 'Level ${t.level}';
      case 'chest':
        return 'From chests';
      case 'streak':
        return 'Streak reward';
      case 'starter':
        return 'Starter';
      default:
        return 'Badge reward';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: AppRadius.feature,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < titles.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.hairline),
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      height: 28,
                      padding: const EdgeInsets.fromLTRB(9, 0, 11, 0),
                      decoration: BoxDecoration(
                        color: titles[i].owned ? AppColors.tealSoft : AppColors.well,
                        borderRadius: const BorderRadius.all(Radius.circular(14)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            titles[i].owned ? Icons.auto_awesome_rounded : Icons.lock_rounded,
                            size: 12,
                            color: titles[i].owned ? AppColors.tealDeep : AppColors.placeholder,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            titles[i].name,
                            style: AppText.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: titles[i].owned ? AppColors.tealDeep : AppColors.placeholder,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _source(titles[i]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ),
                    if (titles[i].id == equippedId)
                      Semantics(
                        button: true,
                        label: 'Equipped. Tap to remove the title',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: onClear,
                          child: Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: const BoxDecoration(
                          color: AppColors.tealDeep,
                          borderRadius: BorderRadius.all(Radius.circular(13)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 12, color: AppColors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Equipped',
                              style: AppText.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                          ),
                        ),
                      )
                    else if (titles[i].owned)
                      ClayPill(
                        label: 'Equip',
                        height: 32,
                        onPressed: onEquip == null ? null : () => onEquip!(titles[i]),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
