import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/two_factor_account.dart';
import '../services/storage_service.dart';
import '../services/otp_service.dart';
import '../utils/exceptions.dart';
import '../utils/style_utils.dart';

/// 扫描二维码添加2FA动态口令页面
class AddScan2FaScreen extends StatefulWidget {
  const AddScan2FaScreen({super.key});

  @override
  State<AddScan2FaScreen> createState() => _AddScan2FaScreenState();
}

class _AddScan2FaScreenState extends State<AddScan2FaScreen>
    with WidgetsBindingObserver {
  /// 是否正在扫描中（防止重复扫描）
  bool _isScanning = true;

  /// 数据库存储服务
  final StorageService _storageService = StorageService();

  /// 摄像头扫描控制器
  final MobileScannerController _controller = MobileScannerController();

  /// 注册生命周期监听，用于前后台切换时控制摄像头
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// 释放摄像头资源和生命周期监听
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// 前后台切换时控制摄像头：前台启动，后台停止
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

  /// 构建摄像头扫描界面：扫描框 + 提示文字 + 返回/闪光灯按钮
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
                    const Expanded(
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
          const Positioned(
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

  /// 处理扫描到的 otpauth:// 二维码数据，解析并存入数据库
  Future<void> _processScannedData(String data) async {
    try {
      if (!data.startsWith('otpauth://')) {
        throw ValidationException('二维码格式错误，必须是 otpauth:// 格式的URI');
      }

      final params = OtpService.parseOtpAuthUri(data);

      final secret = params['secret'] as String;
      if (secret.isEmpty) {
        throw ValidationException('二维码缺少必要的密钥信息（secret）');
      }

      if (!_isValidBase32(secret)) {
        throw ValidationException('密钥格式无效，必须是Base32编码');
      }

      // 转换 secret 为大写，确保 Base32 编码格式正确
      final normalizedSecret = secret.toUpperCase();

      final account = TwoFactorAccount(
        '',
        params['issuer'] as String?,
        params['name'] as String?,
        normalizedSecret,
        params['period'] as int,
        params['algorithm'] as String,
        DateTime.now(),
        DateTime.now(),
        type: params['type'] as String? ?? 'totp',
        counter: params['counter'] as int? ?? 0,
      );

      await _storageService.insertAccount(account);

      if (mounted) {
        Navigator.pop(context, true);
        StyleUtils.successSnackBar(context, '添加成功');
      }
    } on ValidationException catch (e) {
      _showErrorDialog('二维码格式错误', e.message);
    } catch (e) {
      String errorMessage = '无法识别此二维码';
      if (e.toString().contains('Only TOTP is supported')) {
        errorMessage = '仅支持TOTP类型的动态口令，不支持HOTP';
      }
      _showErrorDialog('扫描失败', errorMessage);
    }
  }

  /// 验证字符串是否为有效的 Base32 编码（A-Z, 2-7）
  bool _isValidBase32(String input) {
    final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
    return base32Regex.hasMatch(input.toUpperCase());
  }

  /// 显示扫描错误对话框，提供重试和取消选项
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
