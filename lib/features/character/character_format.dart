import 'character_model.dart';

String characterCatalogName(CharacterCatalogItem character, String locale) {
  final normalized = locale.toLowerCase();
  if (normalized.startsWith('zh') && character.nameZh != null) {
    return character.nameZh!;
  }
  if (normalized.startsWith('ja') && character.nameJa != null) {
    return character.nameJa!;
  }
  return character.nameEn;
}
