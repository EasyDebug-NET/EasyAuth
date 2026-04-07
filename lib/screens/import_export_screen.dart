import 'package:flutter/material.dart';

import '../utils/style_utils.dart';
import 'export_2fa_screen.dart';
import 'import_2fa_screen.dart';

/// 导入导出页面
class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入/导出')),
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
              Text('导入/导出', style: StyleUtils.titleTextStyle(context)),
              StyleUtils.mediumSpacing,
              // 说明文字
              Text(
                '您可以将自己的验证码转移到新设备中\n支持Google Authenticator的转移验证码',
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
                  child: const Text('导出验证码'),
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
                  child: const Text('导入验证码'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
