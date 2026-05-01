import 'package:base32/base32.dart';
import 'package:flutter/material.dart';

import '../models/two_factor_account.dart';
import '../services/storage_service.dart';
import '../utils/style_utils.dart';

/// 手动输入2FA秘钥添加账户页面
class AddManual2FaScreen extends StatefulWidget {
  const AddManual2FaScreen({super.key});

  @override
  State<AddManual2FaScreen> createState() => _AddManual2FaScreenState();
}

/// 手动输入2FA秘钥添加账户页面状态
class _AddManual2FaScreenState extends State<AddManual2FaScreen> {
  /// 表单键
  final _formKey = GlobalKey<FormState>();

  /// 发行者控制器
  final _issuerController = TextEditingController();

  /// 账户名控制器
  final _nameController = TextEditingController();

  /// 秘钥控制器
  final _secretController = TextEditingController();

  /// 计数器控制器
  final _counterController = TextEditingController(text: '0');

  /// 数据库服务
  final StorageService _storageService = StorageService();

  /// 秘钥类型
  String _secretType = 'time';

  @override
  void dispose() {
    _issuerController.dispose();
    _nameController.dispose();
    _secretController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  /// 验证Base32格式
  bool _isValidBase32(String secret) {
    try {
      base32.decode(secret);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 保存账户
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
        _secretController.text,
        30,
        'SHA1',
        DateTime.now(),
        DateTime.now(),
        type: isHotp ? 'hotp' : 'totp',
        counter: counter,
      );

      await _storageService.insertAccount(account);

      if (mounted) {
        Navigator.pop(context, true);
        StyleUtils.successSnackBar(context, '添加成功');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('输入验证码详情')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _issuerController,
                decoration: StyleUtils.inputDecoration('发行者名称', '例如：Google'),
              ),
              StyleUtils.mediumSpacing,
              TextFormField(
                controller: _nameController,
                decoration: StyleUtils.inputDecoration(
                  '账户名称',
                  '例如：user@example.com',
                ),
              ),
              StyleUtils.mediumSpacing,
              TextFormField(
                controller: _secretController,
                decoration: StyleUtils.inputDecoration('2FA秘钥', 'Base32'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入2FA秘钥';
                  }
                  if (!_isValidBase32(value)) {
                    return '无效的Base32秘钥格式';
                  }
                  return null;
                },
              ),
              StyleUtils.mediumSpacing,
              DropdownButtonFormField<String>(
                initialValue: _secretType,
                decoration: StyleUtils.inputDecoration('秘钥类型', null),
                items: const [
                  DropdownMenuItem(value: 'time', child: Text('基于时间')),
                  DropdownMenuItem(value: 'counter', child: Text('基于计数器')),
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
                  decoration: StyleUtils.inputDecoration('计数器初始值', '默认 0'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入计数器值';
                    }
                    if (int.tryParse(value) == null) {
                      return '请输入有效的数字';
                    }
                    return null;
                  },
                ),
              ],
              Spacer(),
              StyleUtils.largeSpacing,
              ElevatedButton(
                onPressed: _saveAccount,
                style: StyleUtils.primaryButtonStyle(context),
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
