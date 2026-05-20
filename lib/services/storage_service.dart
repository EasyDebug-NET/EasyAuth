import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/two_factor_account.dart';

const sharedSecureStorage = FlutterSecureStorage();

/// 安全存储服务 - 单例模式
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  final FlutterSecureStorage _secureStorage = sharedSecureStorage;
  static const String _accountsIndexKey = 'account_ids';
  static const String _accountPrefix = 'account_';
  final Uuid _uuid = const Uuid();

  /// 插入动态口令
  Future<String> insertAccount(TwoFactorAccount account) async {
    try {
      final id = _uuid.v4();

      final accountWithId = TwoFactorAccount(
        id,
        account.issuer,
        account.name,
        account.secret,
        account.period,
        account.algorithm,
        account.createdAt,
        account.updatedAt,
        type: account.type,
        counter: account.counter,
      );

      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      final ids = indexJson != null
          ? (jsonDecode(indexJson) as List).cast<String>()
          : <String>[];

      // 先写索引，避免崩溃留下无引用的孤立数据
      ids.add(id);
      await _secureStorage.write(
        key: _accountsIndexKey,
        value: jsonEncode(ids),
      );

      await _secureStorage.write(
        key: '$_accountPrefix$id',
        value: jsonEncode(accountWithId.toJson()),
      );

      return id;
    } catch (e) {
      print('插入动态口令失败: $e');
      return '';
    }
  }

  /// 获取所有动态口令
  Future<List<TwoFactorAccount>> getAllAccounts() async {
    try {
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson == null) return [];

      final ids = (jsonDecode(indexJson) as List).cast<String>();

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
            print('解析动态口令数据失败: $e');
            continue;
          }
        }
      }

      return accounts;
    } catch (e) {
      print('获取动态口令列表失败: $e');
      return [];
    }
  }

  /// 根据 ID 获取动态口令
  Future<TwoFactorAccount?> getAccountById(String id) async {
    try {
      final accountJson = await _secureStorage.read(key: '$_accountPrefix$id');
      if (accountJson == null) return null;

      final accountData = jsonDecode(accountJson);
      return TwoFactorAccount.fromJson(accountData);
    } catch (e) {
      print('获取动态口令失败: $e');
      return null;
    }
  }

  /// 更新动态口令（只更新 issuer 和 name）
  Future<int> updateAccount(TwoFactorAccount account) async {
    try {
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson == null) return 0;

      final ids = (jsonDecode(indexJson) as List).cast<String>();
      if (!ids.contains(account.id)) return 0;

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
        counter: account.counter,
      );

      await _secureStorage.write(
        key: '$_accountPrefix${account.id}',
        value: jsonEncode(updatedAccount.toJson()),
      );

      return 1;
    } catch (e) {
      print('更新动态口令失败: $e');
      return 0;
    }
  }

  /// 删除动态口令
  Future<int> deleteAccount(String id) async {
    try {
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson == null) return 0;

      final ids = (jsonDecode(indexJson) as List).cast<String>();

      if (!ids.contains(id)) return 0;

      // 先从索引移除，再删数据，避免崩溃留下指向不存在数据的索引
      ids.remove(id);
      await _secureStorage.write(
        key: _accountsIndexKey,
        value: jsonEncode(ids),
      );

      await _secureStorage.delete(key: '$_accountPrefix$id');

      return 1;
    } catch (e) {
      print('删除动态口令失败: $e');
      return 0;
    }
  }

  /// 清空所有动态口令
  Future<void> clearAllAccounts() async {
    try {
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson != null) {
        final ids = (jsonDecode(indexJson) as List).cast<String>();

        for (final id in ids) {
          await _secureStorage.delete(key: '$_accountPrefix$id');
        }

        await _secureStorage.delete(key: _accountsIndexKey);
      }
    } catch (e) {
      print('清空动态口令失败: $e');
    }
  }

  /// 更新动态口令顺序
  Future<bool> updateAccountOrder(List<String> newOrder) async {
    try {
      await _secureStorage.write(
        key: _accountsIndexKey,
        value: jsonEncode(newOrder),
      );
      return true;
    } catch (e) {
      print('更新动态口令顺序失败: $e');
      return false;
    }
  }
}
