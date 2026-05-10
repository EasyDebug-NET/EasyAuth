import 'package:flutter/material.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

import 'models/setting.dart';
import 'screens/about_screen.dart';
import 'screens/add_manual_2fa_screen.dart';
import 'screens/add_scan_2fa_screen.dart';
import 'screens/edit_2fa_screen.dart';
import 'screens/home_screen.dart';
import 'screens/import_export_screen.dart';
import 'screens/setting_screen.dart';
import 'services/backup_service.dart';

/// 全局路由观察者
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// 应用入口函数
void main() {
  runApp(const MyApp());
}

/// 应用主类
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// 应用主类状态
class _MyAppState extends State<MyApp> {
  late Setting _setting;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载应用设置
  ///
  /// 执行步骤：
  /// 1. 从安全存储中加载设置配置
  /// 2. 初始化时设置截屏锁状态
  /// 3. 如果加载失败，使用默认配置
  Future<void> _loadSettings() async {
    final backupService = BackupService();
    try {
      _setting = await backupService.loadConfig();
      // 初始化时设置截屏锁状态
      await _updateScreenshotLock();
    } catch (e) {
      _setting = Setting(
        backupSetting: BackupSetting(
          type: BackupType.off,
          webDavConfig: const WebDavConfig(
            url: '',
            backupDir: '',
            username: '',
            password: '',
          ),
          s3Config: const S3Config(
            endpoint: '',
            accessKeyId: '',
            secretAccessKey: '',
            bucketName: '',
          ),
        ),
        securitySetting: const SecuritySetting(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 依赖变化时更新截屏锁状态
    _updateScreenshotLock();
  }

  /// 更新截屏锁状态
  Future<void> _updateScreenshotLock() async {
    if (_setting.securitySetting.screenshotLockEnabled) {
      // 防止截屏
      await _setSecureWindow(true);
    } else {
      // 允许截屏
      await _setSecureWindow(false);
    }
  }

  /// 设置窗口是否安全（防止截屏）
  Future<void> _setSecureWindow(bool secure) async {
    try {
      if (secure) {
        // 防止截屏
        await FlutterWindowManagerPlus.addFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
      } else {
        // 允许截屏
        await FlutterWindowManagerPlus.clearFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
      }
    } catch (e) {
      debugPrint('设置安全窗口失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyAuth',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Colors.blueAccent,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            )
          : const HomeScreen(),
      routes: {
        '/addScan': (context) => const AddScan2FaScreen(),
        '/addManual': (context) => const AddManual2FaScreen(),
        '/edit': (context) => const Edit2FaScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/importExport': (context) => const ImportExportScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}
