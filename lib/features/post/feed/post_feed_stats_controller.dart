import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../map/map_repository.dart';

class PostFeedStatsController extends ChangeNotifier {
  PostFeedStatsController({MapRepository? repository})
    : _repository = repository ?? GetIt.instance<MapRepository>();

  final MapRepository _repository;

  int? postCount;
  int? contributorCount;
  bool loading = true;
  bool failed = false;
  int _request = 0;
  bool _disposed = false;

  bool get showingSkeletons => loading && postCount == null;

  bool get showingError => failed && postCount == null;

  Future<void> load() async {
    final request = ++_request;
    try {
      final stats = await _repository.fetchCount();
      if (_disposed || request != _request) {
        return;
      }
      postCount = stats.postCount;
      contributorCount = stats.contributorCount;
      loading = false;
      failed = false;
      notifyListeners();
    } catch (_) {
      if (_disposed || request != _request) {
        return;
      }
      loading = false;
      failed = postCount == null;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
