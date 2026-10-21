import 'dart:ui' show Offset;

import 'package:maplibre/maplibre.dart';

import 'map_model.dart';
import 'map_post_id.dart';

typedef MapPostOpener = void Function(int id);

/// Resolves a map click to a known post id and focuses the camera.
bool handleMapPostClick({
  required MapController map,
  required Offset screenPoint,
  required List<String> layerIds,
  required Iterable<MapPoint> points,
  required MapPostOpener onOpenPost,
}) {
  if (layerIds.isEmpty) {
    return false;
  }

  final List<RenderedFeature> hits;
  try {
    hits = map.featuresAtPoint(screenPoint, layerIds: layerIds);
  } catch (_) {
    return false;
  }

  final known = {for (final point in points) point.id: point};
  for (final hit in hits) {
    final id = mapPostIdFromProperties(hit.properties);
    if (id == null) {
      continue;
    }
    final point = known[id];
    if (point == null) {
      continue;
    }
    map.animateCamera(
      center: Geographic(lon: point.lng, lat: point.lat),
      nativeDuration: const Duration(milliseconds: 450),
    );
    onOpenPost(id);
    return true;
  }
  return false;
}
