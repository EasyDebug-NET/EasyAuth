import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../utils/style_utils.dart';

/// 关于页面
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      _packageInfo = null;
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle), centerTitle: true),
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
                    color: Theme.of(context).shadowColor.withAlpha(25),
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
                    l10n.versionLabel(_packageInfo?.version ?? l10n.statusUnknownVersion),
                    style: StyleUtils.subtitleTextStyle(context),
                  ),
            const SizedBox(height: 96),
            Text(
              l10n.copyrightNotice,
              style: StyleUtils.subtitleTextStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}
