import 'dart:math';
import 'dart:typed_data';

const maxPostPhotos = 10;
const maxPhotoBytes = 25 * 1024 * 1024;
const maxTitleLength = 80;
const maxBodyLength = 1000;

class UploadLatLng {
  const UploadLatLng({required this.lat, required this.lng});

  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class UploadGeocode {
  const UploadGeocode({
    required this.displayName,
    required this.placeName,
    required this.lat,
    required this.lng,
    required this.countryName,
    required this.regionName,
    required this.cityName,
  });

  final String displayName;
  final String placeName;
  final double lat;
  final double lng;
  final String? countryName;
  final String? regionName;
  final String? cityName;

  factory UploadGeocode.fromJson(Map<String, dynamic> json) {
    return UploadGeocode(
      displayName: _text(json['displayName']),
      placeName: _text(json['placeName']),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      countryName: _optionalText(json['countryName']),
      regionName: _optionalText(json['regionName']),
      cityName: _optionalText(json['cityName']),
    );
  }
}

class UploadPhoto {
  const UploadPhoto({
    required this.id,
    required this.name,
    required this.path,
    required this.mimeType,
  });

  final String id;
  final String name;
  final String path;
  final String? mimeType;
}

class UploadBlob {
  const UploadBlob({
    required this.path,
    required this.contentType,
    required this.bytes,
  });

  final String path;
  final String contentType;
  final Uint8List bytes;
}

class PreparedPhoto {
  const PreparedPhoto({
    required this.imagePath,
    required this.thumbPath,
    required this.blobs,
  });

  final String imagePath;
  final String? thumbPath;
  final List<UploadBlob> blobs;
}

class SignedUploadTarget {
  const SignedUploadTarget({
    required this.path,
    required this.uploadUrl,
    required this.contentType,
    required this.size,
    required this.headers,
  });

  final String path;
  final String uploadUrl;
  final String contentType;
  final int size;
  final Map<String, String> headers;

  factory SignedUploadTarget.fromJson(Map<String, dynamic> json) {
    return SignedUploadTarget(
      path: _text(json['path']),
      uploadUrl: _text(json['uploadUrl']),
      contentType: _text(json['contentType']),
      size: (json['size'] as num).toInt(),
      headers: _headers(json['headers']),
    );
  }
}

class PhotoExif {
  const PhotoExif({this.lat, this.lng, this.capturedAt});

  final double? lat;
  final double? lng;
  final DateTime? capturedAt;

  bool get hasLocation => lat != null && lng != null;
}

String newUploadId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int start, int end) => bytes
      .sublist(start, end)
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

String formatCoordinate(double value) => value.toStringAsFixed(6);

String _text(Object? value) => value is String ? value : '';

String? _optionalText(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, String> _headers(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.value != null) '${entry.key}': '${entry.value}',
  };
}
