import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mime/mime.dart';

import '../../../core/services/fumo_client_error.dart';
import '../upload_model.dart';
import 'upload_image_codec.dart';
import 'upload_webp_convert.dart';
import 'upload_webp_util.dart';

Future<({Uint8List bytes, String type, String ext, String status})>
encodeUploadOriginal(Uint8List bytes, String type) async {
  final ext = extensionFromMime(type) ?? 'bin';
  if (type == 'image/webp' || type == 'image/gif' || type == 'image/avif') {
    return (bytes: bytes, type: type, ext: ext, status: 'skipped');
  }
  if (type == 'image/jpeg' || type == 'image/png') {
    final webp = await convertToWebp(
      bytes,
      '.$ext',
      webpQualityFor(bytes.length),
      longest: originalLongest,
    );
    if (webp != null && webp.length < bytes.length && webp.isNotEmpty) {
      assertPhotoSize(webp);
      return (
        bytes: webp,
        type: 'image/webp',
        ext: 'webp',
        status: 'converted',
      );
    }
    return (
      bytes: bytes,
      type: type,
      ext: ext,
      status: webp == null ? 'failed' : 'kept',
    );
  }
  final direct = await convertToWebp(
    bytes,
    '.jpg',
    webpQualityFor(bytes.length),
    longest: originalLongest,
  );
  if (direct != null && direct.isNotEmpty) {
    assertPhotoSize(direct);
    return (
      bytes: direct,
      type: 'image/webp',
      ext: 'webp',
      status: 'converted',
    );
  }
  final png = await pngAtLongest(bytes, longest: originalLongest);
  if (png == null) {
    throw const FumoClientError('This photo format is not supported.');
  }
  final webp = await convertToWebp(png, '.png', webpQualityFor(png.length));
  if (webp != null && webp.isNotEmpty) {
    assertPhotoSize(webp);
    return (bytes: webp, type: 'image/webp', ext: 'webp', status: 'converted');
  }
  assertPhotoSize(png);
  return (bytes: png, type: 'image/png', ext: 'png', status: 'kept');
}

Future<({Uint8List? bytes, String status})> encodeUploadThumb(
  Uint8List bytes, {
  required int sourceBytes,
}) async {
  try {
    final quality = math.max(62, webpQualityFor(sourceBytes) - 6);
    final Uint8List? webp;
    if (useNativeWebpEncoder) {
      webp = await convertToWebp(
        bytes,
        '.webp',
        quality,
        longest: thumbLongest,
      );
    } else {
      final png = await pngAtLongest(bytes, longest: thumbLongest);
      webp = png == null ? null : await encodeWebpWithCli(png, '.png', quality);
    }
    if (webp == null || webp.isEmpty || webp.length > maxPhotoBytes) {
      return (bytes: null, status: 'skipped');
    }
    return (bytes: webp, status: 'converted');
  } catch (_) {
    return (bytes: null, status: 'failed');
  }
}
