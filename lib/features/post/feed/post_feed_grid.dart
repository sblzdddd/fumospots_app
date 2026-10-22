import 'package:flutter_staggered_grid/flutter_staggered_grid.dart';
import 'package:material_ui/material_ui.dart';

import '../post_card.dart';
import '../post_model.dart';
import 'post_feed_skeleton_card.dart';

class PostFeedGrid extends StatelessWidget {
  const PostFeedGrid({
    super.key,
    required this.posts,
    required this.loadingFirst,
    required this.hasFilter,
    required this.columns,
    required this.bottomPadding,
    required this.onOpenPost,
  });

  final List<PostListItem> posts;
  final bool loadingFirst;
  final bool hasFilter;
  final int columns;
  final double bottomPadding;
  final ValueChanged<int> onOpenPost;

  static const _skeletonAspects = [0.8, 1.25, 1.0, 1.5, 0.9, 1.35];

  @override
  Widget build(BuildContext context) {
    final itemCount = loadingFirst ? 6 : posts.length;
    final count = itemCount == 0 ? 1 : itemCount;

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
    if (!loadingFirst && posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          hasFilter ? 'No posts match these characters.' : 'No posts yet.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (loadingFirst) {
      return PostFeedSkeletonCard(
        aspect: _skeletonAspects[index % _skeletonAspects.length],
      );
    }

    final post = posts[index];
    return PostCard(
      post: post,
      onPress: () => onOpenPost(post.id),
    );
  }
}
