import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/i18n/keys.dart';
import '../../core/services/fumo_client_error.dart';
import '../auth/auth_controller.dart';
import 'location/upload_coordinates.dart';
import 'location/upload_device_location.dart';
import 'location/upload_place.dart';
import 'photo/upload_exif.dart';
import 'photo/upload_photo_intake.dart';
import 'photo/upload_webp.dart';
import 'upload_model.dart';
import 'upload_repository.dart';
import 'upload_submit.dart';

const _photoCompressionError = S.compressFailed;

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
  bool loadingEdit = false;
  String progressLabel = S.submitting;
  String? error;
  int? editPostId;
  int _photoSeq = 0;
  int _progressDone = 0;
  int _progressTotal = 0;
  bool _disposed = false;
  UploadLatLng? exactLocation;
  final Map<String, EncodedUploadPhoto> _encoded = {};
  final Map<String, Future<void>> _compressionTasks = {};
  String? _compressionError;

  bool get isEditMode => editPostId != null;

  bool get canAddPhoto =>
      photos.length < maxPostPhotos && !uploading && !loadingEdit;

  double? get uploadProgress {
    if (!uploading || _progressTotal == 0) return null;
    return _progressDone / _progressTotal;
  }

  bool get canSubmit =>
      !uploading &&
      !loadingEdit &&
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
      this.error = error.message ?? S.openPhotosFailed;
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
      this.error = error.message ?? S.openCameraFailed;
    } finally {
      _notify();
    }
  }

  Future<void> addPicked(List<XFile> files) async {
    if (files.isEmpty || uploading) return;
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
    final accepted = [
      for (final photo in result.accepted)
        photo.copyWith(compressionProgress: 0),
    ];
    photos = [...photos, ...accepted];
    for (final photo in accepted) {
      _startCompression(photo);
    }
    _notify();
    if (wasEmpty && (exactLocation == null || capturedAt == null)) {
      await fillFromPhoto(overwrite: false);
    }
  }

  void _startCompression(UploadPhoto photo) {
    if (photo.isExisting || photo.path.isEmpty) return;
    _compressionTasks[photo.id] = _runCompression(photo);
  }

  Future<void> _runCompression(UploadPhoto photo) async {
    try {
      final encoded = await encodeUploadPhoto(
        sourcePath: photo.path,
        mimeType: photo.mimeType,
        onProgress: (progress) {
          if (progress >= 1) return;
          _patchPhoto(
            photo.id,
            (current) => current.copyWith(
              compressionProgress: progress,
              compressionFailed: false,
            ),
          );
        },
      );
      if (_disposed || !_hasPhoto(photo.id)) return;
      _encoded[photo.id] = encoded;
      _patchPhoto(
        photo.id,
        (current) =>
            current.copyWith(compressionProgress: 1, compressionFailed: false),
      );
    } on FumoClientError catch (error) {
      _failPhoto(photo.id, error.message);
    } catch (_) {
      _failPhoto(photo.id, _photoCompressionError);
    } finally {
      _compressionTasks.remove(photo.id);
    }
  }

  Future<void> _waitForCompression() {
    final pending = List<Future<void>>.of(_compressionTasks.values);
    if (pending.isEmpty) return Future<void>.value();
    return Future.wait(pending);
  }

  void _failPhoto(String id, String message) {
    if (_disposed || !_hasPhoto(id)) return;
    _encoded.remove(id);
    _compressionError = message;
    error = message;
    _patchPhoto(
      id,
      (photo) =>
          photo.copyWith(compressionProgress: 1, compressionFailed: true),
    );
  }

  void _patchPhoto(String id, UploadPhoto Function(UploadPhoto photo) patch) {
    if (_disposed) return;
    final index = photos.indexWhere((photo) => photo.id == id);
    if (index < 0) return;
    final next = [...photos];
    next[index] = patch(next[index]);
    photos = next;
    _notify();
  }

  bool _hasPhoto(String id) => photos.any((photo) => photo.id == id);

  void removePhoto(String id) {
    if (uploading) return;
    final index = photos.indexWhere((photo) => photo.id == id);
    if (index < 0) return;
    final next = [...photos]..removeAt(index);
    photos = next;
    _encoded.remove(id);
    _compressionTasks.remove(id);
    if (!next.any((photo) => photo.compressionFailed) &&
        error == _compressionError) {
      error = null;
      _compressionError = null;
    }
    _notify();
    if (index == 0 && next.isNotEmpty && exactLocation == null) {
      unawaited(fillFromPhoto(overwrite: false));
    }
  }

  /// Moves [draggedId] into the cell currently occupied by [toIndex].
  void reorderPhotos(String draggedId, int toIndex) {
    if (uploading) return;
    final from = photos.indexWhere((photo) => photo.id == draggedId);
    if (from < 0 ||
        toIndex < 0 ||
        toIndex >= photos.length ||
        from == toIndex) {
      return;
    }
    final next = [...photos];
    final photo = next.removeAt(from);
    next.insert(toIndex, photo);
    photos = next;
    _notify();
    if ((from == 0 || toIndex == 0) && exactLocation == null) {
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

  Future<void> loadForEdit(int postId) async {
    if (uploading || loadingEdit) return;
    loadingEdit = true;
    editPostId = postId;
    error = null;
    _notify();
    try {
      final detail = await _repository.fetchEditablePost(postId);
      if (_disposed) return;
      title = detail.title;
      body = detail.body ?? '';
      placeName = detail.placeName;
      countryName = detail.countryName;
      regionName = detail.regionName;
      cityName = detail.cityName;
      lastAutoPlaceName = null;
      exactLocation = detail.exactLocation;
      latitudeText = formatCoordinate(detail.exactLocation.lat);
      longitudeText = formatCoordinate(detail.exactLocation.lng);
      coordinateError = null;
      capturedAt = detail.capturedAt;
      characterIds = List<int>.unmodifiable(detail.characterIds);
      searchQuery = '';
      searchResults = const [];
      photos = [
        for (var index = 0; index < detail.photos.length; index++)
          UploadPhoto(
            id: 'existing-$index-${detail.photos[index].imagePath}',
            name: _existingPhotoName(detail.photos[index].imagePath, index),
            path: '',
            mimeType: 'image/webp',
            storageImagePath: detail.photos[index].imagePath,
            storageThumbPath: detail.photos[index].thumbPath,
            previewUrl:
                detail.photos[index].thumbUrl ?? detail.photos[index].imageUrl,
          ),
      ];
      _photoSeq = photos.length;
    } on FumoClientError catch (error) {
      this.error = error.message;
    } catch (_) {
      error = S.loadEditFailed;
    } finally {
      loadingEdit = false;
      _notify();
    }
  }

  String _existingPhotoName(String imagePath, int index) {
    final slash = imagePath.lastIndexOf('/');
    if (slash >= 0 && slash < imagePath.length - 1) {
      return imagePath.substring(slash + 1);
    }
    return 'photo-${index + 1}.webp';
  }

  Future<void> fillFromPhoto({required bool overwrite}) async {
    if (uploading || detectingExif) return;
    if (photos.isEmpty) {
      if (overwrite) {
        error = S.addPhotoFirst;
        _notify();
      }
      return;
    }
    if (photos.first.isExisting) {
      if (overwrite) {
        error = S.noLocalExif;
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
        error = S.photoNoLocation;
      }
      if (shot.capturedAt != null && (overwrite || capturedAt == null)) {
        capturedAt = shot.capturedAt;
      }
    } catch (_) {
      if (overwrite) error = S.readPhotoDetailsFailed;
    } finally {
      detectingExif = false;
      _notify();
    }
  }

  Future<void> searchPlaces() async {
    final query = searchQuery.trim();
    if (searching) return;
    if (query.length < 2) {
      error = S.searchMinChars;
      _notify();
      return;
    }
    searching = true;
    error = null;
    _notify();
    try {
      searchResults = await _repository.searchPlaces(query);
      if (searchResults.isEmpty) {
        error = S.noPlacesFound;
      }
    } on FumoClientError catch (error) {
      this.error = error.message;
    } catch (_) {
      error = S.placeSearchFailed;
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
    if (uploading) return false;
    error = null;
    if (!await applyCoordinates()) return false;
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (photos.isEmpty) {
      error = S.addAtLeastOnePhoto;
      _notify();
      return false;
    }
    if (photos.length > maxPostPhotos) {
      error = S.maxPhotos;
      _notify();
      return false;
    }
    if (trimmedTitle.isEmpty || trimmedTitle.length > maxTitleLength) {
      error = S.titleValidation;
      _notify();
      return false;
    }
    if (trimmedBody.length > maxBodyLength) {
      error = S.bodyValidation;
      _notify();
      return false;
    }
    if (characterIds.isEmpty) {
      error = S.chooseCharacter;
      _notify();
      return false;
    }
    final location = exactLocation;
    if (location == null) {
      error = S.setLocation;
      _notify();
      return false;
    }
    final userId = _auth.user?.userId;
    if (userId == null || userId.isEmpty || !_auth.hasUsername) {
      error = S.signInToPost;
      _notify();
      return false;
    }

    final stillCompressing = photos.any((photo) => photo.isCompressing);
    uploading = true;
    progressLabel = stillCompressing ? S.converting : S.uploading;
    _progressDone = 0;
    _progressTotal = 0;
    _notify();
    try {
      await _waitForCompression();
      if (_disposed) return false;
      if (photos.any((photo) => photo.compressionFailed)) {
        error = _compressionError ?? _photoCompressionError;
        return false;
      }
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
          editPostId: editPostId,
        ),
        encodedById: Map<String, EncodedUploadPhoto>.of(_encoded),
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
      error = isEditMode ? S.updateFailed : S.submitFailed;
      return false;
    } finally {
      uploading = false;
      progressLabel = S.submitting;
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
    _encoded.clear();
    _compressionTasks.clear();
    super.dispose();
  }
}
