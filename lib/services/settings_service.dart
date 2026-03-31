import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../models/settings.dart';
import '../models/two_factor_account.dart';
import '../utils/webdav_utils.dart';
import '../utils/s3_utils.dart';
import '../utils/qr_utils.dart';
import 'storage_service.dart';

/// 备份服务
class BackupService {
  final StorageService _storageService = StorageService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// 执行备份操作
  ///
  /// [config] 备份配置
  ///
  /// 执行步骤：
  /// 1. 生成 otpauth-migration 数据
  /// 2. 打包并加密
  /// 3. 上传到存储服务
  /// 4. 清理临时文件
  Future<void> performBackup(BackupConfig config) async {
    // 生成 otpauth-migration 数据
    final migrationData = await _generateMigrationData();

    // 打包并加密
    final tempDir = await getTemporaryDirectory();
    final backupFile = await _createBackupFile(
      migrationData,
      tempDir.path,
      config.backupKey,
    );
    // 上传到存储服务
    final fileName = _generateBackupFileName();

    if (config.type == BackupType.webdav) {
      // 使用 WebDAV 工具类
      final url = buildWebDavFileUrl(
        config.webDavConfig.url,
        config.webDavConfig.backupDir,
        fileName,
      );
      await WebDavUtils.uploadFile(
        backupFile.path,
        url,
        config.webDavConfig.username,
        config.webDavConfig.password,
      );
    } else if (config.type == BackupType.s3) {
      // 使用 S3 工具类
      await S3Utils.uploadFile(
        backupFile.path,
        config.s3Config.endpoint,
        config.s3Config.bucketName,
        fileName,
        config.s3Config.accessKeyId,
        config.s3Config.secretAccessKey,
      );
    }

    // 清理临时文件
    await backupFile.delete();
  }

  /// 执行恢复操作
  ///
  /// [config] 备份配置
  ///
  /// 执行步骤：
  /// 1. 下载最新备份
  /// 2. 解密并解压
  /// 3. 恢复数据
  /// 4. 清理临时文件
  Future<void> restoreBackup(BackupConfig config) async {
    // 下载最新备份
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/backup.zip';
    File backupFile;

    if (config.type == BackupType.webdav) {
      // 使用 WebDAV 工具类获取文件列表
      final listUrl = buildWebDavDirUrl(
        config.webDavConfig.url,
        config.webDavConfig.backupDir,
      );
      final files = await WebDavUtils.listFiles(
        listUrl,
        config.webDavConfig.username,
        config.webDavConfig.password,
      );
      // 过滤并排序备份文件
      final backupFiles =
          files
              .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
              .toList()
            ..sort((a, b) => b.compareTo(a));

      if (backupFiles.isEmpty) {
        throw Exception('WebDAV 存储中没有找到备份文件');
      }
      // 下载最新备份
      final latestBackup = backupFiles.first;
      final url = buildWebDavFileUrl(
        config.webDavConfig.url,
        config.webDavConfig.backupDir,
        latestBackup,
      );
      backupFile = await WebDavUtils.downloadFile(
        url,
        config.webDavConfig.username,
        config.webDavConfig.password,
        savePath,
      );
    } else if (config.type == BackupType.s3) {
      // 使用 S3 工具类获取文件列表
      final objects = await S3Utils.listObjects(
        config.s3Config.endpoint,
        config.s3Config.bucketName,
        config.s3Config.accessKeyId,
        config.s3Config.secretAccessKey,
      );
      // 过滤并排序备份文件
      final backupFiles =
          objects
              .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
              .toList()
            ..sort((a, b) => b.compareTo(a));

      if (backupFiles.isEmpty) {
        throw Exception('S3 存储中没有找到备份文件');
      }
      // 下载最新备份
      final latestBackup = backupFiles.first;
      backupFile = await S3Utils.downloadFile(
        config.s3Config.endpoint,
        config.s3Config.bucketName,
        latestBackup,
        config.s3Config.accessKeyId,
        config.s3Config.secretAccessKey,
        savePath,
      );
    } else {
      throw Exception('不支持的备份类型');
    }

    try {
      // 解密并解压
      final migrationData = await _extractMigrationData(
        backupFile.path,
        config.backupKey,
      );
      // 恢复数据
      await _restoreFromMigrationData(migrationData);
    } finally {
      // 清理临时文件
      await backupFile.delete();
    }
  }

  /// 加载备份配置
  Future<BackupConfig> loadConfig() async {
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
      final backupKey = await _secureStorage.read(key: 'backup_key') ?? '';
      return BackupConfig(
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
        ),
        backupKey: backupKey,
      );
    } catch (e) {
      // 出错时返回默认配置
      return BackupConfig(
        type: BackupType.off,
        webDavConfig: WebDavConfig(url: '', username: '', password: ''),
        s3Config: S3Config(
          endpoint: '',
          accessKeyId: '',
          secretAccessKey: '',
          bucketName: '',
        ),
        backupKey: '',
      );
    }
  }

  /// 保存备份配置
  Future<void> saveConfig(BackupConfig config) async {
    await _secureStorage.write(
      key: 'backup_type',
      value: config.type.toString().split('.').last,
    );
    await _secureStorage.write(
      key: 'webdav_url',
      value: config.webDavConfig.url,
    );
    await _secureStorage.write(
      key: 'webdav_backup_dir',
      value: config.webDavConfig.backupDir,
    );
    await _secureStorage.write(
      key: 'webdav_username',
      value: config.webDavConfig.username,
    );
    await _secureStorage.write(
      key: 'webdav_password',
      value: config.webDavConfig.password,
    );
    await _secureStorage.write(
      key: 's3_endpoint',
      value: config.s3Config.endpoint,
    );
    await _secureStorage.write(
      key: 's3_access_key_id',
      value: config.s3Config.accessKeyId,
    );
    await _secureStorage.write(
      key: 's3_secret_access_key',
      value: config.s3Config.secretAccessKey,
    );
    await _secureStorage.write(
      key: 's3_bucket_name',
      value: config.s3Config.bucketName,
    );

    await _secureStorage.write(key: 'backup_key', value: config.backupKey);
  }

  /// 验证备份配置是否有效
  bool isConfigValid(BackupConfig config) {
    if (config.type == BackupType.off) {
      return false;
    }

    if (config.type == BackupType.webdav) {
      final webDavConfig = config.webDavConfig;
      return webDavConfig.url.isNotEmpty &&
          webDavConfig.username.isNotEmpty &&
          webDavConfig.password.isNotEmpty &&
          config.backupKey.isNotEmpty;
    } else if (config.type == BackupType.s3) {
      final s3Config = config.s3Config;
      return s3Config.endpoint.isNotEmpty &&
          s3Config.accessKeyId.isNotEmpty &&
          s3Config.secretAccessKey.isNotEmpty &&
          s3Config.bucketName.isNotEmpty &&
          config.backupKey.isNotEmpty;
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
    // 使用用户提供的备份密钥作为 ZIP 密码
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
  }

  /// 从迁移数据恢复账户
  Future<void> _restoreFromMigrationData(String migrationData) async {
    // 清空现有账户
    final db = await _storageService.database;
    await db.delete('two_factor_accounts');

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
        0,
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
  /// [config] 备份配置
  ///
  /// 返回值：远程是否有备份文件
  Future<bool> hasRemoteBackup(BackupConfig config) async {
    if (config.type == BackupType.webdav) {
      /// 使用 WebDAV 工具类获取文件列表
      final listUrl = buildWebDavDirUrl(
        config.webDavConfig.url,
        config.webDavConfig.backupDir,
      );
      final files = await WebDavUtils.listFiles(
        listUrl,
        config.webDavConfig.username,
        config.webDavConfig.password,
      );

      /// 过滤备份文件
      final backupFiles = files
          .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
          .toList();

      return backupFiles.isNotEmpty;
    } else if (config.type == BackupType.s3) {
      /// 使用 S3 工具类获取文件列表
      final objects = await S3Utils.listObjects(
        config.s3Config.endpoint,
        config.s3Config.bucketName,
        config.s3Config.accessKeyId,
        config.s3Config.secretAccessKey,
      );

      /// 过滤备份文件
      final backupFiles = objects
          .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
          .toList();

      return backupFiles.isNotEmpty;
    }

    return false;
  }

  /// 删除远程备份文件
  ///
  /// [config] 备份配置
  Future<void> deleteRemoteBackup(BackupConfig config) async {
    if (config.type == BackupType.webdav) {
      /// 使用 WebDAV 工具类获取文件列表
      final listUrl = buildWebDavDirUrl(
        config.webDavConfig.url,
        config.webDavConfig.backupDir,
      );
      final files = await WebDavUtils.listFiles(
        listUrl,
        config.webDavConfig.username,
        config.webDavConfig.password,
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
          config.webDavConfig.url,
          config.webDavConfig.backupDir,
          file,
        );
        await WebDavUtils.deleteFile(
          url,
          config.webDavConfig.username,
          config.webDavConfig.password,
        );
      }
    } else if (config.type == BackupType.s3) {
      /// 使用 S3 工具类获取文件列表
      final objects = await S3Utils.listObjects(
        config.s3Config.endpoint,
        config.s3Config.bucketName,
        config.s3Config.accessKeyId,
        config.s3Config.secretAccessKey,
      );

      /// 过滤备份文件
      final backupFiles = objects
          .where((f) => f.startsWith('backup_') && f.endsWith('.zip'))
          .toList();

      /// 删除所有备份文件
      for (final file in backupFiles) {
        await S3Utils.deleteObject(
          config.s3Config.endpoint,
          config.s3Config.bucketName,
          file,
          config.s3Config.accessKeyId,
          config.s3Config.secretAccessKey,
        );
      }
    }
  }

  /// 迁移数据文件名
  static const String _migrationDataFileName = 'migration_data.txt';
}
