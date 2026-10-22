import 'dart:io';

import 'package:exif/exif.dart';

import '../upload_model.dart';

Future<PhotoExif> readPhotoExif(String path) async {
  final tags = await readExifFromBytes(await File(path).readAsBytes());
  final lat = _coordinate(tags, 'GPS GPSLatitude', 'GPS GPSLatitudeRef');
  final lng = _coordinate(tags, 'GPS GPSLongitude', 'GPS GPSLongitudeRef');
  return PhotoExif(
    lat: lat != null && lat >= -90 && lat <= 90 ? lat : null,
    lng: lng != null && lng >= -180 && lng <= 180 ? lng : null,
    capturedAt: _capturedAt(tags),
  );
}

double? _coordinate(Map<String, IfdTag> tags, String valueKey, String refKey) {
  final tag = tags[valueKey];
  if (tag == null) return null;
  final values = tag.values;
  double? decimal;
  if (values is IfdRatios && values.ratios.isNotEmpty) {
    final ratios = values.ratios;
    final degrees = ratios[0].toDouble();
    final minutes = ratios.length > 1 ? ratios[1].toDouble() : 0;
    final seconds = ratios.length > 2 ? ratios[2].toDouble() : 0;
    decimal = degrees + (minutes / 60) + (seconds / 3600);
  } else {
    decimal = double.tryParse(tag.printable.trim());
  }
  if (decimal == null || decimal.isNaN) return null;
  final ref = (tags[refKey]?.printable ?? '').trim().toUpperCase();
  if (ref.startsWith('S') || ref.startsWith('W')) {
    decimal = -decimal.abs();
  }
  return decimal;
}

DateTime? _capturedAt(Map<String, IfdTag> tags) {
  for (final key in const [
    'EXIF DateTimeOriginal',
    'EXIF DateTimeDigitized',
    'Image DateTime',
  ]) {
    final raw = tags[key]?.printable.trim();
    if (raw == null || raw.isEmpty) continue;
    final match = RegExp(r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})')
        .firstMatch(raw);
    if (match == null) continue;
    return DateTime(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
      int.parse(match[4]!),
      int.parse(match[5]!),
      int.parse(match[6]!),
    );
  }
  return null;
}
