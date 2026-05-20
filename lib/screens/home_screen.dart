import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/setting.dart';
import '../models/two_factor_account.dart';
import '../services/backup_service.dart';
import '../services/security_service.dart';
import '../services/storage_service.dart';
import '../services/otp_service.dart';
import '../utils/exceptions.dart';
import '../utils/style_utils.dart';

/// 主页面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  /// 数据库存储服务
  final StorageService _storageService = StorageService();
  /// 备份/恢复服务
  final BackupService _backupService = BackupService();
  /// 安全认证服务（生物识别等）
  final SecurityService _securityService = SecurityService();

  /// 认证失败后退出应用的延迟时间
  static const _authFailureExitDelay = Duration(milliseconds: 500);
  /// 操作结果状态（成功/失败）的自动重置时间
  static const _operationStatusResetDuration = Duration(seconds: 3);

  /// 是否需要显示认证界面
  bool _needsAuthentication = false;
  /// 应用设置配置
  Setting? _setting;
  /// 所有动态口令列表（原始数据，未过滤）
  List<TwoFactorAccount> _accounts = [];

  /// 过滤后的动态口令列表（根据搜索文本）
  List<TwoFactorAccount> _filteredAccounts = [];

  /// 动态口令ID到动态码的映射
  final Map<String, String> _codes = {};

  /// 动态口令ID到剩余秒数的映射
  final Map<String, int> _remainingSeconds = {};

  /// 搜索文本输入控制器
  final TextEditingController _searchController = TextEditingController();

  /// 当前搜索文本
  String _searchText = '';

  /// 定时器，每秒更新动态码
  Timer? _timer;

  /// 备份状态
  bool _isBackupRunning = false;

  /// 恢复状态
  bool _isRestoreRunning = false;

  /// 操作结果状态：0-初始，1-成功，2-失败
  int _operationStatus = 0;

  /// 上传图标闪烁状态
  bool _isUploadIconFilling = false;

  /// 下载图标闪烁状态
  bool _isDownloadIconFilling = false;

  /// 图标闪烁定时器
  Timer? _iconBlinkTimer;

  /// 搜索防抖计时器
  Timer? _searchDebounceTimer;

  /// 防抖计时器
  Timer? _loadAccountsDebounceTimer;

  /// 是否处于排序模式
  bool _isSortingMode = false;

  /// 初始化状态：注册生命周期监听、加载数据、启动定时器
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initialize();
      _startTimer();
    });
    _searchController.addListener(() {
      // 防抖处理搜索，避免频繁更新
      if (_searchDebounceTimer != null) {
        _searchDebounceTimer?.cancel();
      }

      _searchDebounceTimer = Timer(Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _searchText = _searchController.text;
          _filterAccounts();
        });
      });
    });
  }

  /// 按顺序初始化：加载设置 → 检查安全锁 → 加载数据
  Future<void> _initialize() async {
    try {
      await _loadSettingsConfig();
      await _checkSecurityLock();
      await _updateAccounts();
    } catch (e) {
      debugPrint('初始化失败: $e');
      if (mounted) {
        StyleUtils.errorSnackBar(context, '初始化失败: ${e.toString()}');
      }
    }
  }

  /// 检查安全锁设置，需要时触发生物识别认证
  Future<void> _checkSecurityLock() async {
    if (_setting == null) return;

    if (_securityService.needsAuthentication(
      _setting!.securitySetting.appLockEnabled,
    )) {
      setState(() {
        _needsAuthentication = true;
      });

      bool authenticated = await _securityService.authenticate(
        reason: '请验证身份以访问应用',
      );

      if (!authenticated) {
        // 认证失败，退出应用（Android 上使用 SystemNavigator.pop 避免闪退）
        Future.delayed(_authFailureExitDelay, () {
          if (mounted) {
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            } else if (Platform.isIOS) {
              exit(0);
            }
          }
        });
      } else {
        setState(() {
          _needsAuthentication = false;
        });
      }
    }
  }

  /// 从数据库加载动态口令数据，数据未变化时跳过 UI 重建
  Future<void> _updateAccounts() async {
    try {
      final accounts = await _storageService.getAllAccounts();

      // 仅当数据真正变化时才重建 UI，避免不必要的刷新
      if (_accounts.length != accounts.length ||
          !_accounts.every(
            (account) => accounts.any(
              (newAccount) =>
                  newAccount.id == account.id &&
                  newAccount.issuer == account.issuer &&
                  newAccount.name == account.name &&
                  newAccount.secret == account.secret &&
                  newAccount.period == account.period &&
                  newAccount.algorithm == account.algorithm &&
                  newAccount.type == account.type &&
                  newAccount.counter == account.counter,
            ),
          )) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _accounts = accounts;
          });
          _updateCodes();
          _filterAccounts();
        });
      } else {
        // 数据没有变化，只更新动态码
        _updateCodes();
      }
    } catch (e) {
      debugPrint('加载动态口令失败: $e');
    }
  }

  /// 从本地存储加载应用设置配置
  Future<void> _loadSettingsConfig() async {
    _setting = await _backupService.loadConfig();
  }

  /// 释放所有资源：定时器、控制器、路由监听
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _timer?.cancel();
    _loadAccountsDebounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _iconBlinkTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// 监听应用生命周期变化：后台时重置认证，前台时重新加载
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 当应用切换到后台或失去焦点时，重置认证状态
        // 这样下次回到前台时需要重新认证
        _securityService.resetAuthentication();
        debugPrint('应用切换到后台，认证状态已重置');
        break;
      case AppLifecycleState.resumed:
        // 当应用从后台回到前台时重新加载数据和检查安全设置
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // 应用被销毁或隐藏，不需要特殊处理
        break;
    }
  }

  /// 从后台回到前台时：重新加载设置 → 检查安全锁 → 加载数据
  Future<void> _handleAppResumed() async {
    await _loadSettingsConfig();
    await _checkSecurityLock();
    _loadAccounts();
  }

  /// 订阅路由观察器，用于监听页面返回事件
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  /// 从其他页面返回时重新加载数据和设置
  @override
  void didPopNext() {
    _loadAccounts();
    _loadSettingsConfig();
  }

  /// 根据搜索文本过滤动态口令列表
  void _filterAccounts() {
    if (_searchText.isEmpty) {
      _filteredAccounts = _accounts;
    } else {
      _filteredAccounts = _accounts.where((account) {
        final code = _codes[account.id] ?? '';
        return account.displayIssuerName.toLowerCase().contains(
              _searchText.toLowerCase(),
            ) ||
            code.contains(_searchText);
      }).toList();
    }
  }

  /// 构建主页面 UI：AppBar（搜索/排序/云备份）+ 动态口令列表 + FAB 添加按钮
  @override
  Widget build(BuildContext context) {
    // 认证过程中显示加载界面
    if (_needsAuthentication) {
      final themeColor = Theme.of(context).colorScheme.primary;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
              const SizedBox(height: 16),
              const Text('正在验证身份...'),
              const SizedBox(height: 8),
              const Text('请验证您的生物识别信息', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade200
                    : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: StyleUtils.menuIcon,
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    style: StyleUtils.iconButtonStyle(),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜索...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isSortingMode ? Icons.check : Icons.sort),
                  onPressed: _toggleSortingMode,
                  style: StyleUtils.iconButtonStyle(),
                ),
                Builder(
                  builder: (buttonContext) => IconButton(
                    icon: _buildCloudIcon(),
                    onPressed: () =>
                        _handleBackupButtonPressed(buttonContext),
                    style: StyleUtils.iconButtonStyle(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const _MenuDrawer(),
      body: _isSortingMode
          ? _buildSortableList()
          : RefreshIndicator(
              onRefresh: _loadAccounts,
              child: _accounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '此处似乎尚无任何动态口令',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '点击右下角 + 添加动态口令',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredAccounts.length,
                      itemBuilder: (context, index) {
                        final account = _filteredAccounts[index];
                        final code = _codes[account.id] ?? '';
                        final remainingSeconds =
                            _remainingSeconds[account.id] ?? 0;
                        final progress = remainingSeconds / account.period;
                        final themeColor = Theme.of(
                          context,
                        ).colorScheme.primary;

                        return Dismissible(
                          key: Key(account.id.toString()),
                          direction: DismissDirection.horizontal,
                          dismissThresholds: const {
                            DismissDirection.startToEnd: 0.8,
                            DismissDirection.endToStart: 0.8,
                          },
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              await _showEditDialog(account);
                              return false;
                            } else {
                              await _showDeleteConfirmDialog(account);
                              return false;
                            }
                          },
                          background: Container(
                            color: Colors.blue,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 8,
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.displayName,
                                        style: const TextStyle(fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      if (account.issuer != null &&
                                          account.issuer!.isNotEmpty)
                                        Text(
                                          account.issuer!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    code,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: themeColor,
                                    ),
                                  ),
                                  trailing: account.isHotp
                                      ? _buildHotpTrailing(account)
                                      : SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: progress,
                                                strokeWidth: 3,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      progress > 0.3
                                                          ? Colors.green
                                                          : Colors.orange,
                                                    ),
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                              ),
                                              Text(
                                                '${remainingSeconds}s',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: progress > 0.3
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              Divider(
                                color: Theme.of(context).brightness == Brightness.light
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade800,
                                height: 1,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: Material(
        color: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 6,
        child: PopupMenuButton(
          icon: const Icon(Icons.add, color: Colors.white),
          color: Theme.of(context).colorScheme.surface,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'scan',
              child: ListTile(
                leading: Icon(Icons.qr_code_scanner),
                title: Text('扫描二维码'),
              ),
            ),
            const PopupMenuItem(
              value: 'manual',
              child: ListTile(
                leading: Icon(Icons.keyboard),
                title: Text('输入2FA密钥'),
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'scan') {
              final result = await Navigator.pushNamed(context, '/addScan');
              if (result == true) {
                await _loadAccounts();
              }
            } else if (value == 'manual') {
              final result = await Navigator.pushNamed(context, '/addManual');
              if (result == true) {
                await _loadAccounts();
              }
            }
          },
        ),
      ),
    );
  }

  /// 从数据库加载所有动态口令
  Future<void> _loadAccounts() async {
    // 防抖处理，避免频繁调用
    if (_loadAccountsDebounceTimer != null) {
      _loadAccountsDebounceTimer?.cancel();
    }

    _loadAccountsDebounceTimer = Timer(Duration(milliseconds: 50), () async {
      await _updateAccounts();
    });
  }

  /// 启动每秒更新动态码的定时器
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCodes();
    });
  }

  /// 根据备份/恢复状态显示不同云图标
  Widget _buildCloudIcon() {
    // 操作结果状态：1-成功，2-失败
    if (_operationStatus == 1) {
      return const Icon(Icons.cloud, color: Colors.green);
    } else if (_operationStatus == 2) {
      return const Icon(Icons.cloud, color: Colors.red);
    }

    if (_isBackupRunning) {
      return Icon(
        _isUploadIconFilling ? Icons.cloud_upload : Icons.cloud_upload_outlined,
        color: Colors.blue,
      );
    }

    if (_isRestoreRunning) {
      return Icon(
        _isDownloadIconFilling
            ? Icons.cloud_download
            : Icons.cloud_download_outlined,
        color: Colors.blue,
      );
    }

    return StyleUtils.cloudIcon;
  }

  /// 构建 HOTP 动态口令的 trailing 控件（递增按钮）
  Widget _buildHotpTrailing(TwoFactorAccount account) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: const Icon(Icons.refresh, size: 22),
        padding: EdgeInsets.zero,
        tooltip: '递增计数器 (当前: ${account.counter})',
        onPressed: () => _incrementCounter(account),
      ),
    );
  }

  /// 递增 HOTP 计数器并刷新动态口令
  Future<void> _incrementCounter(TwoFactorAccount account) async {
    final newCounter = account.counter + 1;
    final updatedAccount = TwoFactorAccount(
      account.id,
      account.issuer,
      account.name,
      account.secret,
      account.period,
      account.algorithm,
      account.createdAt,
      DateTime.now(),
      type: account.type,
      counter: newCounter,
    );
    await _storageService.updateAccount(updatedAccount);
    await _loadAccounts();
  }

  /// 更新所有动态口令的动态码和倒计时
  void _updateCodes() {
    if (_accounts.isEmpty) return;

    setState(() {
      for (final account in _accounts) {
        try {
          _codes[account.id] = OtpService.generateCode(
            secret: account.secret,
            period: account.period,
            algorithm: account.algorithm,
            counter: account.isHotp ? account.counter : null,
          );
        } catch (e) {
          // 单个失败不影响其他动态口令
          _codes[account.id] = 'ERROR';
          debugPrint('生成动态码失败 - 动态口令 ${account.displayIssuerName}: $e');
        }
        _remainingSeconds[account.id] = OtpService.getRemainingSeconds(period: account.period);
      }
    });
  }

  /// 跳转到编辑动态口令页面
  Future<void> _showEditDialog(TwoFactorAccount account) async {
    await Navigator.pushNamed(context, '/edit', arguments: account);
    await _loadAccounts();
  }

  /// 显示删除动态口令确认对话框
  Future<bool> _showDeleteConfirmDialog(TwoFactorAccount account) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除动态口令'),
        content: Text('确定要删除动态口令 "${account.displayIssuerName}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _storageService.deleteAccount(account.id);
      await _loadAccounts();
    }

    return false;
  }

  /// 切换排序模式
  void _toggleSortingMode() async {
    if (_isSortingMode) {
      // 保存排序结果
      await _saveSortOrder();
    } else {
      setState(() {
        _isSortingMode = true;
      });
    }
  }

  /// 保存排序顺序
  Future<void> _saveSortOrder() async {
    final newOrder = _accounts.map((account) => account.id).toList();
    _filteredAccounts = List.from(_accounts);
    final success = await _storageService.updateAccountOrder(newOrder);
    if (success) {
      setState(() {
        _isSortingMode = false;
      });
      StyleUtils.successSnackBar(context, '排序已保存');
      // 重新加载动态口令以更新显示顺序
      await _loadAccounts();
    } else {
      StyleUtils.errorSnackBar(context, '保存排序失败');
    }
  }

  /// 构建可排序列表
  Widget _buildSortableList() {
    return ReorderableListView(
      children: _filteredAccounts.map((account) {
        return Container(
          key: Key(account.id),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 8,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (account.issuer != null && account.issuer!.isNotEmpty)
                      Text(
                        account.issuer!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
                trailing: const Icon(Icons.drag_handle),
              ),
              Divider(color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade200
                    : Colors.grey.shade800, height: 1),
            ],
          ),
        );
      }).toList(),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final account = _filteredAccounts.removeAt(oldIndex);
          _filteredAccounts.insert(newIndex, account);
        });
      },
    );
  }

  /// 处理备份按钮点击
  Future<void> _handleBackupButtonPressed(BuildContext buttonContext) async {
    // 检查备份配置
    if (_setting == null || _setting!.backupSetting.type == BackupType.off) {
      // 如果备份类型是“关闭”，则跳转到备份设置页面
      final result = await Navigator.pushNamed(
        context,
        '/settings',
        arguments: {'fromCloudIcon': true},
      );

      // 处理返回结果，更新云图标状态
      if (result is Map<String, dynamic>) {
        final operation = result['operation'] as String;
        final status = result['status'] as String;

        setState(() {
          if (operation == 'backup') {
            _isBackupRunning = false;
            _isUploadIconFilling = false;
          } else if (operation == 'restore') {
            _isRestoreRunning = false;
            _isDownloadIconFilling = false;
          }

          _operationStatus = status == 'success' ? 1 : 2;
        });
      }
    } else {
      // 从按钮位置动态计算菜单位置
      final RenderBox box =
          buttonContext.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero);
      final buttonRect = offset & box.size;
      final position = RelativeRect.fromRect(
        buttonRect,
        Offset.zero & MediaQuery.of(context).size,
      );

      showMenu(
        context: context,
        position: position,
        items: [
          PopupMenuItem(
            value: 'backup',
            child: ListTile(
              leading: Icon(Icons.cloud_upload),
              title: Text('备份到远端'),
            ),
          ),
          PopupMenuItem(
            value: 'restore',
            child: ListTile(
              leading: Icon(Icons.cloud_download),
              title: Text('从远端恢复'),
            ),
          ),
        ],
      ).then((value) async {
        if (!mounted) return;

        if (value == 'backup') {
          // 备份到远端
          setState(() {
            _isBackupRunning = true;
            _isUploadIconFilling = true;
          });

          try {
            await _backupService.performBackup(_setting!);
            if (mounted) {
              StyleUtils.successSnackBar(context, '备份成功');
              setState(() {
                _operationStatus = 1;
              });

              // 3秒后自动重置状态
              Future.delayed(_operationStatusResetDuration, () {
                if (mounted) {
                  setState(() {
                    _operationStatus = 0;
                  });
                }
              });
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
              setState(() {
                _operationStatus = 2;
              });

              // 3秒后自动重置状态
              Future.delayed(_operationStatusResetDuration, () {
                if (mounted) {
                  setState(() {
                    _operationStatus = 0;
                  });
                }
              });
            }
          } finally {
            if (mounted) {
              setState(() {
                _isBackupRunning = false;
                _isUploadIconFilling = false;
              });
            }
          }
        } else if (value == 'restore') {
          // 从远端恢复
          // 显示确认对话框
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

          if (result == true && mounted) {
            setState(() {
              _isRestoreRunning = true;
              _isDownloadIconFilling = true;
            });

            try {
              await _backupService.restoreBackup(_setting!);
              if (mounted) {
                StyleUtils.successSnackBar(context, '恢复成功');
                setState(() {
                  _operationStatus = 1;
                });
                await _loadAccounts();

                // 3秒后自动重置状态
                Future.delayed(_operationStatusResetDuration, () {
                  if (mounted) {
                    setState(() {
                      _operationStatus = 0;
                    });
                  }
                });
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
                setState(() {
                  _operationStatus = 2;
                });

                // 3秒后自动重置状态
                Future.delayed(_operationStatusResetDuration, () {
                  if (mounted) {
                    setState(() {
                      _operationStatus = 0;
                    });
                  }
                });
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isRestoreRunning = false;
                  _isDownloadIconFilling = false;
                });
              }
            }
          }
        }
      });
    }
  }
}

/// 侧边栏菜单
///
/// 包含应用 Logo、导入/导出入口和设置入口。
class _MenuDrawer extends StatelessWidget {
  const _MenuDrawer();

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 64),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Easy',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'Auth',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('导入/导出'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/importExport');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
    );
  }
}
