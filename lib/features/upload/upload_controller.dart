import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/fumo_client_error.dart';
import '../auth/auth_controller.dart';
import 'upload_exif.dart';
import 'upload_model.dart';
import 'upload_repository.dart';
import 'upload_webp.dart';

class UploadController extends ChangeNotifier {
  UploadController({
    UploadRepository? repository,
    ImagePicker? picker,
    AuthController? auth,
  }) : _repository = repository ?? GetIt.instance<UploadRepository>(),
       _picker = picker ?? ImagePicker(),
       _auth = auth ?? GetIt.instance<AuthController>();

  final UploadRepository _repository;
  final ImagePicker _picker;
  final AuthController _auth;

  List<UploadPhoto> photos = const [];
  String title = '';
  String body = '';
  String placeName = '';
  String? countryName;
  String? regionName;
  String? cityName;
  String? lastAutoPlaceName;
  String latitudeText = '';
  String longitudeText = '';
  String? coordinateError;
  DateTime? capturedAt;
  List<int> characterIds = const [];
  String searchQuery = '';
  List<UploadGeocode> searchResults = const [];
  bool searching = false;
  bool detectingExif = false;
  bool locating = false;
  bool reverseLookup = false;
  bool uploading = false;
  String? error;
  int _photoSeq = 0;
  int _progressDone = 0;
  int _progressTotal = 0;
  bool _disposed = false;
  UploadLatLng? exactLocation;

  bool get canAddPhoto => photos.length < maxPostPhotos && !uploading;

  double? get uploadProgress {
    if (!uploading || _progressTotal == 0) return null;
    return _progressDone / _progressTotal;
  }

  bool get canSubmit =>
      !uploading &&
      photos.isNotEmpty &&
      title.trim().isNotEmpty &&
      characterIds.isNotEmpty &&
      exactLocation != null &&
      coordinateError == null;

  bool get locationBusy => locating || detectingExif || reverseLookup;

  void setTitle(String value) {
    title = value;
    _notify();
  }

  void setBody(String value) {
    body = value;
    _notify();
  }

  void setPlaceName(String value) {
    placeName = value;
    _notify();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    if (searchResults.isNotEmpty) {
      searchResults = const [];
    }
    _notify();
  }

  void setLatitudeText(String value) {
    latitudeText = value;
    coordinateError = null;
    _notify();
  }

  void setLongitudeText(String value) {
    longitudeText = value;
    coordinateError = null;
    _notify();
  }

  void setCapturedAt(DateTime? value) {
    capturedAt = value;
    _notify();
  }

  void setCharacterIds(List<int> ids) {
    characterIds = List<int>.unmodifiable(ids);
    _notify();
  }

  Future<void> pickFromGallery() async {
    if (!canAddPhoto) return;
    try {
      final files = await _picker.pickMultiImage(
        limit: maxPostPhotos - photos.length,
        requestFullMetadata: true,
      );
      await addPicked(files);
    } on PlatformException catch (error) {
      this.error = error.message ?? 'Could not open photos.';
    } finally {
      _notify();
    }
  }

  Future<void> pickFromCamera() async {
    if (!canAddPhoto) return;
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: true,
      );
      if (file != null) await addPicked([file]);
    } on PlatformException catch (error) {
      this.error = error.message ?? 'Could not open the camera.';
    } finally {
      _notify();
    }
  }

  Future<void> addPicked(List<XFile> files) async {
    if (files.isEmpty || uploading) return;
    error = null;
    final accepted = <UploadPhoto>[];
    var rejectedType = false;
    var rejectedSize = false;
    for (final file in files) {
      if (photos.length + accepted.length >= maxPostPhotos) {
        error = 'You can add up to $maxPostPhotos photos.';
        break;
      }
      if (contentTypeFor(file.path, file.mimeType) == null) {
        rejectedType = true;
        continue;
      }
      final length = await File(file.path).length();
      if (length < 1 || length > maxPhotoBytes) {
        rejectedSize = true;
        continue;
      }
      accepted.add(
        UploadPhoto(
          id: '${++_photoSeq}',
          name: file.name,
          path: file.path,
          mimeType: file.mimeType,
        ),
      );
    }
    if (rejectedType) {
      error = 'Use a JPEG, PNG, WebP, GIF, or AVIF photo.';
    } else if (rejectedSize) {
      error = 'Photo is larger than 25 MB.';
    }
    if (accepted.isEmpty) {
      _notify();
      return;
    }
    final wasEmpty = photos.isEmpty;
    photos = [...photos, ...accepted];
    _notify();
    if (wasEmpty && (exactLocation == null || capturedAt == null)) {
      await fillFromPhoto(overwrite: false);
    }
  }

  void removePhoto(String id) {
    if (uploading) return;
    final index = photos.indexWhere((photo) => photo.id == id);
    if (index < 0) return;
    final next = [...photos]..removeAt(index);
    photos = next;
    _notify();
    if (index == 0 && next.isNotEmpty && exactLocation == null) {
      unawaited(fillFromPhoto(overwrite: false));
    }
  }

  void movePhoto(String id, int direction) {
    if (uploading) return;
    final index = photos.indexWhere((photo) => photo.id == id);
    final nextIndex = index + direction;
    if (index < 0 || nextIndex < 0 || nextIndex >= photos.length) return;
    final next = [...photos];
    final photo = next.removeAt(index);
    next.insert(nextIndex, photo);
    photos = next;
    _notify();
    if ((index == 0 || nextIndex == 0) && exactLocation == null) {
      unawaited(fillFromPhoto(overwrite: false));
    }
  }

  Future<void> fillFromDevice() async {
    if (uploading || locating) return;
    locating = true;
    error = null;
    _notify();
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        error = 'Turn on location services to use your device location.';
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        error = 'Location permission is required.';
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      await _applyExact(position.latitude, position.longitude);
    } on FumoClientError catch (error) {
      this.error = error.message;
    } catch (_) {
      error = 'Could not read the device location.';
    } finally {
      locating = false;
      _notify();
    }
  }

  Future<void> fillFromPhoto({required bool overwrite}) async {
    if (uploading || detectingExif) return;
    if (photos.isEmpty) {
      if (overwrite) {
        error = 'Add a photo first.';
        _notify();
      }
      return;
    }
    detectingExif = true;
    if (overwrite) error = null;
    _notify();
    try {
      final shot = await readPhotoExif(photos.first.path);
      if (shot.hasLocation && (overwrite || exactLocation == null)) {
        await _applyExact(shot.lat!, shot.lng!);
      } else if (overwrite && !shot.hasLocation) {
        error = 'This photo has no location.';
      }
      if (shot.capturedAt != null && (overwrite || capturedAt == null)) {
        capturedAt = shot.capturedAt;
      }
    } catch (_) {
      if (overwrite) error = 'Could not read photo details.';
    } finally {
      detectingExif = false;
      _notify();
    }
  }

  Future<void> searchPlaces() async {
    final query = searchQuery.trim();
    if (searching) return;
    if (query.length < 2) {
      error = 'Enter at least 2 characters to search.';
      _notify();
      return;
    }
    searching = true;
    error = null;
    _notify();
    try {
      searchResults = await _repository.searchPlaces(query);
      if (searchResults.isEmpty) {
        error = 'No places found.';
      }
    } on FumoClientError catch (error) {
      this.error = error.message;
    } catch (_) {
      error = 'Place search failed.';
    } finally {
      searching = false;
      _notify();
    }
  }

  void selectPlace(UploadGeocode result) {
    searchQuery = result.displayName;
    searchResults = const [];
    _setPlace(result, overwritePlace: true);
    exactLocation = UploadLatLng(lat: result.lat, lng: result.lng);
    latitudeText = formatCoordinate(result.lat);
    longitudeText = formatCoordinate(result.lng);
    coordinateError = null;
    _notify();
  }

  Future<bool> applyCoordinates({bool lookup = true}) async {
    final latitudeValue = latitudeText.trim();
    final longitudeValue = longitudeText.trim();
    if (latitudeValue.isEmpty && longitudeValue.isEmpty) {
      exactLocation = null;
      coordinateError = null;
      _notify();
      return true;
    }
    if (latitudeValue.isEmpty || longitudeValue.isEmpty) {
      coordinateError = 'Enter both latitude and longitude.';
      _notify();
      return false;
    }
    final latitude = _parseCoordinate(latitudeValue, min: -90, max: 90);
    final longitude = _parseCoordinate(longitudeValue, min: -180, max: 180);
    if (latitude == null) {
      coordinateError = 'Latitude must be between -90 and 90.';
      _notify();
      return false;
    }
    if (longitude == null) {
      coordinateError = 'Longitude must be between -180 and 180.';
      _notify();
      return false;
    }
    coordinateError = null;
    final current = exactLocation;
    if (current != null &&
        latitudeText.trim() == formatCoordinate(current.lat) &&
        longitudeText.trim() == formatCoordinate(current.lng)) {
      _notify();
      return true;
    }
    exactLocation = UploadLatLng(lat: latitude, lng: longitude);
    latitudeText = formatCoordinate(latitude);
    longitudeText = formatCoordinate(longitude);
    _notify();
    if (lookup) await _reverse(exactLocation!);
    return true;
  }

  Future<bool> submit() async {
    if (uploading) return false;
    error = null;
    if (!await applyCoordinates()) return false;
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (photos.isEmpty) {
      error = 'Add at least one photo.';
      _notify();
      return false;
    }
    if (photos.length > maxPostPhotos) {
      error = 'You can add up to $maxPostPhotos photos.';
      _notify();
      return false;
    }
    if (trimmedTitle.isEmpty || trimmedTitle.length > maxTitleLength) {
      error = 'Title is required and must be 80 characters or fewer.';
      _notify();
      return false;
    }
    if (trimmedBody.length > maxBodyLength) {
      error = 'Body must be 1000 characters or fewer.';
      _notify();
      return false;
    }
    if (characterIds.isEmpty) {
      error = 'Choose at least one character.';
      _notify();
      return false;
    }
    final location = exactLocation;
    if (location == null) {
      error = 'Set a location.';
      _notify();
      return false;
    }
    final userId = _auth.user?.userId;
    if (userId == null || userId.isEmpty || !_auth.hasUsername) {
      error = 'Sign in to post a spot.';
      _notify();
      return false;
    }

    uploading = true;
    _progressDone = 0;
    _progressTotal = 0;
    _notify();
    final postFolder = newUploadId();
    final attempted = <String>[];
    try {
      final prepared = <PreparedPhoto>[];
      for (var index = 0; index < photos.length; index++) {
        final photo = photos[index];
        prepared.add(
          await prepareUploadPhoto(
            sourcePath: photo.path,
            mimeType: photo.mimeType,
            userId: userId,
            postFolder: postFolder,
            index: index,
          ),
        );
      }
      final blobs = [for (final photo in prepared) ...photo.blobs];
      _progressTotal = blobs.length + 1;
      _notify();
      await _repository.uploadBlobs(
        blobs,
        onUploaded: (path) {
          attempted.add(path);
          _progressDone += 1;
          _notify();
        },
      );
      await _repository.createPost(
        title: trimmedTitle,
        body: trimmedBody.isEmpty ? null : trimmedBody,
        photos: prepared,
        capturedAt: capturedAt,
        location: location,
        placeName: placeName.trim(),
        countryName: countryName,
        regionName: regionName,
        cityName: cityName,
        characterIds: characterIds,
      );
      _progressDone += 1;
      _notify();
      return true;
    } on FumoClientError catch (error) {
      await _cleanup(attempted);
      this.error = error.message;
      return false;
    } catch (_) {
      await _cleanup(attempted);
      error = 'Could not submit the spot.';
      return false;
    } finally {
      uploading = false;
      _progressDone = 0;
      _progressTotal = 0;
      _notify();
    }
  }

  Future<void> _applyExact(double lat, double lng) async {
    exactLocation = UploadLatLng(lat: lat, lng: lng);
    latitudeText = formatCoordinate(lat);
    longitudeText = formatCoordinate(lng);
    coordinateError = null;
    _notify();
    await _reverse(exactLocation!);
  }

  Future<void> _reverse(UploadLatLng location) async {
    reverseLookup = true;
    _notify();
    try {
      final result = await _repository.reverseGeocode(location);
      final current = exactLocation;
      if (current == null ||
          current.lat != location.lat ||
          current.lng != location.lng) {
        return;
      }
      _setPlace(result, overwritePlace: false);
    } catch (_) {
      // Place names are a convenience and should not block the location.
    } finally {
      reverseLookup = false;
      _notify();
    }
  }

  void _setPlace(UploadGeocode result, {required bool overwritePlace}) {
    countryName = result.countryName;
    regionName = result.regionName;
    cityName = result.cityName;
    final next = result.placeName.trim();
    final current = placeName.trim();
    if (overwritePlace ||
        current.isEmpty ||
        (lastAutoPlaceName != null && current == lastAutoPlaceName)) {
      placeName = next;
      lastAutoPlaceName = next.isEmpty ? null : next;
    }
  }

  double? _parseCoordinate(
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

  Future<void> _cleanup(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _repository.deleteUploads(paths);
    } catch (_) {}
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
