import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/setting.dart';
import '../services/backup_service.dart';
import '../services/security_service.dart';
import '../utils/exceptions.dart';
import '../utils/s3_utils.dart';
import '../utils/style_utils.dart';
import '../utils/webdav_utils.dart';

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

  /// 应用设置
  late Setting _setting;

  /// 安全服务
  final SecurityService _securityService = SecurityService();

  /// 是否加载中
  bool _isLoading = false;

  /// 是否加载配置
  bool _isLoadingConfig = true;

  /// 是否支持生物识别
  bool _isBiometricAvailable = false;

  /// 是否从云图标点击跳转过来
  bool _fromCloudIcon = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 接收来自 home_screen 的参数
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _fromCloudIcon = arguments['fromCloudIcon'] ?? false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _checkBiometricAvailability();
  }

  /// 检查生物识别可用性
  Future<void> _checkBiometricAvailability() async {
    _isBiometricAvailable = await _securityService.isBiometricAvailable();
    debugPrint('生物识别可用性: $_isBiometricAvailable');
    setState(() {});
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      final setting = await _backupService.loadConfig();
      if (!mounted) return;
      setState(() {
        _setting = setting;
        _isLoadingConfig = false;
      });

      // 检查是否未配置备份参数且是从云图标点击跳转过来
      if (_fromCloudIcon && _setting.backupSetting.type == BackupType.off) {
        // 显示未配置备份参数的提示
        StyleUtils.normalSnackBar(context, '未配置备份参数');
      }
    } catch (e) {
      debugPrint('加载配置失败: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingConfig = false;
      });
      // 显示加载配置失败的提示
      StyleUtils.errorSnackBar(context, '加载配置失败: ${e.toString()}');
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    try {
      await _backupService.saveConfig(_setting);
    } catch (e) {
      debugPrint('保存配置失败: $e');
      if (mounted) {
        StyleUtils.errorSnackBar(context, '保存配置失败: ${e.toString()}');
      }
    }
  }

  /// 更新截屏锁状态
  ///
  /// [enabled] 是否启用截屏锁
  Future<void> _updateScreenshotLock(bool enabled) async {
    try {
      if (enabled) {
        // 防止截屏
        await FlutterWindowManagerPlus.addFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
        debugPrint('截屏锁已开启');
        if (mounted) {
          StyleUtils.normalSnackBar(context, '截屏锁已开启');
        }
      } else {
        // 允许截屏
        await FlutterWindowManagerPlus.clearFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
        debugPrint('截屏锁已关闭');
        if (mounted) {
          StyleUtils.normalSnackBar(context, '截屏锁已关闭');
        }
      }
    } catch (e) {
      debugPrint('更新截屏锁状态失败: $e');
      if (mounted) {
        StyleUtils.errorSnackBar(context, '更新截屏锁状态失败: ${e.toString()}');
      }
    }
  }

  /// 处理应用锁开关变化
  Future<void> _handleAppLockToggle(bool value) async {
    if (value) {
      // 检查设备是否支持生物识别
      if (!_isBiometricAvailable) {
        // 设备不支持生物识别，显示提示
        StyleUtils.normalSnackBar(context, '设备不支持生物识别，无法开启应用锁');
        return;
      }

      // 开启应用锁时，先进行生物识别认证
      bool authenticated = await _securityService.authenticate(
        reason: '请验证身份以开启应用锁',
      );

      if (authenticated) {
        // 认证成功，开启应用锁
        setState(() {
          _setting = _setting.copyWith(
            securitySetting: _setting.securitySetting.copyWith(
              appLockEnabled: true,
            ),
          );
        });
        await _saveConfig();
        // 显示成功提示，保持在设置页面
        if (mounted) {
          StyleUtils.normalSnackBar(context, '应用锁已开启');
        }
      }
    } else {
      // 关闭应用锁时，也需要进行生物识别认证，确保是合法用户操作
      bool authenticated = await _securityService.authenticate(
        reason: '请验证身份以关闭应用锁',
      );

      if (authenticated) {
        // 认证成功，关闭应用锁
        setState(() {
          _setting = _setting.copyWith(
            securitySetting: _setting.securitySetting.copyWith(
              appLockEnabled: false,
            ),
          );
        });
        await _saveConfig();
        if (mounted) {
          StyleUtils.normalSnackBar(context, '应用锁已关闭');
        }
      } else {
        // 认证失败，显示提示
        if (mounted) {
          StyleUtils.errorSnackBar(context, '认证失败，无法关闭应用锁');
        }
      }
    }
  }

  /// 获取备份配置状态文本
  /// 关闭=未配置，已配置=已配置
  String _getBackupConfigStatusText() {
    if (_setting.backupSetting.type == BackupType.off) {
      return '未配置';
    }
    return '已配置';
  }

  /// 打开备份参数配置弹出层
  Future<void> _showBackupConfigDialog() async {
    final result = await showModalBottomSheet<Setting>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _BackupConfigDialog(initialConfig: _setting);
      },
    );

    if (result != null) {
      setState(() {
        _setting = result;
      });
      await _saveConfig();
    }
  }

  /// 执行备份操作
  Future<void> _performBackup() async {
    if (!mounted) return;

    if (_setting.backupSetting.type == BackupType.off) {
      // 优化SnackBar样式，使用floating行为提升用户体验
      StyleUtils.normalSnackBar(context, '请先选择备份类型');
      return;
    }

    if (!_backupService.isConfigValid(_setting)) {
      StyleUtils.normalSnackBar(context, '请先配置完整的备份参数');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.performBackup(_setting);
      if (mounted) {
        // 优化SnackBar样式，使用floating行为提升用户体验
        StyleUtils.successSnackBar(context, '备份完成');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '备份失败';
        String? errorDetails;

        if (e is AppException) {
          errorMessage = e.message;
          errorDetails = e.details;
        } else {
          errorMessage = '备份失败: ${e.toString()}';
        }

        StyleUtils.errorSnackBar(context, errorMessage, errorDetails);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 恢复备份
  Future<void> _restoreBackup() async {
    if (!mounted) return;

    if (_setting.backupSetting.type == BackupType.off) {
      // 优化SnackBar样式，使用floating行为提升用户体验
      StyleUtils.normalSnackBar(context, '请先选择备份类型');
      return;
    }

    if (!_backupService.isConfigValid(_setting)) {
      StyleUtils.normalSnackBar(context, '请先配置完整的备份参数');
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
      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      try {
        await _backupService.restoreBackup(_setting);
        if (mounted) {
          StyleUtils.successSnackBar(context, '恢复成功');
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = '恢复失败';
          String? errorDetails;

          if (e is AppException) {
            errorMessage = e.message;
            errorDetails = e.details;
          } else {
            errorMessage = '恢复失败: ${e.toString()}';
          }

          StyleUtils.errorSnackBar(context, errorMessage, errorDetails);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  /// 管理远端备份
  Future<void> _manageRemoteBackup() async {
    if (!mounted) return;

    if (_setting.backupSetting.type == BackupType.off) {
      StyleUtils.normalSnackBar(context, '请先选择备份类型');
      return;
    }

    if (!_backupService.isConfigValid(_setting)) {
      StyleUtils.normalSnackBar(context, '请先配置完整的备份参数');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RemoteBackupManager(config: _setting),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('加载配置中...'),
            ],
          ),
        ),
      );
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                  const SizedBox(height: 16),
                  const Text('正在执行操作...'),
                  const SizedBox(height: 8),
                  Text(
                    '请稍候',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSection('备份设置', [
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

                        if (_setting.backupSetting.type != BackupType.off) ...[
                          _buildButton('备份到远端', _performBackup, primaryColor),
                          const SizedBox(height: 16),
                          _buildButton('从远端恢复', _restoreBackup, primaryColor),
                          const SizedBox(height: 16),
                          _buildButton(
                            '管理远端备份',
                            _manageRemoteBackup,
                            primaryColor,
                          ),
                        ],
                      ]),
                    ),
                    // 添加分割线
                    Divider(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
                      height: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSection('安全设置', [
                        Container(
                          height: 50,
                          decoration: StyleUtils.lockContainerStyle(context),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '应用锁',
                                          style: StyleUtils.lockTextStyle(context),
                                        ),
                                        if (!_isBiometricAvailable)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: Text(
                                              '设备不支持生物识别',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.yellowAccent,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Switch(
                                      value:
                                          _setting
                                              .securitySetting
                                              .appLockEnabled,
                                      onChanged: _handleAppLockToggle,
                                      activeThumbColor: Colors.white,
                                      inactiveThumbColor: Colors.white,
                                      activeTrackColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      inactiveTrackColor: Colors.grey[300],
                                      trackOutlineColor:
                                          WidgetStateProperty.resolveWith((
                                            states,
                                          ) {
                                            if (states.contains(
                                              WidgetState.selected,
                                            )) {
                                              return Colors.transparent;
                                            }
                                            return Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.5);
                                          }),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 50,
                          decoration: StyleUtils.lockContainerStyle(context),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '截屏锁',
                                          style: StyleUtils.lockTextStyle(context),
                                        ),
                                        if (!Platform.isAndroid)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Text(
                                              '仅支持 Android',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.yellowAccent,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Switch(
                                      value:
                                          _setting
                                              .securitySetting
                                              .screenshotLockEnabled,
                                      onChanged: Platform.isAndroid ? (value) async {
                                        setState(() {
                                          _setting = _setting.copyWith(
                                            securitySetting: _setting
                                                .securitySetting
                                                .copyWith(
                                                  screenshotLockEnabled: value,
                                                ),
                                          );
                                        });
                                        await _saveConfig();
                                        // 立即更新截屏锁状态
                                        await _updateScreenshotLock(value);
                                      } : null,
                                      activeThumbColor: Colors.white,
                                      inactiveThumbColor: Colors.white,
                                      activeTrackColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      inactiveTrackColor: Colors.grey[300],
                                      trackOutlineColor:
                                          WidgetStateProperty.resolveWith((
                                            states,
                                          ) {
                                            if (states.contains(
                                              WidgetState.selected,
                                            )) {
                                              return Colors.transparent;
                                            }
                                            return Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.5);
                                          }),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 构建设置区块
  Widget _buildSection(String title, List<Widget> children) {
    return Container(
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
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(text), const SizedBox()],
        ),
      ),
    );
  }
}

/// 远端备份管理弹出层
///
/// 用于展示备份文件列表，支持全选、单选和批量删除操作
class _RemoteBackupManager extends StatefulWidget {
  /// 应用设置
  final Setting config;

  const _RemoteBackupManager({required this.config});

  @override
  State<_RemoteBackupManager> createState() => _RemoteBackupManagerState();
}

class _RemoteBackupManagerState extends State<_RemoteBackupManager> {
  /// 应用设置
  late Setting _config;

  /// 备份文件列表
  List<BackupFile> _backupFiles = [];

  /// 是否正在加载
  bool _isLoading = true;

  /// 是否全选
  bool _selectAll = false;

  /// 选中的文件列表
  final _selectedFiles = <String>{};

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _loadBackupFiles();
  }

  /// 加载备份文件列表
  ///
  /// 执行步骤：
  /// 1. 设置加载状态
  /// 2. 根据备份类型获取文件列表
  /// 3. 过滤并解析备份文件
  /// 4. 按时间降序排序
  /// 5. 更新状态
  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backupService = BackupService();
      List<String> files;

      if (_config.backupSetting.type == BackupType.webdav) {
        // 构建 WebDAV 目录 URL
        final listUrl = backupService.buildWebDavDirUrl(
          _config.backupSetting.webDavConfig.url,
          _config.backupSetting.webDavConfig.backupDir,
        );
        // 获取 WebDAV 文件列表
        files = await WebDavUtils.listFiles(
          listUrl,
          _config.backupSetting.webDavConfig.username,
          _config.backupSetting.webDavConfig.password,
        );
      } else if (_config.backupSetting.type == BackupType.s3) {
        // 获取 S3 文件列表
        files = await S3Utils.listFiles(
          _config.backupSetting.s3Config.endpoint,
          _config.backupSetting.s3Config.bucketName,
          _config.backupSetting.s3Config.accessKeyId,
          _config.backupSetting.s3Config.secretAccessKey,
          region: _config.backupSetting.s3Config.region,
        );
        // 过滤出指定目录下的文件
        if (_config.backupSetting.s3Config.backupDir.isNotEmpty) {
          files = files
              .where(
                (file) =>
                    file.startsWith(_config.backupSetting.s3Config.backupDir),
              )
              .map(
                (file) => file
                    .substring(_config.backupSetting.s3Config.backupDir.length)
                    .replaceFirst(RegExp(r'^/'), ''),
              )
              .toList();
        }
      } else {
        files = [];
      }

      // 过滤备份文件并解析时间
      final backupFiles = files
          .where((file) => file.startsWith('backup_') && file.endsWith('.zip'))
          .map((file) {
            final timestamp = file
                .replaceAll('backup_', '')
                .replaceAll('.zip', '');
            DateTime? dateTime;
            try {
              // 解析时间戳格式: YYYYMMDD_HHMMSS
              if (timestamp.length >= 14 && timestamp.contains('_')) {
                final parts = timestamp.split('_');
                if (parts.length == 2) {
                  final date = parts[0];
                  final time = parts[1];
                  if (date.length == 8 && time.length == 6) {
                    dateTime = DateTime(
                      int.parse(date.substring(0, 4)),
                      int.parse(date.substring(4, 6)),
                      int.parse(date.substring(6, 8)),
                      int.parse(time.substring(0, 2)),
                      int.parse(time.substring(2, 4)),
                      int.parse(time.substring(4, 6)),
                    );
                  }
                }
              }
            } catch (e) {
              dateTime = null;
            }
            return BackupFile(name: file, dateTime: dateTime);
          })
          .toList();

      // 按时间降序排序
      backupFiles.sort((a, b) {
        if (a.dateTime == null) return 1;
        if (b.dateTime == null) return -1;
        return b.dateTime!.compareTo(a.dateTime!);
      });

      setState(() {
        _backupFiles = backupFiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        StyleUtils.normalSnackBar(context, '加载失败: ${e.toString()}');
      }
    }
  }

  /// 切换全选状态
  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedFiles.addAll(_backupFiles.map((file) => file.name));
      } else {
        _selectedFiles.clear();
      }
    });
  }

  /// 切换单个文件的选择状态
  ///
  /// [fileName] 文件名
  void _toggleSelect(String fileName) {
    setState(() {
      if (_selectedFiles.contains(fileName)) {
        _selectedFiles.remove(fileName);
      } else {
        _selectedFiles.add(fileName);
      }
      _selectAll = _selectedFiles.length == _backupFiles.length;
    });
  }

  /// 删除选中的备份文件
  ///
  /// 执行步骤：
  /// 1. 显示确认对话框
  /// 2. 设置加载状态
  /// 3. 遍历删除选中的文件
  /// 4. 显示删除结果
  /// 5. 重新加载文件列表
  Future<void> _deleteSelected() async {
    if (_selectedFiles.isEmpty) {
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedFiles.length} 个备份文件吗？此操作不可恢复。'),
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
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (result != true) return;

    setState(() {
      _isLoading = true;
    });

    String? errorMsg;
    try {
      final backupService = BackupService();

      for (final fileName in _selectedFiles) {
        if (_config.backupSetting.type == BackupType.webdav) {
          // 构建 WebDAV 文件 URL
          final url = backupService.buildWebDavFileUrl(
            _config.backupSetting.webDavConfig.url,
            _config.backupSetting.webDavConfig.backupDir,
            fileName,
          );
          // 删除 WebDAV 文件
          await WebDavUtils.deleteFile(
            url,
            _config.backupSetting.webDavConfig.username,
            _config.backupSetting.webDavConfig.password,
          );
        } else if (_config.backupSetting.type == BackupType.s3) {
          // 删除 S3 文件
          String objectKey = fileName;
          if (_config.backupSetting.s3Config.backupDir.isNotEmpty) {
            if (_config.backupSetting.s3Config.backupDir.endsWith('/')) {
              objectKey =
                  '${_config.backupSetting.s3Config.backupDir}$fileName';
            } else {
              objectKey =
                  '${_config.backupSetting.s3Config.backupDir}/$fileName';
            }
          }
          await S3Utils.deleteFile(
            _config.backupSetting.s3Config.endpoint,
            _config.backupSetting.s3Config.bucketName,
            objectKey,
            _config.backupSetting.s3Config.accessKeyId,
            _config.backupSetting.s3Config.secretAccessKey,
            region: _config.backupSetting.s3Config.region,
          );
        }
      }

      if (mounted) {
        StyleUtils.successSnackBar(context, '删除成功');
        _loadBackupFiles();
      }
    } catch (e) {
      errorMsg = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
        _selectedFiles.clear();
        _selectAll = false;
      });
    }

    if (errorMsg != null && mounted) {
      StyleUtils.errorSnackBar(context, '删除失败', errorMsg!);
    }
  }

  /// 恢复指定版本的备份文件
  ///
  /// [fileName] 备份文件名
  ///
  /// 执行步骤：
  /// 1. 显示确认对话框
  /// 2. 设置加载状态
  /// 3. 调用备份服务恢复指定文件
  /// 4. 显示恢复结果
  Future<void> _restoreFile(String fileName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: Text('确定要恢复到 "$fileName" 吗？\n恢复将覆盖当前所有数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定恢复'),
          ),
        ],
      ),
    );

    if (result != true) return;

    setState(() {
      _isLoading = true;
    });

    String? errorMsg;
    try {
      final backupService = BackupService();
      await backupService.restoreBackup(_config, specificFile: fileName);

      if (mounted) {
        StyleUtils.successSnackBar(context, '恢复成功');
        Navigator.pop(context);
      }
    } catch (e) {
      errorMsg = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    if (errorMsg != null && mounted) {
      StyleUtils.errorSnackBar(context, '恢复失败', errorMsg!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '管理远端备份',
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

          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 40),
          ] else if (_backupFiles.isEmpty) ...[
            const Center(child: Text('没有找到备份文件')),
            const SizedBox(height: 40),
          ] else ...[
            // 全选和删除按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _selectAll,
                      onChanged: (_) => _toggleSelectAll(),
                    ),
                    const Text('全选'),
                  ],
                ),
                ElevatedButton(
                  onPressed: _selectedFiles.isEmpty ? null : _deleteSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('删除'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 备份文件列表
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _backupFiles.length,
                itemBuilder: (context, index) {
                  final file = _backupFiles[index];
                  return CheckboxListTile(
                    value: _selectedFiles.contains(file.name),
                    onChanged: (_) => _toggleSelect(file.name),
                    title: Text(file.name),
                    subtitle: Text(
                      file.dateTime != null
                          ? '${file.dateTime!.year}-${file.dateTime!.month.toString().padLeft(2, '0')}-${file.dateTime!.day.toString().padLeft(2, '0')} ${file.dateTime!.hour.toString().padLeft(2, '0')}:${file.dateTime!.minute.toString().padLeft(2, '0')}:${file.dateTime!.second.toString().padLeft(2, '0')}'
                          : '未知时间',
                    ),
                    secondary: IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: '恢复',
                      onPressed: () => _restoreFile(file.name),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 备份文件模型
///
/// 用于存储备份文件的基本信息，包括文件名和创建时间
class BackupFile {
  /// 文件名
  final String name;

  /// 文件创建时间
  final DateTime? dateTime;

  /// 创建备份文件实例
  ///
  /// [name] 文件名
  /// [dateTime] 文件创建时间
  BackupFile({required this.name, this.dateTime});
}

/// 备份参数配置弹出层
class _BackupConfigDialog extends StatefulWidget {
  final Setting initialConfig;

  const _BackupConfigDialog({required this.initialConfig});

  @override
  State<_BackupConfigDialog> createState() => _BackupConfigDialogState();
}

class _BackupConfigDialogState extends State<_BackupConfigDialog> {
  late Setting _config;
  final _formKey = GlobalKey<FormState>();
  bool _hasBackupPassword = false;

  // WebDAV 控制器
  late TextEditingController _webDavUrlController;
  late TextEditingController _webDavBackupDirController;
  late TextEditingController _webDavUsernameController;
  late TextEditingController _webDavPasswordController;

  // S3 控制器
  late TextEditingController _s3EndpointController;
  late TextEditingController _s3AccessKeyIdController;
  late TextEditingController _s3SecretAccessKeyController;
  late TextEditingController _s3BucketNameController;
  late TextEditingController _s3BackupDirController;
  late TextEditingController _s3RegionController;

  // 备份密码控制器
  late TextEditingController _backupPasswordController;
  late TextEditingController _backupConfirmPasswordController;

  // 历史版本数控制器
  late TextEditingController _historyCountController;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _initControllers();
    _checkPasswordStatus();
  }

  Future<void> _checkPasswordStatus() async {
    _hasBackupPassword = await BackupService().hasBackupPassword();
    if (!mounted) return;
    setState(() {});
  }

  /// 初始化控制器
  void _initControllers() {
    // WebDAV 控制器
    _webDavUrlController = TextEditingController(
      text: _config.backupSetting.webDavConfig.url,
    );
    // 检查WebDAV是否首次配置：如果所有必填字段都为空，说明是首次配置，预填"EasyAuth"
    // 如果用户已经配置过（其他字段有值），则尊重用户的设置，即使backupDir为空
    bool isWebDavFirstTimeSetup =
        _config.backupSetting.webDavConfig.url.isEmpty &&
        _config.backupSetting.webDavConfig.username.isEmpty &&
        _config.backupSetting.webDavConfig.password.isEmpty;

    _webDavBackupDirController = TextEditingController(
      text:
          (isWebDavFirstTimeSetup &&
              _config.backupSetting.webDavConfig.backupDir.isEmpty)
          ? 'EasyAuth'
          : _config.backupSetting.webDavConfig.backupDir,
    );
    _webDavUsernameController = TextEditingController(
      text: _config.backupSetting.webDavConfig.username,
    );
    _webDavPasswordController = TextEditingController(
      text: _config.backupSetting.webDavConfig.password,
    );

    // S3 控制器
    _s3EndpointController = TextEditingController(
      text: _config.backupSetting.s3Config.endpoint,
    );
    _s3AccessKeyIdController = TextEditingController(
      text: _config.backupSetting.s3Config.accessKeyId,
    );
    _s3SecretAccessKeyController = TextEditingController(
      text: _config.backupSetting.s3Config.secretAccessKey,
    );
    _s3BucketNameController = TextEditingController(
      text: _config.backupSetting.s3Config.bucketName,
    );
    // 检查S3是否首次配置：如果所有必填字段都为空，说明是首次配置，预填"EasyAuth"
    // 如果用户已经配置过（其他字段有值），则尊重用户的设置，即使backupDir为空
    bool isFirstTimeSetup =
        _config.backupSetting.s3Config.endpoint.isEmpty &&
        _config.backupSetting.s3Config.accessKeyId.isEmpty &&
        _config.backupSetting.s3Config.secretAccessKey.isEmpty &&
        _config.backupSetting.s3Config.bucketName.isEmpty;

    _s3BackupDirController = TextEditingController(
      text:
          (isFirstTimeSetup && _config.backupSetting.s3Config.backupDir.isEmpty)
          ? 'EasyAuth'
          : _config.backupSetting.s3Config.backupDir,
    );
    _s3RegionController = TextEditingController(
      text: _config.backupSetting.s3Config.region,
    );

    _backupPasswordController = TextEditingController();
    _backupConfirmPasswordController = TextEditingController();
    _historyCountController = TextEditingController(
      text: _config.backupSetting.historyCount.toString(),
    );
  }

  @override
  void dispose() {
    //  dispose 控制器
    _webDavUrlController.dispose();
    _webDavBackupDirController.dispose();
    _webDavUsernameController.dispose();
    _webDavPasswordController.dispose();

    _s3EndpointController.dispose();
    _s3AccessKeyIdController.dispose();
    _s3SecretAccessKeyController.dispose();
    _s3BucketNameController.dispose();
    _s3BackupDirController.dispose();
    _s3RegionController.dispose();
    _backupPasswordController.dispose();
    _backupConfirmPasswordController.dispose();
    _historyCountController.dispose();

    super.dispose();
  }

  /// 打开链接
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法打开链接，请检查是否安装了浏览器'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开链接失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return AnimatedPadding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      duration: const Duration(milliseconds: 100),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
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
                  initialValue: _config.backupSetting.type.name,
                  decoration: const InputDecoration(
                    labelText: '备份类型',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'off', child: Text('关闭')),
                    const DropdownMenuItem(
                      value: 'webdav',
                      child: Text('WebDAV'),
                    ),
                    const DropdownMenuItem(value: 's3', child: Text('对象存储')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      final newType = BackupType.values.firstWhere(
                        (e) => e.name == value,
                      );
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            type: newType,
                          ),
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                if (_config.backupSetting.type != BackupType.off) ...[
                  if (_hasBackupPassword)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          const Text('备份密码已设置',
                              style: TextStyle(color: Colors.black87)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _hasBackupPassword = false;
                                _backupPasswordController.clear();
                                _backupConfirmPasswordController.clear();
                              });
                            },
                            child: const Text('修改'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    TextFormField(
                      controller: _backupPasswordController,
                      decoration: const InputDecoration(
                        labelText: '备份密码',
                        hintText: '请设置备份加密密码',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '备份密码不能为空';
                        }
                        if (value.length < 8) {
                          return '备份密码长度不能少于8位';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _backupConfirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: '确认备份密码',
                        hintText: '请再次输入备份密码',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '确认备份密码不能为空';
                        }
                        if (value != _backupPasswordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '备份密码用于加密备份文件。多台设备需设置相同密码才能共享备份。',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],

                if (_config.backupSetting.type != BackupType.off) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _historyCountController,
                    decoration: const InputDecoration(
                      labelText: '保留历史版本数',
                      hintText: '默认 10，设为 0 则不限制',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final n = int.tryParse(value);
                        if (n == null || n < 0) {
                          return '请输入不小于 0 的数字';
                        }
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final count = int.tryParse(value);
                      if (count != null && count >= 0) {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            historyCount: count,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // WebDAV 配置
                if (_config.backupSetting.type == BackupType.webdav) ...[
                  TextFormField(
                    controller: _webDavUrlController,
                    decoration: const InputDecoration(
                      labelText: 'WebDAV地址',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'WebDAV地址不能为空';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      String processedValue = value;
                      if (processedValue.endsWith('/')) {
                        processedValue = processedValue.substring(
                          0,
                          processedValue.length - 1,
                        );
                      }
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            webDavConfig: _config.backupSetting.webDavConfig
                                .copyWith(url: processedValue),
                          ),
                        );
                      });
                    },
                  ),
                  if (_webDavUrlController.text.startsWith('http://'))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '建议使用 HTTPS 连接，HTTP 下凭据将明文传输',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _webDavUsernameController,
                    decoration: const InputDecoration(
                      labelText: '授权账号',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '授权账号不能为空';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            webDavConfig: _config.backupSetting.webDavConfig
                                .copyWith(username: value),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _webDavPasswordController,
                    decoration: const InputDecoration(
                      labelText: '授权密码',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '授权密码不能为空';
                      }
                      return null;
                    },
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            webDavConfig: _config.backupSetting.webDavConfig
                                .copyWith(password: value),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _webDavBackupDirController,
                    decoration: const InputDecoration(
                      labelText: '存储路径',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '存储路径不能为空';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            webDavConfig: _config.backupSetting.webDavConfig
                                .copyWith(backupDir: value.trim()),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          _launchUrl('https://help.jianguoyun.com/?p=2064'),
                      child: const Text('如何获取配置信息'),
                    ),
                  ),
                ] else if (_config.backupSetting.type == BackupType.s3) ...[
                  // 对象存储/S3/OSS/COS 配置
                  TextFormField(
                    controller: _s3EndpointController,
                    decoration: const InputDecoration(
                      labelText: 'Endpoint URL',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Endpoint URL不能为空';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(
                              endpoint: value,
                            ),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3AccessKeyIdController,
                    decoration: const InputDecoration(
                      labelText: 'Access Key ID',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Access Key ID不能为空';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(
                              accessKeyId: value,
                            ),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3SecretAccessKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Secret Access Key',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Secret Access Key不能为空';
                      }
                      return null;
                    },
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(
                              secretAccessKey: value,
                            ),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3BucketNameController,
                    decoration: const InputDecoration(
                      labelText: 'Bucket Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bucket Name不能为空';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(
                              bucketName: value,
                            ),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3BackupDirController,
                    decoration: const InputDecoration(
                      labelText: 'Path',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        String processedValue = value.trim();
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(
                              backupDir: processedValue,
                            ),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3RegionController,
                    decoration: const InputDecoration(
                      labelText: 'Region ( 选填，默认cn-east-1)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(
                              region: value,
                            ),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _launchUrl('https://s.qiniu.com/eeemeu'),
                      child: const Text('如何获取配置信息'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '推荐使用七牛云对象存储',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              TextButton(
                                onPressed: () =>
                                    _launchUrl('https://s.qiniu.com/fAn6ru'),
                                child: const Text('立即注册七牛云，即获万元免费额度'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            // 保存备份密码
                            final password = _backupPasswordController.text;
                            if (!_hasBackupPassword && password.isNotEmpty) {
                              await BackupService().saveBackupPassword(password);
                            } else if (!_hasBackupPassword) {
                              // 如果之前没设置且现在也没输入，清除密码
                              await BackupService().saveBackupPassword('');
                            }
                            // 如果已有密码且用户修改了
                            if (_hasBackupPassword && password.isNotEmpty) {
                              await BackupService().saveBackupPassword(password);
                            }

                            // 根据备份类型决定保存哪些数据，清空其他类型的数据
                            BackupSetting newBackupSetting;

                            if (_config.backupSetting.type == BackupType.off) {
                              // 类型=关闭：清空 WEBDAV 和对象存储的数据
                              newBackupSetting = _config.backupSetting.copyWith(
                                webDavConfig: const WebDavConfig(
                                  url: '',
                                  backupDir: '',
                                  username: '',
                                  password: '',
                                ),
                                s3Config: const S3Config(
                                  endpoint: '',
                                  accessKeyId: '',
                                  secretAccessKey: '',
                                  bucketName: '',
                                  backupDir: '',
                                ),
                              );
                            } else if (_config.backupSetting.type ==
                                BackupType.webdav) {
                              // 类型=WEBDAV：保存 WEBDAV 数据，清空对象存储的数据
                              newBackupSetting = _config.backupSetting.copyWith(
                                webDavConfig: _config.backupSetting.webDavConfig
                                    .copyWith(
                                      url: _webDavUrlController.text.endsWith('/')
                                          ? _webDavUrlController.text.substring(0, _webDavUrlController.text.length - 1)
                                          : _webDavUrlController.text,
                                      backupDir:
                                          _webDavBackupDirController.text,
                                      username: _webDavUsernameController.text,
                                      password: _webDavPasswordController.text,
                                    ),
                                s3Config: const S3Config(
                                  endpoint: '',
                                  accessKeyId: '',
                                  secretAccessKey: '',
                                  bucketName: '',
                                  backupDir: '',
                                ),
                              );
                            } else if (_config.backupSetting.type ==
                                BackupType.s3) {
                              // 类型=对象存储：保存对象存储数据，清空 WEBDAV 的数据
                              newBackupSetting = _config.backupSetting.copyWith(
                                webDavConfig: const WebDavConfig(
                                  url: '',
                                  backupDir: '',
                                  username: '',
                                  password: '',
                                ),
                                s3Config: _config.backupSetting.s3Config
                                    .copyWith(
                                      endpoint: _s3EndpointController.text,
                                      accessKeyId:
                                          _s3AccessKeyIdController.text,
                                      secretAccessKey:
                                          _s3SecretAccessKeyController.text,
                                      bucketName: _s3BucketNameController.text,
                                      backupDir: _s3BackupDirController.text,
                                      region: _s3RegionController.text,
                                    ),
                              );
                            } else {
                              // 默认情况，保持原有逻辑
                              newBackupSetting = _config.backupSetting.copyWith(
                                webDavConfig: _config.backupSetting.webDavConfig
                                    .copyWith(
                                      url: _webDavUrlController.text.endsWith('/')
                                          ? _webDavUrlController.text.substring(0, _webDavUrlController.text.length - 1)
                                          : _webDavUrlController.text,
                                      backupDir:
                                          _webDavBackupDirController.text,
                                      username: _webDavUsernameController.text,
                                      password: _webDavPasswordController.text,
                                    ),
                                s3Config: _config.backupSetting.s3Config
                                    .copyWith(
                                      endpoint: _s3EndpointController.text,
                                      accessKeyId:
                                          _s3AccessKeyIdController.text,
                                      secretAccessKey:
                                          _s3SecretAccessKeyController.text,
                                      bucketName: _s3BucketNameController.text,
                                      backupDir: _s3BackupDirController.text,
                                      region: _s3RegionController.text,
                                    ),
                              );
                            }

                            final historyCount = int.tryParse(
                              _historyCountController.text,
                            );
                            if (historyCount != null && historyCount >= 0) {
                              newBackupSetting = newBackupSetting.copyWith(
                                historyCount: historyCount,
                              );
                            }

                            _config = _config.copyWith(
                              backupSetting: newBackupSetting,
                            );

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
        ),
      ),
    );
  }
}
