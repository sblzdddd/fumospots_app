class CharacterCatalogItem {
  const CharacterCatalogItem({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.nameZh,
    required this.nameJa,
  });

  final int id;
  final String slug;
  final String nameEn;
  final String? nameZh;
  final String? nameJa;

  factory CharacterCatalogItem.fromJson(Map<String, dynamic> json) {
    return CharacterCatalogItem(
      id: (json['id'] as num).toInt(),
      slug: '${json['slug'] ?? ''}',
      nameEn: '${json['nameEn'] ?? ''}',
      nameZh: json['nameZh'] is String ? json['nameZh'] as String : null,
      nameJa: json['nameJa'] is String ? json['nameJa'] as String : null,
    );
  }
}
