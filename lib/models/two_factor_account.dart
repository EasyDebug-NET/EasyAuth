/// 2FA 动态口令数据模型
class TwoFactorAccount {
  /// 主键 ID，使用 UUID
  final String id;

  /// 发行者名称（如 Google、GitHub 等）
  final String? issuer;

  /// 动态口令名称（如用户邮箱）
  final String? name;

  /// 2FA 密钥（Base32 编码）
  final String secret;

  /// 动态口令更新周期（秒），TOTP 默认 30 秒
  final int period;

  /// 加密算法（SHA1、SHA256、SHA512）
  final String algorithm;

  /// 认证类型：'totp' 基于时间，'hotp' 基于计数器
  final String type;

  /// HOTP 计数器当前值
  final int counter;

  final DateTime createdAt;
  final DateTime updatedAt;

  TwoFactorAccount(
    this.id,
    this.issuer,
    this.name,
    this.secret,
    this.period,
    this.algorithm,
    this.createdAt,
    this.updatedAt, {
    this.type = 'totp',
    this.counter = 0,
  });

  /// 是否为 TOTP 类型
  bool get isTotp => type != 'hotp';

  /// 是否为 HOTP 类型
  bool get isHotp => type == 'hotp';

  /// 显示名称，格式为 "issuer:name" 或仅显示其中之一
  String get displayIssuerName => issuer != null && name != null
      ? '$issuer:$name'
      : issuer ?? name ?? '未命名动态口令';

  /// 显示名称，若为空则返回默认名称
  String get displayName => name != null ? '$name' : '未命名动态口令';

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issuer': issuer,
      'name': name,
      'secret': secret,
      'period': period,
      'algorithm': algorithm,
      'type': type,
      'counter': counter,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 从 JSON Map 创建实例
  factory TwoFactorAccount.fromJson(Map<String, dynamic> json) {
    return TwoFactorAccount(
      json['id'] as String,
      json['issuer'] as String?,
      json['name'] as String?,
      json['secret'] as String,
      json['period'] as int,
      json['algorithm'] as String,
      DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
      type: json['type'] as String? ?? 'totp',
      counter: json['counter'] as int? ?? 0,
    );
  }
}
