import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/storage_service.dart';

/// 语言管理 Provider
///
/// 管理应用的当前语言设置，支持：
/// - 首次启动时根据系统语言自动选择
/// - 手动切换语言并持久化保存
/// - 通过 ChangeNotifier 通知 UI 刷新
class LocaleProvider extends ChangeNotifier {
  /// 存储键
  static const String _storageKey = 'language_code';

  /// 安全存储
  final FlutterSecureStorage _secureStorage = sharedSecureStorage;

  /// 当前语言
  Locale _currentLocale = const Locale('en');

  /// 获取当前语言
  Locale get currentLocale => _currentLocale;

  /// 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// 获取指定语言的原生名称（始终以该语言自身显示）
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

  /// 检查两个 Locale 是否代表相同的语言
  static bool localeEquals(Locale a, Locale b) {
    return a.languageCode == b.languageCode &&
        a.scriptCode == b.scriptCode;
  }

  /// 加载已保存的语言设置，如果没有则检测系统语言
  ///
  /// 首次启动时根据系统语言自动选择：
  /// - 繁体中文：脚本码为 Hant 或国家/地区为 TW/HK/MO
  /// - 简体中文：其他 zh 变体
  /// - 英语：非中文语言
  Future<void> loadLocale() async {
    final saved = await _secureStorage.read(key: _storageKey);
    if (saved != null && saved.isNotEmpty) {
      _currentLocale = _parseLocale(saved);
    } else {
      _currentLocale = _detectSystemLocale();
      // 首次启动时保存检测结果
      await _saveLocale(_currentLocale);
    }
    notifyListeners();
  }

  /// 切换语言
  Future<void> setLocale(Locale locale) async {
    if (localeEquals(_currentLocale, locale)) return;
    _currentLocale = locale;
    await _saveLocale(locale);
    notifyListeners();
  }

  /// 解析保存的语言字符串为 Locale
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

  /// 将 Locale 转换为存储字符串
  String _localeToString(Locale locale) {
    if (locale.languageCode == 'zh') {
      if (locale.scriptCode == 'Hant') return 'zh-Hant';
      if (locale.scriptCode == 'Hans') return 'zh-Hans';
      return 'zh';
    }
    return locale.languageCode;
  }

  /// 保存语言设置
  Future<void> _saveLocale(Locale locale) async {
    await _secureStorage.write(
      key: _storageKey,
      value: _localeToString(locale),
    );
  }

  /// 检测系统语言
  Locale _detectSystemLocale() {
    final systemLocale = PlatformDispatcher.instance.locale;

    // 检查系统语言是否为中文
    if (systemLocale.languageCode == 'zh') {
      // 检查是否为繁体中文
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

      // 遍历所有系统首选语言，查找繁体变体
      final systemLocales = PlatformDispatcher.instance.locales;
      for (final locale in systemLocales) {
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

      // 默认为简体中文
      return const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
      );
    }

    // 非中文，默认英语
    return const Locale('en');
  }
}
