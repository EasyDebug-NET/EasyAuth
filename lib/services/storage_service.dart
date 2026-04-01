import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/two_factor_account.dart';

/// 数据库存储服务 - 单例模式
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  static Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'easyauth.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE two_factor_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        issuer TEXT,
        account_name TEXT,
        secret TEXT NOT NULL,
        period INTEGER NOT NULL DEFAULT 30,
        algorithm TEXT NOT NULL DEFAULT 'SHA1',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// 插入账户
  Future<int> insertAccount(TwoFactorAccount account) async {
    final db = await database;
    return await db.insert('two_factor_accounts', {
      'issuer': account.issuer,
      'account_name': account.name,
      'secret': account.secret,
      'period': account.period,
      'algorithm': account.algorithm,
      'created_at': account.createdAt.millisecondsSinceEpoch,
      'updated_at': account.updatedAt.millisecondsSinceEpoch,
    });
  }

  /// 获取所有账户
  Future<List<TwoFactorAccount>> getAllAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'two_factor_accounts',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return TwoFactorAccount.name(
        maps[i]['id'] as int,
        maps[i]['issuer'] as String?,
        maps[i]['account_name'] as String?,
        maps[i]['secret'] as String,
        maps[i]['period'] as int,
        maps[i]['algorithm'] as String,
        DateTime.fromMillisecondsSinceEpoch(maps[i]['created_at'] as int),
        DateTime.fromMillisecondsSinceEpoch(maps[i]['updated_at'] as int),
      );
    });
  }

  /// 根据ID获取账户
  Future<TwoFactorAccount?> getAccountById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'two_factor_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return TwoFactorAccount.name(
      maps[0]['id'] as int,
      maps[0]['issuer'] as String?,
      maps[0]['account_name'] as String?,
      maps[0]['secret'] as String,
      maps[0]['period'] as int,
      maps[0]['algorithm'] as String,
      DateTime.fromMillisecondsSinceEpoch(maps[0]['created_at'] as int),
      DateTime.fromMillisecondsSinceEpoch(maps[0]['updated_at'] as int),
    );
  }

  /// 更新账户（只更新issuer和accountName）
  Future<int> updateAccount(TwoFactorAccount account) async {
    final db = await database;
    return await db.update(
      'two_factor_accounts',
      {
        'issuer': account.issuer,
        'account_name': account.name,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// 删除账户
  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      'two_factor_accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
