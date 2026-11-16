import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/reward_overlay.dart';
import '../onboarding/onboarding_flags.dart';

/// Plays the next reward from the queue, then Home — or the free chest in onboarding.
class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key});

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen> {
  // Kept so dispose can unsubscribe without touching ref after the widget unmounts.
  late final RewardQueue _queue;

  /// Moments already claimed on this screen, for the queue dots.
  var _played = 0;

  @override
  void initState() {
    super.initState();
    _queue = ref.read(rewardQueueProvider);
    _queue.addListener(_onQueue);
    if (_queue.current == null) _queue.next();
  }

  @override
  void dispose() {
    _queue.removeListener(_onQueue);
    super.dispose();
  }

  void _onQueue() {
    if (mounted) setState(() {});
  }

  void _finish() {
    final next = ref.read(pendingOnboardingChestProvider) ? '/onboarding/chest' : '/home';
    if (context.mounted) context.go(next);
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(rewardQueueProvider);
    final moment = queue.current;
    if (moment == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _finish();
      });
      return const SizedBox.shrink();
    }
    return RewardOverlay(
      key: ValueKey('${moment.kind}-${moment.title}-${queue.pending.length}'),
      moment: moment,
      position: _played + 1,
      count: _played + 1 + queue.pending.length,
      onClaim: () {
        _played += 1;
        queue.claim();
        if (queue.current == null && queue.pending.isEmpty && context.mounted) {
          _finish();
        }
      },
    );
  }
}
