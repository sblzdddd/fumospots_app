import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/fumo_client_error.dart';
import 'map_model.dart';
import 'map_repository.dart';

class MapPointsController extends ChangeNotifier {
  MapPointsController({MapRepository? repository})
    : _repository = repository ?? GetIt.instance<MapRepository>();

  static const _maxPages = 40;

  final MapRepository _repository;

  List<MapPoint> points = const [];
  List<String> characterSlugs = const [];
  bool loading = true;
  String? error;
  bool _disposed = false;
  Future<void>? _inFlight;

  Future<void> load({bool force = false}) {
    if (!force && points.isNotEmpty && !loading && error == null) {
      return Future.value();
    }
    return _inFlight ??= _loadAll().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> retry() {
    points = const [];
    error = null;
    loading = true;
    _notify();
    return load(force: true);
  }

  /// Reload map points for the given character slug filter (OR match).
  Future<void> applyCharacterSlugs(List<String> slugs) {
    final next = List<String>.unmodifiable(slugs);
    if (listEquals(characterSlugs, next) && (points.isNotEmpty || loading)) {
      return _inFlight ?? Future.value();
    }
    characterSlugs = next;
    points = const [];
    error = null;
    loading = true;
    _notify();
    _inFlight = null;
    return load(force: true);
  }

  Future<void> _loadAll() async {
    loading = true;
    error = null;
    _notify();

    final slugs = characterSlugs;

    try {
      final all = <MapPoint>[];
      var afterId = 0;
      int? throughId;

      for (var page = 0; page < _maxPages; page++) {
        final result = await _repository.fetchPointPage(
          afterId,
          throughId: throughId,
          characterSlugs: slugs,
        );
        if (_disposed || !listEquals(characterSlugs, slugs)) {
          return;
        }
        all.addAll(result.points);
        throughId ??= result.throughId;
        if (result.nextAfterId == null) {
          points = all;
          loading = false;
          _notify();
          return;
        }
        if (result.nextAfterId! <= afterId) {
          throw const FumoClientError('Map page did not advance.');
        }
        afterId = result.nextAfterId!;
      }
      throw const FumoClientError('Map has too many pages.');
    } on FumoClientError catch (e) {
      if (_disposed || !listEquals(characterSlugs, slugs)) {
        return;
      }
      error = e.message;
      loading = false;
      _notify();
    } catch (_) {
      if (_disposed || !listEquals(characterSlugs, slugs)) {
        return;
      }
      error = "Couldn't load map spots.";
      loading = false;
      _notify();
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
