import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/inbox_message.dart';
import 'inbox_copy.dart';
import 'providers/inbox_providers.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/clay.dart';

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
      appBar: const ClayHeader(title: 'Inbox'),
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
              icon: Icons.notifications_none_rounded,
            );
          }
          final fresh = [for (final m in messages) if (m.readAt == null) m];
          final earlier = [for (final m in messages) if (m.readAt != null) m];
          Widget row(InboxMessage message) {
            final unread = message.readAt == null;
            return Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => _open(context, ref, message),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 10,
                        child: unread
                            ? Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 16),
                                decoration: const BoxDecoration(
                                  color: AppColors.awakeningTeal,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: unread ? AppColors.tealSoft : AppColors.well,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          size: 20,
                          color: unread ? AppColors.tealDeep : AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inboxTitle(message.type), style: AppText.title.copyWith(fontSize: 15), softWrap: true),
                            const SizedBox(height: 2),
                            Text(
                              inboxBody(message.type, message.payload),
                              style: AppText.bodySmall.copyWith(fontSize: 14, height: 20 / 14, color: AppColors.ink),
                              softWrap: true,
                            ),
                            const SizedBox(height: 4),
                            Text(_when(message.createdAt), style: AppText.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.s16,
              AppSpacing.screen,
              AppSpacing.aboveTabBar,
            ),
            children: [
              if (fresh.isNotEmpty) ...[
                SectionLabel(label: 'New', count: '${fresh.length}'),
                const SizedBox(height: 14),
                ClayList(dividerIndent: 74, children: [for (final m in fresh) row(m)]),
                const SizedBox(height: 28),
              ],
              if (earlier.isNotEmpty) ...[
                const SectionLabel(label: 'Earlier', gemColor: AppColors.inkFaint),
                const SizedBox(height: 14),
                ClayList(dividerIndent: 74, children: [for (final m in earlier) row(m)]),
              ],
            ],
          );
        },
      ),
    );
  }
}
