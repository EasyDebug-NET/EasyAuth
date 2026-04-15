import 'package:flutter/material.dart';

import '../models/two_factor_account.dart';
import '../services/storage_service.dart';
import '../utils/style_utils.dart';

/// 修改2FA账户信息页面
class Edit2FaScreen extends StatefulWidget {
  const Edit2FaScreen({super.key});

  @override
  State<Edit2FaScreen> createState() => _Edit2FaScreenState();
}

/// 修改2FA账户信息页面状态
class _Edit2FaScreenState extends State<Edit2FaScreen> {
  /// 表单键
  final _formKey = GlobalKey<FormState>();

  /// 发行者控制器
  final _issuerController = TextEditingController();

  /// 账户名控制器
  final _nameController = TextEditingController();

  /// 数据库服务
  final StorageService _storageService = StorageService();

  /// 当前账户
  TwoFactorAccount? _account;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_account == null) {
      _account = ModalRoute.of(context)?.settings.arguments as TwoFactorAccount;
      _issuerController.text = _account?.issuer ?? '';
      _nameController.text = _account?.name ?? '';
    }
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// 保存账户
  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate() && _account != null) {
      final updatedAccount = TwoFactorAccount.name(
        _account!.id,
        _issuerController.text.isEmpty ? null : _issuerController.text,
        _nameController.text.isEmpty ? null : _nameController.text,
        _account!.secret,
        _account!.period,
        _account!.algorithm,
        _account!.createdAt,
        DateTime.now(),
        type: _account!.type,
        counter: _account!.counter,
      );

      await _storageService.updateAccount(updatedAccount);

      if (mounted) {
        Navigator.pop(context, true);
        StyleUtils.successSnackBar(context, '修改成功');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('修改账户')),
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
