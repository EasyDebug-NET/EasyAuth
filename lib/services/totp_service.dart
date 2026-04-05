import 'dart:math';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';

/// TOTP服务类，用于计算基于时间的一次性密码
class TotpService {
  /// 计算TOTP动态码
  ///
  /// [secret] Base32编码的秘钥
  /// [period] 动态码更新周期，默认30秒
  /// [digits] 动态码位数，默认6位
  /// [timestamp] 可选的时间戳，默认使用当前时间
  ///
  /// 执行步骤：
  /// 1. 获取当前时间戳或使用指定时间戳
  /// 2. 计算时间步数
  /// 3. 将计数器转换为8字节的大端序字节数组
  /// 4. 解码Base32秘钥
  /// 5. 计算HMAC-SHA1
  /// 6. 动态截取
  /// 7. 计算动态码
  /// 8. 格式化为指定位数的字符串
  ///
  /// 返回动态码字符串
  static String generateCode({
    required String secret,
    int period = 30,
    int digits = 6,
    int? timestamp,
  }) {
    try {
      // 使用当前时间戳或指定时间戳
      final time = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 计算时间步数
      final counter = time ~/ period;

      // 将计数器转换为8字节的大端序字节数组
      final counterBytes = _intToBytes(counter);

      // 解码Base32秘钥
      final key = base32.decode(secret);

      // 计算HMAC-SHA1
      final hmac = Hmac(sha1, key);
      final digest = hmac.convert(counterBytes);

      // 动态截取
      final offset = digest.bytes[digest.bytes.length - 1] & 0x0f;
      final binary =
          ((digest.bytes[offset] & 0x7f) << 24) |
          ((digest.bytes[offset + 1] & 0xff) << 16) |
          ((digest.bytes[offset + 2] & 0xff) << 8) |
          (digest.bytes[offset + 3] & 0xff);

      // 计算动态码
      final otp = binary % pow(10, digits).toInt();

      // 格式化为指定位数的字符串
      return otp.toString().padLeft(digits, '0');
      // 使用字符串插值优化性能
    } catch (e) {
      // 如果解码失败，返回错误占位符
      return 'ERROR';
    }
  }

  /// 获取当前周期剩余秒数
  ///
  /// [period] 动态码更新周期，默认30秒
  /// [timestamp] 可选的时间戳，默认使用当前时间
  ///
  /// 返回剩余秒数
  static int getRemainingSeconds({int period = 30, int? timestamp}) {
    final time = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (time % period);
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

  /// 解析otpauth URI
  ///
  /// [uri] otpauth格式的URI
  ///
  /// 返回包含issuer、name、secret、period、algorithm的Map
  static Map<String, dynamic> parseOtpAuthUri(String uri) {
    final result = <String, dynamic>{};

    // 解析URI
    final parsedUri = Uri.parse(uri);

    // 检查协议
    if (parsedUri.scheme != 'otpauth') {
      throw Exception('Invalid OTP URI: scheme must be otpauth');
    }

    // 检查类型
    if (parsedUri.host != 'totp') {
      throw Exception('Only TOTP is supported');
    }

    // 解析路径获取issuer和name
    final path = Uri.decodeFull(parsedUri.path.substring(1)); // 移除开头的'/'并解码
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
    result['period'] = int.tryParse(params['period'] ?? '30') ?? 30;
    result['algorithm'] = params['algorithm'] ?? 'SHA1';

    // 如果issuer在查询参数中，覆盖从路径解析的值
    if (params['issuer'] != null) {
      result['issuer'] = params['issuer'];
    }

    return result;
  }
}
