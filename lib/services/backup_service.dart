import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// 生成备份密码
  ///
  /// [setting] 应用设置
  ///
  /// 返回生成的备份密码
  /// 使用SHA-256哈希函数生成备份密码，避免直接存储敏感信息
  /// WebDAV: SHA256(url + username + password + 固定盐值)
  /// S3: SHA256(endpoint + accessKeyId + secretAccessKey + 固定盐值)
  /// 生成的哈希值固定为64个字符（十六进制字符串），无需担心长度限制
  String _generateBackupKey(Setting setting) {
    String sourceData;
    if (setting.backupSetting.type == BackupType.webdav) {
      sourceData =
          '${setting.backupSetting.webDavConfig.url}${setting.backupSetting.webDavConfig.username}${setting.backupSetting.webDavConfig.password}';
    } else if (setting.backupSetting.type == BackupType.s3) {
      sourceData =
          '${setting.backupSetting.s3Config.endpoint}${setting.backupSetting.s3Config.accessKeyId}${setting.backupSetting.s3Config.secretAccessKey}';
    } else {
      throw ConfigException('不支持的备份类型');
    }

    // 添加固定盐值，增强安全性
    const salt = 'EasyAuthBackupSalt';
    final combinedData = '$sourceData$salt';

    // 使用SHA-256哈希函数生成备份密码
    final bytes = utf8.encode(combinedData);
    final hash = sha256.convert(bytes);

    // 将哈希值转换为十六进制字符串（固定64个字符）
    return hash.toString();
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
  /// 5. 更新 backupKey
  /// 6. 清理临时文件
  ///
  /// 抛出异常：
  /// - [StorageException] 当生成备份数据失败时
  /// - [NetworkException] 当网络请求失败时
  /// - [ConfigException] 当配置无效时
  Future<void> performBackup(Setting setting) async {
    try {
      // 验证配置
      if (!isConfigValid(setting)) {
        throw ConfigException('备份配置无效', details: '请检查备份参数是否完整');
      }

      // 生成 otpauth-migration 数据
      String migrationData;
      try {
        migrationData = await _generateMigrationData();
      } catch (e) {
        throw StorageException(
          '生成备份数据失败',
          details: '无法读取账户数据',
          originalException: e is Exception ? e : null,
        );
      }

      // 根据备份类型获取备份密码
      final backupKey = _generateBackupKey(setting);

      // 打包并加密
      final tempDir = await getTemporaryDirectory();
      final backupFile = await _createBackupFile(
        migrationData,
        tempDir.path,
        backupKey,
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
          );
        }
      } on SocketException catch (e) {
        throw NetworkException(
          '网络连接失败',
          details: '请检查网络连接是否正常',
          originalException: e,
        );
      } on HttpException catch (e) {
        throw NetworkException(
          '上传备份失败',
          details: e.message,
          originalException: e,
        );
      } catch (e) {
        throw NetworkException(
          '上传备份时发生错误',
          details: e.toString(),
          originalException: e is Exception ? e : null,
        );
      }

      // 更新 backupKey
      final updatedSetting = setting.copyWith(
        backupSetting: setting.backupSetting.copyWith(backupKey: backupKey),
      );
      await saveConfig(updatedSetting);

      // 清理临时文件
      await backupFile.delete();
    } catch (e) {
      // 重新抛出已知的异常类型
      if (e is AppException) {
        rethrow;
      }
      // 包装未知的异常
      throw AppException(
        '备份过程中发生错误',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// 执行恢复操作
  ///
  /// [setting] 应用设置
  ///
  /// 执行步骤：
  /// 1. 下载最新备份
  /// 2. 解密并解压
  /// 3. 恢复数据
  /// 4. 清理临时文件
  ///
  /// 抛出异常：
  /// - [StorageException] 当没有找到备份文件或解密失败时
  /// - [NetworkException] 当网络请求失败时
  /// - [ConfigException] 当配置无效时
  Future<void> restoreBackup(Setting setting) async {
    try {
      // 验证配置
      if (!isConfigValid(setting)) {
        throw ConfigException('恢复配置无效', details: '请检查备份参数是否完整');
      }

      // 下载最新备份
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/backup.zip';
      File backupFile;

      try {
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

          if (backupFiles.isEmpty) {
            throw StorageException(
              '没有找到备份文件',
              details: 'WebDAV 存储中没有找到备份文件，请确保已经执行过备份操作',
            );
          }
          // 下载最新备份
          final latestBackup = backupFiles.first;
          final url = buildWebDavFileUrl(
            setting.backupSetting.webDavConfig.url,
            setting.backupSetting.webDavConfig.backupDir,
            latestBackup,
          );
          backupFile = await WebDavUtils.downloadFile(
            url,
            setting.backupSetting.webDavConfig.username,
            setting.backupSetting.webDavConfig.password,
            savePath,
          );
        } else if (setting.backupSetting.type == BackupType.s3) {
          // 使用 S3 工具类获取文件列表
          final objects = await S3Utils.listObjects(
            setting.backupSetting.s3Config.endpoint,
            setting.backupSetting.s3Config.bucketName,
            setting.backupSetting.s3Config.accessKeyId,
            setting.backupSetting.s3Config.secretAccessKey,
          );
          // 过滤并排序备份文件
          List<String> backupFiles;
          if (setting.backupSetting.s3Config.backupDir.isEmpty) {
            backupFiles = objects.where((f) => f.endsWith('.zip')).toList()
              ..sort((a, b) => b.compareTo(a));
          } else {
            backupFiles =
                objects
                    .where(
                      (f) =>
                          f.startsWith(
                            setting.backupSetting.s3Config.backupDir,
                          ) &&
                          f.endsWith('.zip'),
                    )
                    .map(
                      (f) => f
                          .substring(
                            setting.backupSetting.s3Config.backupDir.length,
                          )
                          .replaceFirst(RegExp(r'^/'), ''),
                    )
                    .toList()
                  ..sort((a, b) => b.compareTo(a));
          }

          if (backupFiles.isEmpty) {
            throw StorageException(
              '没有找到备份文件',
              details: 'S3 存储中没有找到备份文件，请确保已经执行过备份操作',
            );
          }
          // 下载最新备份
          final latestBackup = backupFiles.first;
          String objectKey = latestBackup;
          if (setting.backupSetting.s3Config.backupDir.isNotEmpty) {
            if (setting.backupSetting.s3Config.backupDir.endsWith('/')) {
              objectKey =
                  '${setting.backupSetting.s3Config.backupDir}$latestBackup';
            } else {
              objectKey =
                  '${setting.backupSetting.s3Config.backupDir}/$latestBackup';
            }
          }
          backupFile = await S3Utils.downloadFile(
            setting.backupSetting.s3Config.endpoint,
            setting.backupSetting.s3Config.bucketName,
            objectKey,
            setting.backupSetting.s3Config.accessKeyId,
            setting.backupSetting.s3Config.secretAccessKey,
            savePath,
          );
        } else {
          throw ConfigException('不支持的备份类型');
        }
      } on SocketException catch (e) {
        throw NetworkException(
          '网络连接失败',
          details: '请检查网络连接是否正常',
          originalException: e,
        );
      } on HttpException catch (e) {
        throw NetworkException(
          '下载备份失败',
          details: e.message,
          originalException: e,
        );
      } catch (e) {
        throw NetworkException(
          '下载备份时发生错误',
          details: e.toString(),
          originalException: e is Exception ? e : null,
        );
      }

      try {
        // 如果 backupKey 为空，根据当前配置生成新的 backupKey
        String backupKey = setting.backupSetting.backupKey;
        if (backupKey.isEmpty) {
          backupKey = _generateBackupKey(setting);
        }

        // 解密并解压
        final migrationData = await _extractMigrationData(
          backupFile.path,
          backupKey,
        );
        // 恢复数据
        await _restoreFromMigrationData(migrationData);
      } on StorageException {
        rethrow;
      } catch (e) {
        throw StorageException(
          '恢复数据失败',
          details: '备份文件可能已损坏或密码错误',
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
        '恢复过程中发生错误',
        details: e.toString(),
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// 加载应用设置
  Future<Setting> loadConfig() async {
    try {
      final typeStr = await _secureStorage.read(key: 'backup_type') ?? 'off';
      final backupType = BackupType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => BackupType.off,
      );
      final webDavUrl = await _secureStorage.read(key: 'webdav_url') ?? '';
      final webDavBackupDir =
          await _secureStorage.read(key: 'webdav_backup_dir') ?? '';
      final webDavUsername =
          await _secureStorage.read(key: 'webdav_username') ?? '';
      final webDavPassword =
          await _secureStorage.read(key: 'webdav_password') ?? '';
      final s3Endpoint = await _secureStorage.read(key: 's3_endpoint') ?? '';
      final s3AccessKeyId =
          await _secureStorage.read(key: 's3_access_key_id') ?? '';
      final s3SecretAccessKey =
          await _secureStorage.read(key: 's3_secret_access_key') ?? '';
      final s3BucketName =
          await _secureStorage.read(key: 's3_bucket_name') ?? '';
      final s3BackupDir = await _secureStorage.read(key: 's3_backup_dir') ?? '';
      final backupKey = await _secureStorage.read(key: 'backup_key') ?? '';
      final appLockEnabledStr =
          await _secureStorage.read(key: 'app_lock_enabled') ?? '0';
      final appLockEnabled = int.tryParse(appLockEnabledStr) ?? 0;
      final screenshotLockEnabledStr =
          await _secureStorage.read(key: 'screenshot_lock_enabled') ?? '1';
      final screenshotLockEnabled = int.tryParse(screenshotLockEnabledStr) ?? 1;
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
          ),
          backupKey: backupKey,
        ),
        securitySetting: SecuritySetting(
          appLockEnabled: appLockEnabled,
          screenshotLockEnabled: screenshotLockEnabled,
        ),
      );
    } catch (e) {
      // 出错时返回默认配置
      return Setting(
        backupSetting: BackupSetting(
          type: BackupType.off,
          webDavConfig: WebDavConfig(url: '', username: '', password: ''),
          s3Config: S3Config(
            endpoint: '',
            accessKeyId: '',
            secretAccessKey: '',
            bucketName: '',
          ),
          backupKey: '',
        ),
      );
    }
  }

  /// 保存应用设置
  Future<void> saveConfig(Setting setting) async {
    await _secureStorage.write(
      key: 'backup_type',
      value: setting.backupSetting.type.toString().split('.').last,
    );
    await _secureStorage.write(
      key: 'webdav_url',
      value: setting.backupSetting.webDavConfig.url,
    );
    await _secureStorage.write(
      key: 'webdav_backup_dir',
      value: setting.backupSetting.webDavConfig.backupDir,
    );
    await _secureStorage.write(
      key: 'webdav_username',
      value: setting.backupSetting.webDavConfig.username,
    );
    await _secureStorage.write(
      key: 'webdav_password',
      value: setting.backupSetting.webDavConfig.password,
    );
    await _secureStorage.write(
      key: 's3_endpoint',
      value: setting.backupSetting.s3Config.endpoint,
    );
    await _secureStorage.write(
      key: 's3_access_key_id',
      value: setting.backupSetting.s3Config.accessKeyId,
    );
    await _secureStorage.write(
      key: 's3_secret_access_key',
      value: setting.backupSetting.s3Config.secretAccessKey,
    );
    await _secureStorage.write(
      key: 's3_bucket_name',
      value: setting.backupSetting.s3Config.bucketName,
    );
    await _secureStorage.write(
      key: 's3_backup_dir',
      value: setting.backupSetting.s3Config.backupDir,
    );

    await _secureStorage.write(
      key: 'backup_key',
      value: setting.backupSetting.backupKey,
    );
    await _secureStorage.write(
      key: 'app_lock_enabled',
      value: setting.securitySetting.appLockEnabled.toString(),
    );
    await _secureStorage.write(
      key: 'screenshot_lock_enabled',
      value: setting.securitySetting.screenshotLockEnabled.toString(),
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

    // 转换账户数据格式，使其符合 QrUtils.generateMigrationData 的要求
    final accountList = accounts
        .map(
          (account) => {
            'secret': account.secret,
            'name': account.name ?? '',
            'issuer': account.issuer ?? '',
            'algorithm': account.algorithm,
            'digits': 6,
            'type': 'totp', // 目前只支持 TOTP
            'period': account.period,
          },
        )
        .toList();

    // 复用 QrUtils 中的 generateMigrationData 方法
    return QrUtils.generateMigrationData(accountList);
  }

  /// 创建备份文件（打包并加密）
  ///
  /// [migrationData] 迁移数据（otpauth-migration 格式）
  /// [tempDir] 临时目录路径
  /// [backupKey] 备份密钥（用于 ZIP 加密）
  ///
  /// 执行步骤：
  /// 1. 创建 ZIP 存档
  /// 2. 添加迁移数据文件到存档
  /// 3. 使用标准 ZIP 加密编码存档
  /// 4. 写入最终备份文件
  ///
  /// 返回创建的备份文件
  Future<File> _createBackupFile(
    String migrationData,
    String tempDir,
    String backupKey,
  ) async {
    // 创建 ZIP 存档
    final archive = Archive();
    final fileBytes = migrationData.codeUnits;
    archive.addFile(
      ArchiveFile(_migrationDataFileName, fileBytes.length, fileBytes),
    );

    // 编码为加密 ZIP（使用标准 ZIP 加密）
    final zipEncoder = ZipEncoder(password: backupKey);
    final zipData = zipEncoder.encode(archive);

    // 写入最终备份文件
    final backupFile = File('$tempDir/backup.zip');
    await backupFile.writeAsBytes(zipData);
    return backupFile;
  }

  /// 提取迁移数据（解密并解压）
  ///
  /// [filePath] 备份文件路径
  /// [backupKey] 备份密钥（用于 ZIP 解密）
  ///
  /// 执行步骤：
  /// 1. 读取加密文件
  /// 2. 使用标准 ZIP 解密解压存档
  /// 3. 找到迁移数据文件
  /// 4. 读取文件内容
  ///
  /// 返回迁移数据（otpauth-migration 格式）
  Future<String> _extractMigrationData(
    String filePath,
    String backupKey,
  ) async {
    // 读取加密文件
    final encryptedData = await File(filePath).readAsBytes();

    try {
      // 解压加密 ZIP
      // 使用用户提供的备份密钥作为 ZIP 密码
      final archive = ZipDecoder().decodeBytes(
        encryptedData,
        password: backupKey,
      );

      // 找到迁移数据文件
      final migrationFile = archive.files.firstWhere(
        (file) => file.name == _migrationDataFileName,
        orElse: () => throw Exception('备份文件格式错误'),
      );

      // 读取文件内容
      final content = String.fromCharCodes(migrationFile.content as List<int>);
      return content;
    } catch (e) {
      // 捕获解密失败的异常
      if (e.toString().contains('password') ||
          e.toString().contains('decrypt')) {
        throw Exception('恢复数据解密失败，请确认是否修改了备份参数。');
      }
      rethrow;
    }
  }

  /// 从迁移数据恢复账户
  Future<void> _restoreFromMigrationData(String migrationData) async {
    // 清空现有账户
    await _storageService.clearAllAccounts();

    // 使用 QrUtils.parseMigrationData 解析迁移数据
    // 复用 qr_utils.dart 中的解析方法，确保与二维码解析逻辑一致
    final accounts = QrUtils.parseMigrationData(migrationData);

    // 遍历解析出的账户数据，添加到数据库
    for (final account in accounts) {
      final secret = account['secret'] as String?;
      final name = account['name'] as String?;
      final issuer = account['issuer'] as String?;
      final algorithm = account['algorithm'] as String? ?? 'SHA1';
      final period = account['period'] as int? ?? 30;

      if (secret == null || name == null) continue;

      // 创建账户
      final twoFactorAccount = TwoFactorAccount.name(
        '',
        // ID 会自动生成
        issuer,
        name,
        secret,
        period,
        algorithm,
        DateTime.now(),
        DateTime.now(),
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
      /// 使用 WebDAV 工具类获取文件列表
      final listUrl = buildWebDavDirUrl(
        setting.backupSetting.webDavConfig.url,
        setting.backupSetting.webDavConfig.backupDir,
      );
      final files = await WebDavUtils.listFiles(
        listUrl,
        setting.backupSetting.webDavConfig.username,
        setting.backupSetting.webDavConfig.password,
      );

      /// 过滤备份文件
      final backupFiles = files
          .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
          .toList();

      return backupFiles.isNotEmpty;
    } else if (setting.backupSetting.type == BackupType.s3) {
      /// 使用 S3 工具类获取文件列表
      final objects = await S3Utils.listObjects(
        setting.backupSetting.s3Config.endpoint,
        setting.backupSetting.s3Config.bucketName,
        setting.backupSetting.s3Config.accessKeyId,
        setting.backupSetting.s3Config.secretAccessKey,
      );

      /// 过滤备份文件（与 restoreBackup 保持一致，按 backupDir 过滤）
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
      /// 使用 WebDAV 工具类获取文件列表
      final listUrl = buildWebDavDirUrl(
        setting.backupSetting.webDavConfig.url,
        setting.backupSetting.webDavConfig.backupDir,
      );
      final files = await WebDavUtils.listFiles(
        listUrl,
        setting.backupSetting.webDavConfig.username,
        setting.backupSetting.webDavConfig.password,
      );

      /// 过滤并排序备份文件
      final backupFiles =
          files
              .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
              .toList()
            ..sort((a, b) => b.compareTo(a));

      /// 删除所有备份文件
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
      /// 使用 S3 工具类获取文件列表
      final objects = await S3Utils.listObjects(
        setting.backupSetting.s3Config.endpoint,
        setting.backupSetting.s3Config.bucketName,
        setting.backupSetting.s3Config.accessKeyId,
        setting.backupSetting.s3Config.secretAccessKey,
      );

      /// 过滤备份文件
      final backupFiles = objects
          .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
          .toList();

      /// 删除所有备份文件
      for (final file in backupFiles) {
        await S3Utils.deleteObject(
          setting.backupSetting.s3Config.endpoint,
          setting.backupSetting.s3Config.bucketName,
          file,
          setting.backupSetting.s3Config.accessKeyId,
          setting.backupSetting.s3Config.secretAccessKey,
        );
      }
    }
  }

  /// 迁移数据文件名
  static const String _migrationDataFileName = 'migration_data.txt';
}
