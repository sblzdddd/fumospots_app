import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../../map/preview/map_preview_controller.dart';
import '../feed/post_feed_controller.dart';
import '../post_format.dart';
import '../post_model.dart';
import '../post_photos.dart';
import 'post_detail_body.dart';
import 'post_detail_controller.dart';

/// Fraction of the safe area the post sheet covers when it first opens.
const postDetailSheetInitialSize = 0.75;

Future<void> showPostDetailSheet(BuildContext context, int postId) {
  final previewThumbUrl = resolvePostPreviewThumb(postId);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: postDetailSheetInitialSize,
        minChildSize: 0.6,
        maxChildSize: 0.92,
        shouldCloseOnMinExtent: true,
        builder: (context, scrollController) {
          return M3EBottomSheet(
            showDragHandle: true,
            padding: EdgeInsets.zero,
            child: PostDetailSheet(
              postId: postId,
              previewThumbUrl: previewThumbUrl,
              scrollController: scrollController,
            ),
          );
        },
      );
    },
  );
}

/// Thumb URL known before detail fetch (feed card or map preview cache).
String? resolvePostPreviewThumb(int postId) {
  final feed = GetIt.instance<PostFeedController>();
  for (final post in feed.posts) {
    if (post.id == postId &&
        post.thumbUrl != null &&
        post.thumbUrl!.isNotEmpty) {
      return post.thumbUrl;
    }
  }
  final mapThumb =
      GetIt.instance<MapPreviewController>().peek(postId)?.thumbUrl;
  if (mapThumb != null && mapThumb.isNotEmpty) {
    return mapThumb;
  }
  return null;
}

class PostDetailSheet extends StatefulWidget {
  const PostDetailSheet({
    super.key,
    required this.postId,
    this.previewThumbUrl,
    this.scrollController,
  });

  final int postId;
  final String? previewThumbUrl;
  final ScrollController? scrollController;

  @override
  State<PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<PostDetailSheet> {
  late final PostDetailController _controller =
      GetIt.instance<PostDetailController>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.open(widget.postId);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final List<PostPhoto> photos = _controller.detail == null
        ? const []
        : displayPhotos(_controller.detail!);
    final photoIndex = photos.isEmpty
        ? 0
        : _controller.photoIndex.clamp(0, photos.length - 1);
    final maxHeroHeight = media.size.height * 0.45;
    final previewThumb = widget.previewThumbUrl;
    final showLoadingHero =
        _controller.loading && previewThumb != null && photos.isEmpty;

    // Same list content as before — only the controller is wired so the sheet
    // can take over the drag when the list is at the top.
    return ListView(
      controller: widget.scrollController,
      children: [
        if (showLoadingHero)
          PostLoadingThumbHero(
            postId: widget.postId,
            thumbUrl: previewThumb,
            maxHeight: maxHeroHeight,
          ),
        if (_controller.loading)
          _DetailSkeleton(includePhotoPlaceholder: !showLoadingHero),
        if (photos.isNotEmpty && !_controller.loading)
          PostPhotos(
            postId: widget.postId,
            photos: photos,
            maxHeight: maxHeroHeight,
            index: photoIndex,
            onIndex: _controller.setPhotoIndex,
          ),
        if (_controller.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: Column(
              children: [
                Text(
                  'Post unavailable',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _controller.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        if (_controller.detail != null)
          PostDetailBody(
            detail: _controller.detail!,
            locale: deviceLocale(),
            liking: _controller.liking,
            onLike: _onLikePressed,
          ),
        const SizedBox(height: 48),
      ],
    );
  }

  Future<void> _onLikePressed() async {
    final message = await _controller.toggleLike();
    if (!mounted || message == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({this.includePhotoPlaceholder = true});

  final bool includePhotoPlaceholder;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (includePhotoPlaceholder)
          Container(height: 288, width: double.infinity, color: color),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 28,
                width: 220,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 140,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 180,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
