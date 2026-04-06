import 'package:base32/base32.dart';
import 'package:flutter/material.dart';

import '../models/two_factor_account.dart';
import '../services/storage_service.dart';

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

  /// 数据库服务
  final StorageService _storageService = StorageService();

  /// 秘钥类型
  String _secretType = 'time';

  @override
  void dispose() {
    _issuerController.dispose();
    _nameController.dispose();
    _secretController.dispose();
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
      final account = TwoFactorAccount.name(
        '',
        _issuerController.text.isEmpty ? null : _issuerController.text,
        _nameController.text.isEmpty ? null : _nameController.text,
        _secretController.text,
        _secretType == 'time' ? 30 : 0,
        'SHA1',
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
                decoration: InputDecoration(
                  labelText: '发行者名称',
                  hintText: '例如：Google',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '账户名称',
                  hintText: '例如：user@example.com',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _secretController,
                decoration: InputDecoration(
                  labelText: '2FA秘钥',
                  hintText: 'Base32',
                  border: OutlineInputBorder(),
                ),
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
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _secretType,
                decoration: InputDecoration(
                  labelText: '秘钥类型',
                  border: OutlineInputBorder(),
                ),
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
              Spacer(),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
