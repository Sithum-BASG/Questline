import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/q_button.dart';
import '../../core/widgets/qr_scanner_view.dart';
import 'friend_links.dart';
import 'providers/pending_friend_code.dart';

/// Camera QR scan for a friend invite. Permission is requested by the plugin on open.
class ScanFriendScreen extends ConsumerStatefulWidget {
  const ScanFriendScreen({super.key});

  @override
  ConsumerState<ScanFriendScreen> createState() => _ScanFriendScreenState();
}

class _ScanFriendScreenState extends ConsumerState<ScanFriendScreen> {
  var _handled = false;
  String? _error;

  void _onCode(String raw) {
    if (_handled) return;
    final code = friendCodeFromScan(raw);
    if (code == null) {
      setState(() => _error = raw.startsWith('questline://raid')
          ? 'That is a party invite. Join it from Bosses.'
          : 'That QR is not a Questline friend invite.');
      return;
    }
    _handled = true;
    HapticFeedback.mediumImpact();
    ref.read(pendingFriendCodeProvider.notifier).setCode(code);
    context.go('/social/friends');
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: const ClayHeader(title: 'Scan a friend'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, bottom + 120),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SizedBox(
              height: 430,
              child: QrScannerView(onCode: _onCode, hint: "Point at the QR on your friend's screen"),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Your friend opens Friends and taps Show QR. The camera is only used while this is open.',
            textAlign: TextAlign.center,
            style: _error != null
                ? AppText.bodySmall.copyWith(color: AppColors.errorText, fontWeight: FontWeight.w500)
                : AppText.caption.copyWith(fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 20),
          QButton(
            label: 'Type the code instead',
            icon: Icons.keyboard_rounded,
            variant: QButtonVariant.secondary,
            onPressed: () => context.go('/social/friends'),
          ),
        ],
      ),
    );
  }
}
