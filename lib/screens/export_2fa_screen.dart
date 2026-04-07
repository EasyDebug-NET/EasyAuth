import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../models/two_factor_account.dart';
import '../services/storage_service.dart';
import '../utils/qr_utils.dart';
import '../utils/style_utils.dart';

/// 导出验证码页面
class Export2FaScreen extends StatefulWidget {
  const Export2FaScreen({super.key});

  @override
  State<Export2FaScreen> createState() => _Export2FaScreenState();
}

class _Export2FaScreenState extends State<Export2FaScreen> {
  /// 数据库存储服务
  final StorageService _storageService = StorageService();

  /// 所有账户列表
  List<TwoFactorAccount> _accounts = [];

  /// 每个账户是否被选中
  List<bool> _selectedAccounts = [];

  /// 生成的二维码数据
  String? _qrcodeData;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  /// 从数据库加载所有账户
  Future<void> _loadAccounts() async {
    final accounts = await _storageService.getAllAccounts();
    setState(() {
      _accounts = accounts;
      _selectedAccounts = List.filled(accounts.length, true);
    });
  }

  /// 根据选中的账户生成二维码数据
  void _generateQrcode() {
    try {
      final selectedAccounts = _accounts.where((account) {
        final index = _accounts.indexOf(account);
        return _selectedAccounts[index];
      }).toList();

      if (selectedAccounts.isEmpty) {
        StyleUtils.errorSnackBar(context, '请至少选择一个验证码');
        return;
      }

      final migrationData = _generateMigrationData(selectedAccounts);
      setState(() {
        _qrcodeData = migrationData;
      });
    } catch (e) {
      StyleUtils.errorSnackBar(context, '生成二维码时出错');
    }
  }

  /// 生成 otpauth-migration://offline 格式的迁移数据
  ///
  /// 将选中的账户信息序列化为 JSON，再进行 base64Url 编码。
  String _generateMigrationData(List<TwoFactorAccount> accounts) {
    try {
      final otps = accounts
          .map((account) {
            try {
              // name 字段格式: issuer:name (Google Authenticator 标准格式)
              final issuer = account.issuer ?? '';
              final name = account.name ?? '';
              final fullName = issuer.isNotEmpty && name.isNotEmpty
                  ? '$issuer:$name'
                  : (name.isNotEmpty ? name : issuer);

              return {
                'type': 'totp',
                'name': fullName,
                'secret': account.secret,
                'issuer': issuer,
                'algorithm': account.algorithm,
                'digits': 6,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导出验证码')),
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
                      child: const Text('导出'),
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
                      const Text(
                        '请使用另一台设备扫描此二维码',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const _QrCodeWidget({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);

    return CustomPaint(
      size: Size(size, size),
      painter: _QrPainter(qrImage: qrImage),
    );
  }
}

class _QrPainter extends CustomPainter {
  final QrImage qrImage;

  _QrPainter({required this.qrImage});

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

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.qrImage != qrImage;
  }
}
