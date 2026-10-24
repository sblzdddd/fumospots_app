import 'package:geolocator/geolocator.dart';

import '../../../core/i18n/keys.dart';
import '../upload_model.dart';

class DeviceLocationResult {
  const DeviceLocationResult._({this.location, this.error});

  const DeviceLocationResult.ok(UploadLatLng location)
    : this._(location: location);

  const DeviceLocationResult.failed(String error) : this._(error: error);

  final UploadLatLng? location;
  final String? error;
}

Future<DeviceLocationResult> readDeviceLatLng() async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return const DeviceLocationResult.failed(S.locationServicesOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const DeviceLocationResult.failed(S.locationPermission);
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return DeviceLocationResult.ok(
      UploadLatLng(lat: position.latitude, lng: position.longitude),
    );
  } catch (_) {
    return const DeviceLocationResult.failed(S.deviceLocationFailed);
  }
}
