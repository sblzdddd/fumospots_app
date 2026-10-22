import 'dart:io';

import '../../../core/services/fumo_client_error.dart';
import '../upload_model.dart';
import 'upload_content_type.dart';
import 'upload_webp_encode.dart';
import 'upload_webp_util.dart';

export 'upload_content_type.dart' show contentTypeFor;

Future<PreparedPhoto> prepareUploadPhoto({
  required String sourcePath,
  required String? mimeType,
  required String userId,
  required String postFolder,
  required int index,
  void Function()? onStep,
}) async {
  final bytes = await File(sourcePath).readAsBytes();
  final type = contentTypeFor(sourcePath, mimeType);
  if (type == null) {
    throw const FumoClientError('Use a JPEG, PNG, WebP, GIF, or AVIF photo.');
  }
  assertPhotoSize(bytes);
  final original = await encodeUploadOriginal(bytes, type);
  onStep?.call();
  final thumb = await encodeUploadThumb(
    original.bytes,
    sourceBytes: bytes.length,
  );
  onStep?.call();
  final folder = (index + 1).toString().padLeft(2, '0');
  final imagePath = '$userId/$postFolder/$folder/original.${original.ext}';
  final thumbPath = thumb == null
      ? null
      : '$userId/$postFolder/$folder/thumb.webp';
  return PreparedPhoto(
    imagePath: imagePath,
    thumbPath: thumbPath,
    blobs: [
      UploadBlob(
        path: imagePath,
        contentType: original.type,
        bytes: original.bytes,
      ),
      if (thumb != null && thumbPath != null)
        UploadBlob(path: thumbPath, contentType: 'image/webp', bytes: thumb),
    ],
  );
}
