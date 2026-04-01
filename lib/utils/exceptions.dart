/// 自定义异常类，用于提供更有意义的错误信息
class AppException implements Exception {
  final String message;
  final String? details;
  final Exception? originalException;

  AppException(this.message, {this.details, this.originalException});

  @override
  String toString() {
    if (details != null) {
      return '$message: $details';
    }
    return message;
  }
}

/// 网络异常
class NetworkException extends AppException {
  NetworkException(super.message, {super.details, super.originalException});
}

/// 配置异常
class ConfigException extends AppException {
  ConfigException(super.message, {super.details, super.originalException});
}

/// 认证异常
class AuthException extends AppException {
  AuthException(super.message, {super.details, super.originalException});
}

/// 存储异常
class StorageException extends AppException {
  StorageException(super.message, {super.details, super.originalException});
}

/// 验证异常
class ValidationException extends AppException {
  ValidationException(super.message, {super.details, super.originalException});
}
