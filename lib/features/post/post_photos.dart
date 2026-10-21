import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'post_model.dart';

class PostPhotos extends StatefulWidget {
  const PostPhotos({
    super.key,
    required this.photos,
    required this.height,
    required this.index,
    required this.onIndex,
  });

  final List<PostPhoto> photos;
  final double height;
  final int index;
  final ValueChanged<int> onIndex;

  @override
  State<PostPhotos> createState() => _PostPhotosState();
}

class _PostPhotosState extends State<PostPhotos> {
  late final PageController _pageController = PageController(
    initialPage: widget.index,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: widget.onIndex,
            itemBuilder: (context, photoIndex) {
              final uri = widget.photos[photoIndex].viewerUrl;
              return ColoredBox(
                color: Theme.of(context).colorScheme.outlineVariant,
                child: uri == null
                    ? Center(
                        child: FaIcon(
                          FontAwesomeIcons.image,
                          size: 28,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Image.network(
                        uri,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Center(
                          child: FaIcon(
                            FontAwesomeIcons.image,
                            size: 28,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
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
                children: List.generate(widget.photos.length, (dotIndex) {
                  final active = dotIndex == widget.index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: active ? 16 : 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
