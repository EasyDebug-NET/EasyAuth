<div align="center">

<img src="docs/icon.webp" alt="EasyAuth" width="96" />

# EasyAuth

**Open-source 2FA authenticator — works offline, data under your control, safe and reliable**

[Website](https://easyauth.easydebug.net/) · [GitHub](https://github.com/EasyDebug-NET/EasyAuth) · [Gitee](https://gitee.com/EasyDebug-NET/EasyAuth) · [GitCode](https://gitcode.com/EasyDebug-NET/EasyAuth)

[简体中文](README.zh.md) · [繁體中文](README.zh-Hant.md) · [한국어](README.ko.md)

![License](https://img.shields.io/badge/license-Apache%202.0-blue)

[![GitHub Download](https://img.shields.io/badge/GitHub-Download-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/EasyDebug-NET/EasyAuth/releases/latest)
[![Gitee Download](https://img.shields.io/badge/Gitee-Download-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest)
[![GitCode Download](https://img.shields.io/badge/GitCode-Download-DA203E?style=for-the-badge&logo=gitcode&logoColor=white)](https://gitcode.com/EasyDebug-NET/EasyAuth/releases)

</div>

## Introduction

EasyAuth is an open-source, local two-factor authentication (2FA) app that supports WebDAV and S3 cloud backup (Nutstore, Qiniu Cloud, AWS S3, etc.), balancing data control with multi-device sync.

Built with Flutter. Official packages are currently Android only; the iOS and Windows / macOS / Linux project directories are kept in the repository so you can build them yourself. Biometric unlock and screenshot protection rely on system APIs and are available on Android / iOS only.

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

## Download & Install

- **Android**: download from [GitHub Releases](https://github.com/EasyDebug-NET/EasyAuth/releases/latest), [Gitee Releases](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest) or [GitCode Releases](https://gitcode.com/EasyDebug-NET/EasyAuth/releases)
  - `easyauth-<version>-release.apk`: universal package, works on any device
  - `easyauth-<version>-arm64-v8a-release.apk`, `armeabi-v7a`, `x86_64`: split by CPU architecture, smaller downloads
  - Every APK ships with a matching `.sha1` file so you can verify your download
- **Other platforms**: iOS, Windows, macOS and Linux must be compiled from source — see "Build & Run"

## Tech Stack

- **Framework**: Flutter / Dart 3
- **State management**: Provider
- **Local storage**: flutter_secure_storage
- **Encryption**: encrypt (AES-256-GCM), PBKDF2-HMAC-SHA256 key derivation
- **Biometrics**: local_auth
- **Screenshot protection**: flutter_windowmanager_plus
- **QR code**: mobile_scanner (scanning), qr (generation), otpauth-migration protobuf
- **Cloud backup**: http, xml (WebDAV), aws_signature_v4 (S3)
- **Backup packaging**: archive, path_provider
- **Localization**: flutter_localizations, intl (ARB resources, 5 languages)

> See third-party dependencies: https://easyauth.easydebug.net/third-party

## Project Structure

```
EasyAuth/
├── lib/
│   ├── main.dart                    # app entry point
│   ├── models/                      # data models: setting, two_factor_account
│   ├── providers/                   # state management: locale_provider
│   ├── screens/                     # pages: home, add/edit, import/export, settings, about
│   ├── services/                    # services: backup, otp, security, storage
│   ├── utils/                       # helpers: exceptions, qr, s3, style, webdav
│   └── l10n/                        # ARB resources and generated localization code
├── assets/icon/                     # app icon
├── docs/                            # images used by this README
├── android/ ios/ linux/ macos/ windows/   # platform projects
├── test/                            # tests
├── decryption.py                    # backup decryption script (Python)
├── pubspec.yaml                     # dependency manifest
└── l10n.yaml                        # localization config
```

## Build & Run

### Requirements

- Flutter 3.x (Dart 3.12+)
- Android: Android SDK (Android Studio)
- iOS / macOS: Xcode
- Windows / Linux: the matching desktop toolchain

### Run

```bash
flutter pub get
flutter run
```

### Build

```bash
flutter build apk        # Android
flutter build appbundle  # Android (AAB, for Google Play)
flutter build ios        # iOS
flutter build windows    # Windows
flutter build macos      # macOS
flutter build linux      # Linux
```

## Backup & Decryption

A cloud backup is named `backup_<timestamp>.zip` and contains two entries, `salt` and `data`:

1. A 256-bit key is derived from your backup password and the `salt` with PBKDF2-HMAC-SHA256 (600,000 iterations, the OWASP recommendation for SHA-256)
2. `data` is decrypted with AES-256-GCM (format: 12-byte nonce + ciphertext + 16-byte GCM tag)

You can decrypt your own backups offline, without the app — `decryption.py` in the repository root uses the same scheme and prints an `otpauth://` URI for every account:

```bash
pip install pycryptodomex
python decryption.py backup_20260731_120000.zip
python decryption.py backup_20260731_120000.zip -p your-password -o uris.txt
```

## License

This project is licensed under the [Apache License 2.0](LICENSE).

## Links

- **Website**: https://easyauth.easydebug.net/
- **GitHub**: https://github.com/EasyDebug-NET/EasyAuth
- **Gitee**: https://gitee.com/EasyDebug-NET/EasyAuth
- **GitCode**: https://gitcode.com/EasyDebug-NET/EasyAuth
