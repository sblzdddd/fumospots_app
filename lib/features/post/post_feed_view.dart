import 'package:flutter_staggered_grid/flutter_staggered_grid.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import 'post_card.dart';
import 'post_feed_controller.dart';

class PostFeedView extends StatefulWidget {
  const PostFeedView({
    super.key,
    required this.contentInsetTop,
    required this.onOpenPost,
  });

  final double contentInsetTop;
  final ValueChanged<int> onOpenPost;

  @override
  State<PostFeedView> createState() => _PostFeedViewState();
}

class _PostFeedViewState extends State<PostFeedView> {
  final PostFeedController _controller = GetIt.instance<PostFeedController>();
  final ScrollController _scrollController = ScrollController();
  final M3EPullToRefreshController _refreshController =
      M3EPullToRefreshController();

  bool _indicatorArmed = false;
  bool _refreshFromIndicator = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _scrollController.addListener(_onScroll);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_controller.showingSkeletons) {
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.jumpTo(0);
      }
      if (!_indicatorArmed && !_refreshFromIndicator) {
        _indicatorArmed = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _refreshController.refresh();
          _indicatorArmed = false;
        });
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _controller.loadMore();
    }
  }

  Future<void> _onRefresh() async {
    _refreshFromIndicator = true;
    try {
      await _controller.refresh();
    } finally {
      _refreshFromIndicator = false;
    }
  }

  int _columnCount(double width) => width >= 840 ? 3 : 2;

  Widget _wrapRefresh({required Widget child}) {
    final inset = widget.contentInsetTop;
    return M3EPullToRefreshIndicator(
      controller: _refreshController,
      onRefresh: _onRefresh,
      edgeOffset: inset,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Transform.translate(
            offset: Offset(0, -inset),
            child: SizedBox(
              height: constraints.maxHeight + inset,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = _controller;
    final loadingFirst = feed.showingSkeletons;
    final width = MediaQuery.sizeOf(context).width;
    final columns = _columnCount(width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (feed.error != null && feed.posts.isEmpty) {
      return _wrapRefresh(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: widget.contentInsetTop),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        feed.error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      M3EButton(
                        onPressed: feed.retry,
                        style: M3EButtonStyle.filled,
                        shape: M3EButtonShape.round,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final itemCount = loadingFirst ? 6 : feed.posts.length;

    return _wrapRefresh(
      child: MasonryGridView.count(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        padding: EdgeInsets.fromLTRB(
          8,
          widget.contentInsetTop + 16,
          8,
          bottomInset,
        ),
        itemCount: itemCount == 0 ? 1 : itemCount,
        itemBuilder: (context, index) {
          if (!loadingFirst && feed.posts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No posts yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          if (loadingFirst) {
            final aspects = [0.8, 1.25, 1.0, 1.5, 0.9, 1.35];
            return _SkeletonCard(aspect: aspects[index % aspects.length]);
          }

          final post = feed.posts[index];
          return PostCard(
            post: post,
            onPress: () => widget.onOpenPost(post.id),
          );
        },
        footer: loadingFirst
            ? null
            : _FeedFooter(
                loading: feed.loadingMore,
                error: feed.loadMoreError,
                onRetry: feed.loadMore,
              ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.aspect});

  final double aspect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = colors.surfaceContainerHighest;

    return M3ESegmentedItem(
      index: 0,
      position: M3ESegmentedItemPosition.single,
      outerRadius: 16,
      innerRadius: 16,
      gap: 0,
      color: colors.surfaceContainerHigh,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1 / aspect,
            child: ColoredBox(color: fill),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(8, 0, 32, 0),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 80,
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter({
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            Text(
              error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            M3EButton(
              onPressed: onRetry,
              style: M3EButtonStyle.text,
              shape: M3EButtonShape.round,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!loading) {
      return const SizedBox(height: 8);
    }

    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        children: [
          Expanded(child: _SkeletonCard(aspect: 1)),
          SizedBox(width: 8),
          Expanded(child: _SkeletonCard(aspect: 1.25)),
        ],
      ),
    );
  }
}
