import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'post_model.dart';

const _estimatedAspects = [0.75, 1.0, 1.25, 1.5];

double _estimateAspect(int id) {
  return _estimatedAspects[id.abs() % _estimatedAspects.length];
}

double _clampAspect(double aspect) {
  if (!aspect.isFinite || aspect <= 0) {
    return 1;
  }
  return aspect.clamp(0.7, 1.6);
}

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post, required this.onPress});

  final PostListItem post;
  final VoidCallback onPress;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late double _aspect = _estimateAspect(widget.post.id);
  bool _loaded = false;
  bool _failed = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _listenForSize(widget.post.thumbUrl);
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.thumbUrl != widget.post.thumbUrl) {
      _aspect = _estimateAspect(widget.post.id);
      _loaded = false;
      _failed = false;
      _listenForSize(widget.post.thumbUrl);
    }
  }

  @override
  void dispose() {
    _clearListener();
    super.dispose();
  }

  void _listenForSize(String? url) {
    _clearListener();
    if (url == null) {
      return;
    }
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (info, _) {
        final width = info.image.width.toDouble();
        final height = info.image.height.toDouble();
        if (width > 0 && height > 0 && mounted) {
          setState(() => _aspect = _clampAspect(height / width));
        }
      },
      onError: (_, _) {},
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _clearListener() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showImage = widget.post.thumbUrl != null && !_failed;

    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onPress,
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
                      Image.network(
                        widget.post.thumbUrl!,
                        fit: BoxFit.cover,
                        opacity: AlwaysStoppedAnimation(_loaded ? 1 : 0),
                        errorBuilder: (_, _, _) {
                          if (!_failed) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _failed = true);
                              }
                            });
                          }
                          return const SizedBox.shrink();
                        },
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (!_loaded &&
                                  (frame != null || wasSynchronouslyLoaded)) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    setState(() => _loaded = true);
                                  }
                                });
                              }
                              return child;
                            },
                      ),
                    if (!_loaded || !showImage)
                      Center(
                        child: _failed || widget.post.thumbUrl == null
                            ? FaIcon(
                                FontAwesomeIcons.image,
                                size: 22,
                                color: colors.onSurfaceVariant,
                              )
                            : const SizedBox.shrink(),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
