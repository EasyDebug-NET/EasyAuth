// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'EasyAuth';

  @override
  String get settingsTitle => '설정';

  @override
  String get aboutTitle => '정보';

  @override
  String get importExportTitle => '가져오기/내보내기';

  @override
  String get addManualTitle => '2FA 세부 정보 입력';

  @override
  String get addScanTitle => 'QR 코드 스캔';

  @override
  String get editTitle => '2FA 정보 편집';

  @override
  String get exportTitle => '2FA 내보내기';

  @override
  String get importTitle => '2FA 가져오기';

  @override
  String get buttonSave => '저장';

  @override
  String get buttonCancel => '취소';

  @override
  String get buttonConfirm => '확인';

  @override
  String get buttonDelete => '삭제';

  @override
  String get buttonImport => '가져오기';

  @override
  String get buttonExport => '내보내기';

  @override
  String get buttonRetry => '재시도';

  @override
  String get buttonOK => '확인';

  @override
  String get buttonModify => '수정';

  @override
  String get buttonSelectAll => '전체 선택';

  @override
  String get buttonRestore => '복원';

  @override
  String get sectionBackupSettings => '백업 설정';

  @override
  String get sectionSecuritySettings => '보안 설정';

  @override
  String get sectionLanguage => '언어';

  @override
  String get labelIssuer => '발급자 이름';

  @override
  String get hintIssuer => '예: Google';

  @override
  String get labelAccountName => '계정 이름';

  @override
  String get hintAccountName => '예: user@example.com';

  @override
  String get labelSecretKey => '2FA 키';

  @override
  String get hintSecretKey => 'Base32';

  @override
  String get labelSecretType => '키 유형';

  @override
  String get secretTypeTime => '시간 기반 (TOTP)';

  @override
  String get secretTypeCounter => '카운터 기반 (HOTP)';

  @override
  String get labelCounterInitial => '초기 카운터 값';

  @override
  String get hintCounterInitial => '기본값 0';

  @override
  String get labelBackupType => '백업 유형';

  @override
  String get backupTypeOff => '끄기';

  @override
  String get backupTypeWebDAV => 'WebDAV';

  @override
  String get backupTypeS3 => '객체 스토리지';

  @override
  String get labelBackupPassword => '백업 비밀번호';

  @override
  String get hintBackupPassword => '백업 암호화 비밀번호 설정';

  @override
  String get labelConfirmBackupPassword => '백업 비밀번호 확인';

  @override
  String get hintConfirmBackupPassword => '백업 비밀번호 다시 입력';

  @override
  String get labelHistoryCount => '보관할 기록 버전 수';

  @override
  String get hintHistoryCount => '기본값 10, 0으로 설정 시 무제한';

  @override
  String get labelWebDavUrl => 'WebDAV URL';

  @override
  String get labelWebDavUsername => '사용자 이름';

  @override
  String get labelWebDavPassword => '비밀번호';

  @override
  String get labelStoragePath => '저장 경로';

  @override
  String get labelEndpointUrl => '엔드포인트 URL';

  @override
  String get labelAccessKeyId => '액세스 키 ID';

  @override
  String get labelSecretAccessKey => '비밀 액세스 키';

  @override
  String get labelBucketName => '버킷 이름';

  @override
  String get labelPath => '경로';

  @override
  String get labelRegion => '리전 (선택 사항, 기본값 cn-east-1)';

  @override
  String get labelAppLock => '앱 잠금';

  @override
  String get labelScreenshotLock => '스크린샷 잠금';

  @override
  String get statusNotConfigured => '설정 안 됨';

  @override
  String get statusConfigured => '설정됨';

  @override
  String get statusUnknownVersion => '알 수 없음';

  @override
  String get statusUnknownTime => '알 수 없는 시간';

  @override
  String get biometricNotSupported => '기기가 생체 인식을 지원하지 않습니다';

  @override
  String get androidOnly => 'Android만 지원';

  @override
  String get passwordAlreadySet => '백업 비밀번호가 설정되었습니다';

  @override
  String get passwordTipMessage =>
      '백업 비밀번호는 백업 파일을 암호화하는 데 사용됩니다. 여러 기기에서 백업을 공유하려면 동일한 비밀번호를 설정해야 합니다.';

  @override
  String get httpsWarning => 'HTTPS 연결을 권장합니다. HTTP에서는 자격 증명이 평문으로 전송됩니다.';

  @override
  String get howToGetConfig => '설정 정보 얻는 방법';

  @override
  String get qiniuPromoTitle => '추천: Qiniu Cloud 객체 스토리지';

  @override
  String get qiniuPromoLink => '지금 Qiniu Cloud에 가입하고 무료 크레딧 받기';

  @override
  String get validationRequired => '이 필드는 비워둘 수 없습니다';

  @override
  String get validationSecretRequired => '2FA 키를 입력하세요';

  @override
  String get validationSecretInvalidBase32 => '유효하지 않은 Base32 키 형식입니다';

  @override
  String get validationCounterRequired => '카운터 값을 입력하세요';

  @override
  String get validationCounterInvalidNumber => '유효한 숫자를 입력하세요';

  @override
  String get validationBackupPasswordRequired => '백업 비밀번호는 비워둘 수 없습니다';

  @override
  String get validationBackupPasswordMinLength => '백업 비밀번호는 8자 이상이어야 합니다';

  @override
  String get validationConfirmPasswordRequired => '확인 비밀번호는 비워둘 수 없습니다';

  @override
  String get validationPasswordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get validationHistoryCountInvalid => '0 이상의 숫자를 입력하세요';

  @override
  String get validationWebDavUrlRequired => 'WebDAV URL은 비워둘 수 없습니다';

  @override
  String get validationWebDavUsernameRequired => '사용자 이름은 비워둘 수 없습니다';

  @override
  String get validationWebDavPasswordRequired => '비밀번호는 비워둘 수 없습니다';

  @override
  String get validationStoragePathRequired => '저장 경로는 비워둘 수 없습니다';

  @override
  String get validationEndpointRequired => '엔드포인트 URL은 비워둘 수 없습니다';

  @override
  String get validationAccessKeyRequired => '액세스 키 ID는 비워둘 수 없습니다';

  @override
  String get validationSecretKeyRequired => '비밀 액세스 키는 비워둘 수 없습니다';

  @override
  String get validationBucketNameRequired => '버킷 이름은 비워둘 수 없습니다';

  @override
  String get snackAddedSuccess => '추가되었습니다';

  @override
  String get snackModifiedSuccess => '수정되었습니다';

  @override
  String get snackBackupSuccess => '백업 성공';

  @override
  String get snackBackupFailed => '백업 실패';

  @override
  String get snackRestoreSuccess => '복원 성공';

  @override
  String get snackRestoreFailed => '복원 실패';

  @override
  String get snackSortSaved => '정렬 순서가 저장되었습니다';

  @override
  String get snackSortSaveFailed => '정렬 순서 저장에 실패했습니다';

  @override
  String snackInitFailed(String error) {
    return '초기화 실패: $error';
  }

  @override
  String snackLoadConfigFailed(String error) {
    return '설정 불러오기 실패: $error';
  }

  @override
  String snackSaveConfigFailed(String error) {
    return '설정 저장 실패: $error';
  }

  @override
  String get snackNotConfigured => '백업 매개변수가 설정되지 않았습니다';

  @override
  String get snackSelectBackupTypeFirst => '먼저 백업 유형을 선택하세요';

  @override
  String get snackConfigureBackupFirst => '먼저 백업 매개변수를 완전히 설정하세요';

  @override
  String get snackScreenshotLockOn => '스크린샷 잠금이 활성화되었습니다';

  @override
  String get snackScreenshotLockOff => '스크린샷 잠금이 비활성화되었습니다';

  @override
  String snackScreenshotLockError(String error) {
    return '스크린샷 잠금 업데이트 실패: $error';
  }

  @override
  String get snackBiometricNotAvailable =>
      '기기가 생체 인식을 지원하지 않아 앱 잠금을 활성화할 수 없습니다';

  @override
  String get snackAppLockEnabled => '앱 잠금이 활성화되었습니다';

  @override
  String get snackAppLockDisabled => '앱 잠금이 비활성화되었습니다';

  @override
  String get snackAppLockDisableFailed => '인증 실패, 앱 잠금을 비활성화할 수 없습니다';

  @override
  String get snackDeleteSuccess => '삭제되었습니다';

  @override
  String get snackDeleteFailed => '삭제 실패';

  @override
  String snackLoadFailed(String error) {
    return '불러오기 실패: $error';
  }

  @override
  String snackImportSuccess(int count) {
    return '$count개의 계정을 가져왔습니다';
  }

  @override
  String get snackImportNone => '성공적으로 가져온 계정이 없습니다';

  @override
  String get snackImportError => '계정을 가져오는 중 오류가 발생했습니다';

  @override
  String get snackSelectAccountsToImport => '가져올 계정을 선택하세요';

  @override
  String get snackSelectAtLeastOne => '최소 하나의 계정을 선택하세요';

  @override
  String get snackQrCodeGenerateError => 'QR 코드 생성 중 오류가 발생했습니다';

  @override
  String get dialogTitleDeleteAccount => '2FA 계정 삭제';

  @override
  String dialogConfirmDeleteAccount(String name) {
    return '\"$name\"을(를) 삭제하시겠습니까?';
  }

  @override
  String get dialogTitleConfirmRestore => '복원 확인';

  @override
  String get dialogConfirmRestoreBody => '복원하면 현재 데이터가 덮어써집니다. 계속하시겠습니까?';

  @override
  String get dialogButtonConfirmRestore => '복원 확인';

  @override
  String get dialogTitleError => '오류';

  @override
  String get dialogTitleScanFailed => '스캔 실패';

  @override
  String get dialogTitleQrCodeError => 'QR 코드 형식 오류';

  @override
  String get dialogTitleConfirmDelete => '삭제 확인';

  @override
  String dialogConfirmDeleteBackups(int count) {
    return '선택한 $count개의 백업 파일을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String dialogConfirmRestoreFile(String name) {
    return '\"$name\"(으)로 복원하시겠습니까?\n현재 모든 데이터가 덮어써집니다.';
  }

  @override
  String get loadingConfig => '설정 불러오는 중...';

  @override
  String get loadingOperation => '처리 중...';

  @override
  String get loadingPleaseWait => '잠시만 기다려 주세요';

  @override
  String get loadingAuthenticating => '인증 중...';

  @override
  String get loadingAuthPrompt => '생체 정보를 확인하세요';

  @override
  String get authReasonAccess => '앱에 접근하려면 본인 확인이 필요합니다';

  @override
  String get authReasonEnable => '앱 잠금을 활성화하려면 본인 확인이 필요합니다';

  @override
  String get authReasonDisable => '앱 잠금을 비활성화하려면 본인 확인이 필요합니다';

  @override
  String get emptyNoAccounts => '아직 2FA 계정이 없습니다';

  @override
  String get emptyAddPrompt => '+ 버튼을 눌러 계정을 추가하세요';

  @override
  String get emptyNoBackupFiles => '백업 파일을 찾을 수 없습니다';

  @override
  String get hintSearch => '검색...';

  @override
  String get drawerImportExport => '가져오기/내보내기';

  @override
  String get drawerSettings => '설정';

  @override
  String get drawerAbout => '정보';

  @override
  String get backupConfigTitle => '백업 매개변수 설정';

  @override
  String get backupToRemote => '원격으로 백업';

  @override
  String get restoreFromRemote => '원격에서 복원';

  @override
  String get manageRemoteBackups => '원격 백업 관리';

  @override
  String get scanHintText => 'QR 코드를 프레임 안에 넣으면 자동으로 스캔됩니다';

  @override
  String get exportScanPrompt => '다른 기기로 이 QR 코드를 스캔하세요';

  @override
  String get fabScanQr => 'QR 코드 스캔';

  @override
  String get fabEnterKey => '2FA 키 입력';

  @override
  String hotpIncrementTooltip(int counter) {
    return '카운터 증가 (현재: $counter)';
  }

  @override
  String get importExportDescription =>
      '2FA 계정을 새 기기로 전송할 수 있습니다\nGoogle Authenticator 마이그레이션 지원';

  @override
  String get exportAccounts => '계정 내보내기';

  @override
  String get importAccounts => '계정 가져오기';

  @override
  String get copyrightNotice => '2016-2026 EasyDebug.NET All rights reserved.';

  @override
  String get errorQrFormat => '유효하지 않은 QR 코드 형식입니다. otpauth:// URI여야 합니다.';

  @override
  String get errorQrMissingSecret => 'QR 코드에 필요한 비밀 키가 없습니다';

  @override
  String get errorSecretInvalidBase32 => '유효하지 않은 키 형식입니다. Base32 인코딩이 필요합니다.';

  @override
  String get errorCannotRecognizeQr => '이 QR 코드를 인식할 수 없습니다';

  @override
  String get errorTotpOnly => 'TOTP 유형만 지원됩니다. HOTP는 QR 스캔에서 지원되지 않습니다.';

  @override
  String get errorQrDataFormat => 'QR 코드 데이터 형식 오류';

  @override
  String get errorInvalidMigrationQr => '유효하지 않은 마이그레이션 QR 코드입니다';

  @override
  String get errorInvalidQrDataFormat => '유효하지 않은 QR 코드 데이터 형식입니다';

  @override
  String get errorCannotOpenUrl => '링크를 열 수 없습니다. 브라우저가 설치되어 있는지 확인하세요.';

  @override
  String errorOpenUrlFailed(String error) {
    return '링크 열기 실패: $error';
  }

  @override
  String get exceptionConfigInvalid => '유효하지 않은 백업 설정';

  @override
  String get exceptionConfigCheckParams => '백업 매개변수가 완전한지 확인하세요';

  @override
  String get exceptionGenerateDataFailed => '백업 데이터 생성 실패';

  @override
  String get exceptionCannotReadAccounts => '2FA 계정 데이터를 읽을 수 없습니다';

  @override
  String get exceptionSetPasswordFirst => '먼저 백업 비밀번호를 설정하세요';

  @override
  String get exceptionPasswordNotSet => '백업 비밀번호가 설정되지 않았습니다';

  @override
  String get exceptionNetworkFailed => '네트워크 연결 실패';

  @override
  String get exceptionCheckNetwork => '네트워크 연결을 확인하세요';

  @override
  String get exceptionUploadError => '백업 업로드 중 오류가 발생했습니다';

  @override
  String get exceptionBackupError => '백업 중 오류가 발생했습니다';

  @override
  String get exceptionRestoreConfigInvalid => '유효하지 않은 복원 설정';

  @override
  String get exceptionUnsupportedBackupType => '지원되지 않는 백업 유형입니다';

  @override
  String get exceptionDownloadError => '백업 다운로드 중 오류가 발생했습니다';

  @override
  String get exceptionRestoreDataFailed => '데이터 복원 실패';

  @override
  String get exceptionBackupCorrupted => '백업 파일이 손상되었거나 비밀번호가 잘못되었습니다';

  @override
  String get exceptionRestoreError => '복원 중 오류가 발생했습니다';

  @override
  String get exceptionNoBackupFound => '백업 파일을 찾을 수 없습니다';

  @override
  String get exceptionNoBackupWebDav =>
      'WebDAV 스토리지에 백업 파일이 없습니다. 먼저 백업을 실행하세요.';

  @override
  String get exceptionNoBackupS3 => 'S3 스토리지에 백업 파일이 없습니다. 먼저 백업을 실행하세요.';

  @override
  String get exceptionFormatMissingSalt => '백업 파일 형식 오류: 솔트 없음';

  @override
  String get exceptionFormatMissingData => '백업 파일 형식 오류: 데이터 없음';

  @override
  String get exceptionDecryptFailed =>
      '백업 데이터 복호화에 실패했습니다. 백업 비밀번호가 올바른지 확인하세요.';

  @override
  String versionLabel(String version) {
    return '$version';
  }

  @override
  String get privacyDisclaimer => '개인정보처리방침 및 면책 조항';

  @override
  String get thirdPartySoftwareLicenses => '타사 소프트웨어 및 라이선스';
}
