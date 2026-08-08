import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../utils/style_utils.dart';

/// About page.
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
  static const _githubUrl = 'https://github.com/EasyDebug-NET/EasyAuth';
  static const _giteeUrl = 'https://gitee.com/EasyDebug-NET/EasyAuth';

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
    final l10n = AppLocalizations.of(context);
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

  Widget _buildLinkText(BuildContext context, String text, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(context, url),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle), centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  StyleUtils.mediumSpacing,
                  const Text(
                    '软件著作权登记号：2026SR0762825',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          // Repository buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildRepoButton(
                    icon: FontAwesomeIcons.github,
                    label: 'GitHub',
                    url: _githubUrl,
                    color: const Color(0xFF24292E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRepoButton(
                    icon: FontAwesomeIcons.gitee,
                    label: 'Gitee',
                    url: _giteeUrl,
                    color: const Color(0xFFC71D23),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.copyrightNotice,
            style: StyleUtils.subtitleTextStyle(context),
          ),
          const SizedBox(height: 12),
          _buildLinkText(context, l10n.privacyDisclaimer, _privacyUrl),
          const SizedBox(height: 4),
          _buildLinkText(context, l10n.thirdPartySoftwareLicenses, _thirdPartyUrl),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRepoButton({
    required FaIconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _launchUrl(context, url),
      icon: FaIcon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
