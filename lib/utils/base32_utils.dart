import 'dart:typed_data';

/// Base32编码工具类
///
/// 实现RFC4648标准的base32编码和解码功能，用于2FA秘钥等场景。
class Base32 {
  /// RFC4648标准的base32编码表
  static const String _base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// 将字节数组编码为base32字符串（无填充）
  static String encode(Uint8List bytes) {
    final output = StringBuffer();
    int bits = 0;
    int value = 0;

    for (int i = 0; i < bytes.length; i++) {
      value = (value << 8) | bytes[i];
      bits += 8;

      while (bits >= 5) {
        output.write(_base32Chars[(value >> (bits - 5)) & 0x1F]);
        bits -= 5;
      }
    }

    if (bits > 0) {
      output.write(_base32Chars[(value << (5 - bits)) & 0x1F]);
    }

    return output.toString();
  }

  /// 将base32字符串解码为字节数组
  static Uint8List decode(String input) {
    final cleanedInput = input.toUpperCase().replaceAll(
      RegExp(r'[^A-Z2-7]'),
      '',
    );
    final output = <int>[];
    int bits = 0;
    int value = 0;

    for (int i = 0; i < cleanedInput.length; i++) {
      final char = cleanedInput[i];
      final index = _base32Chars.indexOf(char);
      if (index == -1) {
        throw FormatException('Invalid base32 character: $char');
      }

      value = (value << 5) | index;
      bits += 5;

      if (bits >= 8) {
        output.add((value >> (bits - 8)) & 0xFF);
        bits -= 8;
      }
    }

    return Uint8List.fromList(output);
  }
}
