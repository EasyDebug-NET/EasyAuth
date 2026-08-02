import 'package:base32/base32.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/two_factor_account.dart';
import '../services/storage_service.dart';
import '../utils/style_utils.dart';

/// 手动输入2FA密钥添加动态口令页面
class AddManual2FaScreen extends StatefulWidget {
  const AddManual2FaScreen({super.key});

  @override
  State<AddManual2FaScreen> createState() => _AddManual2FaScreenState();
}

class _AddManual2FaScreenState extends State<AddManual2FaScreen> {
  /// 表单校验键
  final _formKey = GlobalKey<FormState>();

  /// 发行者名称输入控制器
  final _issuerController = TextEditingController();

  /// 动态口令名称输入控制器
  final _nameController = TextEditingController();

  /// 2FA密钥输入控制器
  final _secretController = TextEditingController();

  /// HOTP计数器初始值输入控制器
  final _counterController = TextEditingController(text: '0');

  /// 数据库存储服务
  final StorageService _storageService = StorageService();

  /// 密钥类型：'time' 基于时间（TOTP），'counter' 基于计数器（HOTP）
  String _secretType = 'time';

  /// 释放所有输入控制器资源
  @override
  void dispose() {
    _issuerController.dispose();
    _nameController.dispose();
    _secretController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  /// 验证字符串是否为有效的 Base32 编码
  bool _isValidBase32(String secret) {
    try {
      base32.decode(secret);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 保存新添加的动态口令到数据库
  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      final isHotp = _secretType == 'counter';
      final counter = isHotp
          ? (int.tryParse(_counterController.text) ?? 0)
          : 0;

      final account = TwoFactorAccount(
        '',
        _issuerController.text.isEmpty ? null : _issuerController.text,
        _nameController.text.isEmpty ? null : _nameController.text,
        // Normalise secret to uppercase for correct Base32 decoding.
        _secretController.text.toUpperCase(),
        30,
        'SHA1',
        DateTime.now(),
        DateTime.now(),
        type: isHotp ? 'hotp' : 'totp',
        counter: counter,
      );

      try {
        await _storageService.insertAccount(account);
        if (mounted) {
          Navigator.pop(context, true);
          StyleUtils.successSnackBar(context, AppLocalizations.of(context).snackAddedSuccess);
        }
      } catch (e) {
        if (mounted) {
          StyleUtils.errorSnackBar(context, AppLocalizations.of(context).snackSaveConfigFailed(e.toString()));
        }
      }
    }
  }

  /// 构建手动输入表单：发行者 + 名称 + 密钥 + 类型（TOTP/HOTP）+ 保存按钮
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addManualTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _issuerController,
                decoration: StyleUtils.inputDecoration(l10n.labelIssuer, l10n.hintIssuer),
              ),
              StyleUtils.mediumSpacing,
              TextFormField(
                controller: _nameController,
                decoration: StyleUtils.inputDecoration(
                  l10n.labelAccountName,
                  l10n.hintAccountName,
                ),
              ),
              StyleUtils.mediumSpacing,
              TextFormField(
                controller: _secretController,
                decoration: StyleUtils.inputDecoration(l10n.labelSecretKey, l10n.hintSecretKey),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.validationSecretRequired;
                  }
                  if (!_isValidBase32(value)) {
                    return l10n.validationSecretInvalidBase32;
                  }
                  return null;
                },
              ),
              StyleUtils.mediumSpacing,
              DropdownButtonFormField<String>(
                initialValue: _secretType,
                decoration: StyleUtils.inputDecoration(l10n.labelSecretType, null),
                items: [
                  DropdownMenuItem(value: 'time', child: Text(l10n.secretTypeTime)),
                  DropdownMenuItem(value: 'counter', child: Text(l10n.secretTypeCounter)),
                ],
                onChanged: (value) {
                  setState(() {
                    _secretType = value!;
                  });
                },
              ),
              if (_secretType == 'counter') ...[
                StyleUtils.mediumSpacing,
                TextFormField(
                  controller: _counterController,
                  decoration: StyleUtils.inputDecoration(l10n.labelCounterInitial, l10n.hintCounterInitial),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.validationCounterRequired;
                    }
                    if (int.tryParse(value) == null) {
                      return l10n.validationCounterInvalidNumber;
                    }
                    return null;
                  },
                ),
              ],
              const Spacer(),
              StyleUtils.largeSpacing,
              ElevatedButton(
                onPressed: _saveAccount,
                style: StyleUtils.primaryButtonStyle(context),
                child: Text(l10n.buttonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
