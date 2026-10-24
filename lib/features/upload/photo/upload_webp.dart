import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';

import '../../../core/services/fumo_client_error.dart';
import '../upload_model.dart';
import 'upload_webp_encode.dart';
import 'upload_webp_util.dart';

class EncodedUploadPhoto {
  const EncodedUploadPhoto({
    required this.bytes,
    required this.contentType,
    required this.extension,
    required this.thumbBytes,
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;
  final Uint8List? thumbBytes;
}

/// Reads and compresses a picked photo. [onProgress] reports checkpoints:
/// 0.15 once the file is read, 0.75 after the original, and 1 after the thumb.
Future<EncodedUploadPhoto> encodeUploadPhoto({
  required String sourcePath,
  required String? mimeType,
  void Function(double progress)? onProgress,
}) async {
  final bytes = await File(sourcePath).readAsBytes();
  final type = lookupMimeType(sourcePath) ?? mimeType;
  if (type == null || !uploadImageContentTypes.contains(type)) {
    throw const FumoClientError('Use a JPEG, PNG, WebP, GIF, or AVIF photo.');
  }
  assertPhotoSize(bytes);
  onProgress?.call(0.15);
  final ({Uint8List bytes, String type, String ext, String status}) original;
  final ({Uint8List? bytes, String status}) thumb;
  try {
    original = await encodeUploadOriginal(bytes, type);
    onProgress?.call(0.75);
    thumb = await encodeUploadThumb(original.bytes, sourceBytes: bytes.length);
  } on FumoClientError catch (error) {
    logWebpImageFailed(sourcePath, error.message);
    rethrow;
  } catch (_) {
    logWebpImageFailed(sourcePath, 'Conversion failed');
    rethrow;
  }
  onProgress?.call(1);
  logWebpImage(
    sourcePath: sourcePath,
    before: bytes.length,
    originalBytes: original.bytes.length,
    originalStatus: original.status,
    thumbBytes: thumb.bytes?.length,
    thumbStatus: thumb.status,
  );
  return EncodedUploadPhoto(
    bytes: original.bytes,
    contentType: original.type,
    extension: original.ext,
    thumbBytes: thumb.bytes,
  );
}

PreparedPhoto preparedPhotoFromEncoded({
  required EncodedUploadPhoto encoded,
  required String userId,
  required String postFolder,
  required int index,
}) {
  final folder = (index + 1).toString().padLeft(2, '0');
  final imagePath = '$userId/$postFolder/$folder/original.${encoded.extension}';
  final thumbPath = encoded.thumbBytes == null
      ? null
      : '$userId/$postFolder/$folder/thumb.webp';
  return PreparedPhoto(
    imagePath: imagePath,
    thumbPath: thumbPath,
    blobs: [
      UploadBlob(
        path: imagePath,
        contentType: encoded.contentType,
        bytes: encoded.bytes,
      ),
      if (encoded.thumbBytes != null && thumbPath != null)
        UploadBlob(
          path: thumbPath,
          contentType: 'image/webp',
          bytes: encoded.thumbBytes!,
        ),
    ],
  );
}

Future<PreparedPhoto> prepareUploadPhoto({
  required String sourcePath,
  required String? mimeType,
  required String userId,
  required String postFolder,
  required int index,
  void Function()? onStep,
}) async {
  var reportedOriginal = false;
  final encoded = await encodeUploadPhoto(
    sourcePath: sourcePath,
    mimeType: mimeType,
    onProgress: (progress) {
      if (onStep == null) return;
      if (!reportedOriginal && progress >= 0.75 && progress < 1) {
        reportedOriginal = true;
        onStep();
      } else if (progress >= 1) {
        onStep();
      }
    },
  );
  return preparedPhotoFromEncoded(
    encoded: encoded,
    userId: userId,
    postFolder: postFolder,
    index: index,
  );
}
