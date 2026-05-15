/// 备份类型枚举
enum BackupType { off, webdav, s3 }

/// WebDAV 备份配置
class WebDavConfig {
  /// WebDAV 服务器地址
  final String url;

  /// 存储路径（相对于 WebDAV 根目录的子目录）
  final String backupDir;

  /// 授权用户名
  final String username;

  /// 授权密码
  final String password;

  const WebDavConfig({
    required this.url,
    this.backupDir = '',
    required this.username,
    required this.password,
  });

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'backupDir': backupDir,
      'username': username,
      'password': password,
    };
  }

  /// 从 JSON Map 反序列化
  factory WebDavConfig.fromJson(Map<String, dynamic> json) {
    return WebDavConfig(
      url: json['url'] ?? '',
      backupDir: json['backupDir'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }

  /// 创建副本，可选择覆盖部分字段
  WebDavConfig copyWith({
    String? url,
    String? backupDir,
    String? username,
    String? password,
  }) {
    return WebDavConfig(
      url: url ?? this.url,
      backupDir: backupDir ?? this.backupDir,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}

/// S3 备份配置
class S3Config {
  /// S3 服务端点
  final String endpoint;

  /// 访问密钥 ID
  final String accessKeyId;

  /// 访问密钥
  final String secretAccessKey;

  /// 存储桶名称
  final String bucketName;

  /// 存储路径
  final String backupDir;

  /// 区域（用于 AWS Signature V4 签名）
  final String? region;

  const S3Config({
    required this.endpoint,
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.bucketName,
    this.backupDir = '',
    this.region,
  });

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'accessKeyId': accessKeyId,
      'secretAccessKey': secretAccessKey,
      'bucketName': bucketName,
      'backupDir': backupDir,
      'region': region,
    };
  }

  /// 从 JSON Map 反序列化
  factory S3Config.fromJson(Map<String, dynamic> json) {
    return S3Config(
      endpoint: json['endpoint'] ?? '',
      accessKeyId: json['accessKeyId'] ?? '',
      secretAccessKey: json['secretAccessKey'] ?? '',
      bucketName: json['bucketName'] ?? '',
      backupDir: json['backupDir'] ?? '',
      region: json['region'] as String?,
    );
  }

  /// 创建副本，可选择覆盖部分字段
  S3Config copyWith({
    String? endpoint,
    String? accessKeyId,
    String? secretAccessKey,
    String? bucketName,
    String? backupDir,
    String? region,
  }) {
    return S3Config(
      endpoint: endpoint ?? this.endpoint,
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretAccessKey: secretAccessKey ?? this.secretAccessKey,
      bucketName: bucketName ?? this.bucketName,
      backupDir: backupDir ?? this.backupDir,
      region: region ?? this.region,
    );
  }
}

/// 安全设置
class SecuritySetting {
  /// 是否开启应用锁
  final bool appLockEnabled;

  /// 是否开启截屏锁
  final bool screenshotLockEnabled;

  const SecuritySetting({
    this.appLockEnabled = false,
    this.screenshotLockEnabled = true,
  });

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'appLockEnabled': appLockEnabled,
      'screenshotLockEnabled': screenshotLockEnabled,
    };
  }

  /// 从 JSON Map 反序列化
  factory SecuritySetting.fromJson(Map<String, dynamic> json) {
    return SecuritySetting(
      appLockEnabled: json['appLockEnabled'] == true,
      screenshotLockEnabled: json['screenshotLockEnabled'] != false,
    );
  }

  /// 创建副本，可选择覆盖部分字段
  SecuritySetting copyWith({bool? appLockEnabled, bool? screenshotLockEnabled}) {
    return SecuritySetting(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      screenshotLockEnabled:
          screenshotLockEnabled ?? this.screenshotLockEnabled,
    );
  }
}

/// 备份设置
class BackupSetting {
  /// 备份类型（关闭、WebDAV、S3）
  final BackupType type;

  /// WebDAV 配置
  final WebDavConfig webDavConfig;

  /// S3 配置
  final S3Config s3Config;

  const BackupSetting({
    required this.type,
    required this.webDavConfig,
    required this.s3Config,
  });

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'webDavConfig': webDavConfig.toJson(),
      's3Config': s3Config.toJson(),
    };
  }

  /// 从 JSON Map 反序列化
  factory BackupSetting.fromJson(Map<String, dynamic> json) {
    return BackupSetting(
      type: BackupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BackupType.off,
      ),
      webDavConfig: WebDavConfig.fromJson(json['webDavConfig'] ?? {}),
      s3Config: S3Config.fromJson(json['s3Config'] ?? {}),
    );
  }

  /// 创建副本，可选择覆盖部分字段
  BackupSetting copyWith({
    BackupType? type,
    WebDavConfig? webDavConfig,
    S3Config? s3Config,
  }) {
    return BackupSetting(
      type: type ?? this.type,
      webDavConfig: webDavConfig ?? this.webDavConfig,
      s3Config: s3Config ?? this.s3Config,
    );
  }
}

/// 应用设置（主类）
class Setting {
  /// 备份设置
  final BackupSetting backupSetting;

  /// 安全设置
  final SecuritySetting securitySetting;

  const Setting({
    required this.backupSetting,
    this.securitySetting = const SecuritySetting(),
  });

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'backupSetting': backupSetting.toJson(),
      'securitySetting': securitySetting.toJson(),
    };
  }

  /// 从 JSON Map 反序列化
  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      backupSetting: BackupSetting.fromJson(json['backupSetting'] ?? {}),
      securitySetting: SecuritySetting.fromJson(json['securitySetting'] ?? {}),
    );
  }

  /// 创建副本，可选择覆盖部分字段
  Setting copyWith({
    BackupSetting? backupSetting,
    SecuritySetting? securitySetting,
  }) {
    return Setting(
      backupSetting: backupSetting ?? this.backupSetting,
      securitySetting: securitySetting ?? this.securitySetting,
    );
  }
}
