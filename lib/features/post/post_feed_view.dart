import 'package:flutter_staggered_grid/flutter_staggered_grid.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import '../character/character_catalog_controller.dart';
import '../character/character_filter_controller.dart';
import '../character/character_filter_sync.dart';
import 'post_feed_controller.dart';
import 'post_feed_error_body.dart';
import 'post_feed_filter_header.dart';
import 'post_feed_footer.dart';
import 'post_feed_grid.dart';
import 'post_feed_refresh.dart';
import 'post_feed_stats_controller.dart';
import 'post_feed_stats_header.dart';

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
  final PostFeedStatsController _stats = PostFeedStatsController();
  final CharacterFilterController _filter =
      GetIt.instance<CharacterFilterController>();
  final CharacterCatalogController _catalog =
      GetIt.instance<CharacterCatalogController>();
  final ScrollController _scrollController = ScrollController();
  final M3EPullToRefreshController _refreshController =
      M3EPullToRefreshController();
  final GlobalKey _statsKey = GlobalKey();

  bool _indicatorArmed = false;
  bool _refreshFromIndicator = false;
  bool _filterPinned = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _stats.addListener(_onChanged);
    _filter.addListener(_onFilterChanged);
    _catalog.addListener(_onFilterChanged);
    _scrollController.addListener(_onScroll);
    _stats.load();
    _catalog.load();
    _syncCharacterFilter();
    if (_controller.posts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.load();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _stats.removeListener(_onChanged);
    _filter.removeListener(_onFilterChanged);
    _catalog.removeListener(_onFilterChanged);
    _stats.dispose();
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    _syncCharacterFilter();
    if (mounted) {
      setState(() {});
    }
  }

  void _syncCharacterFilter() {
    final slugs = resolveCharacterFilterSlugs(
      filter: _filter,
      catalog: _catalog,
    );
    if (slugs == null) {
      return;
    }
    _controller.applyCharacterSlugs(slugs);
  }

  void _onChanged() {
    if (_controller.showingSkeletons) {
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.jumpTo(0);
      }
      _filterPinned = false;
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

    final statsBox = _statsKey.currentContext?.findRenderObject() as RenderBox?;
    final statsHeight = statsBox?.size.height ?? 0;
    final pinned = statsHeight > 0 && position.pixels >= statsHeight - 0.5;
    if (pinned != _filterPinned) {
      setState(() => _filterPinned = pinned);
    }
  }

  Future<void> _onRefresh() async {
    _refreshFromIndicator = true;
    try {
      await Future.wait([
        _controller.refresh(),
        _stats.refresh(),
      ]);
    } finally {
      _refreshFromIndicator = false;
    }
  }

  int _columnCount(double width) => width >= 840 ? 3 : 2;

  Widget _statsHeader() {
    return KeyedSubtree(
      key: _statsKey,
      child: PostFeedStatsHeader(
        // Safe-area inset is reserved by [wrapFeedRefresh] edgeOffset.
        topInset: 0,
        loading: _stats.showingSkeletons,
        failed: _stats.showingError,
        postCount: _stats.postCount,
        contributorCount: _stats.contributorCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = _controller;
    final loadingFirst = feed.showingSkeletons;
    final columns = _columnCount(MediaQuery.sizeOf(context).width);

    return Stack(
      fit: StackFit.expand,
      children: [
        withFeedBarBottomPadding(
          context,
          (bottomPadding) => wrapFeedRefresh(
            contentInsetTop: widget.contentInsetTop,
            controller: _refreshController,
            onRefresh: _onRefresh,
            child: feed.error != null && feed.posts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    children: [
                      _statsHeader(),
                      const PostFeedFilterHeader(),
                      PostFeedErrorBody(
                        message: feed.error!,
                        onRetry: feed.retry,
                      ),
                    ],
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _statsHeader()),
                      SliverStickyHeader(
                        header: PostFeedFilterHeader(visible: !_filterPinned),
                        child: PostFeedGrid(
                          posts: feed.posts,
                          loadingFirst: loadingFirst,
                          hasFilter: _filter.hasFilter,
                          columns: columns,
                          bottomPadding: bottomPadding,
                          onOpenPost: widget.onOpenPost,
                        ),
                      ),
                      if (!loadingFirst)
                        SliverToBoxAdapter(
                          child: PostFeedFooter(
                            loading: feed.loadingMore,
                            error: feed.loadMoreError,
                            onRetry: feed.loadMore,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        PostFeedFilterOverlay(
          topInset: widget.contentInsetTop,
          visible: _filterPinned,
        ),
      ],
    );
  }
}
