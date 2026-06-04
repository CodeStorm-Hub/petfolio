import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const int webNetworkImageMemCacheMax = 1080;
const int webNetworkImageMemCacheFeed = 640;
const int webNetworkImageMemCacheThumb = 256;
const int webNetworkImageMemCacheAvatar = 160;

int? networkImageMemCacheWidth(
  BuildContext context,
  double logicalWidth, {
  int? maxPixels,
}) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  var pixels = (logicalWidth * dpr).round();
  if (pixels <= 0) return null;
  if (kIsWeb) {
    final cap = maxPixels ?? webNetworkImageMemCacheMax;
    pixels = pixels.clamp(1, cap);
  }
  return pixels;
}

int? networkImageMaxDiskCacheWidth(
  BuildContext context,
  double logicalWidth, {
  int? maxPixels,
}) {
  final mem = networkImageMemCacheWidth(
    context,
    logicalWidth,
    maxPixels: maxPixels,
  );
  if (mem == null) return null;
  return (mem * 1.25).round();
}
