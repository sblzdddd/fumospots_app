class MapPoint {
  const MapPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.userId,
  });

  final int id;
  final double lat;
  final double lng;
  final String userId;
}

/// One-shot camera request from outside the map (e.g. post detail → map).
class MapFocusTarget {
  const MapFocusTarget({
    required this.lat,
    required this.lng,
    required this.generation,
  });

  final double lat;
  final double lng;
  final int generation;
}

class MapPointPage {
  const MapPointPage({
    required this.points,
    required this.nextAfterId,
    required this.throughId,
  });

  final List<MapPoint> points;
  final int? nextAfterId;
  final int throughId;
}

class MapPreviewItem {
  const MapPreviewItem({
    required this.id,
    required this.title,
    required this.thumbUrl,
  });

  final int id;
  final String title;
  final String? thumbUrl;
}

class MapCount {
  const MapCount({
    required this.postCount,
    required this.contributorCount,
  });

  final int postCount;
  final int contributorCount;
}
