import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/clay.dart';
import '../../core/widgets/q_button.dart';
import 'friend_links.dart';

/// Opens your friend QR as a sheet. Friends scan it from their Friends screen.
Future<void> showFriendQrSheet(BuildContext context, String code) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
    builder: (context) => FriendQrSheet(code: code),
  );
}

class FriendQrSheet extends StatefulWidget {
  const FriendQrSheet({super.key, required this.code});

  final String code;

  @override
  State<FriendQrSheet> createState() => _FriendQrSheetState();
}

class _FriendQrSheetState extends State<FriendQrSheet> {
  var _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.code;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: 'Your friend QR',
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          10,
          AppSpacing.screen,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: AppColors.handle, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text('Your friend QR', style: AppText.h1.copyWith(fontSize: 22, height: 28 / 22)),
                  ),
                ),
                ClayIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  size: 40,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Clay(
                radius: 30,
                width: 220,
                height: 220,
                child: Center(
                  child: Container(
                    width: 176,
                    height: 176,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Semantics(
                      image: true,
                      label: 'QR code for friend code $code',
                      excludeSemantics: true,
                      child: QrImageView(
                        data: friendInviteUri(code),
                        size: 156,
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.ink),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Well(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Text(
                    'YOUR FRIEND CODE',
                    style: AppText.label.copyWith(fontSize: 10, height: 12 / 10, letterSpacing: 1),
                  ),
                  const SizedBox(height: 2),
                  Semantics(
                    label: 'Friend code ${code.split('').join(' ')}',
                    excludeSemantics: true,
                    child: Text(
                      code,
                      style: AppText.numbers.copyWith(fontSize: 22, height: 28 / 22, letterSpacing: 1.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Friends scan this from Friends › Scan QR. A Questline account is needed.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: QButton(
                    label: _copied ? 'Copied' : 'Copy',
                    icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                    variant: QButtonVariant.secondary,
                    height: 58,
                    onPressed: _copy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 7,
                  child: QButton(
                    label: 'Share link',
                    icon: Icons.ios_share_rounded,
                    height: 58,
                    onPressed: () => SharePlus.instance.share(ShareParams(text: friendInviteShareText(code))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
