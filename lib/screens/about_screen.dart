import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/style_utils.dart';

/// 关于页面
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late PackageInfo _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('关于'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
              ),
            ),
            StyleUtils.largeSpacing,
            Text('EasyAuth', style: StyleUtils.titleTextStyle(context)),
            StyleUtils.smallSpacing,
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    '版本 ${_packageInfo.version}',
                    style: StyleUtils.subtitleTextStyle(context),
                  ),
            const SizedBox(height: 96),
            Text(
              '2016-2026 EasyDebug.NET All rights reserved.',
              style: StyleUtils.subtitleTextStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}
