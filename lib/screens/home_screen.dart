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
import '../services/totp_service.dart';
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

  /// 备份服务
  final BackupService _backupService = BackupService();

  /// 安全服务
  final SecurityService _securityService = SecurityService();

  /// 是否需要显示认证界面
  bool _needsAuthentication = false;

  /// 应用设置
  Setting? _setting;

  /// 所有账户列表
  List<TwoFactorAccount> _accounts = [];

  /// 过滤后的账户列表（根据搜索文本）
  List<TwoFactorAccount> _filteredAccounts = [];

  /// 账户ID到动态码的映射
  final Map<String, String> _codes = {};

  /// 账户ID到剩余秒数的映射
  final Map<String, int> _remainingSeconds = {};

  /// 搜索控制器
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 延迟初始化，让UI先显示
    Future.delayed(Duration(milliseconds: 50), () {
      _initialize();
    });
    // 延迟启动定时器，避免在初始化时占用主线程
    Future.delayed(Duration(milliseconds: 100), () {
      _startTimer();
    });
    _searchController.addListener(() {
      // 防抖处理搜索，避免频繁更新
      if (_searchDebounceTimer != null) {
        _searchDebounceTimer?.cancel();
      }

      _searchDebounceTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _searchText = _searchController.text;
          _filterAccounts();
        });
      });
    });
  }

  /// 初始化方法，按照顺序加载数据和设置配置
  /// 1. 先加载设置配置（包含安全设置）
  /// 2. 检查安全锁设置，需要时进行认证
  /// 3. 从本地数据库加载账户数据
  Future<void> _initialize() async {
    try {
      /// 先加载设置配置（包含安全设置）
      await _loadSettingsConfig();

      /// 检查安全锁设置
      await _checkSecurityLock();

      /// 从本地数据库加载账户数据
      await _loadLocalAccounts();
    } catch (e) {
      debugPrint('初始化失败: $e');
      if (mounted) {
        StyleUtils.errorSnackBar(context, '初始化失败: ${e.toString()}');
      }
    }
  }

  /// 检查安全锁设置
  Future<void> _checkSecurityLock() async {
    // 确保应用设置已加载
    if (_setting == null) {
      return;
    }

    // 检查是否需要认证
    if (_securityService.needsAuthentication(
      _setting!.securitySetting.appLockEnabled == 1,
    )) {
      // 需要进行生物识别认证
      setState(() {
        _needsAuthentication = true;
      });

      bool authenticated = await _securityService.authenticate(
        reason: '请验证身份以访问应用',
      );

      if (!authenticated) {
        // 认证失败，退出应用
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            // 使用 SystemNavigator.pop() 退出应用，避免闪退
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            } else if (Platform.isIOS) {
              exit(0);
            }
          }
        });
      } else {
        // 认证成功，继续加载数据
        setState(() {
          _needsAuthentication = false;
        });
      }
    }
  }

  /// 从本地数据库加载账户数据
  Future<void> _loadLocalAccounts() async {
    await _updateAccounts();
  }

  /// 更新账户数据
  ///
  /// 执行步骤：
  /// 1. 从数据库获取账户数据
  /// 2. 检查数据是否变化
  /// 3. 如果数据变化，更新UI和动态码
  /// 4. 如果数据未变化，只更新动态码
  Future<void> _updateAccounts() async {
    try {
      final accounts = await _storageService.getAllAccounts();

      // 检查是否需要更新，只有当账户数据真正变化时才更新
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
        // 延迟更新 UI，让主线程有更多时间处理其他任务
        Future.delayed(Duration(milliseconds: 16), () {
          setState(() {
            _accounts = accounts;
          });
          // 延迟更新动态码，进一步减轻主线程负担
          Future.delayed(Duration(milliseconds: 8), () {
            _updateCodes();
            _filterAccounts();
          });
        });
      } else {
        // 数据没有变化，只更新动态码
        _updateCodes();
      }
    } catch (e) {
      debugPrint('加载账户失败: $e');
    }
  }

  /// 加载设置配置
  Future<void> _loadSettingsConfig() async {
    _setting = await _backupService.loadConfig();
  }

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

  /// 处理应用从后台回到前台的逻辑
  Future<void> _handleAppResumed() async {
    // 先加载设置配置
    await _loadSettingsConfig();
    // 再检查安全锁
    await _checkSecurityLock();
    // 最后加载账户数据
    _loadAccounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 订阅路由观察
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // 当从其他页面返回时重新加载数据
    _loadAccounts();
    _loadSettingsConfig();
    // 从设置页面返回时，如果应用锁已开启且已认证，则不重复认证
    // 这里不需要额外的认证检查，因为_checkSecurityLock方法会处理
  }

  /// 根据搜索文本过滤账户列表
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
              color: Colors.grey[100],
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
                IconButton(
                  icon: _buildCloudIcon(),
                  onPressed: _handleBackupButtonPressed,
                  style: StyleUtils.iconButtonStyle(),
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
                            '此处似乎尚无任何验证码',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '点击右下角 + 添加动态密码',
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
                                                    Colors.grey[300],
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
                              const Divider(
                                color: Color(0xFFE0E0E0),
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
          color: Colors.white,
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
                title: Text('输入2FA秘钥'),
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

  /// 从数据库加载所有账户
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

  /// 构建云图标，根据不同状态显示不同的图标和颜色
  Widget _buildCloudIcon() {
    // 操作结果状态：1-成功，2-失败
    if (_operationStatus == 1) {
      return const Icon(Icons.cloud, color: Colors.green);
    } else if (_operationStatus == 2) {
      return const Icon(Icons.cloud, color: Colors.red);
    }

    // 备份状态
    if (_isBackupRunning) {
      return Icon(
        _isUploadIconFilling ? Icons.cloud_upload : Icons.cloud_upload_outlined,
        color: Colors.blue,
      );
    }

    // 恢复状态
    if (_isRestoreRunning) {
      return Icon(
        _isDownloadIconFilling
            ? Icons.cloud_download
            : Icons.cloud_download_outlined,
        color: Colors.blue,
      );
    }

    // 初始状态
    return StyleUtils.cloudIcon;
  }

  /// 构建 HOTP 账户的 trailing 控件（递增按钮）
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

  /// 递增 HOTP 计数器并刷新验证码
  Future<void> _incrementCounter(TwoFactorAccount account) async {
    final newCounter = account.counter + 1;
    final updatedAccount = TwoFactorAccount.name(
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

  /// 更新所有账户的动态码和倒计时
  void _updateCodes() {
    // 只在账户列表不为空时更新
    if (_accounts.isEmpty) return;

    // 计算一次剩余秒数，因为所有账户的剩余秒数都是相同的（基于当前时间）
    final remainingSeconds = TotpService.getRemainingSeconds(period: 30);

    // 检查是否需要更新，只有当剩余秒数变化时才更新
    if (_remainingSeconds.isNotEmpty &&
        _remainingSeconds.values.first == remainingSeconds) {
      return;
    }

    // 一次性更新状态，减少setState调用次数
    setState(() {
      for (final account in _accounts) {
        try {
          _codes[account.id] = TotpService.generateCode(
            secret: account.secret,
            period: account.period,
            algorithm: account.algorithm,
            counter: account.isHotp ? account.counter : null,
          );
        } catch (e) {
          // 单个账户生成失败，显示错误信息但不影响其他账户
          _codes[account.id] = 'ERROR';
          debugPrint('生成动态码失败 - 账户 ${account.displayIssuerName}: $e');
        }
        _remainingSeconds[account.id] = remainingSeconds;
      }
    });
  }

  /// 跳转到编辑账户页面
  Future<void> _showEditDialog(TwoFactorAccount account) async {
    await Navigator.pushNamed(context, '/edit', arguments: account);
    await _loadAccounts();
  }

  /// 显示删除账户确认对话框
  Future<bool> _showDeleteConfirmDialog(TwoFactorAccount account) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除账户'),
        content: Text('确定要删除账户 "${account.displayIssuerName}" 吗？'),
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
    final newOrder = _filteredAccounts.map((account) => account.id).toList();
    final success = await _storageService.updateAccountOrder(newOrder);
    if (success) {
      setState(() {
        _isSortingMode = false;
      });
      StyleUtils.successSnackBar(context, '排序已保存');
      // 重新加载账户以更新显示顺序
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
              const Divider(color: Color(0xFFE0E0E0), height: 1),
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
  Future<void> _handleBackupButtonPressed() async {
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
      // 如果备份类型不是“关闭”，则弹出菜单
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(350, 80, 0, 0),
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
              Future.delayed(Duration(seconds: 3), () {
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
              if (e is Exception) {
                errorMessage = '备份失败: ${e.toString().split(':').last.trim()}';
              }
              StyleUtils.errorSnackBar(context, errorMessage);
              setState(() {
                _operationStatus = 2;
              });

              // 3秒后自动重置状态
              Future.delayed(Duration(seconds: 3), () {
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
                // 重新加载账户
                await _loadAccounts();

                // 3秒后自动重置状态
                Future.delayed(Duration(seconds: 3), () {
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
                  errorMessage = '恢复失败: ${e.toString().split(':').last.trim()}';
                }

                StyleUtils.errorSnackBar(context, errorMessage, errorDetails);
                setState(() {
                  _operationStatus = 2;
                });

                // 3秒后自动重置状态
                Future.delayed(Duration(seconds: 3), () {
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
                      color: Colors.black,
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
