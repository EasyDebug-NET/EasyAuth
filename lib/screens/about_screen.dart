import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const _privacyUrl = 'https://easyauth.easydebug.net/privacy';
  static const _thirdPartyUrl = 'https://easyauth.easydebug.net/third-party';

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

  Future<void> _launchUrl(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCannotOpenUrl),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLinkButton(BuildContext context, String text, String url) {
    return TextButton(
      onPressed: () => _launchUrl(context, url),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
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
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
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
            const SizedBox(height: 8),
            const Text(
              '软件著作权登记号：2026SR0762825',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 80),
            Text(
              l10n.copyrightNotice,
              style: StyleUtils.subtitleTextStyle(context),
            ),
            const SizedBox(height: 24),
            _buildLinkButton(context, l10n.privacyDisclaimer, _privacyUrl),
            _buildLinkButton(context, l10n.thirdPartySoftwareLicenses, _thirdPartyUrl),
          ],
        ),
      ),
    );
  }
}
