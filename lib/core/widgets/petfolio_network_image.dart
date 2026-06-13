import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PetfolioNetworkImage extends StatelessWidget {
  const PetfolioNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fit,
    required this.errorFallback,
    this.semanticLabel,
    this.memCacheWidth,
    this.maxWidthDiskCache,
    this.cacheManager,
    this.placeholder,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget errorFallback;
  final String? semanticLabel;
  final int? memCacheWidth;
  final int? maxWidthDiskCache;
  final CacheManager? cacheManager;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      memCacheWidth: memCacheWidth,
      maxWidthDiskCache: maxWidthDiskCache,
      cacheManager: cacheManager,
      placeholder: placeholder != null ? (_, _) => placeholder! : null,
      errorWidget: (_, url, _) {
        unawaited(_evictStaleCache(url, cacheManager));
        return errorFallback;
      },
    );

    if (semanticLabel == null) return image;
    return Semantics(label: semanticLabel, image: true, child: image);
  }
}

Future<void> _evictStaleCache(String url, CacheManager? cacheManager) async {
  try {
    await (cacheManager ?? DefaultCacheManager()).removeFile(url);
  } catch (_) {}
}
