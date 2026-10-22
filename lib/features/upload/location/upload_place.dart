import '../upload_model.dart';

class PlaceFields {
  const PlaceFields({
    required this.placeName,
    required this.lastAutoPlaceName,
    required this.countryName,
    required this.regionName,
    required this.cityName,
  });

  final String placeName;
  final String? lastAutoPlaceName;
  final String? countryName;
  final String? regionName;
  final String? cityName;
}

PlaceFields applyGeocodePlace({
  required UploadGeocode result,
  required String currentPlaceName,
  required String? lastAutoPlaceName,
  required bool overwritePlace,
}) {
  final next = result.placeName.trim();
  final current = currentPlaceName.trim();
  final shouldReplace =
      overwritePlace ||
      current.isEmpty ||
      (lastAutoPlaceName != null && current == lastAutoPlaceName);
  return PlaceFields(
    placeName: shouldReplace ? next : currentPlaceName,
    lastAutoPlaceName: shouldReplace
        ? (next.isEmpty ? null : next)
        : lastAutoPlaceName,
    countryName: result.countryName,
    regionName: result.regionName,
    cityName: result.cityName,
  );
}
