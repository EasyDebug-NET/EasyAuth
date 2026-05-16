import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';

import 'exceptions.dart';

/// 二维码数据解析与生成工具类
///
/// 用于解析和生成 Google Authenticator 迁移二维码数据（otpauth-migration://offline 格式）。
/// 数据采用 Protocol Buffers (proto3) 二进制格式编码。
///
/// 官方 proto 定义：
/// ```proto
/// message MigrationPayload {
///   enum Algorithm { ALGO_INVALID=0; ALGO_SHA1=1; ALGO_SHA256=2; ALGO_SHA512=3; ALGO_MD5=4; }
///   enum OtpType { OTP_INVALID=0; OTP_HOTP=1; OTP_TOTP=2; }
///   message OtpParameters {
///     bytes secret=1; string name=2; string issuer=3;
///     Algorithm algorithm=4; int32 digits=5; OtpType type=6; int64 counter=7;
///   }
///   repeated OtpParameters otp_parameters=1;
///   int32 version=2; int32 batch_size=3; int32 batch_index=4; int32 batch_id=5;
/// }
/// ```
class QrUtils {
  static List<Map<String, dynamic>> parseMigrationData(String qrCode) {
    qrCode = qrCode.trim();
    if (!qrCode.startsWith('otpauth-migration://offline?data=')) {
      throw ValidationException('无效的迁移二维码');
    }

    var base64 = qrCode.replaceFirst('otpauth-migration://offline?data=', '');
    base64 = Uri.decodeComponent(base64);

    final paddedBase64 = base64.padRight(
      base64.length + (4 - base64.length % 4) % 4,
      '=',
    );

    final Uint8List bytes;
    try {
      bytes = base64Url.decode(paddedBase64);
    } catch (e) {
      throw ValidationException('Base64解码失败', details: e.toString());
    }

    final payload = _decodeMigrationPayload(bytes);
    final accounts = <Map<String, dynamic>>[];

    for (final otpParams in payload['otp_parameters'] as List) {
      final p = otpParams as Map<String, dynamic>;
      final secret = p['secret'];
      if (secret == null || secret.isEmpty) continue;

      final name = (p['name'] as String?) ?? '';
      if (name.isEmpty) continue;

      final type = p['type'] as String? ?? 'OTP_TOTP';
      final algorithm = p['algorithm'] as String? ?? 'ALGO_SHA1';
      final digits = p['digits'] as int? ?? 6;
      final counter = p['counter'] as int? ?? 0;

      // 使用final关键字进行类型推断，提高代码可读性
      accounts.add({
        'secret': secret,
        'name': name,
        'issuer': (p['issuer'] as String?) ?? '',
        'type': type == 'OTP_TOTP' ? 'totp' : 'hotp',
        'algorithm': _algoToString(algorithm),
        'digits': digits,
        'period': 30,
        'counter': counter,
      });
    }

    if (accounts.isEmpty) {
      throw ValidationException('无效的二维码数据格式');
    }

    return accounts;
  }

  static String _algoToString(String algo) {
    switch (algo) {
      case 'ALGO_SHA1':
        return 'SHA1';
      case 'ALGO_SHA256':
        return 'SHA256';
      case 'ALGO_SHA512':
        return 'SHA512';
      case 'ALGO_MD5':
        return 'MD5';
      default:
        return 'SHA1';
    }
  }

  static int _algoToInt(String algorithm) {
    switch (algorithm) {
      case 'SHA1':
        return 1;
      case 'SHA256':
        return 2;
      case 'SHA512':
        return 3;
      case 'MD5':
        return 4;
      default:
        return 1;
    }
  }

  static String _algoToEnumName(int value) {
    switch (value) {
      case 1:
        return 'ALGO_SHA1';
      case 2:
        return 'ALGO_SHA256';
      case 3:
        return 'ALGO_SHA512';
      case 4:
        return 'ALGO_MD5';
      default:
        return 'ALGO_INVALID';
    }
  }

  static String _otpTypeToEnumName(int value) {
    switch (value) {
      case 1:
        return 'OTP_HOTP';
      case 2:
        return 'OTP_TOTP';
      default:
        return 'OTP_INVALID';
    }
  }

  // ── Protobuf 手动解码 ──────────────────────────────────────

  static Map<String, dynamic> _decodeMigrationPayload(Uint8List data) {
    final result = <String, dynamic>{
      'otp_parameters': <Map<String, dynamic>>[],
      'version': 0,
      'batch_size': 0,
      'batch_index': 0,
      'batch_id': 0,
    };

    int offset = 0;
    while (offset < data.length) {
      final tagAndWire = data[offset++];
      final fieldNumber = tagAndWire >> 3;
      final wireType = tagAndWire & 0x07;

      switch (fieldNumber) {
        case 1: // repeated OtpParameters otp_parameters
          if (wireType == 2) {
            final length = _readVarint(data, offset);
            offset += _varintSize(length);
            final subMessage = data.sublist(offset, offset + length);
            final otpParams = _decodeOtpParameters(subMessage);
            (result['otp_parameters'] as List).add(otpParams);
            offset += length;
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 2: // int32 version
          if (wireType == 0) {
            result['version'] = _readVarint(data, offset);
            offset += _varintSize(result['version'] as int);
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 3: // int32 batch_size
          if (wireType == 0) {
            result['batch_size'] = _readVarint(data, offset);
            offset += _varintSize(result['batch_size'] as int);
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 4: // int32 batch_index
          if (wireType == 0) {
            result['batch_index'] = _readVarint(data, offset);
            offset += _varintSize(result['batch_index'] as int);
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 5: // int32 batch_id
          if (wireType == 0) {
            result['batch_id'] = _readVarint(data, offset);
            offset += _varintSize(result['batch_id'] as int);
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        default:
          offset = _skipField(data, offset, wireType);
          break;
      }
    }

    return result;
  }

  static Map<String, dynamic> _decodeOtpParameters(Uint8List data) {
    final result = <String, dynamic>{};
    int offset = 0;

    while (offset < data.length) {
      final tagAndWire = data[offset++];
      final fieldNumber = tagAndWire >> 3;
      final wireType = tagAndWire & 0x07;

      switch (fieldNumber) {
        case 1: // bytes secret
          if (wireType == 2) {
            final length = _readVarint(data, offset);
            offset += _varintSize(length);
            final secretBytes = data.sublist(offset, offset + length);
            result['secret'] = base32.encode(secretBytes);
            offset += length;
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 2: // string name
          if (wireType == 2) {
            final length = _readVarint(data, offset);
            offset += _varintSize(length);
            result['name'] = utf8.decode(data.sublist(offset, offset + length));
            offset += length;
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 3: // string issuer
          if (wireType == 2) {
            final length = _readVarint(data, offset);
            offset += _varintSize(length);
            result['issuer'] = utf8.decode(
              data.sublist(offset, offset + length),
            );
            offset += length;
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 4: // Algorithm algorithm (enum/varint)
          if (wireType == 0) {
            final value = _readVarint(data, offset);
            offset += _varintSize(value);
            result['algorithm'] = _algoToEnumName(value);
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 5: // int32 digits
          if (wireType == 0) {
            final value = _readVarint(data, offset);
            offset += _varintSize(value);
            result['digits'] = value;
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 6: // OtpType type (enum/varint)
          if (wireType == 0) {
            final value = _readVarint(data, offset);
            offset += _varintSize(value);
            result['type'] = _otpTypeToEnumName(value);
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        case 7: // int64 counter
          if (wireType == 0) {
            final value = _readVarint(data, offset);
            offset += _varintSize(value);
            result['counter'] = value;
          } else {
            offset = _skipField(data, offset, wireType);
          }
          break;
        default:
          offset = _skipField(data, offset, wireType);
          break;
      }
    }

    return result;
  }

  static int _skipField(Uint8List data, int offset, int wireType) {
    int newOffset;
    switch (wireType) {
      case 0: // varint
        final value = _readVarint(data, offset);
        newOffset = offset + _varintSize(value);
        break;
      case 1: // 64-bit
        newOffset = offset + 8;
        break;
      case 2: // length-delimited
        final length = _readVarint(data, offset);
        newOffset = offset + _varintSize(length) + length;
        break;
      case 5: // 32-bit
        newOffset = offset + 4;
        break;
      default:
        throw ValidationException('未知的wire type: $wireType');
    }
    return newOffset > data.length ? data.length : newOffset;
  }

  // ── Protobuf 手动编码 ──────────────────────────────────────

  static String generateMigrationData(List<Map<String, dynamic>> accounts) {
    final buffer = <int>[];

    // field 1: repeated OtpParameters otp_parameters
    for (final account in accounts) {
      final otpBytes = _encodeOtpParameters(account);
      buffer.add(0x0a); // tag = 1 << 3 | 2
      buffer.addAll(_writeVarint(otpBytes.length));
      buffer.addAll(otpBytes);
    }

    // field 2: int32 version = 1
    buffer.add(0x10); // tag = 2 << 3 | 0
    buffer.addAll(_writeVarint(1));

    // field 3: int32 batch_size = 1
    buffer.add(0x18); // tag = 3 << 3 | 0
    buffer.addAll(_writeVarint(1));

    // field 4: int32 batch_index = 0
    buffer.add(0x20); // tag = 4 << 3 | 0
    buffer.addAll(_writeVarint(0));

    // field 5: int32 batch_id (使用随机数或固定值)
    buffer.add(0x28); // tag = 5 << 3 | 0
    buffer.addAll(_writeVarint(1));

    final data = Uint8List.fromList(buffer);
    final base64Data = base64Url.encode(data).replaceAll('=', '');
    return 'otpauth-migration://offline?data=$base64Data';
  }

  static List<int> _encodeOtpParameters(Map<String, dynamic> account) {
    final buffer = <int>[];

    // field 1: bytes secret
    if (account.containsKey('secret') && account['secret'] != null) {
      final secret = base32.decode(account['secret'] as String);
      buffer.add(0x0a); // tag = 1 << 3 | 2
      buffer.addAll(_writeVarint(secret.length));
      buffer.addAll(secret);
    }

    // field 2: string name
    if (account.containsKey('name') && account['name'] != null) {
      final nameBytes = utf8.encode(account['name'] as String);
      buffer.add(0x12); // tag = 2 << 3 | 2
      buffer.addAll(_writeVarint(nameBytes.length));
      buffer.addAll(nameBytes);
    }

    // field 3: string issuer
    if (account.containsKey('issuer') && account['issuer'] != null) {
      final issuer = account['issuer'] as String;
      if (issuer.isNotEmpty) {
        final issuerBytes = utf8.encode(issuer);
        buffer.add(0x1a); // tag = 3 << 3 | 2
        buffer.addAll(_writeVarint(issuerBytes.length));
        buffer.addAll(issuerBytes);
      }
    }

    // field 4: Algorithm algorithm
    if (account.containsKey('algorithm')) {
      final algoValue = _algoToInt(account['algorithm'] as String);
      buffer.add(0x20); // tag = 4 << 3 | 0
      buffer.addAll(_writeVarint(algoValue));
    }

    // field 5: int32 digits
    if (account.containsKey('digits')) {
      final digits = account['digits'] as int;
      buffer.add(0x28); // tag = 5 << 3 | 0
      buffer.addAll(_writeVarint(digits));
    }

    // field 6: OtpType type
    if (account.containsKey('type')) {
      final type = account['type'] as String;
      final typeValue = type == 'hotp' ? 1 : 2;
      buffer.add(0x30); // tag = 6 << 3 | 0
      buffer.addAll(_writeVarint(typeValue));
    }

    // field 7: int64 counter
    if (account.containsKey('counter')) {
      final counter = account['counter'] as int;
      buffer.add(0x38); // tag = 7 << 3 | 0
      buffer.addAll(_writeVarint(counter));
    }

    return buffer;
  }

  // ── Varint 工具方法 ────────────────────────────────────────

  static int _readVarint(Uint8List data, int offset) {
    int value = 0;
    int shift = 0;
    while (offset < data.length && shift < 64) {
      final byte = data[offset++];
      value |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return value;
  }

  static List<int> _writeVarint(int value) {
    final buffer = <int>[];
    if (value == 0) return [0];
    while (value > 0) {
      if (value > 0x7F) {
        buffer.add((value & 0x7F) | 0x80);
      } else {
        buffer.add(value & 0x7F);
      }
      value >>= 7;
    }
    return buffer;
  }

  static int _varintSize(int value) {
    if (value <= 0) return 1;
    int size = 0;
    while (value > 0) {
      size++;
      value >>= 7;
    }
    return size;
  }
}
