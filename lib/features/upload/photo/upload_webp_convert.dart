import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_to_webp/image_to_webp.dart';

import 'upload_image_codec.dart';
import 'upload_webp_util.dart';

bool get useNativeWebpEncoder => Platform.isIOS || Platform.isAndroid;

Future<Uint8List?> convertToWebp(
  Uint8List bytes,
  String extension,
  int quality, {
  int? longest,
}) async {
  if (!useNativeWebpEncoder) {
    return encodeWebpWithCli(bytes, extension, quality);
  }
  if (longest != null) {
    final size = await imageSize(bytes);
    final edge = size == null ? 0 : math.max(size.width, size.height);
    if (edge > preScaleEdge && edge > longest) {
      final png = await pngAtLongest(bytes, longest: longest);
      if (png != null) return encodeWebpNative(png, quality: quality);
    }
  }
  return encodeWebpNative(bytes, quality: quality, longest: longest);
}

Future<Uint8List?> encodeWebpNative(
  Uint8List bytes, {
  required int quality,
  int? longest,
}) async {
  try {
    final size = await imageSize(bytes);
    final target = targetSize(size, longest);
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

Future<Uint8List?> encodeWebpWithCli(
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
