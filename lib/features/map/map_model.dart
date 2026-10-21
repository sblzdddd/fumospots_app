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
