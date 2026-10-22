import 'package:get_it/get_it.dart';

import 'character_catalog_controller.dart';
import 'character_filter_controller.dart';

/// Resolves selected character IDs to API slugs once the catalog is ready.
List<String>? resolveCharacterFilterSlugs({
  CharacterFilterController? filter,
  CharacterCatalogController? catalog,
}) {
  final selected = filter ?? GetIt.instance<CharacterFilterController>();
  final characters = catalog ?? GetIt.instance<CharacterCatalogController>();

  if (!selected.hasFilter) {
    return const [];
  }
  if (characters.characters.isEmpty) {
    // Catalog not ready yet — keep prior filter instead of clearing.
    return null;
  }
  return characters.slugsForIds(selected.selectedIds);
}
