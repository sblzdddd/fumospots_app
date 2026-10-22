import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/fumo_client_error.dart';
import 'character_model.dart';
import 'character_repository.dart';

class CharacterCatalogController extends ChangeNotifier {
  CharacterCatalogController({CharacterRepository? repository})
    : _repository = repository ?? GetIt.instance<CharacterRepository>();

  final CharacterRepository _repository;

  List<CharacterCatalogItem> characters = const [];
  bool loading = false;
  String? error;
  bool _disposed = false;
  Future<void>? _inFlight;

  CharacterCatalogItem? byId(int id) {
    for (final character in characters) {
      if (character.id == id) {
        return character;
      }
    }
    return null;
  }

  List<String> slugsForIds(Iterable<int> ids) {
    final selected = ids.toSet();
    return [
      for (final character in characters)
        if (selected.contains(character.id)) character.slug,
    ];
  }

  Future<void> load({bool force = false}) {
    if (!force && characters.isNotEmpty && error == null) {
      return Future.value();
    }
    return _inFlight ??= _load().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<void> retry() => load(force: true);

  Future<void> _load() async {
    loading = true;
    error = null;
    _notify();
    try {
      characters = await _repository.fetchCatalog();
      loading = false;
      _notify();
    } on FumoClientError catch (e) {
      error = e.message;
      loading = false;
      _notify();
    } catch (_) {
      error = "Couldn't load characters.";
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
