import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:maplibre/maplibre.dart';
import 'package:material_ui/material_ui.dart';

import '../character/character_catalog_controller.dart';
import '../character/character_filter_bar.dart';
import '../character/character_filter_controller.dart';
import '../character/character_filter_sync.dart';
import '../post/post_detail_sheet.dart';
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
  final CharacterFilterController _filter =
      GetIt.instance<CharacterFilterController>();
  final CharacterCatalogController _catalog =
      GetIt.instance<CharacterCatalogController>();
  final MapLocate _locate = MapLocate();
  final MapPreviewAnnotations _previews = MapPreviewAnnotations();

  MapController? _map;
  bool _locating = false;
  double _zoom = mapDefaultZoom;
  Size _mapSize = Size.zero;
  List<Feature<Point>> _circleFeatures = const [];
  MapPalette _palette = MapPalette.light;
  bool _mapSurfaceReady = false;
  bool _styleReady = false;
  int _mapAttempt = 0;
  Timer? _styleRecovery;

  bool get _recoverBlankIosMap =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _points.addListener(_onPointsChanged);
    _filter.addListener(_onFilterChanged);
    _catalog.addListener(_onFilterChanged);
    _circleFeatures = mapPointFeatures(_points.points);
    _catalog.load();
    _syncCharacterFilter();
    _points.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _mapSurfaceReady = true);
    });
  }

  @override
  void dispose() {
    _styleRecovery?.cancel();
    _points.removeListener(_onPointsChanged);
    _filter.removeListener(_onFilterChanged);
    _catalog.removeListener(_onFilterChanged);
    _previews.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    _syncCharacterFilter();
    if (mounted) {
      setState(() {});
    }
  }

  void _syncCharacterFilter() {
    final slugs = resolveCharacterFilterSlugs(
      filter: _filter,
      catalog: _catalog,
    );
    if (slugs == null) {
      return;
    }
    unawaited(_points.applyCharacterSlugs(slugs));
  }

  void _armStyleRecovery() {
    _styleRecovery?.cancel();
    if (!_recoverBlankIosMap) {
      return;
    }
    _styleRecovery = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _styleReady || _mapAttempt >= 1) {
        return;
      }
      setState(() => _mapAttempt++);
    });
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
    _styleReady = true;
    _styleRecovery?.cancel();
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

    final padding = MediaQuery.paddingOf(context);
    handleMapPostClick(
      map: map,
      screenPoint: event.screenPoint,
      layerIds: layerIds,
      points: _points.points,
      onOpenPost: widget.onOpenPost,
      mapSize: _mapSize,
      topInset: padding.top,
      bottomInset: padding.bottom,
      sheetFraction: postDetailSheetInitialSize,
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

  Widget _locateFab(double bottom) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: M3EFab(
        color: M3EFabColor.secondary,
        tooltip: 'My location',
        onPressed: _locating ? null : _goToMyLocation,
        icon: _locating
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              )
            : const FaIcon(FontAwesomeIcons.locationCrosshairs),
      ),
    );
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
    final barHeight = BottomBarScope.maybeOf(context)?.barHeight;

    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final nextSize = Size(constraints.maxWidth, constraints.maxHeight);
            if (nextSize != _mapSize &&
                nextSize.width > 0 &&
                nextSize.height > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                _mapSize = nextSize;
                unawaited(_syncPreviews());
              });
            }

            if (!_mapSurfaceReady ||
                nextSize.width <= 0 ||
                nextSize.height <= 0) {
              return const SizedBox.expand();
            }

            final attempt = _mapAttempt;
            return MapLibreMap(
              key: ValueKey('$styleUrl#$attempt'),
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
                if (!mounted || attempt != _mapAttempt) {
                  return;
                }
                _map = controller;
                _locate.reset();
                _styleReady = false;
                _armStyleRecovery();
              },
              onStyleLoaded: (style) {
                if (!mounted || attempt != _mapAttempt) {
                  return;
                }
                unawaited(_onStyleLoaded(style));
              },
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
          top: widget.contentInsetTop,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CharacterFilterBar(floating: true),
              const SizedBox(height: 8),
              MapStatusBanner(
                loading: _points.loading && _points.points.isEmpty,
                empty:
                    !_points.loading &&
                    _points.error == null &&
                    _points.points.isEmpty,
                error: _points.error,
                onRetry: _points.retry,
              ),
            ],
          ),
        ),
        Positioned(
          right: 32,
          bottom: 0,
          child: barHeight == null
              ? _locateFab(bottomPad)
              : ValueListenableBuilder<double>(
                  valueListenable: barHeight,
                  builder: (context, value, _) {
                    final clearance = value > bottomPad ? value : bottomPad;
                    return _locateFab(clearance);
                  },
                ),
        ),
      ],
    );
  }
}
