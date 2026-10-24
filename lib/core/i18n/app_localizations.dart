import 'package:material_ui/material_ui.dart';

import 'app_language.dart';
import 'translations/en.dart';
import 'translations/ja.dart';
import 'translations/zh.dart';

class AppLocalizations {
  AppLocalizations(this.language);

  final AppLanguage language;

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations not found in context');
    return value!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('zh'),
    Locale('ja'),
  ];

  Map<String, String> get _map => switch (language) {
    AppLanguage.en => enStrings,
    AppLanguage.zh => zhStrings,
    AppLanguage.ja => jaStrings,
  };

  /// Looks up [key]. Unknown keys (e.g. API error text) are returned as-is.
  String t(String key, {Map<String, String>? params}) {
    var value = _map[key] ?? enStrings[key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }
    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLanguage.values.any((lang) => lang.code == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(AppLanguage.fromLocale(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String t(String key, {Map<String, String>? params}) =>
      l10n.t(key, params: params);
}
