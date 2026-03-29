import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/two_factor_account.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/totp_service.dart';
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

  /// 备份配置
  BackupConfig? _backupConfig;

  /// 所有账户列表
  List<TwoFactorAccount> _accounts = [];

  /// 过滤后的账户列表（根据搜索文本）
  List<TwoFactorAccount> _filteredAccounts = [];

  /// 账户ID到动态码的映射
  final Map<int, String> _codes = {};

  /// 账户ID到剩余秒数的映射
  final Map<int, int> _remainingSeconds = {};

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

  /// 初始化方法，按照顺序加载数据和备份配置
  /// 1. 先从本地数据库加载账户数据
  /// 2. 加载备份配置
  Future<void> _initialize() async {
    // 移到后台执行，避免阻塞主线程
    await Future.microtask(() async {
      /// 先从本地数据库加载账户数据
      await _loadLocalAccounts();

      /// 加载备份配置
      await _loadBackupConfig();
    });
  }

  /// 从本地数据库加载账户数据
  Future<void> _loadLocalAccounts() async {
    try {
      final accounts = await Future.microtask(() async {
        return await _storageService.getAllAccounts();
      });

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
                  newAccount.algorithm == account.algorithm,
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
      debugPrint('加载本地账户失败: $e');
    }
  }

  /// 检查远程备份
  Future<void> _checkRemoteBackup() async {
    try {
      if (_backupConfig != null &&
          _backupService.isConfigValid(_backupConfig!)) {
        // 在后台线程检查远程是否有备份文件
        bool hasRemoteBackup = await Future.microtask(() async {
          return await _backupService.hasRemoteBackup(_backupConfig!);
        });

        if (hasRemoteBackup) {
          debugPrint('远程有备份文件');

          // 如果本地没有数据但远程有数据，询问用户是否删除远程备份文件
          if (_accounts.isEmpty) {
            if (mounted) {
              showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('删除远程备份'),
                  content: Text('本地没有数据，但远程存储中有备份文件。是否删除远程备份文件？'),
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
              ).then((result) async {
                if (result == true) {
                  try {
                    // 在后台线程执行删除操作
                    await Future.microtask(() async {
                      return await _backupService.deleteRemoteBackup(
                        _backupConfig!,
                      );
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('远程备份已删除'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('删除远程备份失败: ${e.toString()}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              });
            }
          } else {
            // 本地有数据，询问用户是否恢复备份
            if (mounted) {
              showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('恢复备份'),
                  content: Text('检测到远程有备份文件，是否恢复？恢复将覆盖当前数据。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('恢复'),
                    ),
                  ],
                ),
              ).then((result) async {
                if (result == true) {
                  await _restoreFromRemoteBackup();
                }
              });
            }
          }
        } else {
          debugPrint('远程没有备份文件');
        }
      }
    } catch (e) {
      debugPrint('检查远程备份失败: $e');
    }
  }

  /// 从远程备份恢复数据
  Future<void> _restoreFromRemoteBackup() async {
    if (_backupConfig == null ||
        !_backupService.isConfigValid(_backupConfig!)) {
      return;
    }

    setState(() {
      _isRestoreRunning = true;
      _operationStatus = 0; // 重置操作结果状态
    });

    // 启动图标闪烁
    _startIconBlinkTimer();

    try {
      // 在后台线程执行恢复操作
      await Future.microtask(() async {
        return await _backupService.restoreBackup(_backupConfig!);
      });
      if (mounted) {
        // 重新加载本地数据
        await _loadLocalAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('恢复完成'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // 操作成功
      setState(() {
        _operationStatus = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复失败: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // 操作失败
      setState(() {
        _operationStatus = 2;
      });
    } finally {
      setState(() {
        _isRestoreRunning = false;
      });
      // 停止图标闪烁
      _stopIconBlinkTimer();
    }
  }

  /// 加载备份配置
  Future<void> _loadBackupConfig() async {
    _backupConfig = await _backupService.loadConfig();
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
    // 关闭数据库连接，防止内存泄漏
    _storageService.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 当应用从后台回到前台时重新加载数据
      _loadAccounts();
    }
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
  }

  /// 根据搜索文本过滤账户列表
  void _filterAccounts() {
    if (_searchText.isEmpty) {
      _filteredAccounts = _accounts;
    } else {
      _filteredAccounts = _accounts.where((account) {
        final code = _codes[account.id] ?? '';
        return account.displayName.toLowerCase().contains(
              _searchText.toLowerCase(),
            ) ||
            code.contains(_searchText);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  icon: _buildCloudIcon(),
                  onPressed: _handleBackupButtonPressed,
                  style: StyleUtils.iconButtonStyle(),
                ),
              ],
            ),
          ),
        ),
        actions: const [],
      ),
      drawer: const _MenuDrawer(),
      body: RefreshIndicator(
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
                  final remainingSeconds = _remainingSeconds[account.id] ?? 0;
                  final progress = remainingSeconds / account.period;
                  final themeColor = Theme.of(context).colorScheme.primary;

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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name ?? "未命名账户",
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
                        trailing: SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress > 0.3 ? Colors.green : Colors.orange,
                                ),
                                backgroundColor: Colors.grey[300],
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
      try {
        // 在后台线程获取账户数据
        final accounts = await Future.microtask(() async {
          return await _storageService.getAllAccounts();
        });

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
                    newAccount.algorithm == account.algorithm,
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
    });
  }

  /// 启动每秒更新动态码的定时器
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCodes();
    });
  }

  /// 启动图标闪烁定时器
  void _startIconBlinkTimer() {
    // 取消之前的定时器
    _iconBlinkTimer?.cancel();

    // 每1秒闪烁一次
    _iconBlinkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isBackupRunning) {
          _isUploadIconFilling = !_isUploadIconFilling;
        } else if (_isRestoreRunning) {
          _isDownloadIconFilling = !_isDownloadIconFilling;
        }
      });
    });
  }

  /// 停止图标闪烁定时器
  void _stopIconBlinkTimer() {
    _iconBlinkTimer?.cancel();
    setState(() {
      _isUploadIconFilling = false;
      _isDownloadIconFilling = false;
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

    setState(() {
      for (final account in _accounts) {
        _codes[account.id] = TotpService.generateCode(
          secret: account.secret,
          period: account.period,
        );
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
        content: Text('确定要删除账户 "${account.displayName}" 吗？'),
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

  /// 处理备份按钮点击
  Future<void> _handleBackupButtonPressed() async {
    // 跳转到设置页面的备份设置，并等待返回结果
    final result = await Navigator.pushNamed(context, '/settings');

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

      // 3秒后重置状态
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _operationStatus = 0;
          });
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
        ],
      ),
    );
  }
}
