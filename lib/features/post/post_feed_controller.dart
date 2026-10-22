import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/fumo_client_error.dart';
import '../map/map_repository.dart';
import 'post_model.dart';
import 'post_repository.dart';

class PostFeedController extends ChangeNotifier {
  PostFeedController({
    PostRepository? repository,
    MapRepository? mapRepository,
  }) : _repository = repository ?? GetIt.instance<PostRepository>(),
       _mapRepository = mapRepository ?? GetIt.instance<MapRepository>();

  static const _pageSize = 24;
  static const _maxMapPages = 40;

  final PostRepository _repository;
  final MapRepository _mapRepository;

  List<PostListItem> posts = const [];
  int postCount = 0;
  bool loading = true;
  bool loadingMore = false;
  String? error;
  String? loadMoreError;
  bool hasMore = true;
  PostSortOrder sortOrder = PostSortOrder.desc;
  List<String> characterSlugs = const [];

  int _nextOffset = 0;
  int _generation = 0;
  bool _loadingMore = false;
  bool _freshLoad = false;
  bool _disposed = false;
  Future<void>? _freshInFlight;

  /// Filtered feed built from map post ids + previews (existing public APIs).
  List<int> _filteredIds = const [];
  final Map<int, PostListItem> _previewItems = {};

  /// True while a fresh load is in progress with no posts to show.
  bool get showingSkeletons => loading && posts.isEmpty && error == null;

  bool get _filtering => characterSlugs.isNotEmpty;

  Future<void> load({PostSortOrder? sort}) {
    if (sort != null) {
      sortOrder = sort;
    }
    return _load(append: false);
  }

  Future<void> refresh() => _load(append: false);

  Future<void> loadMore() => _load(append: true);

  Future<void> retry() => _load(append: false);

  Future<void> applyCharacterSlugs(List<String> slugs) {
    final next = List<String>.unmodifiable(slugs);
    if (listEquals(characterSlugs, next)) {
      return _freshInFlight ?? Future.value();
    }
    characterSlugs = next;
    return _load(append: false);
  }

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
      // Allow superseding when filter changes mid-flight via generation bump below.
    }

    _generation += 1;
    _freshLoad = true;
    _loadingMore = false;
    loading = true;
    loadingMore = false;
    error = null;
    loadMoreError = null;
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
      if (_filtering) {
        await _fetchFiltered(append: append, offset: offset, request: request);
      } else {
        await _fetchUnfiltered(append: append, offset: offset, request: request);
      }
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

  Future<void> _fetchUnfiltered({
    required bool append,
    required int offset,
    required int request,
  }) async {
    _filteredIds = const [];
    _previewItems.clear();
    final page = await _repository.fetchPostsPage(offset, sortOrder);
    if (request != _generation) {
      return;
    }
    _nextOffset = page.nextOffset ?? page.postCount;
    hasMore = page.nextOffset != null;
    postCount = page.postCount;
    posts = append ? [...posts, ...page.items] : page.items;
  }

  Future<void> _fetchFiltered({
    required bool append,
    required int offset,
    required int request,
  }) async {
    if (!append) {
      _filteredIds = await _loadFilteredIds(characterSlugs);
      _previewItems.clear();
      if (request != _generation) {
        return;
      }
      postCount = _filteredIds.length;
    }

    if (request != _generation) {
      return;
    }

    if (_filteredIds.isEmpty) {
      posts = const [];
      _nextOffset = 0;
      hasMore = false;
      postCount = 0;
      return;
    }

    final end = (offset + _pageSize).clamp(0, _filteredIds.length);
    final pageIds = _filteredIds.sublist(offset, end);
    await _ensurePreviews(pageIds);
    if (request != _generation) {
      return;
    }

    final pageItems = [
      for (final id in pageIds)
        _previewItems[id] ??
            PostListItem(
              id: id,
              title: '',
              thumbUrl: null,
              placeName: null,
              createdAt: null,
            ),
    ];

    _nextOffset = end;
    hasMore = end < _filteredIds.length;
    posts = append ? [...posts, ...pageItems] : pageItems;
  }

  Future<List<int>> _loadFilteredIds(List<String> slugs) async {
    final ids = <int>[];
    var afterId = 0;
    int? throughId;

    for (var page = 0; page < _maxMapPages; page++) {
      final result = await _mapRepository.fetchPointPage(
        afterId,
        throughId: throughId,
        characterSlugs: slugs,
      );
      for (final point in result.points) {
        ids.add(point.id);
      }
      throughId ??= result.throughId;
      if (result.nextAfterId == null) {
        // Newest-first for feed feel (map pages are ascending by id).
        return ids.reversed.toList(growable: false);
      }
      if (result.nextAfterId! <= afterId) {
        throw const FumoClientError('Map page did not advance.');
      }
      afterId = result.nextAfterId!;
    }
    throw const FumoClientError('Too many filtered posts.');
  }

  Future<void> _ensurePreviews(List<int> ids) async {
    final missing = [
      for (final id in ids)
        if (!_previewItems.containsKey(id)) id,
    ];
    if (missing.isEmpty) {
      return;
    }
    final items = await _mapRepository.fetchPreviews(missing);
    for (final item in items) {
      _previewItems[item.id] = PostListItem(
        id: item.id,
        title: item.title,
        thumbUrl: item.thumbUrl,
        placeName: null,
        createdAt: null,
      );
    }
    for (final id in missing) {
      _previewItems.putIfAbsent(
        id,
        () => PostListItem(
          id: id,
          title: '',
          thumbUrl: null,
          placeName: null,
          createdAt: null,
        ),
      );
    }
  }

  bool _notifyScheduled = false;

  void _notify() {
    if (_disposed) {
      return;
    }
    final phase = SchedulerBinding.instance.schedulerPhase;
    final building =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (!building) {
      notifyListeners();
      return;
    }
    if (_notifyScheduled) {
      return;
    }
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
