#!/usr/bin/env python3
"""
EasyAuth 备份文件解密工具

解密 EasyAuth App 生成的备份 zip 文件，输出 otpauth:// URI 列表。

加密方案（对应 Flutter backup_service.dart）：
  1. 从 zip 中提取 salt（16 字节）和加密数据
  2. 密钥派生: SHA-256(密码_utf8 + salt)
  3. AES-256-GCM 解密: nonce(12字节) + ciphertext + GCM tag(16字节)
  4. 输出 otpauth-migration protobuf 数据

用法:
  python decryption-zip.py backup_20260731_120000.zip
  python decryption-zip.py backup_20260731_120000.zip -p 你的密码
  python decryption-zip.py backup.zip -o uris.txt
"""

import argparse
import hashlib
import struct
import sys
import zipfile
from pathlib import Path

try:
    from Cryptodome.Cipher import AES
except ImportError:
    print("错误: 需要安装 pycryptodomex 库")
    print("  pip install pycryptodomex")
    sys.exit(1)

# 文件在 zip 中的固定名称（对应 backup_service.dart 的 _saltFileName / _dataFileName）
SALT_FILENAME = "salt"
DATA_FILENAME = "data"

# AES-GCM 参数
NONCE_LENGTH = 12   # _nonceLength
TAG_LENGTH = 16     # GCM tag 固定 16 字节


def derive_key(password: str, salt: bytes) -> bytes:
    """SHA-256(password_utf8 + salt) -> 32 字节 AES-256 密钥"""
    data = password.encode("utf-8") + salt
    return hashlib.sha256(data).digest()


def decrypt_backup(zip_path: str, password: str) -> bytes:
    """
    解密备份文件，返回解密后的 otpauth-migration 数据。

    异常:
      ValueError: 密码错误或文件损坏
      FileNotFoundError: 文件不存在
      zipfile.BadZipFile: 非法的 zip 文件
      KeyError: zip 中缺少 salt 或 data 文件
    """
    with zipfile.ZipFile(zip_path, "r") as zf:
        # 提取 salt
        try:
            salt = zf.read(SALT_FILENAME)
        except KeyError:
            raise KeyError(
                f"备份文件格式错误: 缺少 '{SALT_FILENAME}' 文件。"
                f"请确认这是 EasyAuth 生成的备份文件。"
            )

        # 提取加密数据
        try:
            encrypted_data = zf.read(DATA_FILENAME)
        except KeyError:
            raise KeyError(
                f"备份文件格式错误: 缺少 '{DATA_FILENAME}' 文件。"
                f"请确认这是 EasyAuth 生成的备份文件。"
            )

    if len(salt) != 16:
        raise ValueError(f"salt 长度异常: {len(salt)} 字节（期望 16）")

    if len(encrypted_data) < NONCE_LENGTH + TAG_LENGTH:
        raise ValueError(
            f"加密数据太短: {len(encrypted_data)} 字节"
            f"（至少需要 {NONCE_LENGTH + TAG_LENGTH}）"
        )

    # 解析: nonce(12) + ciphertext + GCM tag(16)
    nonce = encrypted_data[:NONCE_LENGTH]
    ciphertext_with_tag = encrypted_data[NONCE_LENGTH:]

    # 派生密钥
    key = derive_key(password, salt)

    # AES-256-GCM 解密
    try:
        cipher = AES.new(key, AES.MODE_GCM, nonce=nonce)
        plaintext = cipher.decrypt_and_verify(
            ciphertext_with_tag[:-TAG_LENGTH],
            ciphertext_with_tag[-TAG_LENGTH:],
        )
        return plaintext
    except (ValueError, KeyError) as e:
        raise ValueError(
            f"解密失败: 密码不正确或备份文件已损坏。\n"
            f"原始错误: {e}"
        )


def parse_otpauth_uris(data: bytes) -> list[str]:
    """
    从 otpauth-migration protobuf 中提取 otpauth:// URI。

    解析 Google Authenticator 迁移协议（Protocol Buffers 编码）。
    消息格式: MigrationPayload { repeated OtpParameters otp_parameters }

    OtpParameters 字段:
      field 1: secret   (bytes, base32)
      field 2: name     (string)
      field 3: issuer   (string)
      field 4: algorithm (int, 0=unspecified 1=SHA1 2=SHA256 3=SHA512 4=MD5)
      field 5: digits   (int, 0=unspecified 1=6 2=8)
      field 6: type     (int, 0=unspecified 1=HOTP 2=TOTP)
      field 7: counter  (int64)
    """
    import base64

    ALGORITHMS = {0: "SHA1", 1: "SHA1", 2: "SHA256", 3: "SHA512", 4: "MD5"}
    DIGITS = {0: 6, 1: 6, 2: 8}
    TYPES = {0: "totp", 1: "hotp", 2: "totp"}

    uris = []
    pos = 0

    try:
        while pos < len(data):
            tag, pos = read_varint(data, pos)
            field_number = tag >> 3
            wire_type = tag & 0x07

            if field_number == 1 and wire_type == 2:
                # otp_parameters: 长度分隔的子消息
                length, pos = read_varint(data, pos)
                sub_data = data[pos : pos + length]
                pos += length
                uri = parse_otp_parameter(sub_data, ALGORITHMS, DIGITS, TYPES)
                if uri:
                    uris.append(uri)
            else:
                # 跳过其他字段
                pos = skip_field(data, pos, wire_type)
    except (IndexError, ValueError):
        pass

    # 如果 protobuf 解析失败，尝试直接当文本输出
    if not uris:
        try:
            text = data.decode("utf-8")
            if text.startswith("otpauth://"):
                uris = [line for line in text.splitlines() if line.strip()]
        except UnicodeDecodeError:
            pass

    return uris


def parse_otp_parameter(data: bytes, algorithms: dict, digits_map: dict,
                        types: dict) -> str | None:
    """解析单个 OtpParameters protobuf 消息，生成 otpauth:// URI"""
    import base64
    import urllib.parse

    secret = b""
    name = ""
    issuer = ""
    algorithm = 0
    digits = 0
    otp_type = 0
    counter = 0

    pos = 0
    while pos < len(data):
        tag, pos = read_varint(data, pos)
        field_number = tag >> 3
        wire_type = tag & 0x07

        if field_number == 1 and wire_type == 2:  # secret (bytes)
            length, pos = read_varint(data, pos)
            secret = data[pos : pos + length]
            pos += length
        elif field_number == 2 and wire_type == 2:  # name (string)
            length, pos = read_varint(data, pos)
            name = data[pos : pos + length].decode("utf-8", errors="replace")
            pos += length
        elif field_number == 3 and wire_type == 2:  # issuer (string)
            length, pos = read_varint(data, pos)
            issuer = data[pos : pos + length].decode("utf-8", errors="replace")
            pos += length
        elif field_number == 4 and wire_type == 0:  # algorithm (varint)
            algorithm, pos = read_varint(data, pos)
        elif field_number == 5 and wire_type == 0:  # digits (varint)
            digits, pos = read_varint(data, pos)
        elif field_number == 6 and wire_type == 0:  # type (varint)
            otp_type, pos = read_varint(data, pos)
        elif field_number == 7 and wire_type == 0:  # counter (varint)
            counter, pos = read_varint(data, pos)
        else:
            pos = skip_field(data, pos, wire_type)

    if not secret:
        return None

    # Base32 编码 secret
    secret_b32 = base64.b32encode(secret).decode("ascii").rstrip("=")

    # 确定算法
    algo = algorithms.get(algorithm, "SHA1")
    dig = digits_map.get(digits, 6)
    typ = types.get(otp_type, "totp")

    # 构建 otpauth URI
    label = urllib.parse.quote(name, safe="")
    params = [f"secret={secret_b32}"]
    if issuer:
        params.append(f"issuer={urllib.parse.quote(issuer, safe='')}")
    params.append(f"algorithm={algo}")
    params.append(f"digits={dig}")
    params.append(f"period=30")

    uri = f"otpauth://{typ}/{label}?{'&'.join(params)}"
    return uri


def read_varint(data: bytes, pos: int) -> tuple[int, int]:
    """读取 protobuf varint，返回 (值, 新位置)"""
    result = 0
    shift = 0
    while pos < len(data):
        byte = data[pos]
        pos += 1
        result |= (byte & 0x7F) << shift
        if not (byte & 0x80):
            return result, pos
        shift += 7
    raise IndexError("varint 超出数据范围")


def skip_field(data: bytes, pos: int, wire_type: int) -> int:
    """跳过 protobuf 字段"""
    if wire_type == 0:  # varint
        while pos < len(data) and (data[pos] & 0x80):
            pos += 1
        return pos + 1 if pos < len(data) else pos
    elif wire_type == 2:  # length-delimited
        if pos >= len(data):
            return pos
        length, pos = read_varint(data, pos)
        return pos + length
    elif wire_type == 5:  # 32-bit
        return pos + 4
    elif wire_type == 1:  # 64-bit
        return pos + 8
    return pos


def main():
    parser = argparse.ArgumentParser(
        description="EasyAuth 备份文件解密工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python decryption-zip.py backup_20260731_120000.zip
  python decryption-zip.py backup.zip -p MySecret123
  python decryption-zip.py backup.zip -o decrypted_uris.txt
        """,
    )
    parser.add_argument(
        "zipfile",
        help="EasyAuth 备份 zip 文件路径",
    )
    parser.add_argument(
        "-p", "--password",
        help="备份密码（不提供则交互式输入）",
    )
    parser.add_argument(
        "-o", "--output",
        help="输出文件路径（默认输出到 stdout）",
    )
    parser.add_argument(
        "--raw",
        action="store_true",
        help="输出原始解密数据（不解码 protobuf）",
    )
    args = parser.parse_args()

    zip_path = Path(args.zipfile)
    if not zip_path.exists():
        print(f"错误: 文件不存在: {zip_path}")
        sys.exit(1)

    # 获取密码
    password = args.password
    if not password:
        import getpass
        password = getpass.getpass("备份密码: ")
        if not password:
            print("错误: 密码不能为空")
            sys.exit(1)

    # 解密
    print(f"正在解密: {zip_path.name} ...")
    try:
        plaintext = decrypt_backup(str(zip_path), password)
    except ValueError as e:
        print(f"\n解密失败: {e}")
        sys.exit(1)
    except FileNotFoundError as e:
        print(f"\n文件错误: {e}")
        sys.exit(1)
    except zipfile.BadZipFile:
        print(f"\n错误: '{zip_path}' 不是有效的 ZIP 文件")
        sys.exit(1)
    except KeyError as e:
        print(f"\n错误: {e}")
        sys.exit(1)

    print(f"解密成功! 解密数据大小: {len(plaintext)} 字节\n")

    # 输出
    if args.raw:
        output = plaintext.decode("utf-8", errors="replace")
    else:
        uris = parse_otpauth_uris(plaintext)
        if uris:
            output = "\n".join(uris)
            print(f"找到 {len(uris)} 个动态口令:\n")
        else:
            output = plaintext.decode("utf-8", errors="replace")
            print("未能解析 protobuf，输出原始数据:\n")

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"已保存到: {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
