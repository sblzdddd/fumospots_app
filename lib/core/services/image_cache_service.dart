import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'image_ratio.dart';

/// Disk image cache + in-memory aspect ratios keyed by post id / url.
class ImageCacheService {
  ImageCacheService({BaseCacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  final BaseCacheManager _cacheManager;
  final Map<int, double> _aspectByPostId = {};
  final Map<String, double> _aspectByUrl = {};

  BaseCacheManager get cacheManager => _cacheManager;

  double? aspectForPost(int postId) => _aspectByPostId[postId];

  double? aspectForUrl(String url) => _aspectByUrl[url];

  /// Prefer post id cache, then url cache, then [fallback].
  double aspectOf({int? postId, String? url, double fallback = 1}) {
    if (postId != null) {
      final cached = _aspectByPostId[postId];
      if (cached != null) {
        return cached;
      }
    }
    if (url != null) {
      return _aspectByUrl[url] ?? fallback;
    }
    return fallback;
  }

  bool hasAspect({int? postId, String? url}) {
    if (postId != null && _aspectByPostId.containsKey(postId)) {
      return true;
    }
    if (url != null && _aspectByUrl.containsKey(url)) {
      return true;
    }
    return false;
  }

  void rememberPostAspect(int postId, double aspect) {
    _aspectByPostId[postId] = clampAspect(aspect);
  }

  void rememberUrlAspect(String url, double aspect) {
    _aspectByUrl[url] = clampAspect(aspect);
  }

  /// Loads ratio for [url] if not already cached. Returns null when skipped.
  ImageRatioResolver? resolveAspect({
    required String url,
    int? postId,
    required ValueChanged<double> onRatio,
    VoidCallback? onError,
  }) {
    if (hasAspect(postId: postId, url: url)) {
      return null;
    }

    return ImageRatioResolver(
      provider: CachedNetworkImageProvider(url, cacheManager: _cacheManager),
      onRatio: (ratio) {
        rememberUrlAspect(url, ratio);
        if (postId != null) {
          rememberPostAspect(postId, ratio);
        }
        onRatio(ratio);
      },
      onError: onError,
    );
  }

  Future<void> clear() async {
    _aspectByPostId.clear();
    _aspectByUrl.clear();
    await _cacheManager.emptyCache();
    final memory = PaintingBinding.instance.imageCache;
    memory.clear();
    memory.clearLiveImages();
  }
}
