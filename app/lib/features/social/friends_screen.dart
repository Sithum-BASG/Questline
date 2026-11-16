import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/portrait_frame.dart';
import '../../core/widgets/q_button.dart';
import '../../data/models/profile.dart';
import 'friend_links.dart';
import 'friend_qr_sheet.dart';
import 'providers/friends_providers.dart';
import 'providers/pending_friend_code.dart';
import 'providers/presence_providers.dart';

/// Friends list, incoming requests, and add by username, friend code, QR or link.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  var _busy = false;
  String? _error;
  String? _info;

  var _handlingPending = false;

  @override
  void initState() {
    super.initState();
    // Consume a code that arrived before this screen mounted (cold deep link).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final code = ref.read(pendingFriendCodeProvider);
      if (code != null) _consumePendingCode(code);
    });
  }

  Future<void> _consumePendingCode(String code) async {
    if (_handlingPending || code.isEmpty) return;
    _handlingPending = true;
    ref.read(pendingFriendCodeProvider.notifier).clear();
    try {
      final confirm = await showDialog<bool>(
        context: context,
        barrierColor: AppColors.scrim,
        builder: (context) => _ConfirmCodeDialog(code: code),
      );
      if (confirm != true || !mounted) return;
      final error = await _send(code);
      if (mounted) setState(() => error == null ? _info = 'Request sent.' : _error = error);
    } finally {
      _handlingPending = false;
    }
  }

  Future<void> _share(String code) async {
    await SharePlus.instance.share(ShareParams(text: friendInviteShareText(code)));
  }

  /// Sends a request by friend code or username. Returns an error message, or null when sent.
  Future<String?> _send(String input) async {
    final raw = input.trim();
    if (raw.isEmpty) return 'Enter a username or friend code.';
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final looksLikeCode = RegExp(r'^[A-Za-z0-9]{6,12}$').hasMatch(raw) && !raw.contains('_');
      if (looksLikeCode) {
        await ref.read(apiClientProvider).sendFriendRequest(friendCode: raw.toUpperCase());
      } else {
        await ref.read(apiClientProvider).sendFriendRequest(username: raw);
      }
      ref.invalidate(friendshipsProvider);
      ref.invalidate(friendRowsProvider);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'Could not send the request.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addByUsername() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      builder: (context) => _AddFriendSheet(send: _send),
    );
    if (sent == true && mounted) setState(() => _info = 'Request sent.');
  }

  Future<void> _respond(String fromUid, bool accept) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).respondFriendRequest(fromUid: fromUid, accept: accept);
      ref.invalidate(friendshipsProvider);
      ref.invalidate(friendRowsProvider);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String friendUid) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).removeFriend(friendUid);
      ref.invalidate(friendshipsProvider);
      ref.invalidate(friendRowsProvider);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nested /friends/scan → go('/social/friends') keeps this State alive; listen for new codes.
    ref.listen<String?>(pendingFriendCodeProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _consumePendingCode(next);
      });
    });

    final async = ref.watch(friendRowsProvider);
    final myCode = ref.watch(myFriendCodeProvider).asData?.value;
    final focusing = ref.watch(focusingFriendsProvider).asData?.value ?? const {};

    return Scaffold(
      appBar: ClayHeader(
        title: 'Friends',
        onBack: () => context.go('/social'),
        trailing: ClayIconButton(
          icon: Icons.person_add_alt_1_rounded,
          tooltip: 'Add a friend',
          size: 44,
          onPressed: _busy ? null : _addByUsername,
        ),
      ),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load friends',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(friendRowsProvider),
        ),
        data: (data) {
          final friendCount = data.accepted.length + data.outgoing.length;
          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, bottomClearance(context)),
            children: [
              _CodeCard(
                code: myCode,
                onCopy: myCode == null
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: myCode));
                        if (mounted) setState(() => _info = 'Code copied.');
                      },
                onShowQr: myCode == null ? null : () => showFriendQrSheet(context, myCode),
                onUsername: _busy ? null : _addByUsername,
                onScan: _busy ? null : () => context.go('/social/friends/scan'),
                onShare: myCode == null ? null : () => _share(myCode),
              ),
              if (_error != null || _info != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error ?? _info!,
                  textAlign: TextAlign.center,
                  style: AppText.bodySmall.copyWith(
                    color: _error != null ? AppColors.errorText : AppColors.tealDeep,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (data.incoming.isNotEmpty) ...[
                const SizedBox(height: 24),
                SectionLabel(label: 'Requests', count: '${data.incoming.length}', gemColor: AppColors.legendary),
                const SizedBox(height: 12),
                ClayList(
                  dividerIndent: 76,
                  children: [
                    for (final row in data.incoming)
                      _FriendRowTile(
                        profile: row.profile,
                        subtitle: 'Lv ${row.profile.level} · @${row.profile.username}',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              button: true,
                              label: 'Decline ${row.profile.displayName}',
                              excludeSemantics: true,
                              child: GestureDetector(
                                onTap: _busy ? null : () => _respond(row.profile.id, false),
                                child: const Well(
                                  circle: true,
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.close_rounded, size: 18, color: AppColors.inkMuted),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ClayPill(
                              label: 'Accept',
                              kind: ClayKind.teal,
                              onPressed: _busy ? null : () => _respond(row.profile.id, true),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SectionLabel(label: 'Friends', count: '${data.accepted.length}'),
              const SizedBox(height: 12),
              if (friendCount == 0)
                Well(
                  radius: 24,
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'No friends yet. Add someone by username, scan their QR, or share your link.',
                    textAlign: TextAlign.center,
                    style: AppText.bodySmall,
                  ),
                )
              else
                ClayList(
                  dividerIndent: 76,
                  children: [
                    for (final row in data.accepted)
                      _FriendRowTile(
                        profile: row.profile,
                        subtitle: 'Lv ${row.profile.level} · @${row.profile.username}',
                        onTap: () => context.go('/social/friends/${row.profile.id}'),
                        onLongPress: _busy ? null : () => _remove(row.profile.id),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (focusing.containsKey(row.profile.id)) const _FocusingChip(),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.inkFaint),
                          ],
                        ),
                      ),
                    for (final row in data.outgoing)
                      _FriendRowTile(
                        profile: row.profile,
                        subtitle: 'Lv ${row.profile.level} · @${row.profile.username}',
                        trailing: Well(
                          radius: 16,
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Center(
                            child: Text(
                              'Requested',
                              style: AppText.title.copyWith(fontSize: 12, height: 16 / 12, color: AppColors.inkMuted),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.code,
    required this.onCopy,
    required this.onShowQr,
    required this.onUsername,
    required this.onScan,
    required this.onShare,
  });

  final String? code;
  final VoidCallback? onCopy;
  final VoidCallback? onShowQr;
  final VoidCallback? onUsername;
  final VoidCallback? onScan;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Clay(
      radius: 28,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Well(
            radius: 18,
            padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR FRIEND CODE',
                        style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1),
                      ),
                      const SizedBox(height: 2),
                      Semantics(
                        label: code == null ? 'Friend code loading' : 'Friend code ${code!.split('').join(' ')}',
                        excludeSemantics: true,
                        child: Text(
                          code ?? '········',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.numbers.copyWith(fontSize: 22, height: 28 / 22, letterSpacing: 1.8),
                        ),
                      ),
                    ],
                  ),
                ),
                ClayIconButton(icon: Icons.qr_code_2_rounded, tooltip: 'Show QR', size: 44, onPressed: onShowQr),
                const SizedBox(width: 8),
                ClayIconButton(icon: Icons.copy_rounded, tooltip: 'Copy friend code', size: 44, onPressed: onCopy),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Option(icon: Icons.alternate_email_rounded, label: 'Username', onTap: onUsername)),
              const SizedBox(width: 10),
              Expanded(child: _Option(icon: Icons.qr_code_scanner_rounded, label: 'Scan QR', onTap: onScan)),
              const SizedBox(width: 10),
              Expanded(child: _Option(icon: Icons.ios_share_rounded, label: 'Share link', onTap: onShare)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Clay(
        kind: ClayKind.control,
        radius: 20,
        height: 78,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: AppColors.tealDeep),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.title.copyWith(fontSize: 13, height: 16 / 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRowTile extends StatelessWidget {
  const _FriendRowTile({
    required this.profile,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.onLongPress,
  });

  final Profile profile;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        child: Row(
          children: [
            PortraitFrame(
              skinId: profile.equippedSkinId.replaceFirst('skin_', ''),
              backgroundId: profile.equippedBackgroundId.replaceFirst('bg_', ''),
              frameId: profile.equippedFrameId.replaceFirst('frame_', ''),
              body: profile.bodyType == 'b' ? BodyType.b : BodyType.a,
              size: PortraitFrameSize.leaderboard,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(fontSize: 15, height: 20 / 15),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _FocusingChip extends StatelessWidget {
  const _FocusingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(13)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.awakeningTeal, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'Focusing now',
            style: AppText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tealDeep),
          ),
        ],
      ),
    );
  }
}

class _ConfirmCodeDialog extends StatelessWidget {
  const _ConfirmCodeDialog({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Add friend?', textAlign: TextAlign.center, style: AppText.h2.copyWith(fontSize: 20)),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a friend request to code $code?',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(fontSize: 15, height: 22 / 15, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 22),
            QButton(label: 'Send', height: 56, onPressed: () => Navigator.pop(context, true)),
            const SizedBox(height: 12),
            QButton(
              label: 'Cancel',
              height: 56,
              variant: QButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Add by username": type a username or friend code and send the request.
class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet({required this.send});

  final Future<String?> Function(String input) send;

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _query = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.send(_query.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppSpacing.screen, 10, AppSpacing.screen, MediaQuery.paddingOf(context).bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: AppColors.handle, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text('Add by username', style: AppText.h1.copyWith(fontSize: 22, height: 28 / 22)),
                  ),
                ),
                ClayIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  size: 40,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Well(
              radius: 20,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: AppColors.inkMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      autofocus: true,
                      autocorrect: false,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: 'Username or friend code',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'Usernames look like ada_1234. Friend codes are 8 letters and numbers.',
              style: _error != null
                  ? AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500)
                  : AppText.caption.copyWith(fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            QButton(
              label: 'Send request',
              icon: Icons.person_add_alt_1_rounded,
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
