import '../../core/services/fumo_client.dart';
import '../../core/services/fumo_client_error.dart';
import '../../utils/json_converter.dart';
import 'map_model.dart';

class MapRepository {
  MapRepository({required FumoClient client}) : _client = client;

  final FumoClient _client;

  static const maxPreviewIds = 100;

  Future<MapPointPage> fetchPointPage(int afterId, {int? throughId}) async {
    final response = await _client.get(
      '/api/map/posts',
      queryParameters: {
        'afterId': afterId,
        if (throughId != null) 'throughId': throughId,
      },
      fallback: "Couldn't load map spots.",
    );
    return _pageFromJson(toJsonMap(response.data));
  }

  Future<List<MapPreviewItem>> fetchPreviews(List<int> ids) async {
    if (ids.isEmpty) {
      return const [];
    }
    final limited = ids.take(maxPreviewIds).toList(growable: false);
    final response = await _client.get(
      '/api/map/previews',
      queryParameters: {'ids': limited.join(',')},
      fallback: "Couldn't load map previews.",
    );
    final json = toJsonMap(response.data);
    final items = json['items'];
    if (items is! List) {
      return const [];
    }
    return [
      for (final raw in items)
        if (_previewFromJson(raw) case final item?) item,
    ];
  }

  MapPreviewItem? _previewFromJson(Object? raw) {
    try {
      final json = toJsonMap(raw);
      final id = _asNonNegativeInt(json['id']);
      if (id == null || id <= 0) {
        return null;
      }
      final title = '${json['title'] ?? ''}';
      final thumb = json['thumbUrl'];
      return MapPreviewItem(
        id: id,
        title: title,
        thumbUrl: thumb is String && thumb.isNotEmpty ? thumb : null,
      );
    } catch (_) {
      return null;
    }
  }

  MapPointPage _pageFromJson(Map<String, dynamic> json) {
    final features = json['features'];
    final points = <MapPoint>[];
    if (features is List) {
      for (final raw in features) {
        final point = _pointFromFeature(raw);
        if (point != null) {
          points.add(point);
        }
      }
    }

    final throughId = _asNonNegativeInt(json['throughId']);
    if (throughId == null) {
      throw const FumoClientError('Map page throughId is invalid.');
    }

    final nextAfterId = json['nextAfterId'] == null
        ? null
        : _asNonNegativeInt(json['nextAfterId']);

    return MapPointPage(
      points: points,
      nextAfterId: nextAfterId,
      throughId: throughId,
    );
  }

  MapPoint? _pointFromFeature(Object? raw) {
    try {
      final feature = toJsonMap(raw);
      final geometry = toJsonMap(feature['geometry']);
      final properties = toJsonMap(feature['properties']);
      final coords = geometry['coordinates'];
      if (coords is! List || coords.length < 2) {
        return null;
      }

      final lng = _asDouble(coords[0]);
      final lat = _asDouble(coords[1]);
      final id = _asNonNegativeInt(properties['id']);
      if (lng == null || lat == null || id == null || id <= 0) {
        return null;
      }

      return MapPoint(
        id: id,
        lat: lat,
        lng: lng,
        userId: '${properties['userId'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }

  int? _asNonNegativeInt(Object? value) {
    if (value is int) {
      return value >= 0 ? value : null;
    }
    if (value is num) {
      if (!value.isFinite) {
        return null;
      }
      final asInt = value.toInt();
      if (asInt != value || asInt < 0) {
        return null;
      }
      return asInt;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 0) {
        return null;
      }
      return parsed;
    }
    return null;
  }

  double? _asDouble(Object? value) {
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
