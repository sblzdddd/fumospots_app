import '../upload_model.dart';

class CoordinateParseResult {
  const CoordinateParseResult._({
    this.location,
    this.error,
    this.cleared = false,
  });

  const CoordinateParseResult.cleared() : this._(cleared: true);

  const CoordinateParseResult.ok(UploadLatLng location)
    : this._(location: location);

  const CoordinateParseResult.invalid(String error) : this._(error: error);

  final UploadLatLng? location;
  final String? error;
  final bool cleared;

  bool get isValid => error == null;
}

CoordinateParseResult parseCoordinatePair(
  String latitudeText,
  String longitudeText,
) {
  final latitudeValue = latitudeText.trim();
  final longitudeValue = longitudeText.trim();
  if (latitudeValue.isEmpty && longitudeValue.isEmpty) {
    return const CoordinateParseResult.cleared();
  }
  if (latitudeValue.isEmpty || longitudeValue.isEmpty) {
    return const CoordinateParseResult.invalid(
      'Enter both latitude and longitude.',
    );
  }
  final latitude = parseCoordinate(latitudeValue, min: -90, max: 90);
  final longitude = parseCoordinate(longitudeValue, min: -180, max: 180);
  if (latitude == null) {
    return const CoordinateParseResult.invalid(
      'Latitude must be between -90 and 90.',
    );
  }
  if (longitude == null) {
    return const CoordinateParseResult.invalid(
      'Longitude must be between -180 and 180.',
    );
  }
  return CoordinateParseResult.ok(
    UploadLatLng(lat: latitude, lng: longitude),
  );
}

double? parseCoordinate(
  String value, {
  required double min,
  required double max,
}) {
  if (!RegExp(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$').hasMatch(value)) {
    return null;
  }
  final parsed = double.tryParse(value);
  if (parsed == null || parsed < min || parsed > max) return null;
  return parsed;
}
