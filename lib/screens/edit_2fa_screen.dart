import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/two_factor_account.dart';

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
      );

      await _storageService.updateAccount(updatedAccount);

      if (mounted) {
        Navigator.pop(context, true);
        // 优化SnackBar样式，使用floating行为提升用户体验
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('修改成功'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
