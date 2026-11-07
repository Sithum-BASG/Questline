import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/game_assets.dart';
import '../../core/supabase/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import 'providers/friends_providers.dart';

/// Friends list, incoming requests, and add by username or friend code.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _query = TextEditingController();
  var _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final raw = _query.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Enter a username or friend code.');
      return;
    }
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
      _query.clear();
      ref.invalidate(friendshipsProvider);
      ref.invalidate(friendRowsProvider);
      if (mounted) setState(() => _info = 'Request sent.');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not send the request.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    final async = ref.watch(friendRowsProvider);
    final myCode = ref.watch(myFriendCodeProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: Text('Friends', style: AppText.h2)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load friends',
          body: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: () => ref.invalidate(friendRowsProvider),
        ),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s8,
              AppSpacing.screen,
              100,
            ),
            children: [
              if (myCode != null) ...[
                QCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your friend code', style: AppText.h2),
                            const SizedBox(height: AppSpacing.s4),
                            Text(myCode, style: AppText.body),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: myCode));
                          if (mounted) setState(() => _info = 'Code copied.');
                        },
                        icon: const Icon(Icons.copy_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
              ],
              Text('Add a friend', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              TextField(
                controller: _query,
                decoration: const InputDecoration(
                  labelText: 'Username or friend code',
                ),
                style: AppText.body,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _busy ? null : _send(),
              ),
              const SizedBox(height: AppSpacing.s12),
              QButton(
                label: _busy ? 'Sending…' : 'Send request',
                onPressed: _busy ? null : _send,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(_error!, style: AppText.bodySmall.copyWith(color: AppColors.error)),
              ],
              if (_info != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(_info!, style: AppText.bodySmall),
              ],
              if (data.incoming.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s24),
                Text('Requests', style: AppText.h2),
                const SizedBox(height: AppSpacing.s8),
                for (final row in data.incoming) ...[
                  QCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.profile.displayName, style: AppText.h2),
                        Text('@${row.profile.username}', style: AppText.bodySmall),
                        const SizedBox(height: AppSpacing.s12),
                        Row(
                          children: [
                            Expanded(
                              child: QButton(
                                label: 'Accept',
                                onPressed: _busy ? null : () => _respond(row.profile.id, true),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            Expanded(
                              child: QButton(
                                label: 'Decline',
                                variant: QButtonVariant.secondary,
                                onPressed: _busy ? null : () => _respond(row.profile.id, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
              ],
              const SizedBox(height: AppSpacing.s24),
              Text('Friends', style: AppText.h2),
              const SizedBox(height: AppSpacing.s8),
              if (data.accepted.isEmpty && data.outgoing.isEmpty)
                EmptyState(
                  title: 'No friends yet',
                  body: 'Add someone by username or friend code.',
                )
              else ...[
                for (final row in data.accepted) ...[
                  GestureDetector(
                    onTap: () => context.go('/social/friends/${row.profile.id}'),
                    onLongPress: _busy ? null : () => _remove(row.profile.id),
                    child: MemberCard(
                      name: row.profile.displayName,
                      title: 'Level ${row.profile.level}',
                      skinId: row.profile.equippedSkinId,
                      backgroundId: row.profile.equippedBackgroundId,
                      body: row.profile.bodyType == 'b' ? BodyType.b : BodyType.a,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
                for (final row in data.outgoing) ...[
                  QCard(
                    child: Text(
                      'Pending · ${row.profile.displayName}',
                      style: AppText.body,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
