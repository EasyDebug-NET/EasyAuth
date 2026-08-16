<div align="center">

<img src="docs/icon.webp" alt="EasyAuth" width="96" />

# EasyAuth

**Open-source 2FA authenticator — works offline, data under your control, safe and reliable**

[Website](https://easyauth.easydebug.net/) · [GitHub](https://github.com/EasyDebug-NET/EasyAuth) · [Gitee](https://gitee.com/EasyDebug-NET/EasyAuth)

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [한국어](README.ko.md)

![License](https://img.shields.io/badge/license-Apache%202.0-blue)

[![GitHub Download](https://img.shields.io/badge/GitHub-Download-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/EasyDebug-NET/EasyAuth/releases/latest)
[![Gitee Download](https://img.shields.io/badge/Gitee-Download-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest)

</div>

## Introduction

EasyAuth is an open-source, local two-factor authentication (2FA) app that supports WebDAV and S3 cloud backup (Nutstore, Qiniu Cloud, AWS S3, etc.), balancing data control with multi-device sync.

## Screenshots

<p align="center">
  <img src="docs/screenshot-light.webp" alt="EasyAuth" width="32%" /> <img src="docs/screenshot-dark.webp" alt="EasyAuth" width="32%" />
</p>

## Features

- **Data stored locally**: 2FA secrets are kept in the device's encrypted storage (Android Keystore / iOS Keychain)
- **Encrypted cloud backup**: WebDAV and S3-compatible storage with AES-256-GCM end-to-end encryption
- **Google Authenticator compatible**: supports the otpauth:// protocol and migration QR import/export
- **Biometric protection**: fingerprint / face unlock with automatic lock when backgrounded
- **Screenshot protection**: optionally enable a secure window to block screenshots and screen recording
- **Multi-language**: supports 简体中文 / 繁體中文 / English / 한국어 / 日本語

## Tech Stack

- **Framework**: Flutter / Dart 3
- **State management**: Provider
- **Local storage**: flutter_secure_storage
- **Encryption**: encrypt (AES-256-GCM), PBKDF2 key derivation
- **Biometrics**: local_auth
- **QR code**: mobile_scanner (scanning), qr (generation), otpauth-migration protobuf
- **Cloud backup**: http, xml (WebDAV), aws_signature_v4 (S3)

> See third-party dependencies: https://easyauth.easydebug.net/third-party

## Build & Run

### Requirements

- Flutter 3.x (Dart 3.12+)

### Run

```bash
flutter pub get
flutter run
```

### Build

```bash
flutter build apk      # Android
flutter build ios      # iOS
flutter build windows  # Windows
```

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Links

- Website: https://easyauth.easydebug.net/
- GitHub: https://github.com/EasyDebug-NET/EasyAuth
- Gitee: https://gitee.com/EasyDebug-NET/EasyAuth
