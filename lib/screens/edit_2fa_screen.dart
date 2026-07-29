import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/two_factor_account.dart';
import '../services/storage_service.dart';
import '../utils/style_utils.dart';

/// 修改2FA动态口令信息页面
class Edit2FaScreen extends StatefulWidget {
  const Edit2FaScreen({super.key});

  @override
  State<Edit2FaScreen> createState() => _Edit2FaScreenState();
}

class _Edit2FaScreenState extends State<Edit2FaScreen> {
  /// 表单校验键
  final _formKey = GlobalKey<FormState>();

  /// 发行者名称输入控制器
  final _issuerController = TextEditingController();

  /// 动态口令名称输入控制器
  final _nameController = TextEditingController();

  /// 数据库存储服务
  final StorageService _storageService = StorageService();

  /// 当前正在编辑的动态口令
  TwoFactorAccount? _account;

  /// 从路由参数中获取待编辑的动态口令，初始化表单
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_account == null) {
      _account = ModalRoute.of(context)?.settings.arguments as TwoFactorAccount;
      _issuerController.text = _account?.issuer ?? '';
      _nameController.text = _account?.name ?? '';
    }
  }

  /// 释放输入控制器资源
  @override
  void dispose() {
    _issuerController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// 保存修改后的动态口令信息到数据库
  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate() && _account != null) {
      final updatedAccount = TwoFactorAccount(
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
        StyleUtils.successSnackBar(context, AppLocalizations.of(context)!.snackModifiedSuccess);
      }
    }
  }

  /// 构建编辑表单：发行者名称 + 动态口令名称 + 保存按钮
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editTitle)),
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
