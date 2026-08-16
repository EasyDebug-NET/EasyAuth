<div align="center">

<img src="docs/icon.webp" alt="EasyAuth" width="96" />

# EasyAuth

**오픈소스 2FA 인증기 — 오프라인 사용 가능, 데이터 자주권, 안전하고 신뢰할 수 있습니다**

[웹사이트](https://easyauth.easydebug.net/) · [GitHub](https://github.com/EasyDebug-NET/EasyAuth) · [Gitee](https://gitee.com/EasyDebug-NET/EasyAuth)

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md)

![License](https://img.shields.io/badge/license-Apache%202.0-blue)

[![GitHub 다운로드](https://img.shields.io/badge/GitHub-%EB%8B%A4%EC%9A%B4%EB%A1%9C%EB%93%9C-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/EasyDebug-NET/EasyAuth/releases/latest)
[![Gitee 다운로드](https://img.shields.io/badge/Gitee-%EB%8B%A4%EC%9A%B4%EB%A1%9C%EB%93%9C-C71D23?style=for-the-badge&logo=gitee&logoColor=white)](https://gitee.com/EasyDebug-NET/EasyAuth/releases/latest)

</div>

## 소개

EasyAuth는 오픈소스 로컬 2단계 인증(2FA) 앱으로, WebDAV 및 S3 클라우드 백업(坚果云, Qiniu Cloud, AWS S3 등)을 지원하여 데이터 자주권과 다기기 동기화를 모두 만족시킵니다.

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

## 기술 스택

- **프레임워크**: Flutter / Dart 3
- **상태 관리**: Provider
- **로컬 저장소**: flutter_secure_storage
- **암호화**: encrypt (AES-256-GCM), PBKDF2 키 파생
- **생체 인식**: local_auth
- **QR 코드**: mobile_scanner (스캔), qr (생성), otpauth-migration protobuf
- **클라우드 백업**: http, xml (WebDAV), aws_signature_v4 (S3)

> 타사 의존성 상세: https://easyauth.easydebug.net/third-party

## 빌드 및 실행

### 요구 사항

- Flutter 3.x (Dart 3.12+)

### 실행

```bash
flutter pub get
flutter run
```

### 빌드

```bash
flutter build apk      # Android
flutter build ios      # iOS
flutter build windows  # Windows
```

## 라이선스

본 프로젝트는 [Apache License 2.0](LICENSE) 라이선스를 따릅니다.

## 관련 링크

- 웹사이트: https://easyauth.easydebug.net/
- GitHub: https://github.com/EasyDebug-NET/EasyAuth
- Gitee: https://gitee.com/EasyDebug-NET/EasyAuth
