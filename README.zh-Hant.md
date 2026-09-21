<div align="center">

<img src="docs/icon.webp" alt="EasyAuth" width="96" />

# EasyAuth

**開源、離線可用、資料自主的 2FA 身份驗證器**

[官網](https://easyauth.easydebug.net/) · [GitHub](https://github.com/EasyDebug-NET/EasyAuth) · [Gitee](https://gitee.com/EasyDebug-NET/EasyAuth) · [GitCode](https://gitcode.com/EasyDebug-NET/EasyAuth)

[简体中文](README.zh.md) · [English](README.md) · [한국어](README.ko.md)

![License](https://img.shields.io/badge/license-Apache%202.0-blue)

[![GitHub 下載](https://img.shields.io/badge/GitHub-%E4%B8%8B%E8%BC%89-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/EasyDebug-NET/EasyAuth/releases/latest)
[![Gitee 下載](https://img.shields.io/badge/Gitee-%E4%B8%8B%E8%BC%89-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest)
[![GitCode 下載](https://img.shields.io/badge/GitCode-%E4%B8%8B%E8%BC%89-DA203E?style=for-the-badge&logo=gitcode&logoColor=white)](https://gitcode.com/EasyDebug-NET/EasyAuth/releases)

</div>

## 簡介

EasyAuth 是一款開源的本機雙因素認證（2FA）應用，支援 WebDAV 與 S3 雲端備份（堅果雲、七牛雲、AWS S3 等），兼顧資料可控與多端同步。

以 Flutter 開發。官方安裝包目前僅提供 Android 版本；iOS 與 Windows / macOS / Linux 保留了完整的專案目錄，可自行編譯。生物識別解鎖、防截圖依賴系統介面，僅 Android / iOS 可用。

## 截圖

<p align="center">
  <img src="docs/screenshot-light.webp" alt="EasyAuth" width="32%" /> <img src="docs/screenshot-dark.webp" alt="EasyAuth" width="32%" />
</p>

## 功能特性

- **資料本機儲存**：2FA 金鑰保存在裝置加密區域（Android Keystore / iOS Keychain）
- **加密雲端備份**：支援 WebDAV 與 S3 相容儲存，AES-256-GCM 端到端加密
- **相容 Google Authenticator**：支援 otpauth:// 協定與遷移二維碼匯入/匯出
- **生物識別保護**：指紋 / 面容解鎖，切換背景自動鎖定
- **防截圖**：可開啟安全視窗，阻止截圖與錄影
- **多語言**：支援简体中文 / 繁體中文 / English / 한국어 / 日本語

## 下載安裝

- **Android**：於 [GitHub Releases](https://github.com/EasyDebug-NET/EasyAuth/releases/latest)、[Gitee Releases](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest) 或 [GitCode Releases](https://gitcode.com/EasyDebug-NET/EasyAuth/releases) 下載
  - `easyauth-<版本>-release.apk`：通用包，相容所有裝置
  - `easyauth-<版本>-arm64-v8a-release.apk`、`armeabi-v7a`、`x86_64`：依 CPU 架構拆分，體積更小
  - 每個 APK 都附帶同名 `.sha1` 檔案，可用於校驗下載完整性
- **其他平台**：iOS、Windows、macOS、Linux 需自行編譯，方法見「構建運行」

## 技術棧

- **框架**：Flutter / Dart 3
- **狀態管理**：Provider
- **本機儲存**：flutter_secure_storage
- **加密**：encrypt（AES-256-GCM）、PBKDF2-HMAC-SHA256 金鑰派生
- **生物識別**：local_auth
- **防截圖**：flutter_windowmanager_plus
- **二維碼**：mobile_scanner（掃描）、qr（生成）、otpauth-migration protobuf
- **雲端備份**：http、xml（WebDAV）、aws_signature_v4（S3）
- **備份打包**：archive、path_provider
- **多語言**：flutter_localizations、intl（ARB 資源，5 種語言）

> 第三方依賴詳見：https://easyauth.easydebug.net/third-party

## 專案結構

```
EasyAuth/
├── lib/
│   ├── main.dart                    # 應用入口
│   ├── models/                      # 資料模型：setting、two_factor_account
│   ├── providers/                   # 狀態管理：locale_provider
│   ├── screens/                     # 頁面：首頁、新增/編輯、匯入/匯出、設定、關於
│   ├── services/                    # 服務：backup、otp、security、storage
│   ├── utils/                       # 工具：exceptions、qr、s3、style、webdav
│   └── l10n/                         # ARB 語言資源與生成的本地化程式碼
├── assets/icon/                     # 應用圖示
├── docs/                            # README 配圖
├── android/ ios/ linux/ macos/ windows/   # 各平台專案目錄
├── test/                            # 測試
├── decryption.py                    # 備份解密腳本（Python）
├── pubspec.yaml                     # 依賴設定
└── l10n.yaml                        # 多語言設定
```

## 構建運行

### 環境要求

- Flutter 3.x（Dart 3.12+）
- Android：Android SDK（Android Studio）
- iOS / macOS：Xcode
- Windows / Linux：對應平台的桌面工具鏈

### 運行

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

## 備份與解密

雲端備份檔案命名為 `backup_<時間戳>.zip`，包內含 `salt` 與 `data` 兩個條目：

1. 以 PBKDF2-HMAC-SHA256（600,000 次迭代，OWASP 對 SHA-256 的建議值）從備份密碼與 `salt` 派生出 256 位元金鑰
2. 以 AES-256-GCM 解密 `data`（格式：12 位元組 nonce + 密文 + 16 位元組 GCM 認證標籤）

即使不用 App，也可以離線解開自己的備份——專案根目錄的 `decryption.py` 使用同樣的演算法，並輸出每個帳戶的 `otpauth://` 連結：

```bash
pip install pycryptodomex
python decryption.py backup_20260731_120000.zip
python decryption.py backup_20260731_120000.zip -p 你的備份密碼 -o uris.txt
```

## 許可證

本專案採用 [Apache License 2.0](LICENSE) 開源協議。

## 相關連結

- **官網**：https://easyauth.easydebug.net/
- **GitHub**：https://github.com/EasyDebug-NET/EasyAuth
- **Gitee**：https://gitee.com/EasyDebug-NET/EasyAuth
- **GitCode**：https://gitcode.com/EasyDebug-NET/EasyAuth
## 微信公眾號

<p align="center">
  <img src="https://www.easydebug.net/qrcode.webp" alt="EasyAuth 微信公眾號" width="140" />
</p>

掃碼關注 EasyAuth 微信公眾號。
