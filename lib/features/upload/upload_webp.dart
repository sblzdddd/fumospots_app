import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_to_webp/image_to_webp.dart';

import '../../core/services/fumo_client_error.dart';
import 'upload_model.dart';

Future<PreparedPhoto> prepareUploadPhoto({
  required String sourcePath,
  required String? mimeType,
  required String userId,
  required String postFolder,
  required int index,
}) async {
  final bytes = await File(sourcePath).readAsBytes();
  final type = contentTypeFor(sourcePath, mimeType);
  if (type == null) {
    throw const FumoClientError('Use a JPEG, PNG, WebP, GIF, or AVIF photo.');
  }
  _assertSize(bytes);
  final original = await _encodeOriginal(bytes, type);
  final thumb = await _encodeThumb(bytes);
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
  if (type == 'image/webp' || type == 'image/gif' || type == 'image/avif') {
    return (bytes: bytes, type: type, ext: _extFor(type));
  }
  if (type == 'image/jpeg' || type == 'image/png') {
    final webp = await _toWebp(
      bytes,
      '.${_extFor(type)}',
      _quality(bytes.length),
    );
    if (webp != null && webp.length < bytes.length && webp.isNotEmpty) {
      _assertSize(webp);
      return (bytes: webp, type: 'image/webp', ext: 'webp');
    }
    return (bytes: bytes, type: type, ext: _extFor(type));
  }
  final png = await _png(bytes, longest: 4096);
  if (png == null) {
    throw const FumoClientError('This photo format is not supported.');
  }
  final webp = await _toWebp(png, '.png', _quality(png.length));
  if (webp != null && webp.isNotEmpty) {
    _assertSize(webp);
    return (bytes: webp, type: 'image/webp', ext: 'webp');
  }
  _assertSize(png);
  return (bytes: png, type: 'image/png', ext: 'png');
}

Future<Uint8List?> _encodeThumb(Uint8List bytes) async {
  try {
    final png = await _png(bytes, longest: 720);
    if (png == null) return null;
    final webp = await _toWebp(
      png,
      '.png',
      math.max(62, _quality(bytes.length) - 6),
    );
    if (webp == null || webp.isEmpty || webp.length > maxPhotoBytes) {
      return null;
    }
    return webp;
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _toWebp(
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
