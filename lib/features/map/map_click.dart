import 'dart:ui' show Offset, Size;

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
  Size mapSize = Size.zero,
  double topInset = 0,
  double bottomInset = 0,
  double sheetFraction = 0,
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
    final target = Geographic(lon: point.lng, lat: point.lat);
    map.animateCamera(
      center: _cameraCenterAboveSheet(
        map: map,
        point: target,
        mapSize: mapSize,
        topInset: topInset,
        bottomInset: bottomInset,
        sheetFraction: sheetFraction,
      ),
      nativeDuration: const Duration(milliseconds: 450),
    );
    onOpenPost(id);
    return true;
  }
  return false;
}

/// Places [point] in the open band above a bottom sheet.
///
/// A pure pan at the current zoom is a screen-space translation, so the new
/// center is the coordinate currently under the pixel that should become the
/// viewport center.
Geographic _cameraCenterAboveSheet({
  required MapController map,
  required Geographic point,
  required Size mapSize,
  required double topInset,
  required double bottomInset,
  required double sheetFraction,
}) {
  try {
    if (mapSize.width <= 0 ||
        mapSize.height <= 0 ||
        sheetFraction <= 0 ||
        sheetFraction >= 1) {
      return point;
    }

    final safeHeight = (mapSize.height - topInset - bottomInset).clamp(
      0.0,
      mapSize.height,
    );
    final sheetTop = topInset + safeHeight * (1 - sheetFraction);
    final focusY = ((topInset + sheetTop) / 2).clamp(0.0, mapSize.height);
    final focus = Offset(mapSize.width / 2, focusY);
    final current = map.toScreenLocation(point);
    final screenCenter = Offset(mapSize.width / 2, mapSize.height / 2);
    return map.toLngLat(current + screenCenter - focus);
  } catch (_) {
    return point;
  }
}
