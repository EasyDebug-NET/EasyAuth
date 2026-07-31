import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/setting.dart';
import '../providers/locale_provider.dart';
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

  /// 是否已完成首次初始化
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromArguments();
      if (!_initialized) {
        _initialized = true;
        _loadConfig();
        _checkBiometricAvailability();
      }
    });
  }

  /// 接收来自 home_screen 的路由参数
  void _initFromArguments() {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _fromCloudIcon = arguments['fromCloudIcon'] ?? false;
    }
  }

  /// 检查生物识别可用性
  Future<void> _checkBiometricAvailability() async {
    _isBiometricAvailable = await _securityService.isBiometricAvailable();
    debugPrint('生物识别可用性: $_isBiometricAvailable');
    setState(() {});
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final setting = await _backupService.loadConfig();
      if (!mounted) return;
      setState(() {
        _setting = setting;
        _isLoadingConfig = false;
      });

      // 检查是否未配置备份参数且是从云图标点击跳转过来
      if (_fromCloudIcon && _setting.backupSetting.type == BackupType.off) {
        StyleUtils.normalSnackBar(context, l10n.snackNotConfigured);
      }
    } catch (e) {
      debugPrint('加载配置失败: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingConfig = false;
      });
      StyleUtils.errorSnackBar(context, l10n.snackLoadConfigFailed(e.toString()));
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await _backupService.saveConfig(_setting);
    } catch (e) {
      debugPrint('保存配置失败: $e');
      if (mounted) {
        StyleUtils.errorSnackBar(context, l10n.snackSaveConfigFailed(e.toString()));
      }
    }
  }

  /// 更新截屏锁状态
  Future<void> _updateScreenshotLock(bool enabled) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      if (enabled) {
        await FlutterWindowManagerPlus.addFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
        debugPrint('截屏锁已开启');
        if (mounted) {
          StyleUtils.normalSnackBar(context, l10n.snackScreenshotLockOn);
        }
      } else {
        await FlutterWindowManagerPlus.clearFlags(
          FlutterWindowManagerPlus.FLAG_SECURE,
        );
        debugPrint('截屏锁已关闭');
        if (mounted) {
          StyleUtils.normalSnackBar(context, l10n.snackScreenshotLockOff);
        }
      }
    } catch (e) {
      debugPrint('更新截屏锁状态失败: $e');
      if (mounted) {
        StyleUtils.errorSnackBar(context, l10n.snackScreenshotLockError(e.toString()));
      }
    }
  }

  /// 处理应用锁开关变化
  Future<void> _handleAppLockToggle(bool value) async {
    final l10n = AppLocalizations.of(context)!;

    if (value) {
      if (!_isBiometricAvailable) {
        StyleUtils.normalSnackBar(context, l10n.snackBiometricNotAvailable);
        return;
      }

      bool authenticated = await _securityService.authenticate(
        reason: l10n.authReasonEnable,
      );

      if (authenticated) {
        setState(() {
          _setting = _setting.copyWith(
            securitySetting: _setting.securitySetting.copyWith(
              appLockEnabled: true,
            ),
          );
        });
        await _saveConfig();
        if (mounted) {
          StyleUtils.normalSnackBar(context, l10n.snackAppLockEnabled);
        }
      }
    } else {
      bool authenticated = await _securityService.authenticate(
        reason: l10n.authReasonDisable,
      );

      if (authenticated) {
        setState(() {
          _setting = _setting.copyWith(
            securitySetting: _setting.securitySetting.copyWith(
              appLockEnabled: false,
            ),
          );
        });
        await _saveConfig();
        if (mounted) {
          StyleUtils.normalSnackBar(context, l10n.snackAppLockDisabled);
        }
      } else {
        if (mounted) {
          StyleUtils.errorSnackBar(context, l10n.snackAppLockDisableFailed);
        }
      }
    }
  }

  /// 获取备份配置状态文本
  String _getBackupConfigStatusText() {
    final l10n = AppLocalizations.of(context)!;
    if (_setting.backupSetting.type == BackupType.off) {
      return l10n.statusNotConfigured;
    }
    return l10n.statusConfigured;
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

    final l10n = AppLocalizations.of(context)!;

    if (_setting.backupSetting.type == BackupType.off) {
      StyleUtils.normalSnackBar(context, l10n.snackSelectBackupTypeFirst);
      return;
    }

    if (!_backupService.isConfigValid(_setting)) {
      StyleUtils.normalSnackBar(context, l10n.snackConfigureBackupFirst);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _backupService.performBackup(_setting);
      if (mounted) {
        StyleUtils.successSnackBar(context, l10n.snackBackupSuccess);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = l10n.snackBackupFailed;
        String? errorDetails;

        if (e is AppException) {
          errorMessage = e.message;
          errorDetails = e.details;
        } else {
          errorMessage = '${l10n.snackBackupFailed}: ${e.toString()}';
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

    final l10n = AppLocalizations.of(context)!;

    if (_setting.backupSetting.type == BackupType.off) {
      StyleUtils.normalSnackBar(context, l10n.snackSelectBackupTypeFirst);
      return;
    }

    if (!_backupService.isConfigValid(_setting)) {
      StyleUtils.normalSnackBar(context, l10n.snackConfigureBackupFirst);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogTitleConfirmRestore),
        content: Text(l10n.dialogConfirmRestoreBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.dialogButtonConfirmRestore),
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
          StyleUtils.successSnackBar(context, l10n.snackRestoreSuccess);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = l10n.snackRestoreFailed;
          String? errorDetails;

          if (e is AppException) {
            errorMessage = e.message;
            errorDetails = e.details;
          } else {
            errorMessage = '${l10n.snackRestoreFailed}: ${e.toString()}';
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

    final l10n = AppLocalizations.of(context)!;

    if (_setting.backupSetting.type == BackupType.off) {
      StyleUtils.normalSnackBar(context, l10n.snackSelectBackupTypeFirst);
      return;
    }

    if (!_backupService.isConfigValid(_setting)) {
      StyleUtils.normalSnackBar(context, l10n.snackConfigureBackupFirst);
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
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingConfig) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.loadingConfig),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
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
                  Text(l10n.loadingOperation),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loadingPleaseWait,
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
                      child: _buildSection(l10n.sectionBackupSettings, [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showBackupConfigDialog,
                            style: StyleUtils.primaryButtonStyleLeft(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.backupConfigTitle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                          _buildButton(l10n.backupToRemote, _performBackup, primaryColor),
                          const SizedBox(height: 16),
                          _buildButton(l10n.restoreFromRemote, _restoreBackup, primaryColor),
                          const SizedBox(height: 16),
                          _buildButton(
                            l10n.manageRemoteBackups,
                            _manageRemoteBackup,
                            primaryColor,
                          ),
                        ],
                      ]),
                    ),
                    Divider(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
                      height: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSection(l10n.sectionSecuritySettings, [
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
                                          l10n.labelAppLock,
                                          style: StyleUtils.lockTextStyle(context),
                                        ),
                                        if (!_isBiometricAvailable)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: Text(
                                              l10n.biometricNotSupported,
                                              style: const TextStyle(
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
                                      inactiveTrackColor: Theme.of(context).brightness == Brightness.light
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
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
                                          l10n.labelScreenshotLock,
                                          style: StyleUtils.lockTextStyle(context),
                                        ),
                                        if (!Platform.isAndroid)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Text(
                                              l10n.androidOnly,
                                              style: const TextStyle(
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
                                        await _updateScreenshotLock(value);
                                      } : null,
                                      activeThumbColor: Colors.white,
                                      inactiveThumbColor: Colors.white,
                                      activeTrackColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      inactiveTrackColor: Theme.of(context).brightness == Brightness.light
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
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
                    Divider(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
                      height: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildLanguageSection(l10n.sectionLanguage),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// 语言选项列表（新语言只需在这里加一行）
  static const List<({Locale locale, String label})> _languageOptions = [
    (locale: Locale('en'), label: 'English'),
    (
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      label: '简体中文',
    ),
    (
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      label: '繁體中文',
    ),
    (locale: Locale('ja'), label: '日本語'),
    (locale: Locale('ko'), label: '한국어'),
  ];

  /// 构建语言选择区域（下拉选择样式，与其他 section 统一）
  Widget _buildLanguageSection(String title) {
    final localeProvider = context.watch<LocaleProvider>();
    final currentLabel = _languageOptions
        .firstWhere(
          (o) => LocaleProvider.localeEquals(o.locale, localeProvider.currentLocale),
          orElse: () => _languageOptions.first,
        )
        .label;

    return _buildSection(title, [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _showLanguagePicker,
          style: StyleUtils.primaryButtonStyleLeft(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(currentLabel),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    ]);
  }

  /// 显示语言选择底部弹窗
  void _showLanguagePicker() {
    final localeProvider = context.read<LocaleProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    AppLocalizations.of(ctx)!.sectionLanguage,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ..._languageOptions.map(
                  (option) {
                    final isSelected = LocaleProvider.localeEquals(
                      localeProvider.currentLocale,
                      option.locale,
                    );
                    return ListTile(
                      title: Text(option.label, style: const TextStyle(fontSize: 16)),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        localeProvider.setLocale(option.locale);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
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
class _RemoteBackupManager extends StatefulWidget {
  final Setting config;
  const _RemoteBackupManager({required this.config});

  @override
  State<_RemoteBackupManager> createState() => _RemoteBackupManagerState();
}

class _RemoteBackupManagerState extends State<_RemoteBackupManager> {
  late Setting _config;
  List<BackupFile> _backupFiles = [];
  bool _isLoading = true;
  bool _selectAll = false;
  final _selectedFiles = <String>{};

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final backupService = BackupService();
      List<String> files;

      if (_config.backupSetting.type == BackupType.webdav) {
        final listUrl = backupService.buildWebDavDirUrl(
          _config.backupSetting.webDavConfig.url,
          _config.backupSetting.webDavConfig.backupDir,
        );
        files = await WebDavUtils.listFiles(
          listUrl,
          _config.backupSetting.webDavConfig.username,
          _config.backupSetting.webDavConfig.password,
        );
      } else if (_config.backupSetting.type == BackupType.s3) {
        files = await S3Utils.listFiles(
          _config.backupSetting.s3Config.endpoint,
          _config.backupSetting.s3Config.bucketName,
          _config.backupSetting.s3Config.accessKeyId,
          _config.backupSetting.s3Config.secretAccessKey,
          region: _config.backupSetting.s3Config.region,
        );
        if (_config.backupSetting.s3Config.backupDir.isNotEmpty) {
          files = files
              .where((file) => file.startsWith(_config.backupSetting.s3Config.backupDir))
              .map((file) => file
                  .substring(_config.backupSetting.s3Config.backupDir.length)
                  .replaceFirst(RegExp(r'^/'), ''))
              .toList();
        }
      } else {
        files = [];
      }

      final backupFiles = files
          .where((file) => file.startsWith('backup_') && file.endsWith('.zip'))
          .map((file) {
            final timestamp = file.replaceAll('backup_', '').replaceAll('.zip', '');
            DateTime? dateTime;
            try {
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
        StyleUtils.normalSnackBar(context, l10n.snackLoadFailed(e.toString()));
      }
    }
  }

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

  Future<void> _deleteSelected() async {
    if (_selectedFiles.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogTitleConfirmDelete),
        content: Text(l10n.dialogConfirmDeleteBackups(_selectedFiles.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.buttonDelete),
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
          final url = backupService.buildWebDavFileUrl(
            _config.backupSetting.webDavConfig.url,
            _config.backupSetting.webDavConfig.backupDir,
            fileName,
          );
          await WebDavUtils.deleteFile(
            url,
            _config.backupSetting.webDavConfig.username,
            _config.backupSetting.webDavConfig.password,
          );
        } else if (_config.backupSetting.type == BackupType.s3) {
          String objectKey = fileName;
          if (_config.backupSetting.s3Config.backupDir.isNotEmpty) {
            if (_config.backupSetting.s3Config.backupDir.endsWith('/')) {
              objectKey = '${_config.backupSetting.s3Config.backupDir}$fileName';
            } else {
              objectKey = '${_config.backupSetting.s3Config.backupDir}/$fileName';
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
        StyleUtils.successSnackBar(context, l10n.snackDeleteSuccess);
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
      StyleUtils.errorSnackBar(context, l10n.snackDeleteFailed, errorMsg);
    }
  }

  Future<void> _restoreFile(String fileName) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogTitleConfirmRestore),
        content: Text(l10n.dialogConfirmRestoreFile(fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.dialogButtonConfirmRestore),
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
        StyleUtils.successSnackBar(context, l10n.snackRestoreSuccess);
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
      StyleUtils.errorSnackBar(context, l10n.snackRestoreFailed, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                l10n.manageRemoteBackups,
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
            Center(child: Text(l10n.emptyNoBackupFiles)),
            const SizedBox(height: 40),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _selectAll,
                      onChanged: (_) => _toggleSelectAll(),
                    ),
                    Text(l10n.buttonSelectAll),
                  ],
                ),
                ElevatedButton(
                  onPressed: _selectedFiles.isEmpty ? null : _deleteSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.buttonDelete),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                          : l10n.statusUnknownTime,
                    ),
                    secondary: IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: l10n.buttonRestore,
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
class BackupFile {
  final String name;
  final DateTime? dateTime;
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

  late TextEditingController _webDavUrlController;
  late TextEditingController _webDavBackupDirController;
  late TextEditingController _webDavUsernameController;
  late TextEditingController _webDavPasswordController;

  late TextEditingController _s3EndpointController;
  late TextEditingController _s3AccessKeyIdController;
  late TextEditingController _s3SecretAccessKeyController;
  late TextEditingController _s3BucketNameController;
  late TextEditingController _s3BackupDirController;
  late TextEditingController _s3RegionController;

  late TextEditingController _backupPasswordController;
  late TextEditingController _backupConfirmPasswordController;
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

  void _initControllers() {
    _webDavUrlController = TextEditingController(text: _config.backupSetting.webDavConfig.url);
    bool isWebDavFirstTimeSetup =
        _config.backupSetting.webDavConfig.url.isEmpty &&
        _config.backupSetting.webDavConfig.username.isEmpty &&
        _config.backupSetting.webDavConfig.password.isEmpty;

    _webDavBackupDirController = TextEditingController(
      text: (isWebDavFirstTimeSetup && _config.backupSetting.webDavConfig.backupDir.isEmpty)
          ? 'EasyAuth'
          : _config.backupSetting.webDavConfig.backupDir,
    );
    _webDavUsernameController = TextEditingController(text: _config.backupSetting.webDavConfig.username);
    _webDavPasswordController = TextEditingController(text: _config.backupSetting.webDavConfig.password);

    _s3EndpointController = TextEditingController(text: _config.backupSetting.s3Config.endpoint);
    _s3AccessKeyIdController = TextEditingController(text: _config.backupSetting.s3Config.accessKeyId);
    _s3SecretAccessKeyController = TextEditingController(text: _config.backupSetting.s3Config.secretAccessKey);
    _s3BucketNameController = TextEditingController(text: _config.backupSetting.s3Config.bucketName);
    bool isFirstTimeSetup =
        _config.backupSetting.s3Config.endpoint.isEmpty &&
        _config.backupSetting.s3Config.accessKeyId.isEmpty &&
        _config.backupSetting.s3Config.secretAccessKey.isEmpty &&
        _config.backupSetting.s3Config.bucketName.isEmpty;

    _s3BackupDirController = TextEditingController(
      text: (isFirstTimeSetup && _config.backupSetting.s3Config.backupDir.isEmpty)
          ? 'EasyAuth'
          : _config.backupSetting.s3Config.backupDir,
    );
    _s3RegionController = TextEditingController(text: _config.backupSetting.s3Config.region);

    _backupPasswordController = TextEditingController();
    _backupConfirmPasswordController = TextEditingController();
    _historyCountController = TextEditingController(text: _config.backupSetting.historyCount.toString());
  }

  @override
  void dispose() {
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

  Future<void> _launchUrl(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCannotOpenUrl),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOpenUrlFailed(e.toString())),
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
    final l10n = AppLocalizations.of(context)!;

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
                    Expanded(
                      child: Text(
                        l10n.backupConfigTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  initialValue: _config.backupSetting.type.name,
                  decoration: InputDecoration(
                    labelText: l10n.labelBackupType,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'off', child: Text(l10n.backupTypeOff)),
                    DropdownMenuItem(value: 'webdav', child: Text(l10n.backupTypeWebDAV)),
                    DropdownMenuItem(value: 's3', child: Text(l10n.backupTypeS3)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      final newType = BackupType.values.firstWhere((e) => e.name == value);
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(type: newType),
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
                          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.passwordAlreadySet, style: const TextStyle(color: Colors.black87)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _hasBackupPassword = false;
                                _backupPasswordController.clear();
                                _backupConfirmPasswordController.clear();
                              });
                            },
                            child: Text(l10n.buttonModify),
                          ),
                        ],
                      ),
                    )
                  else ...[

                    TextFormField(
                      controller: _backupPasswordController,
                      decoration: InputDecoration(
                        labelText: l10n.labelBackupPassword,
                        hintText: l10n.hintBackupPassword,
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.validationBackupPasswordRequired;
                        }
                        if (value.length < 8) {
                          return l10n.validationBackupPasswordMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _backupConfirmPasswordController,
                      decoration: InputDecoration(
                        labelText: l10n.labelConfirmBackupPassword,
                        hintText: l10n.hintConfirmBackupPassword,
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.validationConfirmPasswordRequired;
                        }
                        if (value != _backupPasswordController.text) {
                          return l10n.validationPasswordMismatch;
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.passwordTipMessage,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ],
                ],

                if (_config.backupSetting.type != BackupType.off) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _historyCountController,
                    decoration: InputDecoration(
                      labelText: l10n.labelHistoryCount,
                      hintText: l10n.hintHistoryCount,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final n = int.tryParse(value);
                        if (n == null || n < 0) {
                          return l10n.validationHistoryCountInvalid;
                        }
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final count = int.tryParse(value);
                      if (count != null && count >= 0) {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(historyCount: count),
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
                    decoration: InputDecoration(
                      labelText: l10n.labelWebDavUrl,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationWebDavUrlRequired;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      String processedValue = value;
                      if (processedValue.endsWith('/')) {
                        processedValue = processedValue.substring(0, processedValue.length - 1);
                      }
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            webDavConfig: _config.backupSetting.webDavConfig.copyWith(url: processedValue),
                          ),
                        );
                      });
                    },
                  ),
                  if (_webDavUrlController.text.startsWith('http://'))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.httpsWarning,
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _webDavUsernameController,
                    decoration: InputDecoration(
                      labelText: l10n.labelWebDavUsername,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationWebDavUsernameRequired;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            webDavConfig: _config.backupSetting.webDavConfig.copyWith(username: value),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _webDavPasswordController,
                    decoration: InputDecoration(
                      labelText: l10n.labelWebDavPassword,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationWebDavPasswordRequired;
                      }
                      return null;
                    },
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            webDavConfig: _config.backupSetting.webDavConfig.copyWith(password: value),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _webDavBackupDirController,
                    decoration: InputDecoration(
                      labelText: l10n.labelStoragePath,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationStoragePathRequired;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            webDavConfig: _config.backupSetting.webDavConfig.copyWith(backupDir: value.trim()),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _launchUrl('https://help.jianguoyun.com/?p=2064'),
                      child: Text(l10n.howToGetConfig),
                    ),
                  ),
                ] else if (_config.backupSetting.type == BackupType.s3) ...[
                  // S3 配置
                  TextFormField(
                    controller: _s3EndpointController,
                    decoration: InputDecoration(
                      labelText: l10n.labelEndpointUrl,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationEndpointRequired;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(endpoint: value),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3AccessKeyIdController,
                    decoration: InputDecoration(
                      labelText: l10n.labelAccessKeyId,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationAccessKeyRequired;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(accessKeyId: value),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3SecretAccessKeyController,
                    decoration: InputDecoration(
                      labelText: l10n.labelSecretAccessKey,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationSecretKeyRequired;
                      }
                      return null;
                    },
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(secretAccessKey: value),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3BucketNameController,
                    decoration: InputDecoration(
                      labelText: l10n.labelBucketName,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.validationBucketNameRequired;
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(bucketName: value),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3BackupDirController,
                    decoration: InputDecoration(
                      labelText: l10n.labelPath,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        String processedValue = value.trim();
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(backupDir: processedValue),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _s3RegionController,
                    decoration: InputDecoration(
                      labelText: l10n.labelRegion,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _config = _config.copyWith(
                          backupSetting: _config.backupSetting.copyWith(
                            s3Config: _config.backupSetting.s3Config.copyWith(region: value),
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
                      child: Text(l10n.howToGetConfig),
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
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.qiniuPromoTitle,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              TextButton(
                                onPressed: () => _launchUrl('https://s.qiniu.com/fAn6ru'),
                                child: Text(l10n.qiniuPromoLink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: Text(l10n.buttonCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            final password = _backupPasswordController.text;
                            // 仅在密码字段可见时（首次设置或修改密码）保存新密码；
                            // 表单校验已保证 password 非空且长度 >= 8
                            if (!_hasBackupPassword) {
                              await BackupService().saveBackupPassword(password);
                            }

                            BackupSetting newBackupSetting;

                            if (_config.backupSetting.type == BackupType.off) {
                              newBackupSetting = _config.backupSetting.copyWith(
                                webDavConfig: const WebDavConfig(url: '', backupDir: '', username: '', password: ''),
                                s3Config: const S3Config(endpoint: '', accessKeyId: '', secretAccessKey: '', bucketName: '', backupDir: ''),
                              );
                            } else if (_config.backupSetting.type == BackupType.webdav) {
                              newBackupSetting = _config.backupSetting.copyWith(
                                webDavConfig: _config.backupSetting.webDavConfig.copyWith(
                                  url: _webDavUrlController.text.endsWith('/')
                                      ? _webDavUrlController.text.substring(0, _webDavUrlController.text.length - 1)
                                      : _webDavUrlController.text,
                                  backupDir: _webDavBackupDirController.text,
                                  username: _webDavUsernameController.text,
                                  password: _webDavPasswordController.text,
                                ),
                                s3Config: const S3Config(endpoint: '', accessKeyId: '', secretAccessKey: '', bucketName: '', backupDir: ''),
                              );
                            } else if (_config.backupSetting.type == BackupType.s3) {
                              newBackupSetting = _config.backupSetting.copyWith(
                                webDavConfig: const WebDavConfig(url: '', backupDir: '', username: '', password: ''),
                                s3Config: _config.backupSetting.s3Config.copyWith(
                                  endpoint: _s3EndpointController.text,
                                  accessKeyId: _s3AccessKeyIdController.text,
                                  secretAccessKey: _s3SecretAccessKeyController.text,
                                  bucketName: _s3BucketNameController.text,
                                  backupDir: _s3BackupDirController.text,
                                  region: _s3RegionController.text,
                                ),
                              );
                            } else {
                              newBackupSetting = _config.backupSetting.copyWith(
                                webDavConfig: _config.backupSetting.webDavConfig.copyWith(
                                  url: _webDavUrlController.text.endsWith('/')
                                      ? _webDavUrlController.text.substring(0, _webDavUrlController.text.length - 1)
                                      : _webDavUrlController.text,
                                  backupDir: _webDavBackupDirController.text,
                                  username: _webDavUsernameController.text,
                                  password: _webDavPasswordController.text,
                                ),
                                s3Config: _config.backupSetting.s3Config.copyWith(
                                  endpoint: _s3EndpointController.text,
                                  accessKeyId: _s3AccessKeyIdController.text,
                                  secretAccessKey: _s3SecretAccessKeyController.text,
                                  bucketName: _s3BucketNameController.text,
                                  backupDir: _s3BackupDirController.text,
                                  region: _s3RegionController.text,
                                ),
                              );
                            }

                            final historyCount = int.tryParse(_historyCountController.text);
                            if (historyCount != null && historyCount >= 0) {
                              newBackupSetting = newBackupSetting.copyWith(historyCount: historyCount);
                            }

                            _config = _config.copyWith(backupSetting: newBackupSetting);

                            if (!context.mounted) return;
                            Navigator.pop(context, _config);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(l10n.buttonConfirm),
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
