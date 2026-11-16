import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/portrait_frame.dart';
import '../../data/models/inbox_message.dart';
import '../home/providers/home_providers.dart';
import '../social/guild_emblems.dart';
import '../social/providers/friends_providers.dart';
import 'inbox_copy.dart';
import 'providers/inbox_providers.dart';
import 'package:questline/core/assets/decode_size.dart';

/// Looks of the people who sent friend requests, by user id.
final _senderLooksProvider = FutureProvider.autoDispose.family<Map<String, Map<String, dynamic>>, String>((ref, ids) async {
  watchAccount(ref);
  if (ids.isEmpty) return const {};
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('profiles')
      .select('id, equipped_skin_id, equipped_background_id, equipped_frame_id, body_type')
      .inFilter('id', ids.split(','));
  return {for (final row in rows) row['id'] as String: Map<String, dynamic>.from(row)};
});

/// Your guild's name and crest, for guild fight rows.
final _myGuildProvider = FutureProvider.autoDispose<(String, String)?>((ref) async {
  watchAccount(ref);
  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;
  final profile = await client.from('profiles').select('guild_id').eq('id', uid).maybeSingle();
  final guildId = profile?['guild_id'] as String?;
  if (guildId == null) return null;
  final guild = await client.from('guilds').select('name, emblem').eq('id', guildId).maybeSingle();
  if (guild == null) return null;
  return (guild['name'] as String? ?? 'Your guild', guild['emblem'] as String? ?? '');
});

String _when(DateTime at) {
  final local = at.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final time = '$hour:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'am' : 'pm'}';
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  if (day == today) return 'Today $time';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday $time';
  if (today.difference(day).inDays < 7) return '${days[local.weekday - 1]} $time';
  return '${local.day}/${local.month}/${local.year}';
}

int _num(Object? value) => value is num ? value.round() : 0;

/// Server-only events: guild fights, raid/weekly results, friend requests, boss escape.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final _busy = <String>{};
  String? _error;

  Future<void> _open(InboxMessage message) async {
    if (message.readAt == null) await markInboxRead(ref, message.id);
    if (!mounted) return;
    context.push(inboxRoute(message.type, message.payload));
  }

  Future<void> _markAllRead(List<InboxMessage> unread) async {
    await ref.read(inboxRepositoryProvider).markAllRead([for (final m in unread) m.id]);
    ref.invalidate(homeSnapshotProvider);
    ref.invalidate(inboxMessagesProvider);
  }

  Future<void> _respond(InboxMessage message, bool accept) async {
    final from = message.payload['fromUid'] as String?;
    if (from == null) return;
    setState(() {
      _busy.add(message.id);
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).respondFriendRequest(fromUid: from, accept: accept);
      await markInboxRead(ref, message.id);
      ref.invalidate(friendshipsProvider);
      ref.invalidate(friendRowsProvider);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy.remove(message.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inboxMessagesProvider);
    final messages = async.asData?.value ?? const <InboxMessage>[];
    final unread = [for (final m in messages) if (m.readAt == null) m];
    return Scaffold(
      appBar: ClayHeader(
        title: 'Inbox',
        trailing: unread.isEmpty
            ? null
            : ClayPill(label: 'Mark all read', color: AppColors.tealDeep, onPressed: () => _markAllRead(unread)),
      ),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load inbox',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(inboxMessagesProvider),
        ),
        data: (messages) {
          final padding = EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, bottomClearance(context));
          if (messages.isEmpty) {
            return ListView(padding: padding, children: const [_NothingNew()]);
          }
          final fresh = [for (final m in messages) if (m.readAt == null) m];
          final earlier = [for (final m in messages) if (m.readAt != null) m];
          final senders = <String>{
            for (final m in messages)
              if (m.type == 'friend_request' && m.payload['fromUid'] is String) m.payload['fromUid'] as String,
          }.toList()
            ..sort();
          final looks = ref.watch(_senderLooksProvider(senders.join(','))).asData?.value ?? const {};
          final guild = ref.watch(_myGuildProvider).asData?.value;
          final pendingFrom = {
            for (final row in ref.watch(friendRowsProvider).asData?.value.incoming ?? const <FriendRow>[]) row.profile.id,
          };
          Widget row(InboxMessage m) => _InboxRow(
                message: m,
                look: looks[m.payload['fromUid']],
                guild: guild,
                pending: pendingFrom.contains(m.payload['fromUid']),
                busy: _busy.contains(m.id),
                onOpen: () => _open(m),
                onRespond: (accept) => _respond(m, accept),
              );
          return ListView(
            padding: padding,
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
              ],
              if (fresh.isNotEmpty) ...[
                SectionLabel(label: 'New', count: '${fresh.length}'),
                const SizedBox(height: 14),
                ClayList(dividerIndent: 66, children: [for (final m in fresh) row(m)]),
                const SizedBox(height: 24),
              ],
              if (earlier.isNotEmpty) ...[
                const SectionLabel(label: 'Earlier', gemColor: AppColors.inkFaint),
                const SizedBox(height: 14),
                ClayList(dividerIndent: 66, children: [for (final m in earlier) row(m)]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({
    required this.message,
    required this.look,
    required this.guild,
    required this.pending,
    required this.busy,
    required this.onOpen,
    required this.onRespond,
  });

  final InboxMessage message;
  final Map<String, dynamic>? look;
  final (String, String)? guild;
  final bool pending;
  final bool busy;
  final VoidCallback onOpen;
  final ValueChanged<bool> onRespond;

  @override
  Widget build(BuildContext context) {
    final p = message.payload;
    final unread = message.readAt == null;
    final bold = AppText.title.copyWith(fontSize: 14, height: 19 / 14);
    TextSpan b(String text) => TextSpan(text: text, style: bold);
    final when = _when(message.createdAt);
    late final List<InlineSpan> spans;
    String? detail;
    Widget icon;
    List<Widget> actions = const [];

    switch (message.type) {
      case 'weekly_results':
        final coins = _num(p['rankCoins']) + (p['targetHit'] == true ? _num(p['targetCoins']) : 0) + _num(p['guildQuestCoins']);
        final rank = p['rank'];
        spans = [
          b('Weekly results are in.'),
          TextSpan(
            text: rank is num
                ? ' You finished #${rank.toInt()}${p['activeFriends'] is num ? ' of ${_num(p['activeFriends']) + 1}' : ''}'
                    '${coins > 0 ? ' and earned $coins coins.' : '.'}'
                : coins > 0
                    ? ' You earned $coins coins.'
                    : ' See how your week went.',
          ),
        ];
        icon = const _IconCircle(icon: Icons.emoji_events_rounded, wash: AppColors.legendarySoft, color: AppColors.legendaryText);
        actions = [_ActionButton(label: 'See your recap', primary: true, onTap: onOpen)];
      case 'friend_request':
        final name = p['displayName'] as String? ?? p['username'] as String? ?? 'Someone';
        spans = [b(name), const TextSpan(text: ' wants to be friends.')];
        icon = look == null
            ? const _IconCircle(icon: Icons.person_rounded, wash: AppColors.tealSoft, color: AppColors.tealDeep)
            : PortraitFrame(
                skinId: _short(look!['equipped_skin_id'], 'skin_', 'starter'),
                backgroundId: _short(look!['equipped_background_id'], 'bg_', 'starter'),
                frameId: _short(look!['equipped_frame_id'], 'frame_', 'apprentice'),
                body: look!['body_type'] == 'b' ? BodyType.b : BodyType.a,
                size: PortraitFrameSize.leaderboard,
              );
        if (pending) {
          actions = [
            _ActionButton(label: 'Accept', primary: true, onTap: busy ? null : () => onRespond(true)),
            _ActionButton(label: 'Decline', onTap: busy ? null : () => onRespond(false)),
          ];
        }
      case 'raid_result':
        final name = p['name'] as String? ?? 'the boss';
        final result = p['result'] as String? ?? '';
        final won = result == 'victory' || result == 'narrow_win';
        spans = won
            ? [
                b('Raid result:'),
                const TextSpan(text: ' your party beat '),
                b(name),
                TextSpan(text: p['isMvp'] == true ? '. You were MVP.' : '.'),
              ]
            : [b('Raid result:'), const TextSpan(text: ' '), b(name), const TextSpan(text: ' escaped your party.')];
        final coins = _num(p['coins']);
        final penalty = _num(p['penalty']);
        detail = [
          result == 'narrow_win' ? 'Narrow win' : (won ? 'Victory' : 'Escaped'),
          if (coins > 0) '+$coins coins',
          if (penalty > 0) '−$penalty coins',
        ].join(', ');
        icon = const _IconCircle(icon: Icons.groups_rounded, wash: AppColors.arenaLight, color: AppColors.raidInk);
      case 'guild_fight':
        final name = p['name'] as String? ?? 'a boss';
        final g = guild;
        spans = [b(g?.$1 ?? 'Your guild'), const TextSpan(text: ' posted a guild fight: '), b(name), const TextSpan(text: '.')];
        icon = g == null || g.$2.isEmpty
            ? const _IconCircle(icon: Icons.shield_rounded, wash: AppColors.tealSoft, color: AppColors.tealDeep)
            : SizedBox(width: 42, height: 46, child: Center(child: GuildEmblem(id: g.$2, width: 40)));
        actions = [_ActionButton(label: 'Open fight', onTap: onOpen, accent: true)];
      case 'boss_result':
        final name = p['name'] as String? ?? 'A boss';
        final escaped = p['result'] == 'escaped';
        spans = escaped
            ? [b(name), const TextSpan(text: ' escaped before the deadline.')]
            : [b(name), const TextSpan(text: ' was defeated.')];
        final penalty = _num(p['penalty']);
        if (escaped && penalty > 0) detail = '−$penalty coins';
        final tier = p['tier'] is String && GameAssets.bossTiers.contains(p['tier']) ? p['tier'] as String : 'brute';
        icon = _BossCircle(tier: tier, wash: escaped ? AppColors.bossHpSoft : AppColors.tealSoft);
      default:
        spans = [b(inboxTitle(message.type)), TextSpan(text: ' ${inboxBody(message.type, p)}')];
        icon = const _IconCircle(icon: Icons.notifications_rounded, wash: AppColors.tealSoft, color: AppColors.tealDeep);
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 42,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    icon,
                    if (unread)
                      Positioned(
                        left: -10,
                        top: 17,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.awakeningTeal, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  label: unread ? 'Unread' : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(children: spans), style: AppText.bodySmall.copyWith(fontSize: 14, height: 19 / 14)),
                      const SizedBox(height: 4),
                      Text(
                        [when, ?detail].join(' · '),
                        style: AppText.caption.copyWith(fontWeight: FontWeight.w500, color: AppColors.inkFaint),
                      ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, runSpacing: 8, children: actions),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _short(Object? id, String prefix, String fallback) {
  if (id is! String || id.isEmpty) return fallback;
  return id.startsWith(prefix) ? id.substring(prefix.length) : id;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap, this.primary = false, this.accent = false});

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return ClayPill(
      label: label,
      height: 34,
      kind: primary ? ClayKind.teal : ClayKind.control,
      color: primary ? AppColors.white : (accent ? AppColors.tealDeep : AppColors.ink),
      onPressed: onTap,
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.wash, required this.color});

  final IconData icon;
  final Color wash;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _BossCircle extends StatelessWidget {
  const _BossCircle({required this.tier, required this.wash});

  final String tier;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: wash, shape: BoxShape.circle))),
          Positioned(left: -6, top: -12, child: Image.asset(GameAssets.boss(tier), width: 54, height: 54, cacheWidth: decodeWidth(context, 54))),
        ],
      ),
    );
  }
}

class _NothingNew extends StatelessWidget {
  const _NothingNew();

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded, size: 30, color: AppColors.tealDeep),
          ),
          const SizedBox(height: 10),
          Text('Nothing new', style: AppText.h2.copyWith(fontSize: 18, height: 24 / 18)),
          const SizedBox(height: 10),
          Text(
            'Weekly results, raid results, guild fights and friend requests land here.',
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14),
          ),
        ],
      ),
    );
  }
}
