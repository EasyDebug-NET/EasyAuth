import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/two_factor_account.dart';
import '../services/storage_service.dart';
import '../utils/qr_utils.dart';
import '../utils/style_utils.dart';

/// 导入动态口令页面
class Import2FaScreen extends StatefulWidget {
  const Import2FaScreen({super.key});

  @override
  State<Import2FaScreen> createState() => _Import2FaScreenState();
}

class _Import2FaScreenState extends State<Import2FaScreen> {
  /// 数据库存储服务
  final StorageService _storageService = StorageService();

  /// 二维码扫描控制器
  final MobileScannerController _controller = MobileScannerController();

  /// 是否已扫描到二维码（防止重复处理）
  bool _scanned = false;

  /// 解析后的待导入动态口令列表
  List<Map<String, dynamic>> _importedAccounts = [];

  /// 用户勾选要导入的动态口令列表
  List<Map<String, dynamic>> _selectedAccounts = [];

  /// 释放摄像头资源
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 处理扫描到的二维码数据
  ///
  /// 优先使用 [QrUtils.parseMigrationData] 解析 Protocol Buffers 格式，
  /// 如果解析结果为空则尝试 JSON 格式兼容解析。
  void _processQrCode(String code) {
    try {
      final accounts = QrUtils.parseMigrationData(code);

      if (accounts.isNotEmpty) {
        setState(() {
          _importedAccounts = accounts;
          _selectedAccounts = [];
        });
      } else {
        // 兼容其他应用的 JSON 格式
        try {
          if (code.startsWith('otpauth-migration://offline?data=')) {
            final dataPart = code.substring(
              'otpauth-migration://offline?data='.length,
            );
            final cleanedDataPart = dataPart
                .replaceAll('-', '+')
                .replaceAll('_', '/');
            final paddedDataPart = cleanedDataPart.padRight(
              cleanedDataPart.length + (4 - cleanedDataPart.length % 4) % 4,
              '=',
            );
            final decodedData = base64.decode(paddedDataPart);
            final jsonData = json.decode(String.fromCharCodes(decodedData));
            if (jsonData is Map && jsonData.containsKey('otp_parameters')) {
              final otpParameters = jsonData['otp_parameters'] as List?;
              if (otpParameters != null) {
                setState(() {
                  _importedAccounts = otpParameters
                      .cast<Map<String, dynamic>>();
                  _selectedAccounts = [];
                });
              } else {
                _showErrorDialog('二维码数据格式错误');
              }
            } else {
              _showErrorDialog('二维码数据格式错误');
            }
          } else {
            _showErrorDialog('无效的迁移二维码');
          }
        } catch (e) {
          _showErrorDialog('无效的二维码数据格式');
        }
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  /// 显示错误提示对话框，允许重新扫描
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 重置扫描器，允许重新扫描
  void _resetScanner() {
    setState(() {
      _scanned = false;
    });
    _controller.start();
  }

  /// 将解析后的动态口令数据导入到数据库
  Future<void> _importAccounts() async {
    if (!mounted) return;

    try {
      if (_selectedAccounts.isEmpty) {
        StyleUtils.errorSnackBar(context, '请选择要导入的动态口令');
        return;
      }

      int importedCount = 0;
      for (final accountData in _selectedAccounts) {
        try {
          if (accountData.containsKey('secret') &&
              accountData.containsKey('name')) {
            final secret = accountData['secret'] as String;
            final issuer = accountData['issuer'] as String?;
            final rawName = accountData['name'] as String;

            String name = rawName;
            if (issuer != null &&
                issuer.isNotEmpty &&
                rawName.startsWith('$issuer:')) {
              name = rawName.substring(issuer.length + 1);
            }

            final account = TwoFactorAccount(
              '',
              issuer,
              name,
              secret,
              accountData['period'] ?? 30,
              accountData['algorithm'] ?? 'SHA1',
              DateTime.now(),
              DateTime.now(),
              type: accountData['type'] as String? ?? 'totp',
              counter: accountData['counter'] as int? ?? 0,
            );
            await _storageService.insertAccount(account);
            importedCount++;
          }
        } catch (e) {
          continue;
        }
      }

      if (!mounted) return;

      if (importedCount > 0) {
        StyleUtils.successSnackBar(context, '成功导入 $importedCount 个动态口令');
      } else {
        StyleUtils.errorSnackBar(context, '没有成功导入任何动态口令');
      }

      // 导入成功后直接返回首页
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        StyleUtils.errorSnackBar(context, '导入动态口令时出错');
      }
    }
  }

  /// 构建扫描界面 / 导入选择列表界面
  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _importedAccounts.isNotEmpty
          ? AppBar(
              title: const Text('导入动态口令'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: _importedAccounts.isEmpty
          ? Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (!_scanned && barcode.rawValue != null) {
                        _scanned = true;
                        _controller.stop();
                        _processQrCode(barcode.rawValue!);
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
            )
          : Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _importedAccounts.length,
                      itemBuilder: (context, index) {
                        final account = _importedAccounts[index];
                        final isSelected = _selectedAccounts.contains(account);
                        final rawName = account['name'] as String;
                        final issuer = account['issuer'] as String?;
                        String displayName = rawName;
                        if (issuer != null &&
                            issuer.isNotEmpty &&
                            rawName.startsWith('$issuer:')) {
                          displayName = rawName.substring(issuer.length + 1);
                        }
                        return CheckboxListTile(
                          title: Text(
                            displayName,
                            style: StyleUtils.bodyTextStyle(context),
                          ),
                          subtitle: Text(
                            issuer ?? '',
                            style: StyleUtils.subtitleTextStyle(context),
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedAccounts.add(account);
                              } else {
                                _selectedAccounts.remove(account);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _importAccounts,
                        style: StyleUtils.primaryButtonStyle(context),
                        child: const Text('导入'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
