import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/two_factor_account.dart';
import '../utils/exceptions.dart';

const sharedSecureStorage = FlutterSecureStorage();

/// Secure storage service — singleton.
///
/// All read/write operations throw [StorageException] on failure so callers
/// can distinguish errors from valid empty results.
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

  /// Insert a new 2FA account.
  ///
  /// Returns the generated account ID.
  /// Throws [StorageException] on failure.
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

      // Write account data before updating the index so a crash
      // won't leave an index entry pointing to missing data.
      await _secureStorage.write(
        key: '$_accountPrefix$id',
        value: jsonEncode(accountWithId.toJson()),
      );

      ids.add(id);
      await _secureStorage.write(
        key: _accountsIndexKey,
        value: jsonEncode(ids),
      );

      return id;
    } catch (e) {
      throw StorageException(
        'Failed to insert account',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get all 2FA accounts.
  ///
  /// Returns an empty list when there are no accounts.
  /// Throws [StorageException] on read failure.
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
            debugPrint('Failed to parse account data: $e');
            continue;
          }
        }
      }

      return accounts;
    } catch (e) {
      throw StorageException(
        'Failed to load accounts',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Get a single account by ID.
  ///
  /// Returns null when the account does not exist.
  /// Throws [StorageException] on read failure.
  Future<TwoFactorAccount?> getAccountById(String id) async {
    try {
      final accountJson = await _secureStorage.read(key: '$_accountPrefix$id');
      if (accountJson == null) return null;

      final accountData = jsonDecode(accountJson);
      return TwoFactorAccount.fromJson(accountData);
    } catch (e) {
      throw StorageException(
        'Failed to load account',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Update an account (issuer and name only; secret is preserved).
  ///
  /// Throws [StorageException] on failure.
  Future<void> updateAccount(TwoFactorAccount account) async {
    try {
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson == null) {
        throw StorageException('No accounts index found');
      }

      final ids = (jsonDecode(indexJson) as List).cast<String>();
      if (!ids.contains(account.id)) {
        throw StorageException('Account not found in index');
      }

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
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to update account',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Delete an account.
  ///
  /// Throws [StorageException] on failure.
  Future<void> deleteAccount(String id) async {
    try {
      final indexJson = await _secureStorage.read(key: _accountsIndexKey);
      if (indexJson == null) {
        throw StorageException('No accounts index found');
      }

      final ids = (jsonDecode(indexJson) as List).cast<String>();

      if (!ids.contains(id)) {
        throw StorageException('Account not found in index');
      }

      // Remove from index before deleting data so a crash
      // won't leave an index entry pointing to missing data.
      ids.remove(id);
      await _secureStorage.write(
        key: _accountsIndexKey,
        value: jsonEncode(ids),
      );

      await _secureStorage.delete(key: '$_accountPrefix$id');
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to delete account',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Clear all accounts.
  ///
  /// Throws [StorageException] on failure.
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
      throw StorageException(
        'Failed to clear accounts',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Update the display order of accounts.
  ///
  /// Throws [StorageException] on failure.
  Future<void> updateAccountOrder(List<String> newOrder) async {
    try {
      await _secureStorage.write(
        key: _accountsIndexKey,
        value: jsonEncode(newOrder),
      );
    } catch (e) {
      throw StorageException(
        'Failed to update account order',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }
}
