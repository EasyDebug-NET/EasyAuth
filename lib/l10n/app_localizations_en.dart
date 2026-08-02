// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EasyAuth';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get aboutTitle => 'About';

  @override
  String get importExportTitle => 'Import/Export';

  @override
  String get addManualTitle => 'Enter 2FA Details';

  @override
  String get addScanTitle => 'Scan QR Code';

  @override
  String get editTitle => 'Edit 2FA Info';

  @override
  String get exportTitle => 'Export 2FA';

  @override
  String get importTitle => 'Import 2FA';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonConfirm => 'Confirm';

  @override
  String get buttonDelete => 'Delete';

  @override
  String get buttonImport => 'Import';

  @override
  String get buttonExport => 'Export';

  @override
  String get buttonRetry => 'Retry';

  @override
  String get buttonOK => 'OK';

  @override
  String get buttonModify => 'Modify';

  @override
  String get buttonSelectAll => 'Select All';

  @override
  String get buttonRestore => 'Restore';

  @override
  String get sectionBackupSettings => 'Backup Settings';

  @override
  String get sectionSecuritySettings => 'Security Settings';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get labelIssuer => 'Issuer Name';

  @override
  String get hintIssuer => 'e.g. Google';

  @override
  String get labelAccountName => 'Account Name';

  @override
  String get hintAccountName => 'e.g. user@example.com';

  @override
  String get labelSecretKey => '2FA Key';

  @override
  String get hintSecretKey => 'Base32';

  @override
  String get labelSecretType => 'Key Type';

  @override
  String get secretTypeTime => 'Time-based (TOTP)';

  @override
  String get secretTypeCounter => 'Counter-based (HOTP)';

  @override
  String get labelCounterInitial => 'Initial Counter Value';

  @override
  String get hintCounterInitial => 'Default 0';

  @override
  String get labelBackupType => 'Backup Type';

  @override
  String get backupTypeOff => 'Off';

  @override
  String get backupTypeWebDAV => 'WebDAV';

  @override
  String get backupTypeS3 => 'Object Storage';

  @override
  String get labelBackupPassword => 'Backup Password';

  @override
  String get hintBackupPassword => 'Set backup encryption password';

  @override
  String get labelConfirmBackupPassword => 'Confirm Backup Password';

  @override
  String get hintConfirmBackupPassword => 'Re-enter backup password';

  @override
  String get labelHistoryCount => 'Keep History Versions';

  @override
  String get hintHistoryCount => 'Default 10, set 0 for unlimited';

  @override
  String get labelWebDavUrl => 'WebDAV URL';

  @override
  String get labelWebDavUsername => 'Username';

  @override
  String get labelWebDavPassword => 'Password';

  @override
  String get labelStoragePath => 'Storage Path';

  @override
  String get labelEndpointUrl => 'Endpoint URL';

  @override
  String get labelAccessKeyId => 'Access Key ID';

  @override
  String get labelSecretAccessKey => 'Secret Access Key';

  @override
  String get labelBucketName => 'Bucket Name';

  @override
  String get labelPath => 'Path';

  @override
  String get labelRegion => 'Region (optional, default cn-east-1)';

  @override
  String get labelAppLock => 'App Lock';

  @override
  String get labelScreenshotLock => 'Screenshot Lock';

  @override
  String get statusNotConfigured => 'Not Configured';

  @override
  String get statusConfigured => 'Configured';

  @override
  String get statusUnknownVersion => 'Unknown';

  @override
  String get statusUnknownTime => 'Unknown Time';

  @override
  String get biometricNotSupported => 'Device does not support biometrics';

  @override
  String get androidOnly => 'Android Only';

  @override
  String get passwordAlreadySet => 'Backup password is set';

  @override
  String get passwordTipMessage =>
      'The backup password is used to encrypt backup files. Multiple devices must use the same password to share backups.';

  @override
  String get httpsWarning =>
      'HTTPS connection is recommended. Credentials are sent in plaintext over HTTP.';

  @override
  String get howToGetConfig => 'How to configure';

  @override
  String get qiniuPromoTitle => 'Recommended: Qiniu Cloud Object Storage';

  @override
  String get qiniuPromoLink => 'Sign up for Qiniu Cloud now for free credits';

  @override
  String get validationRequired => 'This field cannot be empty';

  @override
  String get validationSecretRequired => 'Please enter the 2FA key';

  @override
  String get validationSecretInvalidBase32 => 'Invalid Base32 key format';

  @override
  String get validationCounterRequired => 'Please enter a counter value';

  @override
  String get validationCounterInvalidNumber => 'Please enter a valid number';

  @override
  String get validationBackupPasswordRequired =>
      'Backup password cannot be empty';

  @override
  String get validationBackupPasswordMinLength =>
      'Backup password must be at least 8 characters';

  @override
  String get validationConfirmPasswordRequired =>
      'Confirm password cannot be empty';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get validationHistoryCountInvalid =>
      'Please enter a number no less than 0';

  @override
  String get validationWebDavUrlRequired => 'WebDAV URL cannot be empty';

  @override
  String get validationWebDavUsernameRequired => 'Username cannot be empty';

  @override
  String get validationWebDavPasswordRequired => 'Password cannot be empty';

  @override
  String get validationStoragePathRequired => 'Storage path cannot be empty';

  @override
  String get validationEndpointRequired => 'Endpoint URL cannot be empty';

  @override
  String get validationAccessKeyRequired => 'Access Key ID cannot be empty';

  @override
  String get validationSecretKeyRequired => 'Secret Access Key cannot be empty';

  @override
  String get validationBucketNameRequired => 'Bucket Name cannot be empty';

  @override
  String get snackAddedSuccess => 'Added successfully';

  @override
  String get snackModifiedSuccess => 'Modified successfully';

  @override
  String get snackBackupSuccess => 'Backup successful';

  @override
  String get snackBackupFailed => 'Backup failed';

  @override
  String get snackRestoreSuccess => 'Restore successful';

  @override
  String get snackRestoreFailed => 'Restore failed';

  @override
  String get snackSortSaved => 'Sort order saved';

  @override
  String get snackSortSaveFailed => 'Failed to save sort order';

  @override
  String snackInitFailed(String error) {
    return 'Initialization failed: $error';
  }

  @override
  String snackLoadConfigFailed(String error) {
    return 'Failed to load config: $error';
  }

  @override
  String snackSaveConfigFailed(String error) {
    return 'Failed to save config: $error';
  }

  @override
  String get snackNotConfigured => 'Backup parameters not configured';

  @override
  String get snackSelectBackupTypeFirst => 'Please select a backup type first';

  @override
  String get snackConfigureBackupFirst =>
      'Please configure complete backup parameters first';

  @override
  String get snackScreenshotLockOn => 'Screenshot lock enabled';

  @override
  String get snackScreenshotLockOff => 'Screenshot lock disabled';

  @override
  String snackScreenshotLockError(String error) {
    return 'Failed to update screenshot lock: $error';
  }

  @override
  String get snackBiometricNotAvailable =>
      'Device does not support biometrics, cannot enable app lock';

  @override
  String get snackAppLockEnabled => 'App lock enabled';

  @override
  String get snackAppLockDisabled => 'App lock disabled';

  @override
  String get snackAppLockDisableFailed =>
      'Authentication failed, cannot disable app lock';

  @override
  String get snackDeleteSuccess => 'Deleted successfully';

  @override
  String get snackDeleteFailed => 'Delete failed';

  @override
  String snackLoadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String snackImportSuccess(int count) {
    return 'Successfully imported $count accounts';
  }

  @override
  String get snackImportNone => 'No accounts were successfully imported';

  @override
  String get snackImportError => 'Error importing accounts';

  @override
  String get snackSelectAccountsToImport => 'Please select accounts to import';

  @override
  String get snackSelectAtLeastOne => 'Please select at least one account';

  @override
  String get snackQrCodeGenerateError => 'Error generating QR code';

  @override
  String get dialogTitleDeleteAccount => 'Delete 2FA Account';

  @override
  String dialogConfirmDeleteAccount(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get dialogTitleConfirmRestore => 'Confirm Restore';

  @override
  String get dialogConfirmRestoreBody =>
      'Restoring will overwrite current data. Are you sure you want to continue?';

  @override
  String get dialogButtonConfirmRestore => 'Confirm Restore';

  @override
  String get dialogTitleError => 'Error';

  @override
  String get dialogTitleScanFailed => 'Scan Failed';

  @override
  String get dialogTitleQrCodeError => 'QR Code Format Error';

  @override
  String get dialogTitleConfirmDelete => 'Confirm Delete';

  @override
  String dialogConfirmDeleteBackups(int count) {
    return 'Are you sure you want to delete the selected $count backup files? This action cannot be undone.';
  }

  @override
  String dialogConfirmRestoreFile(String name) {
    return 'Are you sure you want to restore \"$name\"?\nThis will overwrite all current data.';
  }

  @override
  String get loadingConfig => 'Loading config...';

  @override
  String get loadingOperation => 'Processing...';

  @override
  String get loadingPleaseWait => 'Please wait';

  @override
  String get loadingAuthenticating => 'Authenticating...';

  @override
  String get loadingAuthPrompt => 'Please verify your biometrics';

  @override
  String get authReasonAccess =>
      'Please verify your identity to access the app';

  @override
  String get authReasonEnable =>
      'Please verify your identity to enable app lock';

  @override
  String get authReasonDisable =>
      'Please verify your identity to disable app lock';

  @override
  String get emptyNoAccounts => 'No 2FA accounts yet';

  @override
  String get emptyAddPrompt => 'Tap the + button to add an account';

  @override
  String get emptyNoBackupFiles => 'No backup files found';

  @override
  String get hintSearch => 'Search...';

  @override
  String get drawerImportExport => 'Import/Export';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerAbout => 'About';

  @override
  String get backupConfigTitle => 'Backup Parameter Configuration';

  @override
  String get backupToRemote => 'Backup to Remote';

  @override
  String get restoreFromRemote => 'Restore from Remote';

  @override
  String get manageRemoteBackups => 'Manage Remote Backups';

  @override
  String get scanHintText => 'Place the QR code in the frame to scan';

  @override
  String get exportScanPrompt => 'Please scan this QR code with another device';

  @override
  String get fabScanQr => 'Scan QR Code';

  @override
  String get fabEnterKey => 'Enter 2FA Key';

  @override
  String hotpIncrementTooltip(int counter) {
    return 'Increment counter (current: $counter)';
  }

  @override
  String get importExportDescription =>
      'You can transfer your 2FA accounts to a new device\nCompatible with Google Authenticator migration';

  @override
  String get exportAccounts => 'Export Accounts';

  @override
  String get importAccounts => 'Import Accounts';

  @override
  String get copyrightNotice => '2016-2026 EasyDebug.NET All rights reserved.';

  @override
  String get errorQrFormat => 'Invalid QR code format. Must be otpauth:// URI.';

  @override
  String get errorQrMissingSecret =>
      'QR code is missing the required secret key';

  @override
  String get errorSecretInvalidBase32 =>
      'Invalid key format. Must be Base32 encoded.';

  @override
  String get errorCannotRecognizeQr => 'Cannot recognize this QR code';

  @override
  String get errorTotpOnly =>
      'Only TOTP type is supported, HOTP is not supported in QR scan';

  @override
  String get errorQrDataFormat => 'QR code data format error';

  @override
  String get errorInvalidMigrationQr => 'Invalid migration QR code';

  @override
  String get errorInvalidQrDataFormat => 'Invalid QR code data format';

  @override
  String get errorCannotOpenUrl =>
      'Cannot open link. Please check if a browser is installed.';

  @override
  String errorOpenUrlFailed(String error) {
    return 'Failed to open link: $error';
  }

  @override
  String get exceptionConfigInvalid => 'Invalid backup configuration';

  @override
  String get exceptionConfigCheckParams =>
      'Please check that backup parameters are complete';

  @override
  String get exceptionGenerateDataFailed => 'Failed to generate backup data';

  @override
  String get exceptionCannotReadAccounts => 'Cannot read 2FA account data';

  @override
  String get exceptionSetPasswordFirst => 'Please set a backup password first';

  @override
  String get exceptionPasswordNotSet => 'Backup password not set';

  @override
  String get exceptionNetworkFailed => 'Network connection failed';

  @override
  String get exceptionCheckNetwork => 'Please check your network connection';

  @override
  String get exceptionUploadError => 'Error occurred while uploading backup';

  @override
  String get exceptionBackupError => 'An error occurred during backup';

  @override
  String get exceptionRestoreConfigInvalid => 'Invalid restore configuration';

  @override
  String get exceptionUnsupportedBackupType => 'Unsupported backup type';

  @override
  String get exceptionDownloadError =>
      'Error occurred while downloading backup';

  @override
  String get exceptionRestoreDataFailed => 'Failed to restore data';

  @override
  String get exceptionBackupCorrupted =>
      'Backup file may be corrupted or password is incorrect';

  @override
  String get exceptionRestoreError => 'An error occurred during restore';

  @override
  String get exceptionNoBackupFound => 'No backup files found';

  @override
  String get exceptionNoBackupWebDav =>
      'No backup files found in WebDAV storage. Please run a backup first.';

  @override
  String get exceptionNoBackupS3 =>
      'No backup files found in S3 storage. Please run a backup first.';

  @override
  String get exceptionFormatMissingSalt =>
      'Backup file format error: missing salt';

  @override
  String get exceptionFormatMissingData =>
      'Backup file format error: missing data';

  @override
  String get exceptionDecryptFailed =>
      'Failed to decrypt backup data. Please verify the backup password is correct.';

  @override
  String versionLabel(String version) {
    return '$version';
  }

  @override
  String get privacyDisclaimer => 'Privacy Policy & Disclaimer';

  @override
  String get thirdPartySoftwareLicenses => 'Third-Party Software & Licenses';
}
