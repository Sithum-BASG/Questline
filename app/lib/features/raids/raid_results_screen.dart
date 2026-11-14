import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import '../../data/models/raid.dart';
import '../../data/models/raid_member.dart';
import '../social/providers/friends_providers.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/boss_card.dart';
import '../../core/theme/app_colors.dart';

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
  final Map<String, int> damageByUser;
  final bool isCreator;
  final Set<String> friendIds;
}

final raidResultsProvider =
    FutureProvider.autoDispose.family<RaidResultsSnapshot?, String>((ref, raidId) async {
  final client = ref.watch(supabaseClientProvider);
  final myId = ref.watch(authStateProvider).asData?.value.session?.user.id;
  final row = await client.from('raids').select().eq('id', raidId).maybeSingle();
  if (row == null) return null;
  final raid = Raid.fromJson(Map<String, dynamic>.from(row));

  final memberRows = await client.from('raid_members').select().eq('raid_id', raidId).order('joined_at');
  final members = [
    for (final m in memberRows) RaidMember.fromJson(Map<String, dynamic>.from(m as Map)),
  ];

  final damageRows = await client.from('raid_damage').select().eq('raid_id', raidId);
  final damageByUser = <String, int>{
    for (final d in damageRows) d['user_id'] as String: (d['damage'] as num).toInt(),
  };

  final friendships = await ref.watch(friendshipsProvider.future);
  final friendIds = friendships
      .where((f) => f.status == 'accepted')
      .map((f) => f.friendId)
      .toSet();

  return RaidResultsSnapshot(
    raid: raid,
    members: members,
    damageByUser: damageByUser,
    isCreator: myId != null && raid.createdBy == myId,
    friendIds: friendIds,
  );
});

String _resultLabel(String status) {
  switch (status) {
    case 'victory':
      return 'Victory';
    case 'narrow_win':
      return 'Narrow win';
    case 'escaped':
      return 'Escaped';
    default:
      return status;
  }
}

/// Raid outcome: contribution checks, MVP, add non-friends.
class RaidResultsScreen extends ConsumerStatefulWidget {
  const RaidResultsScreen({super.key, required this.raidId});

  final String raidId;

  @override
  ConsumerState<RaidResultsScreen> createState() => _RaidResultsScreenState();
}

class _RaidResultsScreenState extends ConsumerState<RaidResultsScreen> {
  final _busy = <String>{};

  Future<void> _addFriend(String uid) async {
    setState(() => _busy.add(uid));
    try {
      // Friend requests need username or code; look up username from profiles.
      final row = await ref.read(supabaseClientProvider).from('profiles').select('username').eq('id', uid).maybeSingle();
      final username = row?['username'] as String?;
      if (username == null) throw const ApiException(code: 'not_found', message: 'Player not found.');
      await ref.read(apiClientProvider).sendFriendRequest(username: username);
      ref.invalidate(friendshipsProvider);
      ref.invalidate(raidResultsProvider(widget.raidId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent')),
        );
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

    return Scaffold(
      appBar: ClayHeader(
        title: 'Raid results',
        closeIcon: true,
        onBack: () => context.go('/bosses'),
      ),
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
            return const EmptyState(title: 'Results not found', body: 'This raid may still be active.');
          }
          if (snap.raid.status == 'active') {
            return EmptyState(
              title: 'Raid still active',
              body: 'Results appear after the deadline.',
              actionLabel: 'Open raid',
              onAction: () => context.go('/raids/${widget.raidId}'),
            );
          }
          final mvp = snap.members.where((m) => m.isMvp).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s32),
            children: [
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Clay(
                        circle: true,
                        width: 200,
                        height: 200,
                        gradient: RadialGradient(
                          colors: snap.raid.status == 'defeated'
                              ? const [AppColors.white, AppColors.legendarySoft]
                              : const [AppColors.white, AppColors.well],
                        ),
                      ),
                      BossArt(tier: snap.raid.tier, size: 170, greyed: snap.raid.status != 'defeated'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(_resultLabel(snap.raid.status), style: AppText.display, textAlign: TextAlign.center),
              Text(snap.raid.name, style: AppText.h2.copyWith(color: AppColors.inkMuted), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s20),
              QCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Damage ${snap.raid.damage} / ${snap.raid.maxHp}',
                      style: AppText.title,
                    ),
                    const SizedBox(height: 10),
                    ClayBar(
                      value: snap.raid.maxHp <= 0 ? 0 : snap.raid.damage / snap.raid.maxHp,
                      gradient: hpFillGradient,
                    ),
                  ],
                ),
              ),
              if (mvp.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s16),
                QCard(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Row(
                    children: [
                      ClayDot(
                        size: 44,
                        gradient: dotGradient(AppColors.legendary.withValues(alpha: 0.55), AppColors.legendary),
                        icon: Icons.workspace_premium_rounded,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MVP', style: AppText.label.copyWith(color: AppColors.legendaryText)),
                            Text(mvp.first.displayName, style: AppText.title),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s24),
              Semantics(header: true, child: Text('Contributions', style: AppText.h2)),
              const SizedBox(height: AppSpacing.s12),
              for (final member in snap.members) ...[
                MemberCard(
                  name: member.displayName,
                  title: member.leftRaid
                      ? 'Left · loot forfeited'
                      : member.metFairShare
                          ? 'Pulled their weight'
                          : 'Below fair share',
                  skinId: (member.skinId ?? 'skin_starter').replaceFirst('skin_', ''),
                  backgroundId: 'starter',
                  body: member.bodyType == 'b' ? BodyType.b : BodyType.a,
                  damage: snap.isCreator ? snap.damageByUser[member.userId] : null,
                  pulledWeight: member.metFairShare,
                ),
                if (myId != null &&
                    member.userId != myId &&
                    !member.leftRaid &&
                    !snap.friendIds.contains(member.userId)) ...[
                  const SizedBox(height: AppSpacing.s8),
                  QButton(
                    label: 'Add as friend',
                    icon: Icons.person_add_alt_1_rounded,
                    height: 46,
                    foreground: AppColors.tealDeep,
                    variant: QButtonVariant.secondary,
                    loading: _busy.contains(member.userId),
                    onPressed: _busy.contains(member.userId) ? null : () => _addFriend(member.userId),
                  ),
                ],
                const SizedBox(height: AppSpacing.s12),
              ],
              const SizedBox(height: AppSpacing.s12),
              QButton(
                label: 'Done',
                onPressed: () => context.go('/bosses'),
              ),
            ],
          );
        },
      ),
    );
  }
}
