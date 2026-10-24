import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/fumo_store.dart';

enum HomeStartPage { posts, map }

class VisualSettingsController extends ChangeNotifier {
  VisualSettingsController({FumoStore? store})
    : _store = store ?? GetIt.instance<FumoStore>();

  static const _blurKey = 'visual_blur_enabled';
  static const _startKey = 'home_start_page';

  final FumoStore _store;

  bool blurEnabled = true;
  HomeStartPage startPage = HomeStartPage.posts;
  bool ready = false;

  Future<void> init() async {
    final raw = await _store.read(key: _blurKey);
    blurEnabled = raw != '0';
    final start = await _store.read(key: _startKey);
    startPage = start == 'map' ? HomeStartPage.map : HomeStartPage.posts;
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

  Future<void> setStartPage(HomeStartPage page) async {
    if (startPage == page) {
      return;
    }
    startPage = page;
    notifyListeners();
    await _store.write(
      key: _startKey,
      value: page == HomeStartPage.map ? 'map' : 'posts',
    );
  }
}
