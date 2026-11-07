import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_card.dart';
import '../../data/models/inbox_message.dart';
import 'inbox_copy.dart';
import 'providers/inbox_providers.dart';
import '../../core/widgets/loading_skeleton.dart';

/// Server-only events: guild fights, raid/weekly results, friend requests, boss escape.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  String _when(DateTime at) {
    final local = at.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  Future<void> _open(BuildContext context, WidgetRef ref, InboxMessage message) async {
    if (message.readAt == null) {
      await markInboxRead(ref, message.id);
    }
    if (!context.mounted) return;
    context.push(inboxRoute(message.type, message.payload));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inboxMessagesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox', style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
          if (messages.isEmpty) {
            return const EmptyState(
              title: 'Nothing new',
              body: 'Raid results, weekly recap and friend requests show up here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s8,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            itemCount: messages.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s8),
            itemBuilder: (context, index) {
              final message = messages[index];
              final unread = message.readAt == null;
              return QCard(
                onTap: () => _open(context, ref, message),
                highlighted: unread,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6, right: AppSpacing.s8),
                        decoration: const BoxDecoration(
                          color: AppColors.awakeningTeal,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inboxTitle(message.type), style: AppText.title),
                          const SizedBox(height: AppSpacing.s4),
                          Text(inboxBody(message.type, message.payload), style: AppText.bodySmall),
                          const SizedBox(height: AppSpacing.s4),
                          Text(_when(message.createdAt), style: AppText.caption.copyWith(color: AppColors.inkMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
