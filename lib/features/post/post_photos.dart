import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/image_cache_service.dart';
import '../../core/services/image_ratio.dart';
import 'post_model.dart';

/// Blurred thumb hero shown while post detail is still loading.
/// Sole [ImageFiltered] blur in the photo hero flow.
class PostLoadingThumbHero extends StatelessWidget {
  const PostLoadingThumbHero({
    super.key,
    required this.thumbUrl,
    required this.maxHeight,
    this.postId,
  });

  final String thumbUrl;
  final double maxHeight;
  final int? postId;

  @override
  Widget build(BuildContext context) {
    final images = GetIt.instance<ImageCacheService>();
    final ratio = images.aspectOf(postId: postId, url: thumbUrl);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = heightForRatio(
          width: width,
          ratio: ratio,
          maxHeight: maxHeight,
        );
        return SizedBox(
          height: height,
          width: width,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.outlineVariant,
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: CachedNetworkImage(
                  imageUrl: thumbUrl,
                  cacheManager: images.cacheManager,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, _) => const SizedBox.shrink(),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PostPhotos extends StatefulWidget {
  const PostPhotos({
    super.key,
    required this.photos,
    required this.maxHeight,
    required this.index,
    required this.onIndex,
    this.postId,
  });

  final List<PostPhoto> photos;
  final double maxHeight;
  final int index;
  final ValueChanged<int> onIndex;

  /// When set, reuses the feed thumbnail aspect for the default hero size.
  final int? postId;

  @override
  State<PostPhotos> createState() => _PostPhotosState();
}

class _PostPhotosState extends State<PostPhotos> {
  final ImageCacheService _images = GetIt.instance<ImageCacheService>();
  late final PageController _pageController = PageController(
    initialPage: widget.index,
  );

  late double _thumbRatio;
  ImageRatioResolver? _resolver;

  String? get _thumbUri {
    if (widget.photos.isEmpty) {
      return null;
    }
    final first = widget.photos.first;
    return first.thumbUrl ?? first.imageUrl;
  }

  @override
  void initState() {
    super.initState();
    _bindThumbRatio();
  }

  @override
  void didUpdateWidget(covariant PostPhotos oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldThumb = oldWidget.photos.isEmpty
        ? null
        : (oldWidget.photos.first.thumbUrl ?? oldWidget.photos.first.imageUrl);
    if (oldWidget.postId != widget.postId || oldThumb != _thumbUri) {
      _bindThumbRatio();
    }
    if (oldWidget.index != widget.index &&
        _pageController.hasClients &&
        _pageController.page?.round() != widget.index) {
      _pageController.jumpToPage(widget.index);
    }
  }

  @override
  void dispose() {
    _resolver?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _bindThumbRatio() {
    _resolver?.dispose();
    _resolver = null;

    final uri = _thumbUri;
    _thumbRatio = _images.aspectOf(postId: widget.postId, url: uri);
    _resolver = uri == null
        ? null
        : _images.resolveAspect(
            url: uri,
            postId: widget.postId,
            onRatio: (ratio) {
              if (mounted && _thumbRatio != ratio) {
                setState(() => _thumbRatio = ratio);
              }
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = heightForRatio(
          width: width,
          ratio: _thumbRatio,
          maxHeight: widget.maxHeight,
        );

        return SizedBox(
          height: height,
          width: width,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.outlineVariant,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.photos.length,
                    onPageChanged: widget.onIndex,
                    itemBuilder: (context, photoIndex) {
                      final photo = widget.photos[photoIndex];
                      final uri = photo.viewerUrl;
                      if (uri == null) {
                        return Center(
                          child: FaIcon(
                            FontAwesomeIcons.image,
                            size: 28,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        );
                      }
                      return _PhotoPane(
                        imageUrl: uri,
                        thumbUrl: photo.thumbUrl,
                        cacheManager: _images.cacheManager,
                      );
                    },
                  ),
                  if (widget.photos.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.photos.length, (
                          dotIndex,
                        ) {
                          final active = dotIndex == widget.index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            width: active ? 16 : 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full image with an optional sharp cached thumb underneath while it loads.
class _PhotoPane extends StatefulWidget {
  const _PhotoPane({
    required this.imageUrl,
    required this.thumbUrl,
    required this.cacheManager,
  });

  final String imageUrl;
  final String? thumbUrl;
  final BaseCacheManager cacheManager;

  @override
  State<_PhotoPane> createState() => _PhotoPaneState();
}

class _PhotoPaneState extends State<_PhotoPane> {
  bool _showThumb = false;
  bool _fullLoaded = false;

  String? get _previewThumbUrl {
    final thumb = widget.thumbUrl;
    if (thumb == null || thumb.isEmpty || thumb == widget.imageUrl) {
      return null;
    }
    return thumb;
  }

  @override
  void initState() {
    super.initState();
    _resolveCachedThumb();
  }

  @override
  void didUpdateWidget(covariant _PhotoPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.thumbUrl != widget.thumbUrl) {
      _fullLoaded = false;
      _showThumb = false;
      _resolveCachedThumb();
    }
  }

  Future<void> _resolveCachedThumb() async {
    final thumb = _previewThumbUrl;
    if (thumb == null) {
      return;
    }

    final provider = CachedNetworkImageProvider(
      thumb,
      cacheManager: widget.cacheManager,
    );
    if (PaintingBinding.instance.imageCache.containsKey(provider)) {
      if (mounted) {
        setState(() => _showThumb = true);
      }
      return;
    }

    final file = await widget.cacheManager.getFileFromCache(thumb);
    if (file != null && mounted) {
      setState(() => _showThumb = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _previewThumbUrl;
    final showThumb = _showThumb && !_fullLoaded && thumb != null;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        if (showThumb)
          CachedNetworkImage(
            imageUrl: thumb,
            cacheManager: widget.cacheManager,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, _) => const SizedBox.shrink(),
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
        CachedNetworkImage(
          imageUrl: widget.imageUrl,
          cacheManager: widget.cacheManager,
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 160),
          placeholder: (_, _) => const SizedBox.shrink(),
          imageBuilder: (context, imageProvider) {
            return Image(
              image: imageProvider,
              fit: BoxFit.contain,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if ((wasSynchronouslyLoaded || frame != null) &&
                    !_fullLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_fullLoaded) {
                      setState(() => _fullLoaded = true);
                    }
                  });
                }
                return child;
              },
            );
          },
          errorWidget: (_, _, _) => Center(
            child: FaIcon(
              FontAwesomeIcons.image,
              size: 28,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
