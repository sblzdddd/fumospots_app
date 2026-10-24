import 'package:material_ui/material_ui.dart';

import '../../../core/i18n/i18n.dart';
import '../post_card.dart';
import '../post_masonry_grid.dart';
import '../post_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return PostMasonryGrid(
      itemCount: posts.length,
      loadingFirst: loadingFirst,
      columns: columns,
      bottomPadding: bottomPadding,
      emptyMessage: context.t(
        hasFilter ? S.noPostsMatchFilter : S.noPostsYet,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(
          post: post,
          onPress: () => onOpenPost(post.id),
        );
      },
    );
  }
}
