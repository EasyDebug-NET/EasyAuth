/// 备份类型枚举
enum BackupType { off, webdav, s3 }

/// WebDAV 备份配置
class WebDavConfig {
  /// WebDAV 服务器地址
  final String url;

  /// 备份目录（相对于 WebDAV 根目录的子目录）
  final String backupDir;

  /// 授权用户名
  final String username;

  /// 授权密码（同时作为备份加密秘钥）
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
  /// S3 服务端点地址
  final String endpoint;

  /// 访问密钥 ID
  final String accessKeyId;

  /// 秘密访问密钥（同时作为备份加密秘钥）
  final String secretAccessKey;

  /// 桶名称
  final String bucketName;

  const S3Config({
    required this.endpoint,
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.bucketName,
  });

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
      'accessKeyId': accessKeyId,
      'secretAccessKey': secretAccessKey,
      'bucketName': bucketName,
    };
  }

  /// 从 JSON Map 反序列化
  factory S3Config.fromJson(Map<String, dynamic> json) {
    return S3Config(
      endpoint: json['endpoint'] ?? '',
      accessKeyId: json['accessKeyId'] ?? '',
      secretAccessKey: json['secretAccessKey'] ?? '',
      bucketName: json['bucketName'] ?? '',
    );
  }

  /// 创建副本，可选择覆盖部分字段
  S3Config copyWith({
    String? endpoint,
    String? accessKeyId,
    String? secretAccessKey,
    String? bucketName,
  }) {
    return S3Config(
      endpoint: endpoint ?? this.endpoint,
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretAccessKey: secretAccessKey ?? this.secretAccessKey,
      bucketName: bucketName ?? this.bucketName,
    );
  }
}

/// 备份配置
class BackupConfig {
  /// 备份类型（关闭、WebDAV、S3）
  final BackupType type;

  /// WebDAV 配置
  final WebDavConfig webDavConfig;

  /// S3 配置
  final S3Config s3Config;

  /// 备份加密秘钥（由 WebDAV 密码或 S3 secretAccessKey 同步生成，用户不可直接修改）
  final String backupKey;

  BackupConfig({
    required this.type,
    required this.webDavConfig,
    required this.s3Config,
    required this.backupKey,
  });

  /// 序列化为 JSON Map（不包含 autoBackup，因为它是派生状态）
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'webDavConfig': webDavConfig.toJson(),
      's3Config': s3Config.toJson(),
      'backupKey': backupKey,
    };
  }

  /// 从 JSON Map 反序列化（兼容旧版本含 autoBackup 字段的配置）
  factory BackupConfig.fromJson(Map<String, dynamic> json) {
    return BackupConfig(
      type: BackupType.values.firstWhere(
            (e) => e.toString().split('.').last == json['type'],
        orElse: () => BackupType.off,
      ),
      webDavConfig: WebDavConfig.fromJson(json['webDavConfig'] ?? {}),
      s3Config: S3Config.fromJson(json['s3Config'] ?? {}),
      backupKey: json['backupKey'] ?? '',
    );
  }

  /// 创建副本，可选择覆盖部分字段
  BackupConfig copyWith({
    BackupType? type,
    WebDavConfig? webDavConfig,
    S3Config? s3Config,
    String? backupKey,
    bool? backupOnOpen,
    bool? backupOnExit,
    bool? backupOnRefresh,
  }) {
    return BackupConfig(
      type: type ?? this.type,
      webDavConfig: webDavConfig ?? this.webDavConfig,
      s3Config: s3Config ?? this.s3Config,
      backupKey: backupKey ?? this.backupKey,
    );
  }
}
