import 'dart:math' as math;
import 'dart:typed_data';

import '../../../core/services/fumo_client_error.dart';
import '../upload_model.dart';
import 'upload_content_type.dart';
import 'upload_image_codec.dart';
import 'upload_webp_convert.dart';
import 'upload_webp_util.dart';

Future<({Uint8List bytes, String type, String ext})> encodeUploadOriginal(
  Uint8List bytes,
  String type,
) async {
  final watch = Stopwatch()..start();
  if (type == 'image/webp' || type == 'image/gif' || type == 'image/avif') {
    logWebpConversion(
      'original',
      bytes.length,
      bytes.length,
      'skipped',
      watch.elapsed,
    );
    return (bytes: bytes, type: type, ext: extForContentType(type));
  }
  if (type == 'image/jpeg' || type == 'image/png') {
    final webp = await convertToWebp(
      bytes,
      '.${extForContentType(type)}',
      webpQualityFor(bytes.length),
      longest: originalLongest,
    );
    if (webp != null && webp.length < bytes.length && webp.isNotEmpty) {
      assertPhotoSize(webp);
      logWebpConversion(
        'original',
        bytes.length,
        webp.length,
        'converted',
        watch.elapsed,
      );
      return (bytes: webp, type: 'image/webp', ext: 'webp');
    }
    logWebpConversion(
      'original',
      bytes.length,
      webp?.length,
      webp == null ? 'failed' : 'kept',
      watch.elapsed,
    );
    return (bytes: bytes, type: type, ext: extForContentType(type));
  }
  final direct = await convertToWebp(
    bytes,
    '.jpg',
    webpQualityFor(bytes.length),
    longest: originalLongest,
  );
  if (direct != null && direct.isNotEmpty) {
    assertPhotoSize(direct);
    logWebpConversion(
      'original',
      bytes.length,
      direct.length,
      'converted',
      watch.elapsed,
    );
    return (bytes: direct, type: 'image/webp', ext: 'webp');
  }
  final png = await pngAtLongest(bytes, longest: originalLongest);
  if (png == null) {
    logWebpConversion('original', bytes.length, null, 'failed', watch.elapsed);
    throw const FumoClientError('This photo format is not supported.');
  }
  final webp = await convertToWebp(png, '.png', webpQualityFor(png.length));
  if (webp != null && webp.isNotEmpty) {
    assertPhotoSize(webp);
    logWebpConversion(
      'original',
      bytes.length,
      webp.length,
      'converted',
      watch.elapsed,
    );
    return (bytes: webp, type: 'image/webp', ext: 'webp');
  }
  logWebpConversion(
    'original',
    png.length,
    webp?.length,
    'kept',
    watch.elapsed,
  );
  assertPhotoSize(png);
  return (bytes: png, type: 'image/png', ext: 'png');
}

Future<Uint8List?> encodeUploadThumb(
  Uint8List bytes, {
  required int sourceBytes,
}) async {
  final watch = Stopwatch()..start();
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
      logWebpConversion(
        'thumb',
        sourceBytes,
        webp?.length,
        'skipped',
        watch.elapsed,
      );
      return null;
    }
    logWebpConversion(
      'thumb',
      sourceBytes,
      webp.length,
      'converted',
      watch.elapsed,
    );
    return webp;
  } catch (_) {
    logWebpConversion('thumb', sourceBytes, null, 'failed', watch.elapsed);
    return null;
  }
}
