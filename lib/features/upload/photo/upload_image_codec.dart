import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

({int width, int height}) targetSize(
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

Future<({int width, int height})?> imageSize(Uint8List bytes) async {
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

Future<Uint8List?> pngAtLongest(Uint8List bytes, {required int longest}) async {
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
