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
  if (bytes >= 12 * 1024 * 1024) return 75;
  if (bytes >= 8 * 1024 * 1024) return 80;
  if (bytes >= 4 * 1024 * 1024) return 85;
  if (bytes >= 2 * 1024 * 1024) return 90;
  return 95;
}

void logWebpImage({
  required String sourcePath,
  required int before,
  required int originalBytes,
  required String originalStatus,
  required int? thumbBytes,
  required String thumbStatus,
}) {
  final name = sourcePath.split(RegExp(r'[\\/]')).last;
  final thumb = thumbBytes == null
      ? thumbStatus
      : '${formatByteSize(thumbBytes)} ($thumbStatus)';
  debugPrint(
    'webp $name: ${formatByteSize(before)} -> '
    'original ${formatByteSize(originalBytes)} ($originalStatus), thumb $thumb',
  );
}

void logWebpImageFailed(String sourcePath, String message) {
  final name = sourcePath.split(RegExp(r'[\\/]')).last;
  debugPrint('webp $name: failed ($message)');
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
