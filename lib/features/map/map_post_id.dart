/// Same as WorldMap.vue `getFeaturePostId`.
int? mapPostIdFromProperties(Map<String, Object?> properties) {
  final raw = properties['id'];
  if (raw is num) {
    final id = raw.toInt();
    return id > 0 ? id : null;
  }
  if (raw is String) {
    final id = int.tryParse(raw);
    return id != null && id > 0 ? id : null;
  }
  return null;
}
