<div align="center">

<img src="docs/icon.webp" alt="EasyAuth" width="96" />

# EasyAuth

**开源、离线可用、数据自主的 2FA 身份验证器**

[官网](https://easyauth.easydebug.net/) · [GitHub](https://github.com/EasyDebug-NET/EasyAuth) · [Gitee](https://gitee.com/EasyDebug-NET/EasyAuth)

[English](README.en.md) · [繁體中文](README.zh-Hant.md) · [한국어](README.ko.md)

![License](https://img.shields.io/badge/license-Apache%202.0-blue)

[![GitHub 下载](https://img.shields.io/badge/GitHub-%E4%B8%8B%E8%BD%BD-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/EasyDebug-NET/EasyAuth/releases/latest)
[![Gitee 下载](https://img.shields.io/badge/Gitee-%E4%B8%8B%E8%BD%BD-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest)

</div>

## 简介

EasyAuth 是一款开源的本地双因素认证（2FA）应用，支持 WebDAV 与 S3 云端备份（坚果云、七牛云、AWS S3 等），兼顾数据可控与多端同步。

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

## 技术栈

- **框架**：Flutter / Dart 3
- **状态管理**：Provider
- **本地存储**：flutter_secure_storage
- **加密**：encrypt（AES-256-GCM）、PBKDF2 密钥派生
- **生物识别**：local_auth
- **二维码**：mobile_scanner（扫描）、qr（生成）、otpauth-migration protobuf
- **云备份**：http、xml（WebDAV）、aws_signature_v4（S3）

> 第三方依赖详见：https://easyauth.easydebug.net/third-party

## 构建运行

### 环境要求

- Flutter 3.x（Dart 3.12+）

### 运行

```bash
flutter pub get
flutter run
```

### 打包

```bash
flutter build apk      # Android
flutter build ios      # iOS
flutter build windows  # Windows
```

## 许可证

本项目采用 [Apache License 2.0](LICENSE) 开源协议。

## 相关链接

- 官网：https://easyauth.easydebug.net/
- GitHub：https://github.com/EasyDebug-NET/EasyAuth
- Gitee：https://gitee.com/EasyDebug-NET/EasyAuth
