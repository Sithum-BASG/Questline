import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/portrait_frame.dart';
import '../../core/widgets/q_button.dart';
import 'providers/feed_providers.dart';
import 'package:questline/core/assets/decode_size.dart';

/// Paginated friends activity feed (`activity_events` via `visible_to` RLS), grouped by day.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  var _pages = 1;

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (var i = 0; i < _pages; i++) ref.watch(feedPageProvider(i)),
    ];
    final loadingFirst = pages.first.isLoading && !pages.first.hasValue;
    final firstError = pages.first.asError?.error;

    final items = [
      for (final page in pages) ...?(page.asData?.value.items),
    ];
    final lastPage = pages.last;
    final lastHasMore = lastPage.asData?.value.hasMore ?? false;
    final lastPageError = lastPage.hasError && _pages > 1;
    final loadingMore = lastPage.isLoading && lastPage.hasValue == false && _pages > 1;

    return Scaffold(
      appBar: ClayHeader(
        title: 'Feed',
        onBack: () => context.go('/social'),
        trailing: ClayIconButton(
          icon: Icons.person_add_alt_1_rounded,
          tooltip: 'Add a friend',
          size: 44,
          onPressed: () => context.go('/social/friends'),
        ),
      ),
      body: loadingFirst
          ? const LoadingSkeleton()
          : firstError != null
              ? EmptyState(
                  title: 'Could not load feed',
                  body: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: () {
                    for (var i = 0; i < _pages; i++) {
                      ref.invalidate(feedPageProvider(i));
                    }
                  },
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, bottomClearance(context)),
                  children: items.isEmpty
                      ? [const _QuietCard()]
                      : [
                          for (final (label, group) in _byDay(items)) ...[
                            SectionLabel(
                              label: label,
                              count: '${group.length}',
                              gemColor: label == 'Today' ? AppColors.awakeningTeal : AppColors.inkFaint,
                            ),
                            const SizedBox(height: 14),
                            ClayList(dividerIndent: 76, children: [for (final item in group) _FeedRow(item: item)]),
                            const SizedBox(height: 24),
                          ],
                          if (lastPageError)
                            Center(
                              child: QButton(
                                label: 'Retry',
                                variant: QButtonVariant.secondary,
                                onPressed: () => ref.invalidate(feedPageProvider(_pages - 1)),
                              ),
                            )
                          else if (lastHasMore)
                            Center(
                              child: loadingMore
                                  ? const CircularProgressIndicator()
                                  : QButton(
                                      label: 'Load more',
                                      variant: QButtonVariant.secondary,
                                      onPressed: () => setState(() => _pages += 1),
                                    ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.inkFaint),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Only milestones show here. Quest titles are never shared.',
                                  textAlign: TextAlign.center,
                                  style: AppText.caption.copyWith(fontWeight: FontWeight.w400, color: AppColors.inkFaint),
                                ),
                              ),
                            ],
                          ),
                        ],
                ),
    );
  }
}

/// Groups newest-first items into Today, Yesterday and Earlier.
List<(String, List<FeedItem>)> _byDay(List<FeedItem> items) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final groups = <String, List<FeedItem>>{};
  for (final item in items) {
    final at = item.event.createdAt.toLocal();
    final day = DateTime(at.year, at.month, at.day);
    final label = day == today
        ? 'Today'
        : day == today.subtract(const Duration(days: 1))
            ? 'Yesterday'
            : 'Earlier';
    groups.putIfAbsent(label, () => []).add(item);
  }
  return [for (final label in const ['Today', 'Yesterday', 'Earlier']) if (groups[label] != null) (label, groups[label]!)];
}

String _when(DateTime at) {
  final local = at.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 2) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${local.day}/${local.month}/${local.year}';
}

String _title(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final actor = item.actor;
    final name = item.actorName;
    final payload = item.event.payload;
    final bold = AppText.title.copyWith(fontSize: 14, height: 19 / 14);
    TextSpan b(String text, [Color? color]) => TextSpan(text: text, style: bold.copyWith(color: color));
    final (spans, detail, thumb) = switch (item.event.type) {
      'level_up' => (
          [b(name), const TextSpan(text: ' reached '), b('level ${payload['level'] ?? ''}'.trim())],
          null,
          _LevelThumb(level: payload['level']),
        ),
      'boss_defeated' => (
          payload['name'] is String && (payload['name'] as String).trim().isNotEmpty
              ? [
                  b(name),
                  const TextSpan(text: ' beat '),
                  b(payload['name'] as String),
                  if (payload['tier'] is String) TextSpan(text: ', a ${_title(payload['tier'] as String)} boss'),
                ]
              : [
                  b(name),
                  const TextSpan(text: ' beat a '),
                  b(payload['tier'] is String ? '${_title(payload['tier'] as String)} boss' : 'boss'),
                ],
          null,
          _BossThumb(tier: payload['tier'] is String ? payload['tier'] as String : 'brute'),
        ),
      'raid_won' => (
          [
            b(name),
            const TextSpan(text: "'s party won the raid"),
            if (payload['name'] is String) ...[const TextSpan(text: ' against '), b(payload['name'] as String)],
          ],
          payload['result'] == 'narrow_win' ? 'Narrow win' : null,
          const _IconThumb(icon: Icons.groups_rounded, wash: AppColors.arenaLight, color: AppColors.raidInk),
        ),
      'chest_drop' => (
          [
            b(name),
            const TextSpan(text: ' opened a chest and found '),
            if (payload['rarity'] is String)
              b('${_title(payload['rarity'] as String)} loot', AppColors.rarity(payload['rarity'] as String))
            else
              b('loot'),
          ],
          null,
          _GemThumb(rarity: payload['rarity'] is String ? payload['rarity'] as String : 'common'),
        ),
      'badge' => (
          [b(name), const TextSpan(text: ' earned the '), b(_badgeName(payload)), const TextSpan(text: ' badge')],
          null,
          _BadgeThumb(payload: payload),
        ),
      _ => ([TextSpan(text: item.line)], null, null),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            if (actor != null)
              PortraitFrame(
                skinId: actor.skinId,
                backgroundId: actor.backgroundId,
                frameId: actor.frameId,
                body: actor.bodyType == 'b' ? BodyType.b : BodyType.a,
                size: PortraitFrameSize.leaderboard,
              )
            else
              const SizedBox(width: 48, height: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: spans),
                    style: AppText.bodySmall.copyWith(fontSize: 14, height: 19 / 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [_when(item.event.createdAt), ?detail].join(' · '),
                    style: AppText.caption.copyWith(color: AppColors.inkFaint),
                  ),
                ],
              ),
            ),
            if (thumb != null) ...[const SizedBox(width: 10), thumb],
          ],
        ),
      ),
    );
  }
}

String _badgeName(Map<String, dynamic> payload) {
  final raw = payload['badge'] ?? payload['badge_id'] ?? payload['id'];
  if (raw is! String || raw.isEmpty) return 'new';
  final id = raw.startsWith('badge_') ? raw.substring(6) : raw;
  final words = id.split('_').map(_title).join(' ');
  final tier = payload['tier'];
  const numerals = {1: 'I', 2: 'II', 3: 'III'};
  return tier is num && numerals[tier.toInt()] != null ? '$words ${numerals[tier.toInt()]}' : words;
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.wash, required this.child});

  final Color wash;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
        child: CustomPaint(
          painter: const InnerShadowPainter(
            circle: true,
            shadows: [InnerShadow(Offset(3, 3), 8, Color(0x1F101935)), InnerShadow(Offset(-3, -3), 8, Color(0xD9FFFFFF))],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BossThumb extends StatelessWidget {
  const _BossThumb({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final safe = GameAssets.bossTiers.contains(tier) ? tier : 'brute';
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: _Thumb(wash: AppColors.tealSoft, child: SizedBox.expand())),
          Positioned(left: -6, top: -14, child: Image.asset(GameAssets.boss(safe), width: 64, height: 64, cacheWidth: decodeWidth(context, 64))),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.tealDeep,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: const Icon(Icons.check_rounded, size: 12, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelThumb extends StatelessWidget {
  const _LevelThumb({required this.level});

  final Object? level;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 3)),
        child: Clay(
          kind: ClayKind.teal,
          circle: true,
          width: 40,
          height: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('LV', style: AppText.caption.copyWith(fontSize: 7, height: 8 / 7, fontWeight: FontWeight.w700, color: AppColors.white)),
              Text(
                '${level ?? ''}',
                style: AppText.numbers.copyWith(fontSize: 15, height: 17 / 15, color: AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GemThumb extends StatelessWidget {
  const _GemThumb({required this.rarity});

  final String rarity;

  @override
  Widget build(BuildContext context) {
    final colour = AppColors.rarity(rarity);
    return _Thumb(
      wash: colour.withValues(alpha: 0.12),
      child: Center(
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: dotGradient(Color.lerp(colour, AppColors.white, 0.45)!, colour),
              boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.18), offset: const Offset(2, 3), blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeThumb extends StatelessWidget {
  const _BadgeThumb({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final raw = payload['badge'] ?? payload['badge_id'] ?? payload['id'];
    final id = raw is String ? (raw.startsWith('badge_') ? raw.substring(6) : raw) : '';
    final tier = payload['tier'] is num ? (payload['tier'] as num).toInt().clamp(1, 3) : 1;
    if (!GameAssets.badgeIds.contains(id)) {
      return const _IconThumb(icon: Icons.military_tech_rounded, wash: AppColors.legendarySoft, color: AppColors.legendaryText);
    }
    return SizedBox(width: 52, height: 52, child: Image.asset(GameAssets.badge(id, tier), width: 54, height: 54, cacheWidth: decodeWidth(context, 54)));
  }
}

class _IconThumb extends StatelessWidget {
  const _IconThumb({required this.icon, required this.wash, required this.color});

  final IconData icon;
  final Color wash;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Thumb(wash: wash, child: Center(child: Icon(icon, size: 24, color: color)));
  }
}

class _QuietCard extends StatelessWidget {
  const _QuietCard();

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
            child: const Icon(Icons.dynamic_feed_rounded, size: 28, color: AppColors.tealDeep),
          ),
          const SizedBox(height: 12),
          Text('Quiet so far', style: AppText.h2.copyWith(fontSize: 18, height: 24 / 18)),
          const SizedBox(height: 6),
          Text(
            'When friends level up or beat bosses, it shows here.',
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14),
          ),
          const SizedBox(height: 16),
          QButton(label: 'Add friends', height: 52, onPressed: () => context.go('/social/friends')),
        ],
      ),
    );
  }
}
