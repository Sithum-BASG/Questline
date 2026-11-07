import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
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

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      final uri = Uri.tryParse(raw);
      final code = uri != null ? friendCodeFromUri(uri) : null;
      final fallback = RegExp(r'^[A-Za-z0-9]{8}$').hasMatch(raw) ? raw.toUpperCase() : null;
      final resolved = code ?? fallback;
      if (resolved == null) {
        setState(() => _error = 'That QR is not a Questline friend invite.');
        continue;
      }
      _handled = true;
      ref.read(pendingFriendCodeProvider.notifier).setCode(resolved);
      context.go('/social/friends');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan friend code', style: AppText.h2)),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(onDetect: _onDetect),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Text(
              _error ?? 'Point the camera at a Questline friend QR.',
              style: _error != null
                  ? AppText.bodySmall.copyWith(color: AppColors.error)
                  : AppText.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
