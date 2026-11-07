import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../raids/raid_links.dart';
import 'friend_links.dart';
import 'providers/pending_friend_code.dart';

/// Listens for friend and raid deep links.
class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> {
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    final links = AppLinks();
    links.getInitialLink().then(_handle);
    _sub = links.uriLinkStream.listen(_handle);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handle(Uri? uri) {
    if (uri == null) return;
    final raidCode = raidCodeFromUri(uri);
    if (raidCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        GoRouter.maybeOf(context)?.go('/raids/join?code=$raidCode');
      });
      return;
    }
    final code = friendCodeFromUri(uri);
    if (code == null) return;
    ref.read(pendingFriendCodeProvider.notifier).setCode(code);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GoRouter.maybeOf(context)?.go('/social/friends');
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
