import 'package:flutter/material.dart';

import 'screens/add_manual_2fa_screen.dart';
import 'screens/add_scan_2fa_screen.dart';
import 'screens/edit_2fa_screen.dart';
import 'screens/home_screen.dart';
import 'screens/import_export_screen.dart';
import 'screens/settings_screen.dart';

/// 全局路由观察者
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const HomeScreen(),
      routes: {
        '/addScan': (context) => const AddScan2FaScreen(),
        '/addManual': (context) => const AddManual2FaScreen(),
        '/edit': (context) => const Edit2FaScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/importExport': (context) => const ImportExportScreen(),
      },
    );
  }
}
