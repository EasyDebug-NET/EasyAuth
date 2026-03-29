import 'package:flutter/material.dart';

import '../models/settings.dart';
import '../services/settings_service.dart';
import '../utils/style_utils.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// 设置页面状态
class _SettingsScreenState extends State<SettingsScreen> {
  /// 表单键
  final _formKey = GlobalKey<FormState>();

  /// 备份服务
  final _backupService = BackupService();

  /// 备份配置
  late BackupConfig _config;

  /// 是否加载中
  bool _isLoading = false;

  /// 是否加载配置
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      final config = await _backupService.loadConfig();
      setState(() {
        _config = config;
        _isLoadingConfig = false;
      });
    } catch (e) {
      debugPrint('Failed to load config: $e');
      setState(() {
        _isLoadingConfig = false;
      });
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    try {
      await _backupService.saveConfig(_config);
    } catch (e) {
      debugPrint('Failed to save config: $e');
    }
  }

  /// 获取备份类型的显示文本
  String _getBackupTypeText(BackupType type) {
    switch (type) {
      case BackupType.off:
        return '关闭';
      case BackupType.webdav:
        return 'WebDAV';
      case BackupType.s3:
        return 'S3';
    }
  }

  /// 获取备份配置状态文本
  /// 关闭=未配置，已配置=已配置
  String _getBackupConfigStatusText() {
    if (_config.type == BackupType.off) {
      return '未配置';
    }
    return '已配置';
  }

  /// 打开备份参数配置弹出层
  Future<void> _showBackupConfigDialog() async {
    final result = await showModalBottomSheet<BackupConfig>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _BackupConfigDialog(initialConfig: _config);
      },
    );

    if (result != null) {
      setState(() {
        _config = result;
      });
      await _saveConfig();
    }
  }

  /// 执行备份操作
  Future<void> _performBackup() async {
    if (_config.type == BackupType.off) {
      // 优化SnackBar样式，使用floating行为提升用户体验
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择备份类型'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_backupService.isConfigValid(_config)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先配置完整的备份参数'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.performBackup(_config);
      if (mounted) {
        // 优化SnackBar样式，使用floating行为提升用户体验
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('备份完成'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份失败: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 恢复备份
  Future<void> _restoreBackup() async {
    if (_config.type == BackupType.off) {
      // 优化SnackBar样式，使用floating行为提升用户体验
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择备份类型'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_backupService.isConfigValid(_config)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先配置完整的备份参数'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text('恢复备份将覆盖当前数据，确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定恢复'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _backupService.restoreBackup(_config);
        if (mounted) {
          // 优化SnackBar样式，使用floating行为提升用户体验
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('恢复完成'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('恢复失败: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 清除远端备份
  Future<void> _clearRemoteBackup() async {
    if (_config.type == BackupType.off) {
      // 优化SnackBar样式，使用floating行为提升用户体验
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择备份类型'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_backupService.isConfigValid(_config)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先配置完整的备份参数'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除远端备份吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定清除'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _backupService.deleteRemoteBackup(_config);
        if (mounted) {
          // 优化SnackBar样式，使用floating行为提升用户体验
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('远端备份已清除'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('清除失败: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection('备份设置', [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showBackupConfigDialog,
                    style: StyleUtils.primaryButtonStyleLeft(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('备份参数配置'),
                        Text(
                          _getBackupConfigStatusText(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_config.type != BackupType.off) ...[
                  _buildButton('备份到远端', _performBackup, primaryColor),
                  const SizedBox(height: 16),
                  _buildButton('从远端恢复', _restoreBackup, primaryColor),
                  const SizedBox(height: 16),
                  _buildButton(
                    '清除远端备份',
                    _clearRemoteBackup,
                    primaryColor,
                  ),
                ],
              ]),

              // const SizedBox(height: 24),
              // _buildSection('其他设置', [_buildOtherSettingSwitch()]),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建设置区块
  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[100]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Widget _buildOtherSettingSwitch() {
  //   return Container(
  //     height: 50,
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey[300]!),
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       children: [
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: const Text('其他设置', style: TextStyle(color: Colors.black87)),
  //         ),
  //         Switch(
  //           value: _config.otherSettingEnabled,
  //           onChanged: (value) {
  //             setState(() {
  //               _config = _config.copyWith(otherSettingEnabled: value);
  //             });
  //             _saveConfig();
  //           },
  //           activeColor: Theme.of(context).colorScheme.primary,
  //         ),
  //         const SizedBox(width: 16),
  //       ],
  //     ),
  //   );
  // }

  /// 构建按钮
  Widget _buildButton(String text, VoidCallback onPressed, Color buttonColor) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            buttonColor.withValues(alpha: 0.9),
          ),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        child: Align(alignment: Alignment.centerLeft, child: Text(text)),
      ),
    );
  }
}

/// 备份参数配置弹出层
class _BackupConfigDialog extends StatefulWidget {
  final BackupConfig initialConfig;

  const _BackupConfigDialog({required this.initialConfig});

  @override
  State<_BackupConfigDialog> createState() => _BackupConfigDialogState();
}

class _BackupConfigDialogState extends State<_BackupConfigDialog> {
  late BackupConfig _config;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    // 如果 backupDir 为空，设置默认值
    if (_config.webDavConfig.backupDir.isEmpty) {
      _config = _config.copyWith(
        webDavConfig: _config.webDavConfig.copyWith(backupDir: 'EasyAuth'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.white,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '备份参数配置',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 备份类型
            DropdownButtonFormField<String>(
              initialValue: _config.type.toString().split('.').last,
              decoration: const InputDecoration(
                labelText: '备份类型',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'off', child: Text('关闭')),
                const DropdownMenuItem(value: 'webdav', child: Text('WebDAV')),
                const DropdownMenuItem(value: 's3', child: Text('S3')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _config = _config.copyWith(
                      type: BackupType.values.firstWhere(
                            (e) => e.toString().split('.').last == value,
                      ),
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // WebDAV 配置
            if (_config.type == BackupType.webdav) ...[
              TextFormField(
                initialValue: _config.webDavConfig.url,
                decoration: const InputDecoration(
                  labelText: 'WebDAV地址',
                  hintText: 'https://dav.jianguoyun.com/dav',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    String processedValue = value;
                    if (processedValue.endsWith('/')) {
                      processedValue = processedValue.substring(
                        0,
                        processedValue.length - 1,
                      );
                    }
                    _config = _config.copyWith(
                      webDavConfig: _config.webDavConfig.copyWith(
                        url: processedValue,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _config.webDavConfig.backupDir.isEmpty
                    ? 'EasyAuth'
                    : _config.webDavConfig.backupDir,
                decoration: const InputDecoration(
                  labelText: '备份目录',
                  hintText: 'EasyAuth',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '备份目录不能为空';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(
                      webDavConfig: _config.webDavConfig.copyWith(
                        backupDir: value.trim(),
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _config.webDavConfig.username,
                decoration: const InputDecoration(
                  labelText: '授权账号',
                  hintText: 'username',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(
                      webDavConfig: _config.webDavConfig.copyWith(
                        username: value,
                      ),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _config.webDavConfig.password,
                decoration: const InputDecoration(
                  labelText: '授权密码',
                  hintText: '••••••••',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(
                      webDavConfig: _config.webDavConfig.copyWith(
                        password: value,
                      ),
                      backupKey: value, // 密码作为备份密钥
                    );
                  });
                },
              ),
            ] else if (_config.type == BackupType.s3) ...[
              // S3 配置
              TextFormField(
                initialValue: _config.s3Config.endpoint,
                decoration: const InputDecoration(
                  labelText: 'Endpoint URL',
                  hintText: 'https://s3.amazonaws.com',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(
                      s3Config: _config.s3Config.copyWith(endpoint: value),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _config.s3Config.accessKeyId,
                decoration: const InputDecoration(
                  labelText: 'Access Key ID',
                  hintText: 'AKIAIOSFODNN7EXAMPLE',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(
                      s3Config: _config.s3Config.copyWith(accessKeyId: value),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _config.s3Config.secretAccessKey,
                decoration: const InputDecoration(
                  labelText: 'Secret Access Key',
                  hintText: '••••••••',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(
                      s3Config: _config.s3Config.copyWith(
                        secretAccessKey: value,
                      ),
                      backupKey: value, // 密钥作为备份密钥
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _config.s3Config.bucketName,
                decoration: const InputDecoration(
                  labelText: 'Bucket Name',
                  hintText: 'my-bucket',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(
                      s3Config: _config.s3Config.copyWith(bucketName: value),
                    );
                  });
                },
              ),
            ],

            const SizedBox(height: 32),

            // 按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        // 如果是 WebDAV 且 backupDir 为空，使用默认值
                        if (_config.type == BackupType.webdav &&
                            _config.webDavConfig.backupDir.isEmpty) {
                          _config = _config.copyWith(
                            webDavConfig: _config.webDavConfig.copyWith(
                              backupDir: 'EasyAuth',
                            ),
                          );
                        }
                        Navigator.pop(context, _config);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('确认'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
