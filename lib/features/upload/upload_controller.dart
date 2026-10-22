import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/fumo_client_error.dart';
import '../auth/auth_controller.dart';
import 'location/upload_coordinates.dart';
import 'location/upload_device_location.dart';
import 'location/upload_place.dart';
import 'photo/upload_exif.dart';
import 'photo/upload_photo_intake.dart';
import 'upload_model.dart';
import 'upload_repository.dart';
import 'upload_submit.dart';

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
  bool benchmarking = false;
  String? benchmarkResult;
  String progressLabel = 'Submitting';
  String? error;
  int _photoSeq = 0;
  int _progressDone = 0;
  int _progressTotal = 0;
  bool _disposed = false;
  UploadLatLng? exactLocation;

  bool get canAddPhoto =>
      photos.length < maxPostPhotos && !uploading && !benchmarking;

  double? get uploadProgress {
    if (!uploading || _progressTotal == 0) return null;
    return _progressDone / _progressTotal;
  }

  bool get canSubmit =>
      !uploading &&
      !benchmarking &&
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

  Future<void> benchmarkConversions() async {
    if (photos.isEmpty || uploading || benchmarking) return;
    benchmarking = true;
    benchmarkResult = null;
    error = null;
    _notify();
    try {
      final result = await benchmarkPhotoConversions(photos);
      if (result.error != null) {
        error = result.error;
        benchmarkResult = 'Conversion failed';
      } else {
        benchmarkResult = result.summary;
      }
    } finally {
      benchmarking = false;
      _notify();
    }
  }

  Future<void> addPicked(List<XFile> files) async {
    if (files.isEmpty || uploading || benchmarking) return;
    error = null;
    final result = await intakePickedPhotos(
      files: files,
      currentCount: photos.length,
      nextId: () => ++_photoSeq,
    );
    error = result.error;
    if (result.accepted.isEmpty) {
      _notify();
      return;
    }
    final wasEmpty = photos.isEmpty;
    photos = [...photos, ...result.accepted];
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
      final result = await readDeviceLatLng();
      if (result.location != null) {
        await _applyExact(result.location!.lat, result.location!.lng);
      } else {
        error = result.error;
      }
    } on FumoClientError catch (error) {
      this.error = error.message;
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
    _applyPlace(result, overwritePlace: true);
    exactLocation = UploadLatLng(lat: result.lat, lng: result.lng);
    latitudeText = formatCoordinate(result.lat);
    longitudeText = formatCoordinate(result.lng);
    coordinateError = null;
    _notify();
  }

  Future<bool> applyCoordinates({bool lookup = true}) async {
    final parsed = parseCoordinatePair(latitudeText, longitudeText);
    if (!parsed.isValid) {
      coordinateError = parsed.error;
      _notify();
      return false;
    }
    if (parsed.cleared) {
      exactLocation = null;
      coordinateError = null;
      _notify();
      return true;
    }
    final location = parsed.location!;
    coordinateError = null;
    final current = exactLocation;
    if (current != null &&
        latitudeText.trim() == formatCoordinate(current.lat) &&
        longitudeText.trim() == formatCoordinate(current.lng)) {
      _notify();
      return true;
    }
    exactLocation = location;
    latitudeText = formatCoordinate(location.lat);
    longitudeText = formatCoordinate(location.lng);
    _notify();
    if (lookup) await _reverse(exactLocation!);
    return true;
  }

  Future<bool> submit() async {
    if (uploading || benchmarking) return false;
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
    progressLabel = 'Converting';
    _progressDone = 0;
    _progressTotal = photos.length * 2;
    _notify();
    try {
      await submitUpload(
        repository: _repository,
        input: UploadSubmitInput(
          userId: userId,
          title: trimmedTitle,
          body: trimmedBody,
          photos: photos,
          capturedAt: capturedAt,
          location: location,
          placeName: placeName.trim(),
          countryName: countryName,
          regionName: regionName,
          cityName: cityName,
          characterIds: characterIds,
        ),
        onProgress: (progress) {
          progressLabel = progress.label;
          _progressDone = progress.done;
          _progressTotal = progress.total;
          _notify();
        },
      );
      return true;
    } on FumoClientError catch (error) {
      this.error = error.message;
      return false;
    } catch (_) {
      error = 'Could not submit the spot.';
      return false;
    } finally {
      uploading = false;
      progressLabel = 'Submitting';
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
      _applyPlace(result, overwritePlace: false);
    } catch (_) {
      // Place names are a convenience and should not block the location.
    } finally {
      reverseLookup = false;
      _notify();
    }
  }

  void _applyPlace(UploadGeocode result, {required bool overwritePlace}) {
    final fields = applyGeocodePlace(
      result: result,
      currentPlaceName: placeName,
      lastAutoPlaceName: lastAutoPlaceName,
      overwritePlace: overwritePlace,
    );
    placeName = fields.placeName;
    lastAutoPlaceName = fields.lastAutoPlaceName;
    countryName = fields.countryName;
    regionName = fields.regionName;
    cityName = fields.cityName;
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
