import 'dart:math';
import 'dart:typed_data';

const maxPostPhotos = 10;
const maxPhotoBytes = 25 * 1024 * 1024;
const maxTitleLength = 80;
const maxBodyLength = 1000;

const uploadImageContentTypes = {
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/avif',
  'image/heic',
  'image/heif',
};

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
    this.storageImagePath,
    this.storageThumbPath,
    this.previewUrl,
  });

  final String id;
  final String name;

  /// Local file path for newly picked photos. Empty for existing remote photos.
  final String path;
  final String? mimeType;

  /// Storage object paths when the photo already exists on the server.
  final String? storageImagePath;
  final String? storageThumbPath;
  final String? previewUrl;

  bool get isExisting =>
      storageImagePath != null && storageImagePath!.isNotEmpty;
}

class EditablePostPhoto {
  const EditablePostPhoto({
    required this.imageUrl,
    required this.thumbUrl,
    required this.imagePath,
    required this.thumbPath,
  });

  final String? imageUrl;
  final String? thumbUrl;
  final String imagePath;
  final String? thumbPath;

  factory EditablePostPhoto.fromJson(Map<String, dynamic> json) =>
      EditablePostPhoto(
        imageUrl: _optionalText(json['imageUrl']),
        thumbUrl: _optionalText(json['thumbUrl']),
        imagePath: _text(json['imagePath']),
        thumbPath: _optionalText(json['thumbPath']),
      );
}

class EditablePostDetail {
  const EditablePostDetail({
    required this.id,
    required this.status,
    required this.hasPendingRevision,
    required this.title,
    required this.body,
    required this.photos,
    required this.capturedAt,
    required this.exactLocation,
    required this.placeName,
    required this.countryName,
    required this.regionName,
    required this.cityName,
    required this.characterIds,
  });

  final int id;
  final String status;
  final bool hasPendingRevision;
  final String title;
  final String? body;
  final List<EditablePostPhoto> photos;
  final DateTime? capturedAt;
  final UploadLatLng exactLocation;
  final String placeName;
  final String? countryName;
  final String? regionName;
  final String? cityName;
  final List<int> characterIds;

  factory EditablePostDetail.fromJson(Map<String, dynamic> json) {
    final exact = json['exactLocation'];
    final exactMap = exact is Map ? exact : const <String, dynamic>{};
    final photosRaw = json['photos'];
    return EditablePostDetail(
      id: (json['id'] as num).toInt(),
      status: _text(json['status']),
      hasPendingRevision: json['hasPendingRevision'] as bool? ?? false,
      title: _text(json['title']),
      body: _optionalText(json['body']),
      photos: [
        if (photosRaw is List)
          for (final item in photosRaw)
            if (item is Map) EditablePostPhoto.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
      ],
      capturedAt: _dateTime(json['capturedAt']),
      exactLocation: UploadLatLng(
        lat: (exactMap['lat'] as num).toDouble(),
        lng: (exactMap['lng'] as num).toDouble(),
      ),
      placeName: _text(json['placeName']),
      countryName: _optionalText(json['countryName']),
      regionName: _optionalText(json['regionName']),
      cityName: _optionalText(json['cityName']),
      characterIds: [
        if (json['characterIds'] is List)
          for (final id in json['characterIds'] as List)
            if (id is num) id.toInt(),
      ],
    );
  }
}

DateTime? _dateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
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
