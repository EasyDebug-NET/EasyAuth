import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/setting.dart';
import '../models/two_factor_account.dart';
import '../utils/exceptions.dart';
import '../utils/qr_utils.dart';
import '../utils/s3_utils.dart';
import '../utils/webdav_utils.dart';
import 'storage_service.dart';

/// 备份服务 - 单例模式
class BackupService {
  static final BackupService _instance = BackupService._internal();

  factory BackupService() {
    return _instance;
  }

  BackupService._internal();

  final StorageService _storageService = StorageService();
  final FlutterSecureStorage _secureStorage = sharedSecureStorage;

  static const String _backupPasswordKey = 'backup_password';
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _pbkdf2Iterations = 600000;

  // Storage keys for settings (shared with saveConfig / loadConfig).
  static const String _keyBackupType = 'backup_type';
  static const String _keyWebDavUrl = 'webdav_url';
  static const String _keyWebDavBackupDir = 'webdav_backup_dir';
  static const String _keyWebDavUsername = 'webdav_username';
  static const String _keyWebDavPassword = 'webdav_password';
  static const String _keyS3Endpoint = 's3_endpoint';
  static const String _keyS3AccessKeyId = 's3_access_key_id';
  static const String _keyS3SecretAccessKey = 's3_secret_access_key';
  static const String _keyS3BucketName = 's3_bucket_name';
  static const String _keyS3BackupDir = 's3_backup_dir';
  static const String _keyS3Region = 's3_region';
  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyBackupHistoryCount = 'backup_history_count';
  static const String _keyScreenshotLockEnabled = 'screenshot_lock_enabled';

  /// Generate cryptographically secure random bytes.
  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  /// Derive a 256-bit AES key from the backup password using PBKDF2-HMAC-SHA256.
  ///
  /// Uses 600,000 iterations as recommended by OWASP for SHA-256.
  /// Since the derived key length (32 bytes) matches the SHA-256 output size,
  /// only one PBKDF2 block is needed.
  List<int> _deriveBackupKey(String password, List<int> salt) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);

    // U1 = HMAC-SHA256(password, salt || INT_BE(1))
    final blockIndex = Uint8List(4);
    blockIndex[3] = 1; // big-endian 1
    var u = hmac.convert([...salt, ...blockIndex]).bytes;
    var result = u;

    // U2...Uc with XOR accumulation
    for (int i = 1; i < _pbkdf2Iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  /// 检查是否已设置备份密码
  Future<bool> hasBackupPassword() async {
    final password = await _secureStorage.read(key: _backupPasswordKey);
    return password != null && password.isNotEmpty;
  }

  /// 保存备份密码
  Future<void> saveBackupPassword(String password) async {
    await _secureStorage.write(key: _backupPasswordKey, value: password);
  }

  /// 执行备份操作
  ///
  /// [setting] 应用设置
  ///
  /// 执行步骤：
  /// 1. 生成 otpauth-migration 数据
  /// 2. 根据备份类型获取备份密码
  /// 3. 打包并加密
  /// 4. 上传到存储服务
  /// 5. 清理临时文件
  ///
  /// 抛出异常：
  /// - [StorageException] 当生成备份数据失败时
  /// - [NetworkException] 当网络请求失败时
  /// - [ConfigException] 当配置无效时
  Future<void> performBackup(Setting setting) async {
    try {
      // 验证配置
      if (!isConfigValid(setting)) {
        throw ConfigException('Invalid backup configuration', details: 'Please check that backup parameters are complete');
      }

      // 生成 otpauth-migration 数据
      String migrationData;
      try {
        migrationData = await _generateMigrationData();
      } catch (e) {
        throw StorageException(
          'Failed to generate backup data',
          details: 'Cannot read 2FA account data',
          originalException: e is Exception ? e : null,
        );
      }

      // 检查是否已设置备份密码
      if (!await hasBackupPassword()) {
        throw ConfigException('Please set a backup password first');
      }

      // 打包并加密
      final tempDir = await getTemporaryDirectory();
      final backupFile = await _createBackupFile(
        migrationData,
        tempDir.path,
      );

      // 上传到存储服务
      final fileName = _generateBackupFileName();

      try {
        if (setting.backupSetting.type == BackupType.webdav) {
          // 使用 WebDAV 工具类
          final url = buildWebDavFileUrl(
            setting.backupSetting.webDavConfig.url,
            setting.backupSetting.webDavConfig.backupDir,
            fileName,
          );
          await WebDavUtils.uploadFile(
            backupFile.path,
            url,
            setting.backupSetting.webDavConfig.username,
            setting.backupSetting.webDavConfig.password,
          );
        } else if (setting.backupSetting.type == BackupType.s3) {
          // 使用 S3 工具类
          String objectKey = fileName;
          if (setting.backupSetting.s3Config.backupDir.isNotEmpty) {
            if (setting.backupSetting.s3Config.backupDir.endsWith('/')) {
              objectKey =
                  '${setting.backupSetting.s3Config.backupDir}$fileName';
            } else {
              objectKey =
                  '${setting.backupSetting.s3Config.backupDir}/$fileName';
            }
          }
          await S3Utils.uploadFile(
            backupFile.path,
            setting.backupSetting.s3Config.endpoint,
            setting.backupSetting.s3Config.bucketName,
            objectKey,
            setting.backupSetting.s3Config.accessKeyId,
            setting.backupSetting.s3Config.secretAccessKey,
            region: setting.backupSetting.s3Config.region,
          );
        }
      } on SocketException catch (e) {
        throw NetworkException(
          'Network connection failed',
          details: 'Please check your network connection',
          originalException: e,
        );
      } on NetworkException {
        rethrow;
      } catch (e) {
        throw NetworkException(
          'Error uploading backup',
          details: e.toString(),
          originalException: e is Exception ? e : null,
        );
      }

      // 自动清理旧版本
      try {
        final historyCount = setting.backupSetting.historyCount;
        if (historyCount > 0) {
          List<String> backupFiles;
          if (setting.backupSetting.type == BackupType.webdav) {
            final listUrl = buildWebDavDirUrl(
              setting.backupSetting.webDavConfig.url,
              setting.backupSetting.webDavConfig.backupDir,
            );
            final allFiles = await WebDavUtils.listFiles(
              listUrl,
              setting.backupSetting.webDavConfig.username,
              setting.backupSetting.webDavConfig.password,
            );
            backupFiles = allFiles
                .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
                .toList()
              ..sort((a, b) => b.compareTo(a));
          } else if (setting.backupSetting.type == BackupType.s3) {
            final allFiles = await S3Utils.listFiles(
              setting.backupSetting.s3Config.endpoint,
              setting.backupSetting.s3Config.bucketName,
              setting.backupSetting.s3Config.accessKeyId,
              setting.backupSetting.s3Config.secretAccessKey,
              region: setting.backupSetting.s3Config.region,
            );
            final backupDir = setting.backupSetting.s3Config.backupDir;
            backupFiles = allFiles
                .where((f) {
                  if (backupDir.isNotEmpty && !f.startsWith(backupDir)) {
                    return false;
                  }
                  final name = backupDir.isNotEmpty
                      ? f
                          .substring(backupDir.length)
                          .replaceFirst(RegExp(r'^/'), '')
                      : f;
                  return name.startsWith('backup_') && name.endsWith('.zip');
                })
                .toList()
              ..sort((a, b) => b.compareTo(a));
          } else {
            backupFiles = [];
          }

          if (backupFiles.length > historyCount) {
            final toDelete = backupFiles.sublist(historyCount);
            for (final file in toDelete) {
              try {
                if (setting.backupSetting.type == BackupType.webdav) {
                  final url = buildWebDavFileUrl(
                    setting.backupSetting.webDavConfig.url,
                    setting.backupSetting.webDavConfig.backupDir,
                    file,
                  );
                  await WebDavUtils.deleteFile(
                    url,
                    setting.backupSetting.webDavConfig.username,
                    setting.backupSetting.webDavConfig.password,
                  );
                } else if (setting.backupSetting.type == BackupType.s3) {
                  await S3Utils.deleteFile(
                    setting.backupSetting.s3Config.endpoint,
                    setting.backupSetting.s3Config.bucketName,
                    file,
                    setting.backupSetting.s3Config.accessKeyId,
                    setting.backupSetting.s3Config.secretAccessKey,
                    region: setting.backupSetting.s3Config.region,
                  );
                }
              } catch (e) {
                debugPrint('清理旧备份失败: $file, $e');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('清理旧版本失败: $e');
      }

      // 清理临时文件
      await backupFile.delete();
    } catch (e) {
      // 重新抛出已知的异常类型
      if (e is AppException) {
        rethrow;
      }
      // 包装未知的异常
      throw AppException(
        'An error occurred during backup',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// 执行恢复操作
  ///
  /// [setting] 应用设置
  /// [specificFile] 指定要恢复的文件名（不含目录前缀），为 null 则恢复最新版本
  ///
  /// 执行步骤：
  /// 1. 下载备份（最新或指定版本）
  /// 2. 解密并解压
  /// 3. 恢复数据
  /// 4. 清理临时文件
  ///
  /// 抛出异常：
  /// - [StorageException] 当没有找到备份文件或解密失败时
  /// - [NetworkException] 当网络请求失败时
  /// - [ConfigException] 当配置无效时
  Future<void> restoreBackup(Setting setting, {String? specificFile}) async {
    try {
      // 验证配置
      if (!isConfigValid(setting)) {
        throw ConfigException('Invalid restore configuration', details: 'Please check that backup parameters are complete');
      }

      // 下载备份
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/backup.zip';
      File backupFile;

      try {
        if (setting.backupSetting.type == BackupType.webdav) {
          final fileName = specificFile ?? await _findLatestBackupWebDav(setting);
          final url = buildWebDavFileUrl(
            setting.backupSetting.webDavConfig.url,
            setting.backupSetting.webDavConfig.backupDir,
            fileName,
          );
          backupFile = await WebDavUtils.downloadFile(
            url,
            setting.backupSetting.webDavConfig.username,
            setting.backupSetting.webDavConfig.password,
            savePath,
          );
        } else if (setting.backupSetting.type == BackupType.s3) {
          String objectKey;
          if (specificFile != null) {
            objectKey = _buildS3ObjectKey(setting, specificFile);
          } else {
            objectKey = await _findLatestBackupS3(setting);
          }
          backupFile = await S3Utils.downloadFile(
            setting.backupSetting.s3Config.endpoint,
            setting.backupSetting.s3Config.bucketName,
            objectKey,
            setting.backupSetting.s3Config.accessKeyId,
            setting.backupSetting.s3Config.secretAccessKey,
            savePath,
            region: setting.backupSetting.s3Config.region,
          );
        } else {
          throw ConfigException('Unsupported backup type');
        }
      } on SocketException catch (e) {
        throw NetworkException(
          'Network connection failed',
          details: 'Please check your network connection',
          originalException: e,
        );
      } on NetworkException {
        rethrow;
      } catch (e) {
        throw NetworkException(
          'Error downloading backup',
          details: e.toString(),
          originalException: e is Exception ? e : null,
        );
      }

      try {
        // 解密并解压
        final migrationData = await _extractMigrationData(
          backupFile.path,
        );
        // 恢复数据
        await _restoreFromMigrationData(migrationData);
      } on StorageException {
        rethrow;
      } catch (e) {
        throw StorageException(
          'Failed to restore data',
          details: 'Backup file may be corrupted or password is incorrect',
          originalException: e is Exception ? e : null,
        );
      } finally {
        // 清理临时文件
        await backupFile.delete();
      }
    } catch (e) {
      // 重新抛出已知的异常类型
      if (e is AppException) {
        rethrow;
      }
      // 包装未知的异常
      throw AppException(
        'An error occurred during restore',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// 查找 WebDAV 上最新的备份文件名
  Future<String> _findLatestBackupWebDav(Setting setting) async {
    final listUrl = buildWebDavDirUrl(
      setting.backupSetting.webDavConfig.url,
      setting.backupSetting.webDavConfig.backupDir,
    );
    final files = await WebDavUtils.listFiles(
      listUrl,
      setting.backupSetting.webDavConfig.username,
      setting.backupSetting.webDavConfig.password,
    );
    final backupFiles = files
        .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (backupFiles.isEmpty) {
      throw StorageException(
        'No backup files found',
        details: 'No backup files found in WebDAV storage. Please run a backup first.',
      );
    }
    return backupFiles.first;
  }

  /// 查找 S3 上最新的备份文件 object key
  Future<String> _findLatestBackupS3(Setting setting) async {
    final objects = await S3Utils.listObjects(
      setting.backupSetting.s3Config.endpoint,
      setting.backupSetting.s3Config.bucketName,
      setting.backupSetting.s3Config.accessKeyId,
      setting.backupSetting.s3Config.secretAccessKey,
      region: setting.backupSetting.s3Config.region,
    );
    final backupDir = setting.backupSetting.s3Config.backupDir;
    final backupFiles = objects
        .where((f) {
          if (backupDir.isNotEmpty && !f.startsWith(backupDir)) {
            return false;
          }
          final name = backupDir.isNotEmpty
              ? f.substring(backupDir.length).replaceFirst(RegExp(r'^/'), '')
              : f;
          return name.startsWith('backup_') && name.endsWith('.zip');
        })
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (backupFiles.isEmpty) {
      throw StorageException(
        'No backup files found',
        details: 'No backup files found in S3 storage. Please run a backup first.',
      );
    }
    return backupFiles.first;
  }

  /// 构建 S3 完整 object key（文件名 + backupDir 前缀）
  String _buildS3ObjectKey(Setting setting, String fileName) {
    final backupDir = setting.backupSetting.s3Config.backupDir;
    if (backupDir.isEmpty) return fileName;
    return backupDir.endsWith('/') ? '$backupDir$fileName' : '$backupDir/$fileName';
  }

  /// 加载应用设置
  Future<Setting> loadConfig() async {
    try {
      final typeStr = await _secureStorage.read(key: _keyBackupType) ?? 'off';
      final backupType = BackupType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => BackupType.off,
      );
      final webDavUrl = await _secureStorage.read(key: _keyWebDavUrl) ?? '';
      final webDavBackupDir =
          await _secureStorage.read(key: _keyWebDavBackupDir) ?? '';
      final webDavUsername =
          await _secureStorage.read(key: _keyWebDavUsername) ?? '';
      final webDavPassword =
          await _secureStorage.read(key: _keyWebDavPassword) ?? '';
      final s3Endpoint = await _secureStorage.read(key: _keyS3Endpoint) ?? '';
      final s3AccessKeyId =
          await _secureStorage.read(key: _keyS3AccessKeyId) ?? '';
      final s3SecretAccessKey =
          await _secureStorage.read(key: _keyS3SecretAccessKey) ?? '';
      final s3BucketName =
          await _secureStorage.read(key: _keyS3BucketName) ?? '';
      final s3BackupDir = await _secureStorage.read(key: _keyS3BackupDir) ?? '';
      final s3Region = await _secureStorage.read(key: _keyS3Region);
      final appLockEnabledStr =
          await _secureStorage.read(key: _keyAppLockEnabled) ?? '0';
      final appLockEnabled =
          appLockEnabledStr == '1' || appLockEnabledStr == 'true';
      final historyCountStr =
          await _secureStorage.read(key: _keyBackupHistoryCount) ?? '10';
      final historyCount = int.tryParse(historyCountStr) ?? 10;
      final screenshotLockEnabledStr =
          await _secureStorage.read(key: _keyScreenshotLockEnabled) ?? '1';
      final screenshotLockEnabled =
          screenshotLockEnabledStr != '0' && screenshotLockEnabledStr != 'false';
      return Setting(
        backupSetting: BackupSetting(
          type: backupType,
          webDavConfig: WebDavConfig(
            url: webDavUrl,
            backupDir: webDavBackupDir,
            username: webDavUsername,
            password: webDavPassword,
          ),
          s3Config: S3Config(
            endpoint: s3Endpoint,
            accessKeyId: s3AccessKeyId,
            secretAccessKey: s3SecretAccessKey,
            bucketName: s3BucketName,
            backupDir: s3BackupDir,
            region: s3Region,
          ),
          historyCount: historyCount,
        ),
        securitySetting: SecuritySetting(
          appLockEnabled: appLockEnabled,
          screenshotLockEnabled: screenshotLockEnabled,
        ),
      );
    } catch (e) {
      // 出错时返回默认配置
      return const Setting(
        backupSetting: BackupSetting(
          type: BackupType.off,
          webDavConfig: WebDavConfig(url: '', username: '', password: ''),
          s3Config: S3Config(
            endpoint: '',
            accessKeyId: '',
            secretAccessKey: '',
            bucketName: '',
          ),
          historyCount: 10,
        ),
      );
    }
  }

  /// 保存应用设置
  Future<void> saveConfig(Setting setting) async {
    await _secureStorage.write(
      key: _keyBackupType,
      value: setting.backupSetting.type.name,
    );
    await _secureStorage.write(
      key: _keyWebDavUrl,
      value: setting.backupSetting.webDavConfig.url,
    );
    await _secureStorage.write(
      key: _keyWebDavBackupDir,
      value: setting.backupSetting.webDavConfig.backupDir,
    );
    await _secureStorage.write(
      key: _keyWebDavUsername,
      value: setting.backupSetting.webDavConfig.username,
    );
    await _secureStorage.write(
      key: _keyWebDavPassword,
      value: setting.backupSetting.webDavConfig.password,
    );
    await _secureStorage.write(
      key: _keyS3Endpoint,
      value: setting.backupSetting.s3Config.endpoint,
    );
    await _secureStorage.write(
      key: _keyS3AccessKeyId,
      value: setting.backupSetting.s3Config.accessKeyId,
    );
    await _secureStorage.write(
      key: _keyS3SecretAccessKey,
      value: setting.backupSetting.s3Config.secretAccessKey,
    );
    await _secureStorage.write(
      key: _keyS3BucketName,
      value: setting.backupSetting.s3Config.bucketName,
    );
    await _secureStorage.write(
      key: _keyS3BackupDir,
      value: setting.backupSetting.s3Config.backupDir,
    );
    await _secureStorage.write(
      key: _keyS3Region,
      value: setting.backupSetting.s3Config.region,
    );
    await _secureStorage.write(
      key: _keyBackupHistoryCount,
      value: setting.backupSetting.historyCount.toString(),
    );

    await _secureStorage.write(
      key: _keyAppLockEnabled,
      value: setting.securitySetting.appLockEnabled ? '1' : '0',
    );
    await _secureStorage.write(
      key: _keyScreenshotLockEnabled,
      value: setting.securitySetting.screenshotLockEnabled ? '1' : '0',
    );
  }

  /// 验证备份配置是否有效
  bool isConfigValid(Setting setting) {
    if (setting.backupSetting.type == BackupType.off) {
      return false;
    }

    if (setting.backupSetting.type == BackupType.webdav) {
      final webDavConfig = setting.backupSetting.webDavConfig;
      return webDavConfig.url.isNotEmpty &&
          webDavConfig.username.isNotEmpty &&
          webDavConfig.password.isNotEmpty;
    } else if (setting.backupSetting.type == BackupType.s3) {
      final s3Config = setting.backupSetting.s3Config;
      return s3Config.endpoint.isNotEmpty &&
          s3Config.accessKeyId.isNotEmpty &&
          s3Config.secretAccessKey.isNotEmpty &&
          s3Config.bucketName.isNotEmpty;
    }

    return false;
  }

  /// 生成 otpauth-migration 数据
  ///
  /// 复用 qr_utils.dart 中的 generateMigrationData 方法，确保备份文件中的数据
  /// 与二维码中的数据格式一致，并且更加安全
  Future<String> _generateMigrationData() async {
    final accounts = await _storageService.getAllAccounts();

    // 转换动态口令数据格式，使其符合 QrUtils.generateMigrationData 的要求
    final accountList = accounts
        .map(
          (account) => {
            'secret': account.secret,
            'name': account.name ?? '',
            'issuer': account.issuer ?? '',
            'algorithm': account.algorithm,
            'digits': 6,
            'type': account.type,
            'counter': account.counter,
            'period': account.period,
          },
        )
        .toList();

    // 复用 QrUtils 中的 generateMigrationData 方法
    return QrUtils.generateMigrationData(accountList);
  }

  /// 创建备份文件（打包并 AES-256-GCM 加密）
  ///
  /// [migrationData] 迁移数据（otpauth-migration 格式）
  /// [tempDir] 临时目录路径
  ///
  /// 执行步骤：
  /// 1. 从安全存储读取备份密码
  /// 2. 生成随机盐值（16字节）
  /// 3. SHA-256 派生 256 位密钥
  /// 4. 生成随机 nonce（12字节）
  /// 5. AES-256-GCM 加密数据
  /// 6. 创建明文 ZIP 容器（包含 salt 和加密数据）
  ///
  /// 返回创建的备份文件
  Future<File> _createBackupFile(
    String migrationData,
    String tempDir,
  ) async {
    final password = await _secureStorage.read(key: _backupPasswordKey);
    if (password == null || password.isEmpty) {
      throw ConfigException('Backup password not set');
    }

    // 生成随机盐值
    final salt = _randomBytes(_saltLength);

    // SHA-256 派生密钥
    final keyBytes = _deriveBackupKey(password, salt);

    // AES-256-GCM 加密
    final key = Key(Uint8List.fromList(keyBytes));
    final nonce = _randomBytes(_nonceLength);
    final iv = IV(Uint8List.fromList(nonce));
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(migrationData, iv: iv);

    // encrypted.bytes = ciphertext + 16字节 GCM tag
    final encryptedData = Uint8List.fromList([
      ...nonce,
      ...encrypted.bytes,
    ]);

    // 创建明文 ZIP 容器
    final archive = Archive();
    archive.addFile(ArchiveFile(_saltFileName, salt.length, salt));
    archive.addFile(
      ArchiveFile(_dataFileName, encryptedData.length, encryptedData),
    );

    final zipData = ZipEncoder().encode(archive);

    final backupFile = File('$tempDir/backup.zip');
    await backupFile.writeAsBytes(zipData);
    return backupFile;
  }

  /// 提取迁移数据（解密并解压）
  ///
  /// [filePath] 备份文件路径
  ///
  /// 执行步骤：
  /// 1. 从安全存储读取备份密码
  /// 2. 解压明文 ZIP 获取盐值和加密数据
  /// 3. SHA-256 派生密钥
  /// 4. AES-256-GCM 解密
  ///
  /// 返回迁移数据（otpauth-migration 格式）
  Future<String> _extractMigrationData(String filePath) async {
    final password = await _secureStorage.read(key: _backupPasswordKey);
    if (password == null || password.isEmpty) {
      throw ConfigException('Backup password not set');
    }

    final fileData = await File(filePath).readAsBytes();

    try {
      // 解压明文 ZIP
      final archive = ZipDecoder().decodeBytes(fileData);

      // 提取盐值
      final saltFile = archive.files.firstWhere(
        (file) => file.name == _saltFileName,
        orElse: () => throw StorageException('Backup file format error: missing salt'),
      );
      final salt = saltFile.content as List<int>;

      // 提取加密数据
      final dataFile = archive.files.firstWhere(
        (file) => file.name == _dataFileName,
        orElse: () => throw StorageException('Backup file format error: missing data'),
      );
      final encryptedBytes = dataFile.content as List<int>;

      // 解析加密数据格式: nonce (12) + ciphertext + GCM tag (16)
      final nonce = encryptedBytes.sublist(0, _nonceLength);
      final cipherTextWithTag = encryptedBytes.sublist(_nonceLength);

      // SHA-256 派生密钥
      final keyBytes = _deriveBackupKey(password, salt);

      // AES-256-GCM 解密
      final key = Key(Uint8List.fromList(keyBytes));
      final iv = IV(Uint8List.fromList(nonce));
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final decrypted = encrypter.decrypt(
        Encrypted(Uint8List.fromList(cipherTextWithTag)),
        iv: iv,
      );

      return decrypted;
    } catch (e) {
      if (e is ConfigException) rethrow;
      // AES-GCM 解密失败通常因为密码错误或数据损坏
      throw StorageException('Failed to decrypt backup data. Please verify the backup password is correct.');
    }
  }

  /// 从迁移数据恢复动态口令
  Future<void> _restoreFromMigrationData(String migrationData) async {
    // 清空现有动态口令
    await _storageService.clearAllAccounts();

    // 使用 QrUtils.parseMigrationData 解析迁移数据
    // 复用 qr_utils.dart 中的解析方法，确保与二维码解析逻辑一致
    final accounts = QrUtils.parseMigrationData(migrationData);

    // 遍历解析出的动态口令数据，添加到数据库
    for (final account in accounts) {
      final secret = account['secret'] as String?;
      final name = account['name'] as String?;
      final issuer = account['issuer'] as String?;
      final algorithm = account['algorithm'] as String? ?? 'SHA1';
      final period = account['period'] as int? ?? 30;
      final type = account['type'] as String? ?? 'totp';
      final counter = account['counter'] as int? ?? 0;

      if (secret == null || name == null) continue;

      // 创建动态口令
      final twoFactorAccount = TwoFactorAccount(
        '',
        // ID 会自动生成
        issuer,
        name,
        secret,
        period,
        algorithm,
        DateTime.now(),
        DateTime.now(),
        type: type,
        counter: counter,
      );

      // 插入数据库
      await _storageService.insertAccount(twoFactorAccount);
    }
  }

  /// 生成备份文件名（包含时间戳）
  String _generateBackupFileName() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'backup_$timestamp.zip';
  }

  /// 构建 WebDAV 文件完整 URL
  ///
  /// [baseUrl] WebDAV 服务器基础 URL
  /// [backupDir] 备份目录
  /// [fileName] 文件名
  ///
  /// 返回构建好的文件 URL
  String buildWebDavFileUrl(String baseUrl, String backupDir, String fileName) {
    String url = baseUrl;
    if (backupDir.isNotEmpty) {
      final dir = backupDir.startsWith('/')
          ? backupDir.substring(1)
          : backupDir;
      url = url.endsWith('/') ? '$url$dir' : '$url/$dir';
    }
    return url.endsWith('/') ? '$url$fileName' : '$url/$fileName';
  }

  /// 构建 WebDAV 目录 URL（用于 PROPFIND 列出文件）
  ///
  /// [baseUrl] WebDAV 服务器基础 URL
  /// [backupDir] 备份目录
  ///
  /// 返回构建好的目录 URL（确保以 / 结尾）
  String buildWebDavDirUrl(String baseUrl, String backupDir) {
    String url = baseUrl;
    if (backupDir.isNotEmpty) {
      final dir = backupDir.startsWith('/')
          ? backupDir.substring(1)
          : backupDir;
      url = url.endsWith('/') ? '$url$dir' : '$url/$dir';
    }
    return url.endsWith('/') ? url : '$url/';
  }

  /// 检查远程是否有备份文件
  ///
  /// [setting] 应用设置
  ///
  /// 返回值：远程是否有备份文件
  Future<bool> hasRemoteBackup(Setting setting) async {
    if (setting.backupSetting.type == BackupType.webdav) {
      // 使用 WebDAV 工具类获取文件列表
      final listUrl = buildWebDavDirUrl(
        setting.backupSetting.webDavConfig.url,
        setting.backupSetting.webDavConfig.backupDir,
      );
      final files = await WebDavUtils.listFiles(
        listUrl,
        setting.backupSetting.webDavConfig.username,
        setting.backupSetting.webDavConfig.password,
      );

      // 过滤备份文件
      final backupFiles = files
          .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
          .toList();

      return backupFiles.isNotEmpty;
    } else if (setting.backupSetting.type == BackupType.s3) {
      // 使用 S3 工具类获取文件列表
      final objects = await S3Utils.listObjects(
        setting.backupSetting.s3Config.endpoint,
        setting.backupSetting.s3Config.bucketName,
        setting.backupSetting.s3Config.accessKeyId,
        setting.backupSetting.s3Config.secretAccessKey,
        region: setting.backupSetting.s3Config.region,
      );

      // 过滤备份文件（与 restoreBackup 保持一致，按 backupDir 过滤）
      final backupDir = setting.backupSetting.s3Config.backupDir;
      final backupFiles = objects.where((f) {
        if (backupDir.isNotEmpty && !f.startsWith(backupDir)) {
          return false;
        }
        return f.endsWith('.zip') && f.contains('backup_');
      }).toList();

      return backupFiles.isNotEmpty;
    }

    return false;
  }

  /// 删除远程备份文件
  ///
  /// [setting] 应用设置
  Future<void> deleteRemoteBackup(Setting setting) async {
    if (setting.backupSetting.type == BackupType.webdav) {
      // 使用 WebDAV 工具类获取文件列表
      final listUrl = buildWebDavDirUrl(
        setting.backupSetting.webDavConfig.url,
        setting.backupSetting.webDavConfig.backupDir,
      );
      final files = await WebDavUtils.listFiles(
        listUrl,
        setting.backupSetting.webDavConfig.username,
        setting.backupSetting.webDavConfig.password,
      );

      // 过滤并排序备份文件
      final backupFiles =
          files
              .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
              .toList()
            ..sort((a, b) => b.compareTo(a));

      // 删除所有备份文件
      for (final file in backupFiles) {
        final url = buildWebDavFileUrl(
          setting.backupSetting.webDavConfig.url,
          setting.backupSetting.webDavConfig.backupDir,
          file,
        );
        await WebDavUtils.deleteFile(
          url,
          setting.backupSetting.webDavConfig.username,
          setting.backupSetting.webDavConfig.password,
        );
      }
    } else if (setting.backupSetting.type == BackupType.s3) {
      // 使用 S3 工具类获取文件列表
      final objects = await S3Utils.listObjects(
        setting.backupSetting.s3Config.endpoint,
        setting.backupSetting.s3Config.bucketName,
        setting.backupSetting.s3Config.accessKeyId,
        setting.backupSetting.s3Config.secretAccessKey,
        region: setting.backupSetting.s3Config.region,
      );

      // 过滤备份文件（S3 返回完整 key，需按 backupDir 前缀过滤）
      final backupDir = setting.backupSetting.s3Config.backupDir;
      final backupFiles = objects
          .where((f) {
            if (backupDir.isNotEmpty && !f.startsWith(backupDir)) {
              return false;
            }
            final name = backupDir.isNotEmpty
                ? f.substring(backupDir.length).replaceFirst(RegExp(r'^/'), '')
                : f;
            return name.startsWith('backup_') && name.endsWith('.zip');
          })
          .toList();

      // 删除所有备份文件
      for (final file in backupFiles) {
        await S3Utils.deleteObject(
          setting.backupSetting.s3Config.endpoint,
          setting.backupSetting.s3Config.bucketName,
          file,
          setting.backupSetting.s3Config.accessKeyId,
          setting.backupSetting.s3Config.secretAccessKey,
          region: setting.backupSetting.s3Config.region,
        );
      }
    }
  }

  /// 备份文件内文件名
  static const String _saltFileName = 'salt';
  static const String _dataFileName = 'data';
}
