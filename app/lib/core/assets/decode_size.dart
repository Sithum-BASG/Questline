import 'package:flutter/widgets.dart';

/// Pixel width to decode game art at when it is drawn [logicalWidth] wide.
///
/// Skins and backgrounds are 1024 x 1536 and bosses and gear 1024 x 1024. Decoding them at full size
/// for a 48 px portrait costs about 6 MB each and churns the image cache on lists of friends, so
/// small art is decoded at the size it is shown (times the screen's pixel ratio).
int decodeWidth(BuildContext context, double logicalWidth) {
  final pixels = (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
  return pixels.clamp(1, 2048);
}
