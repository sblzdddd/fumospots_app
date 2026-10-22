import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../map_model.dart';
import '../map_repository.dart';

/// Caches `/api/map/previews` results keyed by post id.
class MapPreviewController extends ChangeNotifier {
  MapPreviewController({MapRepository? repository})
    : _repository = repository ?? GetIt.instance<MapRepository>();

  final MapRepository _repository;
  final Map<int, MapPreviewItem> _byId = {};
  final Set<int> _inFlight = {};
  bool _disposed = false;

  MapPreviewItem? peek(int id) => _byId[id];

  bool has(int id) => _byId.containsKey(id);

  Future<void> ensureIds(Iterable<int> ids) async {
    final missing = <int>[];
    for (final id in ids) {
      if (id <= 0 || _byId.containsKey(id) || _inFlight.contains(id)) {
        continue;
      }
      missing.add(id);
    }
    if (missing.isEmpty) {
      return;
    }

    missing.sort();
    for (var i = 0; i < missing.length; i += MapRepository.maxPreviewIds) {
      final end = (i + MapRepository.maxPreviewIds).clamp(0, missing.length);
      final batch = missing.sublist(i, end);
      _inFlight.addAll(batch);
      try {
        final items = await _repository.fetchPreviews(batch);
        final seen = <int>{};
        for (final item in items) {
          _byId[item.id] = item;
          seen.add(item.id);
        }
        for (final id in batch) {
          if (!seen.contains(id)) {
            _byId[id] = MapPreviewItem(id: id, title: '', thumbUrl: null);
          }
        }
        _notify();
      } catch (_) {
        // Leave ids out of cache so a later idle can retry.
      } finally {
        _inFlight.removeAll(batch);
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
