import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/two_factor_account.dart';

/// 安全存储服务 - 单例模式
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _accountsIndexKey = 'account_ids';
  static const String _accountPrefix = 'account_';
  final Uuid _uuid = const Uuid();

  /// 插入账户
  Future<String> insertAccount(TwoFactorAccount account) async {
    try {
      // 生成 UUID
      final id = _uuid.v4();

      // 创建带 ID 的账户
      final accountWithId = TwoFactorAccount.name(
        id,
        account.issuer,
        account.name,
        account.secret,
        account.period,
        account.algorithm,
        account.createdAt,
        account.updatedAt,
      );

      // 读取当前索引
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      final ids = indexJson != null
          ? (jsonDecode(indexJson) as List).cast<String>()
          : <String>[];

      // 写入账户数据
      await _secureStorage.write(
        key: '$_accountPrefix$id',
        value: jsonEncode(accountWithId.toJson()),
      );

      // 更新索引
      ids.add(id);
      await _secureStorage.write(
        key: _accountsIndexKey,
        value: jsonEncode(ids),
      );

      return id;
    } catch (e) {
      print('插入账户失败: $e');
      return '';
    }
  }

  /// 获取所有账户
  Future<List<TwoFactorAccount>> getAllAccounts() async {
    try {
      // 读取索引
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson == null) return [];

      // 解析索引
      final ids = (jsonDecode(indexJson) as List).cast<String>();

      // 读取每个账户
      final accounts = <TwoFactorAccount>[];
      for (final id in ids) {
        final accountJson = await _secureStorage.read(
          key: '$_accountPrefix$id',
        );
        if (accountJson != null) {
          try {
            final accountData = jsonDecode(accountJson);
            accounts.add(TwoFactorAccount.fromJson(accountData));
          } catch (e) {
            print('解析账户数据失败: $e');
            // 跳过有问题的账户
            continue;
          }
        }
      }

      // 按创建时间降序排序
      accounts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return accounts;
    } catch (e) {
      print('获取账户列表失败: $e');
      return [];
    }
  }

  /// 根据ID获取账户
  Future<TwoFactorAccount?> getAccountById(String id) async {
    try {
      final accountJson = await _secureStorage.read(key: '$_accountPrefix$id');
      if (accountJson == null) return null;

      final accountData = jsonDecode(accountJson);
      return TwoFactorAccount.fromJson(accountData);
    } catch (e) {
      print('获取账户失败: $e');
      return null;
    }
  }

  /// 更新账户（只更新issuer和accountName）
  Future<int> updateAccount(TwoFactorAccount account) async {
    try {
      // 检查账户是否存在
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson == null) return 0;

      final ids = (jsonDecode(indexJson) as List).cast<String>();
      if (!ids.contains(account.id)) return 0;

      // 更新账户数据
      final updatedAccount = TwoFactorAccount.name(
        account.id,
        account.issuer,
        account.name,
        account.secret,
        account.period,
        account.algorithm,
        account.createdAt,
        DateTime.now(), // 更新时间
      );

      await _secureStorage.write(
        key: '$_accountPrefix${account.id}',
        value: jsonEncode(updatedAccount.toJson()),
      );

      return 1;
    } catch (e) {
      print('更新账户失败: $e');
      return 0;
    }
  }

  /// 删除账户
  Future<int> deleteAccount(String id) async {
    try {
      // 读取当前索引
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson == null) return 0;

      final ids = (jsonDecode(indexJson) as List).cast<String>();

      // 检查 ID 是否存在
      if (!ids.contains(id)) return 0;

      // 删除账户数据
      await _secureStorage.delete(key: '$_accountPrefix$id');

      // 更新索引
      ids.remove(id);
      await _secureStorage.write(
        key: _accountsIndexKey,
        value: jsonEncode(ids),
      );

      return 1;
    } catch (e) {
      print('删除账户失败: $e');
      return 0;
    }
  }

  /// 清空所有账户
  Future<void> clearAllAccounts() async {
    try {
      // 读取索引
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson != null) {
        final ids = (jsonDecode(indexJson) as List).cast<String>();

        // 删除每个账户
        for (final id in ids) {
          await _secureStorage.delete(key: '$_accountPrefix$id');
        }

        // 清空索引
        await _secureStorage.delete(key: _accountsIndexKey);
      }
    } catch (e) {
      print('清空账户失败: $e');
    }
  }
}
