import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Camera QR scanner on the dark scan scene with teal corner brackets.
///
/// Reads QR codes only and reports each new value once. Camera problems (permission
/// denied, no camera) show a message on the scene instead of a black box.
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key, required this.onCode, this.hint});

  /// Raw text of a scanned QR.
  final ValueChanged<String> onCode;

  /// Line shown near the bottom of the scene.
  final String? hint;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        widget.onCode(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [AppColors.scanTop, AppColors.scanDeep], radius: 0.9),
          ),
        ),
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          placeholderBuilder: (context) => const SizedBox.shrink(),
          errorBuilder: (context, error) => _CameraProblem(error: error),
        ),
        const IgnorePointer(child: CustomPaint(painter: ScanFramePainter())),
        if (widget.hint != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 26,
            child: Text(
              widget.hint!,
              textAlign: TextAlign.center,
              style: AppText.title.copyWith(fontSize: 14, color: AppColors.white),
            ),
          ),
      ],
    );
  }
}

class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => (
          'Camera access is off',
          'Allow camera access for Questline in your phone settings, then open this again.',
        ),
      MobileScannerErrorCode.unsupported => (
          'No camera found',
          'This device can’t scan. Type the code instead.',
        ),
      _ => ('The camera didn’t start', 'Close this and try again, or type the code instead.'),
    };
    return ColoredBox(
      color: AppColors.scanDeep,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded, size: 36, color: AppColors.tealLight),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: AppText.h2.copyWith(color: AppColors.white)),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppText.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Teal corner brackets and a glowing scan line over the camera.
class ScanFramePainter extends CustomPainter {
  const ScanFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width * 0.62;
    final rect = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.45), width: side, height: side);
    final paint = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const arm = 34.0;
    for (final (corner, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner + Offset(arm * dx, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, arm * dy), paint);
    }
    final y = rect.center.dy;
    final glow = Paint()
      ..shader = LinearGradient(colors: [
        AppColors.teal.withValues(alpha: 0),
        AppColors.tealLight,
        AppColors.teal.withValues(alpha: 0),
      ]).createShader(Rect.fromLTWH(rect.left, y - 2, rect.width, 4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRect(Rect.fromLTWH(rect.left + 8, y - 1.5, rect.width - 16, 3), glow);
  }

  @override
  bool shouldRepaint(ScanFramePainter old) => false;
}
