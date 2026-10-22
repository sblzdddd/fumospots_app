import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:maplibre/maplibre.dart';

import '../../../core/services/image_cache_service.dart';
import '../map_feature_factory.dart';
import '../map_model.dart';
import '../map_style.dart';
import 'map_preview_controller.dart';

/// Native MapLibre symbol annotations for post preview thumbs.
///
/// Images are registered with [StyleController.addImage] and positioned by a
/// GeoJSON symbol layer so they stay glued to the map during gestures.
class MapPreviewAnnotations {
  MapPreviewAnnotations({
    MapPreviewController? previews,
    ImageCacheService? images,
  }) : _previews = previews ?? GetIt.instance<MapPreviewController>(),
       _images = images ?? GetIt.instance<ImageCacheService>();

  static const sourceId = 'spot-previews';
  static const layerId = 'spot-previews-layer';
  static const placeholderIconId = 'spot-preview-placeholder';

  final MapPreviewController _previews;
  final ImageCacheService _images;

  StyleController? _style;
  MapPalette _palette = MapPalette.light;
  double _pixelRatio = 2;
  int? _selectedPostId;

  final Map<int, Uint8List> _pinPngById = {};
  final Set<int> _styleImageIds = {};
  final Set<int> _loadingIds = {};
  Set<int> _visibleIds = {};
  Map<int, MapPoint> _lastPointsById = {};
  bool _ready = false;
  bool _disposed = false;
  int _syncSeq = 0;

  bool get isReady => _ready;

  Future<void> attach(
    StyleController style, {
    required MapPalette palette,
    required double pixelRatio,
  }) async {
    _style = style;
    _palette = palette;
    _pixelRatio = pixelRatio.clamp(1, 3);
    _ready = false;
    _styleImageIds.clear();
    _pinPngById.clear();

    await style.addImage(
      placeholderIconId,
      await _buildPlaceholderPng(_palette),
    );

    await style.addSource(
      GeoJsonSource(id: sourceId, data: emptyFeatureCollectionJson()),
    );
    await style.addLayer(
      SymbolStyleLayer(
        id: layerId,
        sourceId: sourceId,
        minZoom: mapPreviewMinZoom,
        layout: {
          'icon-image': '{icon}',
          'icon-size': _iconSize,
          'icon-allow-overlap': true,
          'icon-ignore-placement': true,
          'icon-anchor': 'center',
        },
      ),
    );

    _ready = true;
    if (_visibleIds.isNotEmpty) {
      await _publishSource();
      unawaited(_hydrateVisible(_syncSeq, _visibleIds));
    }
  }

  void detach() {
    _style = null;
    _ready = false;
    _styleImageIds.clear();
  }

  void dispose() {
    _disposed = true;
    detach();
    _pinPngById.clear();
  }

  /// Update which posts should show preview icons (call on camera idle).
  Future<void> syncVisible({
    required MapController map,
    required Size mapSize,
    required List<MapPoint> points,
    required double zoom,
    int? selectedPostId,
  }) async {
    if (_disposed || !_ready || _style == null) {
      return;
    }

    _selectedPostId = selectedPostId;
    final seq = ++_syncSeq;

    if (zoom < mapPreviewMinZoom || mapSize == Size.zero) {
      _visibleIds = {};
      await _publishSource();
      return;
    }

    final visible = _pickVisibleIds(map, points);
    _visibleIds = visible;

    // Show placeholders immediately so the map is never empty while loading.
    await _publishSource();
    if (visible.isEmpty) {
      return;
    }

    unawaited(_hydrateVisible(seq, visible));
  }

  Future<void> _hydrateVisible(int seq, Set<int> visible) async {
    await _previews.ensureIds(visible);
    if (_disposed || seq != _syncSeq) {
      return;
    }

    // Refresh icons for any thumbs already cached from a prior visit.
    var pendingPublish = false;
    for (final id in visible) {
      if (_pinPngById.containsKey(id) && !_styleImageIds.contains(id)) {
        final uploaded = await _uploadCachedPin(id);
        pendingPublish = pendingPublish || uploaded;
      }
    }
    if (pendingPublish) {
      await _publishSource();
    }

    // Load remaining images one-by-one and reveal as they finish.
    for (final id in visible) {
      if (_disposed || seq != _syncSeq) {
        return;
      }
      final loaded = await _ensurePinImage(id);
      if (loaded) {
        await _publishSource();
      }
    }
  }

  Future<void> _publishSource() async {
    final style = _style;
    if (style == null || !_ready) {
      return;
    }

    final features = <Feature<Point>>[];
    for (final id in _visibleIds) {
      final point = _lastPointsById[id];
      if (point == null) {
        continue;
      }
      final hasPin = _styleImageIds.contains(id);
      features.add(
        mapPointFeature(
          point,
          extraProperties: {
            'icon': hasPin ? _iconId(id) : placeholderIconId,
            'selected': id == _selectedPostId ? 1 : 0,
          },
        ),
      );
    }

    await style.updateGeoJsonSource(
      id: sourceId,
      data: featureCollectionJson(features),
    );
  }

  Set<int> _pickVisibleIds(MapController map, List<MapPoint> points) {
    _lastPointsById = {for (final p in points) p.id: p};

    // Full viewport from MapLibre (not a hand-projected subset of the widget).
    final region = map.getVisibleRegion();
    final lonSpan =
        (region.longitudeEast - region.longitudeWest).abs().clamp(1e-9, 360.0);
    final latSpan =
        (region.latitudeNorth - region.latitudeSouth).abs().clamp(1e-9, 180.0);
    // Pad ~one pin so icons near the edges still load.
    final padLon = lonSpan * 0.04;
    final padLat = latSpan * 0.04;
    final minLon = region.longitudeWest - padLon;
    final maxLon = region.longitudeEast + padLon;
    final minLat = region.latitudeSouth - padLat;
    final maxLat = region.latitudeNorth + padLat;

    final center = map.getCamera().center;
    final cosLat = math.cos(center.lat * math.pi / 180);
    final scored = <({int id, double dist})>[];

    for (final point in points) {
      if (!_lngInRange(point.lng, minLon, maxLon) ||
          point.lat < minLat ||
          point.lat > maxLat) {
        continue;
      }
      final dx = (point.lng - center.lon) * cosLat;
      final dy = point.lat - center.lat;
      scored.add((id: point.id, dist: dx * dx + dy * dy));
    }

    scored.sort((a, b) => a.dist.compareTo(b.dist));
    final limit = math.min(mapPreviewMaxVisible, scored.length);
    return {for (var i = 0; i < limit; i++) scored[i].id};
  }

  /// Inclusive longitude test that tolerates antimeridian-wrapped bounds.
  bool _lngInRange(double lng, double minLon, double maxLon) {
    if (minLon <= maxLon) {
      return lng >= minLon && lng <= maxLon;
    }
    // Bound crosses ±180°.
    return lng >= minLon || lng <= maxLon;
  }

  Future<bool> _uploadCachedPin(int id) async {
    final cached = _pinPngById[id];
    final style = _style;
    if (cached == null || style == null || _styleImageIds.contains(id)) {
      return false;
    }
    await style.addImage(_iconId(id), cached);
    _styleImageIds.add(id);
    return true;
  }

  /// Returns true when a new style image was uploaded.
  Future<bool> _ensurePinImage(int id) async {
    if (_styleImageIds.contains(id) || _loadingIds.contains(id)) {
      return false;
    }
    if (_pinPngById.containsKey(id)) {
      return _uploadCachedPin(id);
    }

    final url = _previews.peek(id)?.thumbUrl;
    if (url == null || url.isEmpty) {
      return false;
    }

    _loadingIds.add(id);
    try {
      final file = await _images.cacheManager.getSingleFile(url);
      final bytes = await file.readAsBytes();
      final png = await _buildPinPng(bytes, _palette);
      if (png == null || _disposed) {
        return false;
      }
      _pinPngById[id] = png;
      return await _uploadCachedPin(id);
    } catch (_) {
      return false;
    } finally {
      _loadingIds.remove(id);
    }
  }

  static String _iconId(int id) =>
      'spot-preview-$id-${mapPreviewThumbSize.round()}-sq';

  /// Bake @ device pixels and shrink with icon-size for sharp output.
  /// (Android `addImage` also density-scales; icon-size compensates.)
  double get _iconSize => 1.0 / _pixelRatio;

  double get _bakeScale => _pixelRatio;

  int get _pinRasterSize =>
      (mapPreviewThumbSize * _bakeScale).round().clamp(48, 256);

  RRect _pinRRect(double size) {
    final inset = 1.5 * _bakeScale;
    final radius =
        mapPreviewThumbSize * mapPreviewCornerFraction * _bakeScale;
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size - inset * 2, size - inset * 2),
      Radius.circular(radius),
    );
  }

  Future<Uint8List> _buildPlaceholderPng(MapPalette palette) {
    final stroke = 2 * _bakeScale;
    return _rasterPin(
      painter: (canvas, size) {
        final rrect = _pinRRect(size);
        canvas.drawRRect(rrect, Paint()..color = palette.primary);
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = palette.contrast
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke,
        );
      },
    );
  }

  Future<Uint8List?> _buildPinPng(Uint8List raw, MapPalette palette) async {
    try {
      final target = _pinRasterSize;
      final stroke = 2 * _bakeScale;
      // Keep aspect ratio; avoid forcing a square decode (stretches photos).
      final codec = await ui.instantiateImageCodec(
        raw,
        targetWidth: target * 2,
      );
      final frame = await codec.getNextFrame();
      final photo = frame.image;
      final png = await _rasterPin(
        size: target,
        painter: (canvas, size) {
          final rrect = _pinRRect(size);
          canvas.save();
          canvas.clipRRect(rrect);
          paintImage(
            canvas: canvas,
            rect: rrect.outerRect,
            image: photo,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          );
          canvas.restore();
          canvas.drawRRect(
            rrect,
            Paint()
              ..color = palette.contrast
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke,
          );
        },
      );
      photo.dispose();
      return png;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _rasterPin({
    int? size,
    required void Function(Canvas canvas, double size) painter,
  }) async {
    final dim = size ?? _pinRasterSize;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter(canvas, dim.toDouble());
    final picture = recorder.endRecording();
    final image = await picture.toImage(dim, dim);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }
}
