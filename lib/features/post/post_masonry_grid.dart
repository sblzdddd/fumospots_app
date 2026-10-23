import 'package:flutter_staggered_grid/flutter_staggered_grid.dart';
import 'package:material_ui/material_ui.dart';

import 'feed/post_feed_skeleton_card.dart';

typedef PostMasonryItemBuilder = Widget Function(BuildContext context, int index);

class PostMasonryGrid extends StatelessWidget {
  const PostMasonryGrid({
    super.key,
    required this.itemCount,
    required this.loadingFirst,
    required this.columns,
    required this.bottomPadding,
    required this.emptyMessage,
    required this.itemBuilder,
    this.skeletonCount = 6,
  });

  final int itemCount;
  final bool loadingFirst;
  final int columns;
  final double bottomPadding;
  final String emptyMessage;
  final PostMasonryItemBuilder itemBuilder;
  final int skeletonCount;

  static const skeletonAspects = [0.8, 1.25, 1.0, 1.5, 0.9, 1.35];

  @override
  Widget build(BuildContext context) {
    final visibleCount = loadingFirst ? skeletonCount : itemCount;
    final count = visibleCount == 0 ? 1 : visibleCount;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottomPadding),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childCount: count,
        itemBuilder: (context, index) => _item(context, index),
      ),
    );
  }

  Widget _item(BuildContext context, int index) {
    if (!loadingFirst && itemCount == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (loadingFirst) {
      return PostFeedSkeletonCard(
        aspect: skeletonAspects[index % skeletonAspects.length],
      );
    }

    return itemBuilder(context, index);
  }
}
