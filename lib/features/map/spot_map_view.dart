import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:maplibre/maplibre.dart';

import 'map_click.dart';
import 'map_feature_factory.dart';
import 'map_locate.dart';
import 'map_points_controller.dart';
import 'map_preview_annotations.dart';
import 'map_status_banner.dart';
import 'map_style.dart';

class SpotMapView extends StatefulWidget {
  const SpotMapView({
    super.key,
    required this.contentInsetTop,
    required this.onOpenPost,
    this.selectedPostId,
  });

  final double contentInsetTop;
  final ValueChanged<int> onOpenPost;
  final int? selectedPostId;

  @override
  State<SpotMapView> createState() => _SpotMapViewState();
}

class _SpotMapViewState extends State<SpotMapView> {
  final MapPointsController _points = GetIt.instance<MapPointsController>();
  final MapLocate _locate = MapLocate();
  final MapPreviewAnnotations _previews = MapPreviewAnnotations();

  MapController? _map;
  bool _locating = false;
  double _zoom = mapDefaultZoom;
  Size _mapSize = Size.zero;
  List<Feature<Point>> _circleFeatures = const [];
  MapPalette _palette = MapPalette.light;

  @override
  void initState() {
    super.initState();
    _points.addListener(_onPointsChanged);
    _circleFeatures = mapPointFeatures(_points.points);
    _points.load();
  }

  @override
  void dispose() {
    _points.removeListener(_onPointsChanged);
    _previews.dispose();
    super.dispose();
  }

  void _onPointsChanged() {
    _circleFeatures = mapPointFeatures(_points.points);
    if (!mounted) {
      return;
    }
    setState(() {});
    unawaited(_syncPreviews());
  }

  Future<void> _onStyleLoaded(StyleController style) async {
    await _previews.attach(
      style,
      palette: _palette,
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    await _syncPreviews();
  }

  Future<void> _syncPreviews() async {
    final map = _map;
    if (map == null || !_previews.isReady || _mapSize == Size.zero) {
      return;
    }
    await _previews.syncVisible(
      map: map,
      mapSize: _mapSize,
      points: _points.points,
      zoom: map.getCamera().zoom,
      selectedPostId: widget.selectedPostId,
    );
  }

  void _handleEvent(MapEvent event) {
    final map = _map;
    if (map == null) {
      return;
    }

    if (event is MapEventMoveCamera) {
      _zoom = event.camera.zoom;
      return;
    }

    if (event is MapEventCameraIdle || event is MapEventIdle) {
      _zoom = map.getCamera().zoom;
      unawaited(_syncPreviews());
      return;
    }

    if (event is! MapEventClick) {
      return;
    }

    final layerCount = widget.selectedPostId == null ? 1 : 4;
    final layerIds = <String>[
      for (var i = 0; i < layerCount; i++) 'maplibre-layer-$i',
      if (_zoom >= mapPreviewMinZoom) MapPreviewAnnotations.layerId,
    ];

    handleMapPostClick(
      map: map,
      screenPoint: event.screenPoint,
      layerIds: layerIds,
      points: _points.points,
      onOpenPost: widget.onOpenPost,
    );
  }

  Future<void> _goToMyLocation() async {
    final map = _map;
    if (map == null || _locating) {
      return;
    }

    setState(() => _locating = true);
    try {
      final error = await _locate.goToMyLocation(map);
      if (error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't get your location.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant SpotMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPostId != widget.selectedPostId) {
      unawaited(_syncPreviews());
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    _palette = MapPalette.of(brightness);
    final styleUrl = hostedMapStyleUrl(dark: brightness == Brightness.dark);
    final selectedId = widget.selectedPostId;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final nextSize = Size(constraints.maxWidth, constraints.maxHeight);
            if (nextSize != _mapSize) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                _mapSize = nextSize;
                unawaited(_syncPreviews());
              });
            }

            return MapLibreMap(
              key: ValueKey(styleUrl),
              options: MapOptions(
                initStyle: styleUrl,
                initCenter: const Geographic(
                  lon: mapDefaultCenterLon,
                  lat: mapDefaultCenterLat,
                ),
                initZoom: mapDefaultZoom,
                minZoom: 1,
                gestures: const MapGestures.all(pitch: false),
                androidTextureMode: true,
              ),
              onMapCreated: (controller) {
                _map = controller;
                _locate.reset();
              },
              onStyleLoaded: _onStyleLoaded,
              onEvent: _handleEvent,
              layers: [
                CircleLayer(
                  points: _circleFeatures,
                  color: _palette.primary,
                  strokeColor: _palette.contrast,
                  strokeWidth: 1,
                  radius: 5,
                  maxZoom: mapPreviewMinZoom,
                ),
                if (selectedId != null) ...[
                  CircleLayer(
                    points: mapPointFeaturesForIds([selectedId], _points.points),
                    color: _palette.halo,
                    strokeColor: _palette.primary,
                    strokeWidth: 3,
                    radius: 16,
                    maxZoom: mapPreviewMinZoom,
                  ),
                  CircleLayer(
                    points: mapPointFeaturesForIds([selectedId], _points.points),
                    color: _palette.primary,
                    strokeColor: _palette.contrast,
                    strokeWidth: 2,
                    radius: 8,
                    maxZoom: mapPreviewMinZoom,
                  ),
                  // Halo under native preview icons when zoomed in.
                  CircleLayer(
                    points: mapPointFeaturesForIds([selectedId], _points.points),
                    color: _palette.halo,
                    strokeColor: _palette.primary,
                    strokeWidth: 3,
                    radius: 28,
                    minZoom: mapPreviewMinZoom,
                  ),
                ],
              ],
            );
          },
        ),
        Positioned(
          top: widget.contentInsetTop + 16,
          left: 16,
          right: 16,
          child: MapStatusBanner(
            loading: _points.loading && _points.points.isEmpty,
            empty:
                !_points.loading &&
                _points.error == null &&
                _points.points.isEmpty,
            error: _points.error,
            onRetry: _points.retry,
          ),
        ),
        Positioned(
          right: 16,
          bottom: bottomPad + 16,
          child: FloatingActionButton.small(
            heroTag: 'map-locate',
            tooltip: 'My location',
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            onPressed: _locating ? null : _goToMyLocation,
            child: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const FaIcon(FontAwesomeIcons.locationCrosshairs, size: 16),
          ),
        ),
      ],
    );
  }
}
