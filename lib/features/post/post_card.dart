import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n/i18n.dart';
import '../../core/services/image_cache_service.dart';
import '../../core/services/image_ratio.dart';
import 'post_model.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onPress,
    this.badge,
    this.onEdit,
  });

  final PostListItem post;
  final VoidCallback onPress;
  final Widget? badge;
  final VoidCallback? onEdit;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final ImageCacheService _images = GetIt.instance<ImageCacheService>();

  late double _aspect;
  bool _loaded = false;
  bool _failed = false;
  ImageRatioResolver? _resolver;

  @override
  void initState() {
    super.initState();
    _bindAspect();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.thumbUrl != widget.post.thumbUrl) {
      _failed = false;
      _bindAspect();
    }
  }

  void _bindAspect() {
    final url = widget.post.thumbUrl;
    _aspect = _images.aspectOf(
      postId: widget.post.id,
      url: url,
      fallback: estimateAspect(widget.post.id),
    );
    _loaded = _images.hasAspect(postId: widget.post.id, url: url);
    _listenForSize(url);
  }

  @override
  void dispose() {
    _resolver?.dispose();
    super.dispose();
  }

  void _listenForSize(String? url) {
    _resolver?.dispose();
    _resolver = null;
    if (url == null) {
      return;
    }

    _resolver = _images.resolveAspect(
      url: url,
      postId: widget.post.id,
      onRatio: (ratio) {
        if (!mounted || (_aspect == ratio && _loaded)) {
          return;
        }
        setState(() {
          _aspect = ratio;
          _loaded = true;
        });
      },
      onError: () {
        if (mounted && !_failed) {
          setState(() => _failed = true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showImage = widget.post.thumbUrl != null && !_failed;
    final onEdit = widget.onEdit;

    return Stack(
      children: [
        M3ESegmentedItem(
          index: 0,
          position: M3ESegmentedItemPosition.single,
          outerRadius: 16,
          innerRadius: 16,
          gap: 0,
          color: colors.surfaceContainerHigh,
          padding: EdgeInsets.zero,
          pressedScale: 0.97,
          pressedRadius: 12,
          splashFactory: InkSparkle.splashFactory,
          onTap: (_) => widget.onPress(),
          semanticLabel: widget.post.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1 / _aspect,
                child: ColoredBox(
                  color: colors.outlineVariant,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (showImage)
                        CachedNetworkImage(
                          imageUrl: widget.post.thumbUrl!,
                          cacheManager: _images.cacheManager,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (_, _) => const SizedBox.shrink(),
                          errorWidget: (_, _, _) => Center(
                            child: FaIcon(
                              FontAwesomeIcons.image,
                              size: 22,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (!showImage)
                        Center(
                          child: FaIcon(
                            FontAwesomeIcons.image,
                            size: 22,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      if (widget.badge != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          right: onEdit != null ? 44 : 8,
                          child: widget.badge!,
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Text(
                  widget.post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  widget.post.placeName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: colors.surface.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onEdit,
                customBorder: const CircleBorder(),
                child: Tooltip(
                  message: 'Edit post',
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.penToSquare,
                        size: 13,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact status chip for overlaying on [PostCard] thumbnails.
class PostStatusBadge extends StatelessWidget {
  const PostStatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            context.t(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
