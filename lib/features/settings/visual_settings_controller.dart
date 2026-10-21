import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/fumo_store.dart';

class VisualSettingsController extends ChangeNotifier {
  VisualSettingsController({FumoStore? store})
    : _store = store ?? GetIt.instance<FumoStore>();

  static const _blurKey = 'visual_blur_enabled';

  final FumoStore _store;

  bool blurEnabled = true;
  bool ready = false;

  Future<void> init() async {
    final raw = await _store.read(key: _blurKey);
    blurEnabled = raw != '0';
    ready = true;
    notifyListeners();
  }

  Future<void> setBlurEnabled(bool enabled) async {
    if (blurEnabled == enabled) {
      return;
    }
    blurEnabled = enabled;
    notifyListeners();
    await _store.write(key: _blurKey, value: enabled ? '1' : '0');
  }
}
