<div align="center">

<img src="docs/icon.webp" alt="EasyAuth" width="96" />

# EasyAuth

**오픈소스 2FA 인증기 — 오프라인 사용 가능, 데이터 자주권, 안전하고 신뢰할 수 있습니다**

[웹사이트](https://easyauth.easydebug.net/) · [GitHub](https://github.com/EasyDebug-NET/EasyAuth) · [Gitee](https://gitee.com/EasyDebug-NET/EasyAuth) · [GitCode](https://gitcode.com/EasyDebug-NET/EasyAuth)

[简体中文](README.zh.md) · [繁體中文](README.zh-Hant.md) · [English](README.md)

![License](https://img.shields.io/badge/license-Apache%202.0-blue)

[![GitHub 다운로드](https://img.shields.io/badge/GitHub-%EB%8B%A4%EC%9A%B4%EB%A1%9C%EB%93%9C-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/EasyDebug-NET/EasyAuth/releases/latest)
[![Gitee 다운로드](https://img.shields.io/badge/Gitee-%EB%8B%A4%EC%9A%B4%EB%A1%9C%EB%93%9C-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest)
[![GitCode 다운로드](https://img.shields.io/badge/GitCode-%EB%8B%A4%EC%9A%B4%EB%A1%9C%EB%93%9C-DA203E?style=for-the-badge&logo=gitcode&logoColor=white)](https://gitcode.com/EasyDebug-NET/EasyAuth/releases)

</div>

## 소개

EasyAuth는 오픈소스 로컬 2단계 인증(2FA) 앱으로, WebDAV 및 S3 클라우드 백업(坚果云, Qiniu Cloud, AWS S3 등)을 지원하여 데이터 자주권과 다기기 동기화를 모두 만족시킵니다.

Flutter로 개발되었습니다. 공식 설치 패키지는 현재 Android 버전만 제공되며, iOS와 Windows / macOS / Linux는 프로젝트 디렉터리가 그대로 유지되어 있어 직접 빌드할 수 있습니다. 생체 인식 잠금 해제와 스크린샷 방지는 시스템 API에 의존하므로 Android / iOS에서만 사용할 수 있습니다.

## 스크린샷

<p align="center">
  <img src="docs/screenshot-light.webp" alt="EasyAuth" width="32%" /> <img src="docs/screenshot-dark.webp" alt="EasyAuth" width="32%" />
</p>

## 주요 기능

- **로컬 데이터 저장**: 2FA 비밀 키를 기기의 암호화 영역(Android Keystore / iOS Keychain)에 저장
- **암호화 클라우드 백업**: WebDAV 및 S3 호환 스토리지를 지원하며 AES-256-GCM 종단간 암호화
- **Google Authenticator 호환**: otpauth:// 프로토콜 및 마이그레이션 QR 코드 가져오기/내보내기 지원
- **생체 인식 보호**: 지문 / 얼굴 잠금 해제, 백그라운드 전환 시 자동 잠금
- **스크린샷 방지**: 보안 창을 활성화하여 스크린샷과 화면 녹화를 차단
- **다국어 지원**: 简体中文 / 繁體中文 / English / 한국어 / 日本語

## 다운로드 및 설치

- **Android**: [GitHub Releases](https://github.com/EasyDebug-NET/EasyAuth/releases/latest), [Gitee Releases](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest) 또는 [GitCode Releases](https://gitcode.com/EasyDebug-NET/EasyAuth/releases)에서 다운로드
  - `easyauth-<버전>-release.apk`: 모든 기기와 호환되는 통합 패키지
  - `easyauth-<버전>-arm64-v8a-release.apk`, `armeabi-v7a`, `x86_64`: CPU 아키텍처별 분할 패키지로 용량이 더 작음
  - 모든 APK에는 동일한 이름의 `.sha1` 파일이 함께 제공되어 다운로드 무결성을 검증할 수 있습니다
- **기타 플랫폼**: iOS, Windows, macOS, Linux는 직접 빌드해야 합니다. 「빌드 및 실행」을 참고하세요

## 기술 스택

- **프레임워크**: Flutter / Dart 3
- **상태 관리**: Provider
- **로컬 저장소**: flutter_secure_storage
- **암호화**: encrypt (AES-256-GCM), PBKDF2-HMAC-SHA256 키 파생
- **생체 인식**: local_auth
- **스크린샷 방지**: flutter_windowmanager_plus
- **QR 코드**: mobile_scanner (스캔), qr (생성), otpauth-migration protobuf
- **클라우드 백업**: http, xml (WebDAV), aws_signature_v4 (S3)
- **백업 패키징**: archive, path_provider
- **다국어**: flutter_localizations, intl (ARB 리소스, 5개 언어)

> 타사 의존성 상세: https://easyauth.easydebug.net/third-party

## 프로젝트 구조

```
EasyAuth/
├── lib/
│   ├── main.dart                    # 앱 진입점
│   ├── models/                      # 데이터 모델: setting, two_factor_account
│   ├── providers/                   # 상태 관리: locale_provider
│   ├── screens/                     # 화면: 홈, 추가/편집, 가져오기/내보내기, 설정, 정보
│   ├── services/                    # 서비스: backup, otp, security, storage
│   ├── utils/                       # 유틸: exceptions, qr, s3, style, webdav
│   └── l10n/                         # ARB 언어 리소스와 생성된 지역화 코드
├── assets/icon/                     # 앱 아이콘
├── docs/                            # README용 이미지
├── android/ ios/ linux/ macos/ windows/   # 플랫폼별 프로젝트
├── test/                            # 테스트
├── decryption.py                    # 백업 복호화 스크립트 (Python)
├── pubspec.yaml                     # 의존성 설정
└── l10n.yaml                        # 지역화 설정
```

## 빌드 및 실행

### 요구 사항

- Flutter 3.x (Dart 3.12+)
- Android: Android SDK (Android Studio)
- iOS / macOS: Xcode
- Windows / Linux: 해당 플랫폼의 데스크톱 툴체인

### 실행

```bash
flutter pub get
flutter run
```

### 빌드

```bash
flutter build apk        # Android
flutter build appbundle  # Android (AAB, Google Play 배포용)
flutter build ios        # iOS
flutter build windows    # Windows
flutter build macos      # macOS
flutter build linux      # Linux
```

## 백업과 복호화

클라우드 백업 파일 이름은 `backup_<타임스탬프>.zip`이며, 압축 파일 안에 `salt`와 `data` 두 항목이 들어 있습니다:

1. 백업 비밀번호와 `salt`로 PBKDF2-HMAC-SHA256(600,000회 반복, SHA-256에 대한 OWASP 권장값)을 사용해 256비트 키를 파생합니다
2. AES-256-GCM으로 `data`를 복호화합니다 (형식: 12바이트 nonce + 암호문 + 16바이트 GCM 인증 태그)

앱 없이도 자신의 백업을 오프라인에서 열 수 있습니다. 저장소 루트의 `decryption.py`가 동일한 알고리즘을 사용해 각 계정의 `otpauth://` 링크를 출력합니다:

```bash
pip install pycryptodomex
python decryption.py backup_20260731_120000.zip
python decryption.py backup_20260731_120000.zip -p 백업_비밀번호 -o uris.txt
```

## 라이선스

본 프로젝트는 [Apache License 2.0](LICENSE) 라이선스를 따릅니다.

## 관련 링크

- **웹사이트**: https://easyauth.easydebug.net/
- **GitHub**: https://github.com/EasyDebug-NET/EasyAuth
- **Gitee**: https://gitee.com/EasyDebug-NET/EasyAuth
- **GitCode**: https://gitcode.com/EasyDebug-NET/EasyAuth
