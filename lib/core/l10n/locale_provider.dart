import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_strings.dart';

/// Holds the active locale and exposes translation lookups.
class LocaleProvider extends ChangeNotifier {
  // Swahili by default, to match the reference mockups.
  Locale _locale = const Locale('sw');

  Locale get locale => _locale;
  bool get isSwahili => _locale.languageCode == 'sw';

  static const List<Locale> supportedLocales = [Locale('sw'), Locale('en')];

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void toggle() {
    setLocale(isSwahili ? const Locale('en') : const Locale('sw'));
  }

  /// Translate [key] using the active locale, falling back to English then the
  /// raw key so missing strings are obvious in the UI.
  String t(String key) {
    final lang = _locale.languageCode;
    return AppStrings.values[lang]?[key] ??
        AppStrings.values['en']?[key] ??
        key;
  }
}

/// Convenience extension: `context.t('key')` and `context.s` everywhere.
extension LocaleX on BuildContext {
  String t(String key) => read<LocaleProvider>().t(key);

  /// Watching variant — rebuilds widgets when the language changes.
  String tr(String key) => watch<LocaleProvider>().t(key);
}
