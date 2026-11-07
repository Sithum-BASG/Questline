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
import '../../core/widgets/q_card.dart';
import '../../data/models/raid.dart';
import 'raid_links.dart';
import '../../core/widgets/loading_skeleton.dart';

final raidInviteProvider = FutureProvider.autoDispose.family<Raid?, String>((ref, raidId) async {
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
      appBar: AppBar(
        title: Text('Invite', style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/raids/$raidId'),
        ),
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
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Text(raid.name, style: AppText.h1),
              Text(raid.title, style: AppText.bodySmall),
              const SizedBox(height: AppSpacing.s24),
              Center(
                child: QrImageView(
                  data: raidInviteUri(code),
                  size: 200,
                  backgroundColor: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              QCard(
                child: Row(
                  children: [
                    Expanded(child: Text(code, style: AppText.h2)),
                    IconButton(
                      tooltip: 'Copy',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite code copied')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              QButton(
                label: 'Share invite',
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: raidInviteShareText(code)),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
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
