import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/fumo_store.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({FumoStore? store})
    : _store = store ?? GetIt.instance<FumoStore>();

  static const _key = 'theme_mode';

  final FumoStore _store;

  ThemeMode mode = ThemeMode.system;
  bool ready = false;

  Future<void> init() async {
    final raw = await _store.read(key: _key);
    mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    ready = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode next) async {
    if (mode == next) {
      return;
    }
    mode = next;
    notifyListeners();
    await _store.write(
      key: _key,
      value: switch (next) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}
