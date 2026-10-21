import 'package:maplibre/maplibre.dart';

import 'map_model.dart';

Feature<Point> mapPointFeature(
  MapPoint point, {
  Map<String, Object?> extraProperties = const {},
}) {
  return Feature(
    geometry: Point(Geographic(lon: point.lng, lat: point.lat)),
    properties: {
      'id': point.id,
      'userId': point.userId,
      ...extraProperties,
    },
  );
}

List<Feature<Point>> mapPointFeatures(Iterable<MapPoint> points) {
  return [for (final point in points) mapPointFeature(point)];
}

List<Feature<Point>> mapPointFeaturesForIds(
  Iterable<int> ids,
  Iterable<MapPoint> points,
) {
  final byId = {for (final point in points) point.id: point};
  return [
    for (final id in ids)
      if (byId[id] case final point?) mapPointFeature(point),
  ];
}

String emptyFeatureCollectionJson() =>
    FeatureCollection(<Feature<Point>>[]).toText();

String featureCollectionJson(List<Feature<Point>> features) {
  return FeatureCollection(features).toText();
}
