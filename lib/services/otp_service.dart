import 'dart:math';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';

import '../utils/exceptions.dart';

/// OTP 服务类，用于计算基于时间 (TOTP) 或计数器 (HOTP) 的一次性密码
class OtpService {
  /// 计算动态码（TOTP 或 HOTP）
  ///
  /// [secret] Base32编码的密钥
  /// [period] TOTP 动态码更新周期，默认30秒
  /// [digits] 动态码位数，默认6位
  /// [algorithm] 加密算法（SHA1、SHA256、SHA512），默认 SHA1
  /// [timestamp] TOTP 可选的时间戳，默认使用当前时间
  /// [counter] HOTP 计数器值，传入时使用 HOTP 模式
  ///
  /// 返回动态码字符串
  static String generateCode({
    required String secret,
    int period = 30,
    int digits = 6,
    String algorithm = 'SHA1',
    int? timestamp,
    int? counter,
  }) {
    // 确定消息值：HOTP 模式用 counter，TOTP 模式用时间步数
    final int message;
    if (counter != null) {
      message = counter;
    } else {
      final time = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      message = time ~/ period;
    }

    return _computeOtp(
      secret: secret,
      message: message,
      digits: digits,
      algorithm: algorithm,
    );
  }

  /// 核心 OTP 计算逻辑：HMAC + 动态截取
  static String _computeOtp({
    required String secret,
    required int message,
    int digits = 6,
    String algorithm = 'SHA1',
  }) {
    final messageBytes = _intToBytes(message);
    final key = base32.decode(secret);
    final hash = _getHash(algorithm);
    final hmac = Hmac(hash, key);
    final digest = hmac.convert(messageBytes);

    final offset = digest.bytes[digest.bytes.length - 1] & 0x0f;
    final binary =
        ((digest.bytes[offset] & 0x7f) << 24) |
        ((digest.bytes[offset + 1] & 0xff) << 16) |
        ((digest.bytes[offset + 2] & 0xff) << 8) |
        (digest.bytes[offset + 3] & 0xff);

    final otp = binary % pow(10, digits).toInt();
    return otp.toString().padLeft(digits, '0');
  }

  /// 获取 TOTP 当前周期剩余秒数（HOTP 不适用）
  ///
  /// [period] 动态码更新周期，默认30秒
  /// [timestamp] 可选的时间戳，默认使用当前时间
  ///
  /// 返回剩余秒数
  static int getRemainingSeconds({int period = 30, int? timestamp}) {
    final time = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (time % period);
  }

  /// 根据算法名返回对应的哈希函数
  static Hash _getHash(String algorithm) {
    switch (algorithm.toUpperCase()) {
      case 'SHA256':
        return sha256;
      case 'SHA512':
        return sha512;
      case 'SHA1':
      default:
        return sha1;
    }
  }

  /// 将整数转换为8字节的大端序字节数组
  static Uint8List _intToBytes(int value) {
    final bytes = Uint8List(8);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = value & 0xff;
      value >>= 8;
    }
    return bytes;
  }

  /// 解析 otpauth URI
  ///
  /// [uri] otpauth 格式的 URI（支持 TOTP 和 HOTP）
  ///
  /// 返回包含 issuer、name、secret、period、algorithm、type、counter 的 Map
  static Map<String, dynamic> parseOtpAuthUri(String uri) {
    final result = <String, dynamic>{};

    // 解析URI
    final parsedUri = Uri.parse(uri);

    // 检查协议
    if (parsedUri.scheme != 'otpauth') {
      throw ValidationException('Invalid OTP URI: scheme must be otpauth');
    }

    // 检查类型
    final type = parsedUri.host;
    if (type != 'totp' && type != 'hotp') {
      throw ValidationException('Unsupported OTP type: $type');
    }

    // 解析路径获取issuer和name
    final path = Uri.decodeFull(parsedUri.path.substring(1));
    final colonIndex = path.indexOf(':');

    if (colonIndex != -1) {
      result['issuer'] = path.substring(0, colonIndex);
      result['name'] = path.substring(colonIndex + 1);
    } else {
      result['issuer'] = '';
      result['name'] = path;
    }

    // 解析查询参数
    final params = parsedUri.queryParameters;
    result['secret'] = params['secret'] ?? '';
    result['algorithm'] = params['algorithm'] ?? 'SHA1';
    result['type'] = type;

    if (type == 'totp') {
      result['period'] = int.tryParse(params['period'] ?? '30') ?? 30;
      result['counter'] = 0;
    } else {
      result['counter'] = int.tryParse(params['counter'] ?? '0') ?? 0;
      result['period'] = 30;
    }

    // 如果issuer在查询参数中，覆盖从路径解析的值
    if (params['issuer'] != null) {
      result['issuer'] = params['issuer'];
    }

    return result;
  }
}
