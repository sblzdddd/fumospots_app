import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/services/image_cache_service.dart';
import '../post_model.dart';

/// Full-screen photo gallery (route, not a drag sheet — so pinch/pan win).
Future<void> showPostPhotoViewer(
  BuildContext context, {
  required List<PostPhoto> photos,
  int initialIndex = 0,
  ValueChanged<int>? onIndex,
}) {
  final urls = photos
      .map((p) => p.viewerUrl)
      .whereType<String>()
      .where((u) => u.isNotEmpty)
      .toList(growable: false);
  if (urls.isEmpty) {
    return Future.value();
  }

  final start = initialIndex.clamp(0, urls.length - 1);
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (context, _, _) => PostPhotoViewer(
        urls: urls,
        initialIndex: start,
        onIndex: onIndex,
      ),
      transitionsBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

/// Owns paging, dismiss chrome, and zoom — nothing about post detail.
class PostPhotoViewer extends StatefulWidget {
  const PostPhotoViewer({
    super.key,
    required this.urls,
    required this.initialIndex,
    this.onIndex,
  });

  final List<String> urls;
  final int initialIndex;
  final ValueChanged<int>? onIndex;

  @override
  State<PostPhotoViewer> createState() => _PostPhotoViewerState();
}

class _PostPhotoViewerState extends State<PostPhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  bool _zoomed = false;

  BaseCacheManager get _cache =>
      GetIt.instance<ImageCacheService>().cacheManager;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _setIndex(int index) {
    if (_index == index) {
      return;
    }
    setState(() {
      _index = index;
      _zoomed = false;
    });
    widget.onIndex?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pages,
            physics: _zoomed
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: widget.urls.length,
            onPageChanged: _setIndex,
            itemBuilder: (context, i) => _ZoomablePhoto(
              // Remount on page change so transform resets cleanly.
              key: ValueKey(widget.urls[i]),
              url: widget.urls[i],
              cacheManager: _cache,
              onZoomed: (zoomed) {
                if (_zoomed != zoomed) {
                  setState(() => _zoomed = zoomed);
                }
              },
            ),
          ),
          Positioned(
            top: top + 8,
            right: 12,
            child: IconButton.filledTonal(
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom + 16,
              child: Text(
                '${_index + 1} / ${widget.urls.length}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({
    super.key,
    required this.url,
    required this.cacheManager,
    required this.onZoomed,
  });

  final String url;
  final BaseCacheManager cacheManager;
  final ValueChanged<bool> onZoomed;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      final animation = _animation;
      if (animation != null) {
        _transform.value = animation.value;
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _reportZoom() {
    final scale = _transform.value.getMaxScaleOnAxis();
    widget.onZoomed(scale > 1.01);
  }

  void _onInteractUpdate(ScaleUpdateDetails _) => _reportZoom();

  void _onInteractEnd(ScaleEndDetails _) => _reportZoom();

  void _onDoubleTapDown(TapDownDetails details) {
    final doubleTap = details.localPosition;
    final scale = _transform.value.getMaxScaleOnAxis();
    final end = scale > 1.01
        ? Matrix4.identity()
        : (Matrix4.identity()
          ..translateByDouble(-doubleTap.dx * 1.5, -doubleTap.dy * 1.5, 0, 1)
          ..scaleByDouble(2.5, 2.5, 1, 1));
    _animation = Matrix4Tween(begin: _transform.value, end: end).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _anim.forward(from: 0).whenComplete(_reportZoom);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _onDoubleTapDown,
      // Empty handler so the detector participates; zoom is driven by Down.
      onDoubleTap: () {},
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 4,
        // Keep pan alive at 1x so vertical drags aren't unused / ambiguous.
        panEnabled: true,
        scaleEnabled: true,
        clipBehavior: Clip.none,
        onInteractionUpdate: _onInteractUpdate,
        onInteractionEnd: _onInteractEnd,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.url,
            cacheManager: widget.cacheManager,
            fit: BoxFit.contain,
            fadeInDuration: Duration.zero,
            placeholder: (_, _) => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            errorWidget: (_, _, _) => const FaIcon(
              FontAwesomeIcons.image,
              size: 40,
              color: Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}
