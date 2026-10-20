import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/reward_overlay.dart';

/// Plays the next reward from the queue, then returns home when the queue is empty.
class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key});

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen> {
  @override
  void initState() {
    super.initState();
    final queue = ref.read(rewardQueueProvider);
    queue.addListener(_onQueue);
    if (queue.current == null) queue.next();
  }

  @override
  void dispose() {
    ref.read(rewardQueueProvider).removeListener(_onQueue);
    super.dispose();
  }

  void _onQueue() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(rewardQueueProvider);
    final moment = queue.current;
    if (moment == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const SizedBox.shrink();
    }
    return RewardOverlay(
      key: ValueKey('${moment.kind}-${moment.title}-${queue.pending.length}'),
      moment: moment,
      onClaim: () {
        queue.claim();
        if (queue.current == null && queue.pending.isEmpty && context.mounted) {
          context.go('/home');
        }
      },
    );
  }
}
