import 'package:flutter/foundation.dart';

import '../../../core/services/fumo_client_error.dart';
import '../upload_model.dart';

const originalLongest = 2048;
const thumbLongest = 720;
const preScaleEdge = 2560;

void assertPhotoSize(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > maxPhotoBytes) {
    throw const FumoClientError('Photo is empty or larger than 25 MB.');
  }
}

int webpQualityFor(int bytes) {
  if (bytes >= 12 * 1024 * 1024) return 68;
  if (bytes >= 8 * 1024 * 1024) return 72;
  if (bytes >= 4 * 1024 * 1024) return 76;
  if (bytes >= 2 * 1024 * 1024) return 80;
  return 84;
}

void logWebpConversion(
  String kind,
  int before,
  int? after,
  String status,
  Duration elapsed,
) {
  final output = after == null ? 'n/a' : formatByteSize(after);
  debugPrint(
    'webp $kind: ${formatByteSize(before)} -> $output ($status, ${elapsed.inMilliseconds} ms)',
  );
}

String formatByteSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '$bytes B (${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB)';
  }
  if (bytes >= 1024) {
    return '$bytes B (${(bytes / 1024).toStringAsFixed(1)} KB)';
  }
  return '$bytes B';
}
