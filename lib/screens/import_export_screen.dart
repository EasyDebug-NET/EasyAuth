import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/style_utils.dart';
import 'export_2fa_screen.dart';
import 'import_2fa_screen.dart';

/// 导入导出页面
class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importExportTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 双箭头图标
              Icon(
                Icons.swap_horiz,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              // 标题
              Text(l10n.importExportTitle, style: StyleUtils.titleTextStyle(context)),
              StyleUtils.mediumSpacing,
              // 说明文字
              Text(
                l10n.importExportDescription,
                textAlign: TextAlign.center,
                style: StyleUtils.subtitleTextStyle(context),
              ),
              StyleUtils.largeSpacing,
              // 导出按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Export2FaScreen(),
                      ),
                    );
                  },
                  style: StyleUtils.primaryButtonStyle(context),
                  child: Text(l10n.exportAccounts),
                ),
              ),
              StyleUtils.mediumSpacing,
              // 导入按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Import2FaScreen(),
                      ),
                    );
                  },
                  style: StyleUtils.primaryButtonStyle(context),
                  child: Text(l10n.importAccounts),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
