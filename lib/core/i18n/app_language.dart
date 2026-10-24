import 'package:material_ui/material_ui.dart';

import 'keys.dart';

enum AppLanguage {
  en(Locale('en'), S.languageEnglish),
  zh(Locale('zh'), S.languageChinese),
  ja(Locale('ja'), S.languageJapanese);

  const AppLanguage(this.locale, this.labelKey);

  final Locale locale;
  final String labelKey;

  String get code => locale.languageCode;

  static AppLanguage fromCode(String? raw) {
    return switch (raw) {
      'zh' => AppLanguage.zh,
      'ja' => AppLanguage.ja,
      _ => AppLanguage.en,
    };
  }

  static AppLanguage fromLocale(Locale locale) {
    return fromCode(locale.languageCode);
  }
}
