import '../../core/services/fumo_client.dart';
import '../../core/services/fumo_client_error.dart';
import '../../utils/json_converter.dart';
import 'character_model.dart';

class CharacterRepository {
  CharacterRepository({required this._client});

  final FumoClient _client;

  Future<List<CharacterCatalogItem>> fetchCatalog() async {
    final response = await _client.get(
      '/api/characters',
      fallback: "Couldn't load characters.",
    );
    final json = toJsonMap(response.data);
    final items = json['items'];
    if (items is! List) {
      throw const FumoClientError("Couldn't load characters.");
    }
    return [
      for (final raw in items)
        if (raw is Map) CharacterCatalogItem.fromJson(toJsonMap(raw)),
    ];
  }
}
