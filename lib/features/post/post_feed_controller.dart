import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/fumo_client_error.dart';
import 'post_model.dart';
import 'post_repository.dart';

class PostFeedController extends ChangeNotifier {
  PostFeedController({PostRepository? repository})
    : _repository = repository ?? GetIt.instance<PostRepository>();

  final PostRepository _repository;

  List<PostListItem> posts = const [];
  int postCount = 0;
  bool loading = true;
  bool loadingMore = false;
  String? error;
  String? loadMoreError;
  bool hasMore = true;
  PostSortOrder sortOrder = PostSortOrder.desc;

  int _nextOffset = 0;
  int _generation = 0;
  bool _loadingMore = false;
  bool _freshLoad = false;
  bool _disposed = false;
  Future<void>? _freshInFlight;

  /// True while a fresh load is in progress with no posts to show.
  bool get showingSkeletons => loading && posts.isEmpty && error == null;

  Future<void> load({PostSortOrder? sort}) {
    if (sort != null) {
      sortOrder = sort;
    }
    return _load(append: false);
  }

  Future<void> refresh() => _load(append: false);

  Future<void> loadMore() => _load(append: true);

  Future<void> retry() => _load(append: false);

  Future<void> _load({required bool append}) async {
    if (append) {
      if (_freshLoad || _loadingMore || !hasMore) {
        return;
      }
      _loadingMore = true;
      loadingMore = true;
      loadMoreError = null;
      _notify();
      await _fetch(append: true, request: _generation);
      return;
    }

    final existing = _freshInFlight;
    if (existing != null) {
      return existing;
    }

    _generation += 1;
    _freshLoad = true;
    _loadingMore = false;
    loading = true;
    loadingMore = false;
    error = null;
    loadMoreError = null;
    // Keep the current list up while a refresh is in flight. Clearing it
    // rebuilds the whole grid and leaves the feed blank until the request ends.
    if (posts.isEmpty) {
      _nextOffset = 0;
      postCount = 0;
      hasMore = true;
    }
    _notify();

    final request = _generation;
    final future = _fetch(append: false, request: request);
    _freshInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_freshInFlight, future)) {
        _freshInFlight = null;
      }
    }
  }

  Future<void> _fetch({required bool append, required int request}) async {
    final offset = append ? _nextOffset : 0;

    try {
      final page = await _repository.fetchPostsPage(offset, sortOrder);
      if (request != _generation) {
        return;
      }
      _nextOffset = page.nextOffset ?? page.postCount;
      hasMore = page.nextOffset != null;
      postCount = page.postCount;
      posts = append ? [...posts, ...page.items] : page.items;
    } on FumoClientError catch (e) {
      if (request != _generation) {
        return;
      }
      if (append) {
        loadMoreError = "Couldn't load more posts.";
      } else {
        error = e.message;
      }
    } catch (_) {
      if (request != _generation) {
        return;
      }
      if (append) {
        loadMoreError = "Couldn't load more posts.";
      } else {
        error = 'Failed to load posts.';
      }
    } finally {
      if (request == _generation) {
        _freshLoad = false;
        _loadingMore = false;
        loading = false;
        loadingMore = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
