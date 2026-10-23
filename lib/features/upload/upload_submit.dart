import 'package:flutter/foundation.dart';

import '../../core/services/fumo_client_error.dart';
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
}) async {
  final newPhotos = [for (final photo in input.photos) if (!photo.isExisting) photo];
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

class BenchmarkResult {
  const BenchmarkResult({this.summary, this.error});

  final String? summary;
  final String? error;
}

Future<BenchmarkResult> benchmarkPhotoConversions(
  List<UploadPhoto> photos,
) async {
  final pending = [
    for (final photo in photos)
      if (!photo.isExisting) photo,
  ];
  if (pending.isEmpty) {
    return const BenchmarkResult(error: 'Add a new photo to time conversion.');
  }
  final watch = Stopwatch()..start();
  try {
    for (var i = 0; i < pending.length; i++) {
      final photo = pending[i];
      final step = Stopwatch()..start();
      await prepareUploadPhoto(
        sourcePath: photo.path,
        mimeType: photo.mimeType,
        userId: 'benchmark',
        postFolder: '00000000-0000-4000-8000-000000000000',
        index: i,
      );
      step.stop();
      debugPrint(
        'webp photo ${i + 1}/${pending.length}: ${step.elapsedMilliseconds} ms',
      );
    }
    watch.stop();
    final seconds = (watch.elapsedMilliseconds / 1000).toStringAsFixed(2);
    final summary = '${pending.length} photos in $seconds s';
    debugPrint('webp total: $summary');
    return BenchmarkResult(summary: summary);
  } on FumoClientError catch (error) {
    return BenchmarkResult(error: error.message);
  } catch (_) {
    return const BenchmarkResult(error: 'Conversion failed');
  }
}

Future<void> _cleanup(UploadRepository repository, List<String> paths) async {
  if (paths.isEmpty) return;
  try {
    await repository.deleteUploads(paths);
  } catch (_) {}
}
