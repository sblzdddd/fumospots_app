import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'post_detail_body.dart';
import 'post_detail_controller.dart';
import 'post_format.dart';
import 'post_model.dart';
import 'post_photos.dart';

Future<void> showPostDetailSheet(BuildContext context, int postId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => PostDetailSheet(postId: postId),
  );
}

class PostDetailSheet extends StatefulWidget {
  const PostDetailSheet({super.key, required this.postId});

  final int postId;

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
    final sheetHeight = (media.size.height - media.padding.top - 28).clamp(
      320.0,
      media.size.height,
    );
    final List<PostPhoto> photos = _controller.detail == null
        ? const []
        : displayPhotos(_controller.detail!);
    final photoIndex = photos.isEmpty
        ? 0
        : _controller.photoIndex.clamp(0, photos.length - 1);
    final heroHeight = media.size.height * 0.5;

    return SizedBox(
      height: sheetHeight,
      child: ListView(
        children: [
          if (_controller.loading) const _DetailSkeleton(),
          if (photos.isNotEmpty && !_controller.loading)
            PostPhotos(
              photos: photos,
              height: heroHeight,
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
            ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
