import 'photo/upload_webp.dart';
import 'upload_model.dart';
import 'upload_repository.dart';

class UploadSubmitInput {
  const UploadSubmitInput({
    required this.userId,
    required this.title,
    required this.body,
    required this.photos,
    required this.capturedAt,
    required this.location,
    required this.placeName,
    required this.countryName,
    required this.regionName,
    required this.cityName,
    required this.characterIds,
    this.editPostId,
  });

  final String userId;
  final String title;
  final String body;
  final List<UploadPhoto> photos;
  final DateTime? capturedAt;
  final UploadLatLng location;
  final String placeName;
  final String? countryName;
  final String? regionName;
  final String? cityName;
  final List<int> characterIds;
  final int? editPostId;

  bool get isEdit => editPostId != null;
}

class UploadSubmitProgress {
  const UploadSubmitProgress({
    required this.label,
    required this.done,
    required this.total,
  });

  final String label;
  final int done;
  final int total;
}

typedef UploadProgressCallback = void Function(UploadSubmitProgress progress);

Future<void> submitUpload({
  required UploadRepository repository,
  required UploadSubmitInput input,
  required UploadProgressCallback onProgress,
  Map<String, EncodedUploadPhoto> encodedById = const {},
}) async {
  final newPhotos = [
    for (final photo in input.photos)
      if (!photo.isExisting) photo,
  ];
  final existingCount = input.photos.length - newPhotos.length;
  var done = 0;
  // Existing photos skip convert (2 steps) and contribute 0 blobs.
  var total = newPhotos.length * 2 + existingCount;
  onProgress(
    UploadSubmitProgress(label: 'Converting', done: done, total: total),
  );

  final postFolder = newUploadId();
  final attempted = <String>[];
  try {
    final prepared = <PreparedPhoto>[];
    for (var index = 0; index < input.photos.length; index++) {
      final photo = input.photos[index];
      if (photo.isExisting) {
        prepared.add(
          PreparedPhoto(
            imagePath: photo.storageImagePath!,
            thumbPath: photo.storageThumbPath,
            blobs: const [],
          ),
        );
        done += 1;
        onProgress(
          UploadSubmitProgress(label: 'Converting', done: done, total: total),
        );
        continue;
      }

      final encoded = encodedById[photo.id];
      if (encoded != null) {
        prepared.add(
          preparedPhotoFromEncoded(
            encoded: encoded,
            userId: input.userId,
            postFolder: postFolder,
            index: index,
          ),
        );
        done += 2;
        onProgress(
          UploadSubmitProgress(label: 'Converting', done: done, total: total),
        );
        continue;
      }

      prepared.add(
        await prepareUploadPhoto(
          sourcePath: photo.path,
          mimeType: photo.mimeType,
          userId: input.userId,
          postFolder: postFolder,
          index: index,
          onStep: () {
            done += 1;
            onProgress(
              UploadSubmitProgress(
                label: 'Converting',
                done: done,
                total: total,
              ),
            );
          },
        ),
      );
    }

    final blobs = [for (final photo in prepared) ...photo.blobs];
    total = done + blobs.length + 1;
    onProgress(
      UploadSubmitProgress(label: 'Uploading', done: done, total: total),
    );

    await repository.uploadBlobs(
      blobs,
      onUploaded: (path) {
        attempted.add(path);
        done += 1;
        onProgress(
          UploadSubmitProgress(label: 'Uploading', done: done, total: total),
        );
      },
    );

    final editPostId = input.editPostId;
    if (editPostId != null) {
      await repository.updatePost(
        postId: editPostId,
        title: input.title,
        body: input.body.isEmpty ? null : input.body,
        photos: prepared,
        capturedAt: input.capturedAt,
        location: input.location,
        placeName: input.placeName,
        countryName: input.countryName,
        regionName: input.regionName,
        cityName: input.cityName,
        characterIds: input.characterIds,
      );
    } else {
      await repository.createPost(
        title: input.title,
        body: input.body.isEmpty ? null : input.body,
        photos: prepared,
        capturedAt: input.capturedAt,
        location: input.location,
        placeName: input.placeName,
        countryName: input.countryName,
        regionName: input.regionName,
        cityName: input.cityName,
        characterIds: input.characterIds,
      );
    }
    done += 1;
    onProgress(
      UploadSubmitProgress(label: 'Uploading', done: done, total: total),
    );
  } catch (_) {
    await _cleanup(repository, attempted);
    rethrow;
  }
}

Future<void> _cleanup(UploadRepository repository, List<String> paths) async {
  if (paths.isEmpty) return;
  try {
    await repository.deleteUploads(paths);
  } catch (_) {}
}
