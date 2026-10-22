import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_to_webp/image_to_webp.dart';

import '../../core/services/fumo_client_error.dart';
import 'upload_model.dart';

const _originalLongest = 2048;
const _thumbLongest = 720;
const _preScaleEdge = 2560;

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
  _assertSize(bytes);
  final original = await _encodeOriginal(bytes, type);
  onStep?.call();
  final thumb = await _encodeThumb(original.bytes, sourceBytes: bytes.length);
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

String? contentTypeFor(String path, String? mimeType) {
  switch (_extension(path)) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.avif':
      return 'image/avif';
    case '.heic':
    case '.heif':
      return 'image/heic';
  }
  switch (mimeType) {
    case 'image/jpeg':
    case 'image/png':
    case 'image/webp':
    case 'image/gif':
    case 'image/avif':
    case 'image/heic':
    case 'image/heif':
      return mimeType;
  }
  return null;
}

Future<({Uint8List bytes, String type, String ext})> _encodeOriginal(
  Uint8List bytes,
  String type,
) async {
  final watch = Stopwatch()..start();
  if (type == 'image/webp' || type == 'image/gif' || type == 'image/avif') {
    _logConversion(
      'original',
      bytes.length,
      bytes.length,
      'skipped',
      watch.elapsed,
    );
    return (bytes: bytes, type: type, ext: _extFor(type));
  }
  if (type == 'image/jpeg' || type == 'image/png') {
    final webp = await _convertWebp(
      bytes,
      '.${_extFor(type)}',
      _quality(bytes.length),
      longest: _originalLongest,
    );
    if (webp != null && webp.length < bytes.length && webp.isNotEmpty) {
      _assertSize(webp);
      _logConversion(
        'original',
        bytes.length,
        webp.length,
        'converted',
        watch.elapsed,
      );
      return (bytes: webp, type: 'image/webp', ext: 'webp');
    }
    _logConversion(
      'original',
      bytes.length,
      webp?.length,
      webp == null ? 'failed' : 'kept',
      watch.elapsed,
    );
    return (bytes: bytes, type: type, ext: _extFor(type));
  }
  final direct = await _convertWebp(
    bytes,
    '.jpg',
    _quality(bytes.length),
    longest: _originalLongest,
  );
  if (direct != null && direct.isNotEmpty) {
    _assertSize(direct);
    _logConversion(
      'original',
      bytes.length,
      direct.length,
      'converted',
      watch.elapsed,
    );
    return (bytes: direct, type: 'image/webp', ext: 'webp');
  }
  final png = await _png(bytes, longest: _originalLongest);
  if (png == null) {
    _logConversion('original', bytes.length, null, 'failed', watch.elapsed);
    throw const FumoClientError('This photo format is not supported.');
  }
  final webp = await _convertWebp(png, '.png', _quality(png.length));
  if (webp != null && webp.isNotEmpty) {
    _assertSize(webp);
    _logConversion(
      'original',
      bytes.length,
      webp.length,
      'converted',
      watch.elapsed,
    );
    return (bytes: webp, type: 'image/webp', ext: 'webp');
  }
  _logConversion('original', png.length, webp?.length, 'kept', watch.elapsed);
  _assertSize(png);
  return (bytes: png, type: 'image/png', ext: 'png');
}

Future<Uint8List?> _encodeThumb(
  Uint8List bytes, {
  required int sourceBytes,
}) async {
  final watch = Stopwatch()..start();
  try {
    final quality = math.max(62, _quality(sourceBytes) - 6);
    final Uint8List? webp;
    if (_useNativeEncoder) {
      webp = await _convertWebp(
        bytes,
        '.webp',
        quality,
        longest: _thumbLongest,
      );
    } else {
      final png = await _png(bytes, longest: _thumbLongest);
      webp = png == null ? null : await _cliWebp(png, '.png', quality);
    }
    if (webp == null || webp.isEmpty || webp.length > maxPhotoBytes) {
      _logConversion(
        'thumb',
        sourceBytes,
        webp?.length,
        'skipped',
        watch.elapsed,
      );
      return null;
    }
    _logConversion(
      'thumb',
      sourceBytes,
      webp.length,
      'converted',
      watch.elapsed,
    );
    return webp;
  } catch (_) {
    _logConversion('thumb', sourceBytes, null, 'failed', watch.elapsed);
    return null;
  }
}

void _logConversion(
  String kind,
  int before,
  int? after,
  String status,
  Duration elapsed,
) {
  final output = after == null ? 'n/a' : _formatSize(after);
  debugPrint(
    'webp $kind: ${_formatSize(before)} -> $output ($status, ${elapsed.inMilliseconds} ms)',
  );
}

String _formatSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '$bytes B (${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB)';
  }
  if (bytes >= 1024) {
    return '$bytes B (${(bytes / 1024).toStringAsFixed(1)} KB)';
  }
  return '$bytes B';
}

bool get _useNativeEncoder => Platform.isIOS || Platform.isAndroid;

Future<Uint8List?> _convertWebp(
  Uint8List bytes,
  String extension,
  int quality, {
  int? longest,
}) async {
  if (!_useNativeEncoder) {
    return _cliWebp(bytes, extension, quality);
  }
  if (longest != null) {
    final size = await _size(bytes);
    final edge = size == null ? 0 : math.max(size.width, size.height);
    if (edge > _preScaleEdge && edge > longest) {
      final png = await _png(bytes, longest: longest);
      if (png != null) return _nativeWebp(png, quality: quality);
    }
  }
  return _nativeWebp(bytes, quality: quality, longest: longest);
}

Future<Uint8List?> _nativeWebp(
  Uint8List bytes, {
  required int quality,
  int? longest,
}) async {
  try {
    final size = await _size(bytes);
    final target = _targetSize(size, longest);
    final webp = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: target.width,
      minHeight: target.height,
      quality: quality,
      format: CompressFormat.webp,
    );
    return webp.isEmpty ? null : webp;
  } catch (_) {
    return null;
  }
}

({int width, int height}) _targetSize(
  ({int width, int height})? size,
  int? longest,
) {
  if (size == null) {
    final edge = longest ?? 8192;
    return (width: edge, height: edge);
  }
  if (longest == null || math.max(size.width, size.height) <= longest) {
    return size;
  }
  final scale = longest / math.max(size.width, size.height);
  return (
    width: math.max(1, (size.width * scale).round()),
    height: math.max(1, (size.height * scale).round()),
  );
}

Future<({int width, int height})?> _size(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width < 1 || descriptor.height < 1) return null;
    return (width: descriptor.width, height: descriptor.height);
  } catch (_) {
    return null;
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

Future<Uint8List?> _cliWebp(
  Uint8List bytes,
  String extension,
  int quality,
) async {
  final dir = await Directory.systemTemp.createTemp('fumo-webp-');
  try {
    final input = File('${dir.path}/source$extension');
    await input.writeAsBytes(bytes, flush: true);
    final config = File('${dir.path}/webp.yaml');
    final folder = dir.path.replaceAll('\\', '/').replaceAll('"', r'\"');
    await config.writeAsString('paths:\n  - "$folder/*"\nquality: $quality\n');
    await runImageToWebp(
      ['--config', config.path],
      stdout: stdout,
      stderr: stderr,
    );
    final output = File('${dir.path}/source.webp');
    if (!output.existsSync()) return null;
    final webp = await output.readAsBytes();
    return webp.isEmpty ? null : webp;
  } catch (_) {
    return null;
  } finally {
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  }
}

Future<Uint8List?> _png(Uint8List bytes, {required int longest}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final width = descriptor.width;
    final height = descriptor.height;
    if (width < 1 || height < 1) return null;
    final scale = longest / math.max(width, height);
    final targetWidth = math.max(1, (width * math.min(1, scale)).round());
    codec = await descriptor.instantiateCodec(targetWidth: targetWidth);
    final frame = await codec.getNextFrame();
    image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return data.buffer.asUint8List();
  } catch (_) {
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}

void _assertSize(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > maxPhotoBytes) {
    throw const FumoClientError('Photo is empty or larger than 25 MB.');
  }
}

int _quality(int bytes) {
  if (bytes >= 12 * 1024 * 1024) return 68;
  if (bytes >= 8 * 1024 * 1024) return 72;
  if (bytes >= 4 * 1024 * 1024) return 76;
  if (bytes >= 2 * 1024 * 1024) return 80;
  return 84;
}

String _extFor(String type) {
  switch (type) {
    case 'image/jpeg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/gif':
      return 'gif';
    case 'image/avif':
      return 'avif';
    default:
      return 'webp';
  }
}

String _extension(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return '';
  return name.substring(dot).toLowerCase();
}
