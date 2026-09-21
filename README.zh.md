<div align="center">

<img src="docs/icon.webp" alt="EasyAuth" width="96" />

# EasyAuth

**开源、离线可用、数据自主的 2FA 身份验证器**

[官网](https://easyauth.easydebug.net/) · [GitHub](https://github.com/EasyDebug-NET/EasyAuth) · [Gitee](https://gitee.com/EasyDebug-NET/EasyAuth) · [GitCode](https://gitcode.com/EasyDebug-NET/EasyAuth)

[English](README.md) · [繁體中文](README.zh-Hant.md) · [한국어](README.ko.md)

![License](https://img.shields.io/badge/license-Apache%202.0-blue)

[![GitHub 下载](https://img.shields.io/badge/GitHub-%E4%B8%8B%E8%BD%BD-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/EasyDebug-NET/EasyAuth/releases/latest)
[![Gitee 下载](https://img.shields.io/badge/Gitee-%E4%B8%8B%E8%BD%BD-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest)
[![GitCode 下载](https://img.shields.io/badge/GitCode-%E4%B8%8B%E8%BD%BD-DA203E?style=for-the-badge&logo=gitcode&logoColor=white)](https://gitcode.com/EasyDebug-NET/EasyAuth/releases)

</div>

## 简介

EasyAuth 是一款开源的本地双因素认证（2FA）应用，支持 WebDAV 与 S3 云端备份（坚果云、七牛云、AWS S3 等），兼顾数据可控与多端同步。

基于 Flutter 开发。官方安装包目前只提供 Android 版本；iOS 与 Windows / macOS / Linux 保留了完整工程目录，可自行编译。生物识别解锁、防截屏依赖系统接口，仅 Android / iOS 可用。

## 截图

<p align="center">
  <img src="docs/screenshot-light.webp" alt="EasyAuth" width="32%" /> <img src="docs/screenshot-dark.webp" alt="EasyAuth" width="32%" />
</p>

## 功能特性

- **数据本地存储**：2FA 密钥保存在设备加密区域（Android Keystore / iOS Keychain）
- **加密云备份**：支持 WebDAV 与 S3 兼容存储，AES-256-GCM 端到端加密
- **兼容 Google Authenticator**：支持 otpauth:// 协议与迁移二维码导入/导出
- **生物识别保护**：指纹 / 面容解锁，切换后台自动锁定
- **防截屏**：可开启安全窗口，阻止截图与录屏
- **多语言**：支持简体中文 / 繁體中文 / English / 한국어 / 日本語

## 下载安装

- **Android**：在 [GitHub Releases](https://github.com/EasyDebug-NET/EasyAuth/releases/latest)、[Gitee Releases](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest) 或 [GitCode Releases](https://gitcode.com/EasyDebug-NET/EasyAuth/releases) 下载
  - `easyauth-<版本>-release.apk`：通用包，兼容所有设备
  - `easyauth-<版本>-arm64-v8a-release.apk`、`armeabi-v7a`、`x86_64`：按 CPU 架构拆分，体积更小
  - 每个 APK 都附带同名 `.sha1` 文件，可用于校验下载完整性
- **其他平台**：iOS、Windows、macOS、Linux 需自行编译，方法见「构建运行」

## 技术栈

- **框架**：Flutter / Dart 3
- **状态管理**：Provider
- **本地存储**：flutter_secure_storage
- **加密**：encrypt（AES-256-GCM）、PBKDF2-HMAC-SHA256 密钥派生
- **生物识别**：local_auth
- **防截屏**：flutter_windowmanager_plus
- **二维码**：mobile_scanner（扫描）、qr（生成）、otpauth-migration protobuf
- **云备份**：http、xml（WebDAV）、aws_signature_v4（S3）
- **备份打包**：archive、path_provider
- **国际化**：flutter_localizations、intl（ARB 资源，5 种语言）

> 第三方依赖详见：https://easyauth.easydebug.net/third-party

## 项目结构

```
EasyAuth/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── models/                      # 数据模型：setting、two_factor_account
│   ├── providers/                   # 状态管理：locale_provider
│   ├── screens/                     # 页面：首页、添加/编辑、导入/导出、设置、关于
│   ├── services/                    # 服务：backup、otp、security、storage
│   ├── utils/                       # 工具：exceptions、qr、s3、style、webdav
│   └── l10n/                         # ARB 语言资源与生成的本地化代码
├── assets/icon/                     # 应用图标
├── docs/                            # README 配图
├── android/ ios/ linux/ macos/ windows/   # 各平台工程目录
├── test/                            # 测试
├── decryption.py                    # 备份解密脚本（Python）
├── pubspec.yaml                     # 依赖配置
└── l10n.yaml                        # 国际化配置
```

## 构建运行

### 环境要求

- Flutter 3.x（Dart 3.12+）
- Android：Android SDK（Android Studio）
- iOS / macOS：Xcode
- Windows / Linux：对应平台的桌面工具链

### 运行

```bash
flutter pub get
flutter run
```

### 打包

```bash
flutter build apk        # Android
flutter build appbundle  # Android（AAB，上架 Google Play 用）
flutter build ios        # iOS
flutter build windows    # Windows
flutter build macos      # macOS
flutter build linux      # Linux
```

## 备份与解密

云备份文件命名为 `backup_<时间戳>.zip`，包内含 `salt` 与 `data` 两个条目：

1. 用 PBKDF2-HMAC-SHA256（600,000 次迭代，OWASP 对 SHA-256 的建议值）从备份密码与 `salt` 派生出 256 位密钥
2. 用 AES-256-GCM 解密 `data`（格式：12 字节 nonce + 密文 + 16 字节 GCM 认证标签）

即使不用 App，也可以离线解开自己的备份——仓库根目录的 `decryption.py` 使用同样的算法，并输出每个账户的 `otpauth://` 链接：

```bash
pip install pycryptodomex
python decryption.py backup_20260731_120000.zip
python decryption.py backup_20260731_120000.zip -p 你的备份密码 -o uris.txt
```

## 许可证

本项目采用 [Apache License 2.0](LICENSE) 开源协议。

## 相关链接

- **官网**：https://easyauth.easydebug.net/
- **GitHub**：https://github.com/EasyDebug-NET/EasyAuth
- **Gitee**：https://gitee.com/EasyDebug-NET/EasyAuth
- **GitCode**：https://gitcode.com/EasyDebug-NET/EasyAuth
## 微信公众号

<p align="center">
  <img src="https://www.easydebug.net/qrcode.webp" alt="EasyAuth 微信公众号" width="140" />
</p>

扫码关注 EasyAuth 微信公众号。
