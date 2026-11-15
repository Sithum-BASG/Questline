import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../data/models/raid.dart';
import 'raid_links.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/clay.dart';

final raidInviteProvider = FutureProvider.autoDispose.family<Raid?, String>((ref, raidId) async {
  watchAccount(ref);
  final row = await ref.watch(supabaseClientProvider).from('raids').select().eq('id', raidId).maybeSingle();
  if (row == null) return null;
  return Raid.fromJson(Map<String, dynamic>.from(row));
});

/// Party invite: code, QR and share text.
class RaidInviteScreen extends ConsumerWidget {
  const RaidInviteScreen({super.key, required this.raidId});

  final String raidId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(raidInviteProvider(raidId));
    return Scaffold(
      appBar: ClayHeader(
        title: 'Invite',
        onBack: () => context.go('/raids/$raidId'),
      ),
      body: async.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => EmptyState(
          title: 'Could not load invite',
          body: 'Try again in a moment.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(raidInviteProvider(raidId)),
        ),
        data: (raid) {
          final code = raid?.inviteCode;
          if (raid == null || code == null || code.isEmpty) {
            return EmptyState(
              title: 'No invite code',
              body: 'Guild fights notify members in the inbox instead.',
              actionLabel: 'Open raid',
              onAction: () => context.go('/raids/$raidId'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.s8, AppSpacing.screen, AppSpacing.s32),
            children: [
              Text(raid.name, style: AppText.h1, textAlign: TextAlign.center),
              Text(raid.title, style: AppText.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s24),
              Center(
                child: Clay(
                  radius: AppRadius.stage,
                  padding: const EdgeInsets.all(20),
                  child: QrImageView(
                    data: raidInviteUri(code),
                    size: 200,
                    backgroundColor: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Well(
                radius: 22,
                padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
                child: Row(
                  children: [
                    Expanded(child: Text(code, style: AppText.h2.copyWith(fontSize: 22, letterSpacing: 4))),
                    ClayIconButton(
                      icon: Icons.copy_rounded,
                      tooltip: 'Copy',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite code copied')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              QButton(
                icon: Icons.ios_share_rounded,
                label: 'Share invite',
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: raidInviteShareText(code)),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              QButton(
                label: 'Open raid',
                variant: QButtonVariant.secondary,
                onPressed: () => context.go('/raids/$raidId'),
              ),
            ],
          );
        },
      ),
    );
  }
}
