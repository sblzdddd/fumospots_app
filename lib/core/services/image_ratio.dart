import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

const estimatedAspects = [0.75, 1.0, 1.25, 1.5];

double estimateAspect(int id) {
  return estimatedAspects[id.abs() % estimatedAspects.length];
}

double clampAspect(double aspect) {
  if (!aspect.isFinite || aspect <= 0) {
    return 1;
  }
  return aspect.clamp(0.7, 1.6);
}

double aspectFromSize(double width, double height) {
  if (width <= 0 || height <= 0) {
    return 1;
  }
  return clampAspect(height / width);
}

double heightForRatio({
  required double width,
  required double ratio,
  required double maxHeight,
}) {
  final height = width * ratio;
  if (!height.isFinite || height <= 0) {
    return maxHeight;
  }
  return height > maxHeight ? maxHeight : height;
}

/// Resolves an [ImageProvider] once and reports a clamped height/width ratio.
class ImageRatioResolver {
  ImageRatioResolver({
    required ImageProvider provider,
    required void Function(double ratio) onRatio,
    void Function()? onError,
  }) {
    _stream = provider.resolve(const ImageConfiguration());
    _listener = ImageStreamListener(
      (info, _) {
        final ratio = aspectFromSize(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        _clear();
        _runAfterBuild(() => onRatio(ratio));
      },
      onError: (_, _) {
        _clear();
        if (onError != null) {
          _runAfterBuild(onError);
        }
      },
    );
    _stream!.addListener(_listener!);
  }

  ImageStream? _stream;
  ImageStreamListener? _listener;

  void dispose() => _clear();

  void _clear() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
  }

  void _runAfterBuild(VoidCallback action) {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      action();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) => action());
  }
}
