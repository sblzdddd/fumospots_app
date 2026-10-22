import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../upload_model.dart';

class PhotoIntakeResult {
  const PhotoIntakeResult({required this.accepted, this.error});

  final List<UploadPhoto> accepted;
  final String? error;
}

Future<PhotoIntakeResult> intakePickedPhotos({
  required List<XFile> files,
  required int currentCount,
  required int Function() nextId,
}) async {
  if (files.isEmpty) {
    return const PhotoIntakeResult(accepted: []);
  }

  final accepted = <UploadPhoto>[];
  var rejectedType = false;
  var rejectedSize = false;
  String? limitError;

  for (final file in files) {
    if (currentCount + accepted.length >= maxPostPhotos) {
      limitError = 'You can add up to $maxPostPhotos photos.';
      break;
    }
    final type = lookupMimeType(file.path) ?? file.mimeType;
    if (type == null || !uploadImageContentTypes.contains(type)) {
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
        id: '${nextId()}',
        name: file.name,
        path: file.path,
        mimeType: file.mimeType,
      ),
    );
  }

  return PhotoIntakeResult(
    accepted: accepted,
    error: limitError ??
        (rejectedType
            ? 'Use a JPEG, PNG, WebP, GIF, or AVIF photo.'
            : rejectedSize
            ? 'Photo is larger than 25 MB.'
            : null),
  );
}
