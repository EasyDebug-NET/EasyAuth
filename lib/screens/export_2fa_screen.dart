import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../l10n/app_localizations.dart';
import '../models/two_factor_account.dart';
import '../services/storage_service.dart';
import '../utils/qr_utils.dart';
import '../utils/style_utils.dart';

/// 导出动态口令页面
class Export2FaScreen extends StatefulWidget {
  const Export2FaScreen({super.key});

  @override
  State<Export2FaScreen> createState() => _Export2FaScreenState();
}

class _Export2FaScreenState extends State<Export2FaScreen> {
  /// 数据库存储服务
  final StorageService _storageService = StorageService();

  /// 所有动态口令列表
  List<TwoFactorAccount> _accounts = [];

  /// 每个动态口令的选中状态
  List<bool> _selectedAccounts = [];

  /// 生成的迁移二维码数据
  String? _qrcodeData;

  /// 加载动态口令列表，默认全部选中
  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  /// 从数据库加载所有动态口令，默认全部选中
  Future<void> _loadAccounts() async {
    try {
      final accounts = await _storageService.getAllAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _selectedAccounts = List.filled(accounts.length, true);
      });
    } catch (e) {
      if (mounted) {
        StyleUtils.errorSnackBar(context, AppLocalizations.of(context).snackLoadFailed(e.toString()));
      }
    }
  }

  /// 根据选中的动态口令生成迁移二维码数据
  void _generateQrcode() {
    final l10n = AppLocalizations.of(context);

    try {
      final selectedAccounts = _accounts.where((account) {
        final index = _accounts.indexOf(account);
        return _selectedAccounts[index];
      }).toList();

      if (selectedAccounts.isEmpty) {
        StyleUtils.errorSnackBar(context, l10n.snackSelectAtLeastOne);
        return;
      }

      final migrationData = _generateMigrationData(selectedAccounts);
      setState(() {
        _qrcodeData = migrationData;
      });
    } catch (e) {
      StyleUtils.errorSnackBar(context, l10n.snackQrCodeGenerateError);
    }
  }

  /// 生成 otpauth-migration://offline 格式的迁移数据
  ///
  /// 将选中的动态口令信息序列化为 JSON，再进行 base64Url 编码，
  /// 兼容 Google Authenticator 的迁移格式。
  String _generateMigrationData(List<TwoFactorAccount> accounts) {
    try {
      final otps = accounts
          .map((account) {
            try {
              final issuer = account.issuer ?? '';
              final name = account.name ?? '';
              final fullName = issuer.isNotEmpty && name.isNotEmpty
                  ? '$issuer:$name'
                  : (name.isNotEmpty ? name : issuer);

              return {
                'secret': account.secret,
                'name': fullName,
                'issuer': issuer,
                'algorithm': account.algorithm,
                'digits': 6,
                'type': account.type,
                'counter': account.counter,
                'period': account.period,
              };
            } catch (e) {
              return null;
            }
          })
          .where((item) => item != null)
          .toList();

      return QrUtils.generateMigrationData(otps.cast<Map<String, dynamic>>());
    } catch (e) {
      return QrUtils.generateMigrationData([]);
    }
  }

  /// 构建导出界面：动态口令选择列表 + 导出按钮，或二维码展示
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportTitle)),
      body: _qrcodeData == null
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      return CheckboxListTile(
                        value: _selectedAccounts[index],
                        onChanged: (value) {
                          setState(() {
                            _selectedAccounts[index] = value ?? false;
                          });
                        },
                        title: Text(
                          account.displayName,
                          style: StyleUtils.bodyTextStyle(context),
                        ),
                        subtitle: Text(
                          account.issuer ?? '',
                          style: StyleUtils.subtitleTextStyle(context),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generateQrcode,
                      style: StyleUtils.primaryButtonStyle(context),
                      child: Text(l10n.buttonExport),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _QrCodeWidget(data: _qrcodeData!, size: 260),
                      const SizedBox(height: 24),
                      Text(
                        l10n.exportScanPrompt,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// 二维码渲染组件
class _QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const _QrCodeWidget({required this.data, required this.size});

  /// 使用 CustomPaint 绘制二维码
  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode(
      payload: QrPayload.fromString(data),
      errorCorrectLevel: QrErrorCorrectLevel.medium,
    );
    final qrImage = QrImage(qrCode);

    return CustomPaint(
      size: Size(size, size),
      painter: _QrPainter(qrImage: qrImage),
    );
  }
}

/// 二维码绘制器，逐个模块绘制黑块
class _QrPainter extends CustomPainter {
  final QrImage qrImage;

  _QrPainter({required this.qrImage});

  /// 遍历二维码矩阵，逐个绘制黑色模块
  @override
  void paint(Canvas canvas, Size size) {
    final moduleCount = qrImage.moduleCount;
    final moduleSize = size.width / moduleCount;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF000000);

    for (int x = 0; x < moduleCount; x++) {
      for (int y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * moduleSize,
              y * moduleSize,
              moduleSize,
              moduleSize,
            ),
            paint,
          );
        }
      }
    }
  }

  /// 仅在二维码数据变化时重绘
  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.qrImage != qrImage;
  }
}
