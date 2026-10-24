import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';

import '../services/fumo_store.dart';
import 'app_language.dart';

class LocaleController extends ChangeNotifier {
  LocaleController({FumoStore? store})
    : _store = store ?? GetIt.instance<FumoStore>();

  static const _key = 'app_language';

  final FumoStore _store;

  AppLanguage language = AppLanguage.en;
  bool ready = false;

  Locale get locale => language.locale;

  Future<void> init() async {
    final raw = await _store.read(key: _key);
    if (raw != null && raw.isNotEmpty) {
      language = AppLanguage.fromCode(raw);
    } else {
      language = AppLanguage.fromCode(
        PlatformDispatcher.instance.locale.languageCode,
      );
    }
    ready = true;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage next) async {
    if (language == next) {
      return;
    }
    language = next;
    notifyListeners();
    await _store.write(key: _key, value: next.code);
  }
}
