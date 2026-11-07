import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/q_card.dart';
import 'providers/feed_providers.dart';

/// Paginated friends activity feed (`activity_events` via `visible_to` RLS).
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  var _pages = 1;

  String _when(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (var i = 0; i < _pages; i++) ref.watch(feedPageProvider(i)),
    ];
    final loadingFirst = pages.first.isLoading && !pages.first.hasValue;
    final firstError = pages.first.asError?.error;

    final items = [
      for (final page in pages)
        ...?(page.asData?.value.items),
    ];
    final lastHasMore = pages.last.asData?.value.hasMore ?? false;
    final loadingMore = pages.last.isLoading && pages.last.hasValue == false && _pages > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Feed', style: AppText.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/social'),
        ),
      ),
      body: loadingFirst
          ? const Center(child: CircularProgressIndicator())
          : firstError != null
              ? EmptyState(
                  title: 'Could not load feed',
                  body: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: () {
                    for (var i = 0; i < _pages; i++) {
                      ref.invalidate(feedPageProvider(i));
                    }
                  },
                )
              : items.isEmpty
                  ? const EmptyState(
                      title: 'Quiet for now',
                      body: 'When friends level up or beat bosses, it shows here',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.s8,
                        AppSpacing.screen,
                        AppSpacing.aboveTabBar,
                      ),
                      itemCount: items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          if (!lastHasMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                              child: Text('You are caught up', style: AppText.caption, textAlign: TextAlign.center),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                            child: Center(
                              child: loadingMore
                                  ? const CircularProgressIndicator()
                                  : QButton(
                                      label: 'Load more',
                                      variant: QButtonVariant.secondary,
                                      onPressed: () => setState(() => _pages += 1),
                                    ),
                            ),
                          );
                        }
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                          child: QCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.line, style: AppText.body),
                                const SizedBox(height: AppSpacing.s4),
                                Text(_when(item.event.createdAt), style: AppText.caption),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
