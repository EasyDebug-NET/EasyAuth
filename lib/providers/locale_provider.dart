import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/storage_service.dart';

/// Locale provider.
///
/// On first launch the system language is detected and saved to settings.
/// The user can override it manually at any time. On subsequent launches
/// the saved language is always used.
class LocaleProvider extends ChangeNotifier {
  static const String _languageCodeKey = 'language_code';

  final FlutterSecureStorage _secureStorage = sharedSecureStorage;

  Locale _currentLocale = const Locale('en');

  /// Current locale.
  Locale get currentLocale => _currentLocale;

  /// Supported locales.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// Native display name for a locale (always in that locale's own language).
  static String getLocaleNativeName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return locale.scriptCode == 'Hant' ? '繁體中文' : '简体中文';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return 'English';
    }
  }

  /// Check whether two locales represent the same language.
  static bool localeEquals(Locale a, Locale b) {
    return a.languageCode == b.languageCode && a.scriptCode == b.scriptCode;
  }

  /// Load locale on startup.
  ///
  /// If a language was previously saved use it; otherwise detect the system
  /// language, save it, and use it.
  Future<void> loadLocale() async {
    final saved = await _secureStorage.read(key: _languageCodeKey);
    if (saved != null && saved.isNotEmpty) {
      _currentLocale = _parseLocale(saved);
    } else {
      _currentLocale = _detectSystemLocale();
      await _secureStorage.write(
        key: _languageCodeKey,
        value: _localeToString(_currentLocale),
      );
    }
    notifyListeners();
  }

  /// Manually set the locale (persisted immediately).
  Future<void> setLocale(Locale locale) async {
    if (localeEquals(_currentLocale, locale)) return;
    _currentLocale = locale;
    await _secureStorage.write(
      key: _languageCodeKey,
      value: _localeToString(locale),
    );
    notifyListeners();
  }

  /// Parse a stored language tag into a Locale.
  Locale _parseLocale(String tag) {
    switch (tag) {
      case 'zh-Hans':
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
      case 'zh-Hant':
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      case 'zh':
        return const Locale('zh');
      case 'ja':
        return const Locale('ja');
      case 'ko':
        return const Locale('ko');
      case 'en':
      default:
        return const Locale('en');
    }
  }

  /// Convert a Locale to a storage string.
  String _localeToString(Locale locale) {
    if (locale.languageCode == 'zh') {
      if (locale.scriptCode == 'Hant') return 'zh-Hant';
      if (locale.scriptCode == 'Hans') return 'zh-Hans';
      return 'zh';
    }
    return locale.languageCode;
  }

  /// Detect the best locale from system preferences.
  Locale _detectSystemLocale() {
    final systemLocale = PlatformDispatcher.instance.locale;

    if (systemLocale.languageCode == 'zh') {
      final scriptCode = systemLocale.scriptCode;
      final countryCode = systemLocale.countryCode;

      if (scriptCode == 'Hant' ||
          countryCode == 'TW' ||
          countryCode == 'HK' ||
          countryCode == 'MO') {
        return const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        );
      }

      // Also check all preferred locales for a Traditional variant.
      for (final locale in PlatformDispatcher.instance.locales) {
        if (locale.languageCode == 'zh') {
          if (locale.scriptCode == 'Hant' ||
              locale.countryCode == 'TW' ||
              locale.countryCode == 'HK' ||
              locale.countryCode == 'MO') {
            return const Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hant',
            );
          }
        }
      }

      return const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
      );
    }

    // Non-Chinese system — default to English.
    return const Locale('en');
  }
}
