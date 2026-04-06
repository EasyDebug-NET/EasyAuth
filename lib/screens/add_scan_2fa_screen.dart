import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/two_factor_account.dart';
import '../services/storage_service.dart';
import '../services/totp_service.dart';

/// 扫描二维码添加2FA账户页面
class AddScan2FaScreen extends StatefulWidget {
  const AddScan2FaScreen({super.key});

  @override
  State<AddScan2FaScreen> createState() => _AddScan2FaScreenState();
}

/// 扫描二维码添加2FA账户页面状态
class _AddScan2FaScreenState extends State<AddScan2FaScreen>
    with WidgetsBindingObserver {
  /// 是否正在扫描
  bool _isScanning = true;

  /// 数据库服务
  final StorageService _storageService = StorageService();

  /// 扫描控制器
  final MobileScannerController _controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        _isScanning = true;
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (_isScanning && barcode.rawValue != null) {
                  _isScanning = false;
                  _controller.stop();
                  _processScannedData(barcode.rawValue!);
                }
              }
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '扫描二维码',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      onPressed: () async {
                        await _controller.toggleTorch();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor, width: 4),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '将二维码放入框内即可自动扫描',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理扫描到的数据
  Future<void> _processScannedData(String data) async {
    try {
      // 验证二维码格式
      if (!data.startsWith('otpauth://')) {
        throw FormatException('二维码格式错误，必须是 otpauth:// 格式的URI');
      }

      final params = TotpService.parseOtpAuthUri(data);

      // 验证必要参数
      final secret = params['secret'] as String;
      if (secret.isEmpty) {
        throw FormatException('二维码缺少必要的密钥信息（secret）');
      }

      // 验证密钥格式（Base32）
      if (!_isValidBase32(secret)) {
        throw FormatException('密钥格式无效，必须是Base32编码');
      }

      // 转换secret为大写，确保Base32编码格式正确
      final normalizedSecret = secret.toUpperCase();

      final account = TwoFactorAccount.name(
        '',
        params['issuer'] as String?,
        params['name'] as String?,
        normalizedSecret,
        params['period'] as int,
        params['algorithm'] as String,
        DateTime.now(),
        DateTime.now(),
      );

      await _storageService.insertAccount(account);

      if (mounted) {
        Navigator.pop(context, true);
        // 优化SnackBar样式，使用floating行为提升用户体验
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('添加成功'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FormatException catch (e) {
      // 格式错误，显示详细的错误信息
      _showErrorDialog('二维码格式错误', e.message);
    } catch (e) {
      // 其他错误
      String errorMessage = '无法识别此二维码';
      if (e.toString().contains('Only TOTP is supported')) {
        errorMessage = '仅支持TOTP类型的验证码，不支持HOTP';
      }
      _showErrorDialog('扫描失败', errorMessage);
    }
  }

  /// 验证字符串是否为有效的Base32编码
  bool _isValidBase32(String input) {
    // Base32字符集：A-Z, 2-7
    final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
    return base32Regex.hasMatch(input.toUpperCase());
  }

  /// 显示错误对话框
  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _controller.start();
                _isScanning = true;
              },
              child: const Text('重试'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }
}
