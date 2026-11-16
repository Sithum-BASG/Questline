import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/q_button.dart';
import '../../data/models/raid.dart';
import '../../data/models/raid_member.dart';
import '../social/providers/friends_providers.dart';
import 'raid_widgets.dart';

class RaidResultsSnapshot {
  const RaidResultsSnapshot({
    required this.raid,
    required this.members,
    required this.damageByUser,
    required this.isCreator,
    required this.friendIds,
  });

  final Raid raid;
  final List<RaidMember> members;

  /// Exact damage: your own row, or every row for the raid creator.
  final Map<String, int> damageByUser;
  final bool isCreator;
  final Set<String> friendIds;
}

final raidResultsProvider = FutureProvider.autoDispose.family<RaidResultsSnapshot?, String>((ref, raidId) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final myId = ref.watch(authStateProvider).asData?.value.session?.user.id;
  final row = await client.from('raids').select().eq('id', raidId).maybeSingle();
  if (row == null) return null;
  final raid = Raid.fromJson(Map<String, dynamic>.from(row));

  final memberRows = await client
      .from('raid_members')
      .select()
      .eq('raid_id', raidId)
      .order('joined_at', ascending: true);
  final members = [for (final m in memberRows) RaidMember.fromJson(Map<String, dynamic>.from(m as Map))];

  final damageRows = await client.from('raid_damage').select().eq('raid_id', raidId);
  final damageByUser = <String, int>{for (final d in damageRows) d['user_id'] as String: (d['damage'] as num).toInt()};

  final friendships = await ref.watch(friendshipsProvider.future);
  final friendIds = friendships.where((f) => f.status == 'accepted').map((f) => f.friendId).toSet();

  return RaidResultsSnapshot(
    raid: raid,
    members: members,
    damageByUser: damageByUser,
    isCreator: myId != null && raid.createdBy == myId,
    friendIds: friendIds,
  );
});

/// Raid outcome: the stamp, party damage against the win line, each member's
/// share and loot, the MVP, and adding raiders as friends.
class RaidResultsScreen extends ConsumerStatefulWidget {
  const RaidResultsScreen({super.key, required this.raidId});

  final String raidId;

  @override
  ConsumerState<RaidResultsScreen> createState() => _RaidResultsScreenState();
}

class _RaidResultsScreenState extends ConsumerState<RaidResultsScreen> {
  final _busy = <String>{};
  final _requested = <String>{};

  Future<void> _addFriend(String uid) async {
    setState(() => _busy.add(uid));
    try {
      // Friend requests need a username or code; look the username up.
      final row = await ref
          .read(supabaseClientProvider)
          .from('profiles')
          .select('username')
          .eq('id', uid)
          .maybeSingle();
      final username = row?['username'] as String?;
      if (username == null) throw const ApiException(code: 'not_found', message: 'Player not found.');
      await ref.read(apiClientProvider).sendFriendRequest(username: username);
      ref.invalidate(friendshipsProvider);
      if (mounted) {
        setState(() => _requested.add(uid));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent')));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(raidResultsProvider(widget.raidId));
    final myId = ref.watch(authStateProvider).asData?.value.session?.user.id;
    final rules = ref.watch(raidRulesProvider).asData?.value;

    return Scaffold(
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load results',
          body: 'Try again in a moment.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(raidResultsProvider(widget.raidId)),
        ),
        data: (snap) {
          if (snap == null) {
            return EmptyState(
              title: 'Results not found',
              body: 'This raid may still be active.',
              actionLabel: 'Back to bosses',
              onAction: () => context.go('/bosses'),
            );
          }
          if (snap.raid.status == 'active') {
            return EmptyState(
              title: 'Raid still active',
              body: 'Results appear after the deadline.',
              actionLabel: 'Open raid',
              onAction: () => context.go('/raids/${widget.raidId}'),
            );
          }
          return _ResultView(
            snap: snap,
            myId: myId,
            rules: rules,
            busy: _busy,
            requested: _requested,
            onAddFriend: _addFriend,
          );
        },
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.snap,
    required this.myId,
    required this.rules,
    required this.busy,
    required this.requested,
    required this.onAddFriend,
  });

  final RaidResultsSnapshot snap;
  final String? myId;
  final RaidRules? rules;
  final Set<String> busy;
  final Set<String> requested;
  final ValueChanged<String> onAddFriend;

  @override
  Widget build(BuildContext context) {
    final raid = snap.raid;
    final escaped = raid.status == 'escaped';
    final win = raid.status == 'victory';
    final topInset = MediaQuery.paddingOf(context).top;
    final arenaHeight = 324 + topInset;
    final pct = raid.maxHp <= 0 ? 0.0 : (raid.damage / raid.maxHp).clamp(0.0, 1.0);
    final narrow = rules?.narrowThreshold ?? 0.75;
    final reached = pct >= narrow;
    final fairShare = rules?.fairShare(raid.maxHp, raid.participants);
    final bonus = ((rules?.victoryBonus ?? 0.25) * 100).round();
    final members = [...snap.members]
      ..sort((a, b) {
        if (a.userId == myId) return -1;
        if (b.userId == myId) return 1;
        return (snap.damageByUser[b.userId] ?? -1).compareTo(snap.damageByUser[a.userId] ?? -1);
      });
    final maxDamage = math.max(fairShare ?? 1, snap.damageByUser.values.fold<int>(0, math.max));
    final mvp = [
      for (final m in snap.members)
        if (m.isMvp) m,
    ];
    final ink = escaped ? AppColors.escapeInk : AppColors.clayEdge;
    final stamp = escaped
        ? 'ESCAPED'
        : win
        ? 'VICTORY'
        : 'NARROW WIN';
    final rule = win
        ? 'Full loot +$bonus%'
        : escaped
        ? 'Under ${(narrow * 100).round()}%: no loot'
        : 'Half loot';

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(bottom: raidDockClearance(context)),
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: arenaHeight,
                  child: RaidArena(
                    center: const Alignment(0, -0.05),
                    floor: const Alignment(0, 0.82),
                    colors: escaped
                        ? const [AppColors.escapeFieldLight, AppColors.escapeFieldMid, AppColors.escapeFieldDeep]
                        : const [AppColors.winFieldLight, AppColors.winFieldMid, AppColors.winFieldDeep],
                    floorColor: escaped ? AppColors.bossHpText : AppColors.tealDeep,
                  ),
                ),
                Positioned(
                  left: escaped ? 70 : 0,
                  right: 0,
                  top: topInset + 22,
                  child: IgnorePointer(
                    child: Center(
                      child: Semantics(
                        label: escaped ? '${raid.name} escaping' : '${raid.name}, defeated',
                        child: escaped
                            ? Transform.flip(flipX: true, child: BossArt(tier: raid.tier, size: 240))
                            : Opacity(
                                opacity: 0.85,
                                child: Transform.translate(
                                  offset: const Offset(0, 14),
                                  child: Transform.rotate(
                                    angle: -12 * math.pi / 180,
                                    child: BossArt(tier: raid.tier, size: 240, greyed: true),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.screen,
                  right: AppSpacing.screen,
                  top: topInset + 12,
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        ClayIconButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Close',
                          kind: ClayKind.onScene,
                          onPressed: () => context.go('/bosses'),
                        ),
                        Expanded(
                          child: Center(
                            child: ArenaPill(label: 'RAID RESULT', color: ink),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: arenaHeight - 102,
                  child: Center(
                    child: _Stamp(label: stamp, escaped: escaped),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.screen, arenaHeight - 28, AppSpacing.screen, 0),
                  child: Clay(
                    radius: 30,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(raid.name, style: AppText.h1.copyWith(fontSize: 21, height: 27 / 21)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          win
                              ? 'Beaten before the deadline'
                              : 'The deadline passed ${raidDeadlineLabel(raid.deadline)}',
                          style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text('PARTY DAMAGE', style: AppText.label.copyWith(fontSize: 11, height: 14 / 11)),
                            ),
                            Text.rich(
                              TextSpan(
                                style: AppText.bodySmall,
                                children: [
                                  TextSpan(
                                    text: formatCount(raid.damage),
                                    style: AppText.numbers.copyWith(
                                      fontSize: 15,
                                      height: 18 / 15,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  TextSpan(text: ' / ${formatCount(raid.maxHp)} · '),
                                  TextSpan(
                                    text: '${(pct * 100).round()}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: reached ? AppColors.tealDeep : AppColors.bossHpText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 22,
                          child: LayoutBuilder(
                            builder: (context, constraints) => Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 4,
                                  child: ClayBar(
                                    value: pct,
                                    gradient: reached ? _tealFill : hpFillGradient,
                                    height: 14,
                                  ),
                                ),
                                Positioned(
                                  left: constraints.maxWidth * narrow - 1,
                                  top: 0,
                                  child: Container(
                                    width: 2,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: AppColors.raidInk,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rule,
                                style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${(narrow * 100).round()}% narrow win',
                              style: AppText.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.raidInk,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Party · ${snap.members.length}',
                        style: AppText.h2.copyWith(fontSize: 18, height: 24 / 18),
                      ),
                    ),
                  ),
                  if (fairShare != null) ...[
                    Container(width: 2, height: 12, color: AppColors.raidInk.withValues(alpha: 0.55)),
                    const SizedBox(width: 6),
                    Text(
                      'Fair share ${formatCount(fairShare)}',
                      style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Clay(
                radius: 28,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final (i, m) in members.indexed) ...[
                      if (i > 0)
                        const Divider(height: 1, thickness: 1, indent: 66, endIndent: 14, color: AppColors.hairline),
                      _MemberRow(
                        member: m,
                        isMe: m.userId == myId,
                        damage: snap.damageByUser[m.userId],
                        maxDamage: maxDamage,
                        fairShare: fairShare,
                        loot: _loot(m, raid),
                        canAdd:
                            myId != null &&
                            m.userId != myId &&
                            !m.leftRaid &&
                            !snap.friendIds.contains(m.userId) &&
                            !requested.contains(m.userId),
                        busy: busy.contains(m.userId),
                        onAdd: () => onAddFriend(m.userId),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (mvp.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: Clay(
                  kind: ClayKind.control,
                  radius: 24,
                  height: 64,
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: AppColors.legendarySoft, shape: BoxShape.circle),
                        child: const Icon(Icons.workspace_premium_rounded, color: AppColors.legendaryText, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mvp.first.userId == myId ? "You're the MVP" : '${mvp.first.displayName} is the MVP',
                              style: AppText.title.copyWith(fontSize: 14, height: 18 / 14),
                            ),
                            Text(
                              snap.damageByUser[mvp.first.userId] != null
                                  ? '${formatCount(snap.damageByUser[mvp.first.userId]!)} damage, the most in the party'
                                  : 'The most damage in the party',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        RaidDock(
          child: QButton(label: 'Back to bosses', height: 60, onPressed: () => context.go('/bosses')),
        ),
      ],
    );
  }

  /// Coins this member got: loot when they met their share, the escape
  /// penalty when they did not.
  int _loot(RaidMember m, Raid raid) {
    if (m.leftRaid) return 0;
    if (m.metFairShare) return raid.coinsEligible ? rules?.lootFor(raid.tier, raid.status) ?? 0 : 0;
    return raid.status == 'escaped' ? -(rules?.escapePenalty ?? 0) : 0;
  }
}

const _tealFill = LinearGradient(colors: [AppColors.tealLight, AppColors.teal]);

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.escaped});

  final String label;
  final bool escaped;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -6 * math.pi / 180,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.white, width: 3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: escaped
                ? const [AppColors.bossHpLight, AppColors.bossHpText]
                : const [AppColors.stampTealLight, AppColors.tealButtonEnd],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.ink.withValues(alpha: 0.25), offset: const Offset(4, 8), blurRadius: 16),
          ],
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: AppText.h2.copyWith(
              fontSize: 19,
              height: 24 / 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.damage,
    required this.maxDamage,
    required this.fairShare,
    required this.loot,
    required this.canAdd,
    required this.busy,
    required this.onAdd,
  });

  final RaidMember member;
  final bool isMe;
  final int? damage;
  final int maxDamage;
  final int? fairShare;
  final int loot;
  final bool canAdd;
  final bool busy;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final met = member.metFairShare;
    final lootInk = loot > 0
        ? AppColors.ink
        : loot < 0
        ? AppColors.bossHpText
        : AppColors.inkMuted;
    final note = member.leftRaid
        ? 'left the raid'
        : met
        ? (loot > 0 ? 'loot' : 'no loot')
        : (loot < 0 ? 'penalty' : 'below share');
    return SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
        child: Row(
          children: [
            HeroHead(skinId: member.skinId, bodyType: member.bodyType, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                isMe ? 'You' : member.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.title.copyWith(fontSize: 15, height: 20 / 15),
                              ),
                            ),
                            if (member.isMvp) ...[
                              const SizedBox(width: 6),
                              Container(
                                height: 18,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.legendary,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 10, color: AppColors.legendaryText),
                                    const SizedBox(width: 2),
                                    Text(
                                      'MVP',
                                      style: AppText.label.copyWith(
                                        fontSize: 9,
                                        height: 10 / 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.legendaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (damage != null)
                        Text(
                          formatCount(damage!),
                          style: AppText.numbers.copyWith(
                            fontSize: 13,
                            height: 16 / 13,
                            color: met ? AppColors.ink : AppColors.bossHpText,
                          ),
                        )
                      else
                        Text(
                          member.leftRaid
                              ? 'Left'
                              : met
                              ? '✓ Did their share'
                              : 'Below share',
                          style: AppText.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: member.leftRaid
                                ? AppColors.inkMuted
                                : met
                                ? AppColors.tealDeep
                                : AppColors.bossHpText,
                          ),
                        ),
                    ],
                  ),
                  if (damage != null) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 8,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClayBar(
                              value: maxDamage <= 0 ? 0 : damage! / maxDamage,
                              gradient: met ? _tealFill : hpFillGradient,
                              height: 8,
                            ),
                            if (fairShare != null && maxDamage > 0)
                              Positioned(
                                left: constraints.maxWidth * (fairShare! / maxDamage).clamp(0.0, 1.0) - 1,
                                top: 0,
                                bottom: 0,
                                child: Container(width: 2, color: AppColors.raidInk.withValues(alpha: 0.55)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 92,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: loot > 0 ? 1 : 0.4,
                        child: Image.asset(GameAssets.icon('coin'), width: 16, height: 16),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        loot > 0 ? '+${formatCount(loot)}' : formatCount(loot),
                        style: AppText.numbers.copyWith(fontSize: 15, height: 18 / 15, color: lootInk),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (canAdd)
                    Material(
                      color: AppColors.tealSoft,
                      borderRadius: BorderRadius.circular(13),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: busy ? null : onAdd,
                        child: Semantics(
                          button: true,
                          label: 'Add ${member.displayName} as a friend',
                          excludeSemantics: true,
                          child: SizedBox(
                            height: 26,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 9),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  busy
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.tealDeep),
                                        )
                                      : const Icon(Icons.person_add_alt_1_rounded, size: 13, color: AppColors.tealDeep),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Add friend',
                                    style: AppText.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.tealDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      note,
                      maxLines: 1,
                      style: AppText.caption.copyWith(fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w500),
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
