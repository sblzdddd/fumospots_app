import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../post/feed/post_feed_error_body.dart';
import '../post/feed/post_feed_refresh.dart';
import '../post/post_card.dart';
import '../post/post_masonry_grid.dart';
import 'user_controller.dart';
import 'user_model.dart';

class UserPostsSection extends StatefulWidget {
  const UserPostsSection({
    super.key,
    required this.onOpenPost,
    required this.onEditPost,
  });

  final ValueChanged<UserPostSummary> onOpenPost;
  final ValueChanged<UserPostSummary> onEditPost;

  @override
  State<UserPostsSection> createState() => _UserPostsSectionState();
}

class _UserPostsSectionState extends State<UserPostsSection> {
  final UserController _controller = GetIt.instance<UserController>();
  final M3EPullToRefreshController _refreshController =
      M3EPullToRefreshController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.page == null && !_controller.loading) {
        _controller.loadForSignedInUser();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _refreshController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onRefresh() => _controller.refresh();

  int _columnCount(double width) => width >= 840 ? 3 : 2;

  @override
  Widget build(BuildContext context) {
    final posts = _controller.posts;
    final loadingFirst = _controller.showingSkeletons;
    final columns = _columnCount(MediaQuery.sizeOf(context).width);

    return withFeedBarBottomPadding(
      context,
      (bottomPadding) => wrapFeedRefresh(
        contentInsetTop: 0,
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'My posts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (_controller.page != null) ...[
                      Text(
                        '${posts.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_controller.totalLikeCount} likes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_controller.error != null && posts.isEmpty)
              SliverToBoxAdapter(
                child: PostFeedErrorBody(
                  message: _controller.error!,
                  onRetry: _controller.retry,
                ),
              )
            else
              PostMasonryGrid(
                itemCount: posts.length,
                loadingFirst: loadingFirst,
                columns: columns,
                bottomPadding: bottomPadding,
                emptyMessage: 'No posts yet.',
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return PostCard(
                    post: post.toListItem(),
                    badge: PostStatusBadge(label: post.statusLabel),
                    onPress: () => widget.onOpenPost(post),
                    onEdit: () => widget.onEditPost(post),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
