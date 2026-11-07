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
      appBar: AppBar(
        title: Text('Raid results', style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/bosses'),
        ),
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
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(_resultLabel(snap.raid.status), style: AppText.h1),
              Text(snap.raid.name, style: AppText.body),
              const SizedBox(height: AppSpacing.s16),
              QCard(
                child: Text(
                  'Damage ${snap.raid.damage} / ${snap.raid.maxHp}',
                  style: AppText.body,
                ),
              ),
              if (mvp.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s16),
                Text('MVP', style: AppText.h2),
                const SizedBox(height: AppSpacing.s8),
                Text(mvp.first.displayName, style: AppText.title),
              ],
              const SizedBox(height: AppSpacing.s24),
              Text('Contributions', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
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
                    variant: QButtonVariant.secondary,
                    loading: _busy.contains(member.userId),
                    onPressed: _busy.contains(member.userId) ? null : () => _addFriend(member.userId),
                  ),
                ],
                const SizedBox(height: AppSpacing.s12),
              ],
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
