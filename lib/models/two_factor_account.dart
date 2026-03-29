/// 2FA 账户数据模型
class TwoFactorAccount {
  /// 主键 ID，由数据库自动生成
  final int id;

  /// 发行者名称（如 Google、GitHub 等）
  final String? issuer;

  /// 账户名称（如用户邮箱）
  final String? name;

  /// 2FA 秘钥（Base32 编码）
  final String secret;

  /// 动态密码更新周期（秒），TOTP 默认 30 秒
  final int period;

  /// 加密算法（SHA1、SHA256、SHA512）
  final String algorithm;

  /// 账户创建时间
  final DateTime createdAt;

  /// 账户最后更新时间
  final DateTime updatedAt;

  /// 创建 2FA 账户实例
  TwoFactorAccount.name(
    this.id,
    this.issuer,
    this.name,
    this.secret,
    this.period,
    this.algorithm,
    this.createdAt,
    this.updatedAt,
  );

  /// 显示名称，格式为 "issuer:name" 或仅显示其中之一
  String get displayName => issuer != null && name != null
      ? "$issuer:$name"
      : issuer ?? name ?? "未命名账户";
}
