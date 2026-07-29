import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'EasyAuth'**
  String get appTitle;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// About screen title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// Import/Export screen title
  ///
  /// In en, this message translates to:
  /// **'Import/Export'**
  String get importExportTitle;

  /// Add manual 2FA screen title
  ///
  /// In en, this message translates to:
  /// **'Enter 2FA Details'**
  String get addManualTitle;

  /// Add scan 2FA screen title
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get addScanTitle;

  /// Edit 2FA screen title
  ///
  /// In en, this message translates to:
  /// **'Edit 2FA Info'**
  String get editTitle;

  /// Export 2FA screen title
  ///
  /// In en, this message translates to:
  /// **'Export 2FA'**
  String get exportTitle;

  /// Import 2FA screen title
  ///
  /// In en, this message translates to:
  /// **'Import 2FA'**
  String get importTitle;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// Confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get buttonConfirm;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buttonDelete;

  /// Import button label
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get buttonImport;

  /// Export button label
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get buttonExport;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetry;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get buttonOK;

  /// Modify button label
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get buttonModify;

  /// Select all checkbox label
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get buttonSelectAll;

  /// Restore button/tooltip label
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get buttonRestore;

  /// Backup settings section header
  ///
  /// In en, this message translates to:
  /// **'Backup Settings'**
  String get sectionBackupSettings;

  /// Security settings section header
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get sectionSecuritySettings;

  /// Language section header
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// Issuer name field label
  ///
  /// In en, this message translates to:
  /// **'Issuer Name'**
  String get labelIssuer;

  /// Issuer name field placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. Google'**
  String get hintIssuer;

  /// 2FA account name field label
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get labelAccountName;

  /// 2FA account name field placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g. user@example.com'**
  String get hintAccountName;

  /// 2FA secret key field label
  ///
  /// In en, this message translates to:
  /// **'2FA Key'**
  String get labelSecretKey;

  /// 2FA secret key field placeholder
  ///
  /// In en, this message translates to:
  /// **'Base32'**
  String get hintSecretKey;

  /// Secret type dropdown label
  ///
  /// In en, this message translates to:
  /// **'Key Type'**
  String get labelSecretType;

  /// TOTP dropdown option
  ///
  /// In en, this message translates to:
  /// **'Time-based (TOTP)'**
  String get secretTypeTime;

  /// HOTP dropdown option
  ///
  /// In en, this message translates to:
  /// **'Counter-based (HOTP)'**
  String get secretTypeCounter;

  /// HOTP counter initial value field label
  ///
  /// In en, this message translates to:
  /// **'Initial Counter Value'**
  String get labelCounterInitial;

  /// HOTP counter placeholder
  ///
  /// In en, this message translates to:
  /// **'Default 0'**
  String get hintCounterInitial;

  /// Backup type dropdown label
  ///
  /// In en, this message translates to:
  /// **'Backup Type'**
  String get labelBackupType;

  /// Backup type: off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get backupTypeOff;

  /// Backup type: WebDAV
  ///
  /// In en, this message translates to:
  /// **'WebDAV'**
  String get backupTypeWebDAV;

  /// Backup type: S3/object storage
  ///
  /// In en, this message translates to:
  /// **'Object Storage'**
  String get backupTypeS3;

  /// Backup password field label
  ///
  /// In en, this message translates to:
  /// **'Backup Password'**
  String get labelBackupPassword;

  /// Backup password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Set backup encryption password'**
  String get hintBackupPassword;

  /// Confirm backup password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Backup Password'**
  String get labelConfirmBackupPassword;

  /// Confirm backup password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Re-enter backup password'**
  String get hintConfirmBackupPassword;

  /// History count field label
  ///
  /// In en, this message translates to:
  /// **'Keep History Versions'**
  String get labelHistoryCount;

  /// History count field placeholder
  ///
  /// In en, this message translates to:
  /// **'Default 10, set 0 for unlimited'**
  String get hintHistoryCount;

  /// WebDAV URL field label
  ///
  /// In en, this message translates to:
  /// **'WebDAV URL'**
  String get labelWebDavUrl;

  /// WebDAV username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get labelWebDavUsername;

  /// WebDAV password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelWebDavPassword;

  /// Storage path field label
  ///
  /// In en, this message translates to:
  /// **'Storage Path'**
  String get labelStoragePath;

  /// S3 endpoint URL field label
  ///
  /// In en, this message translates to:
  /// **'Endpoint URL'**
  String get labelEndpointUrl;

  /// S3 access key ID field label
  ///
  /// In en, this message translates to:
  /// **'Access Key ID'**
  String get labelAccessKeyId;

  /// S3 secret access key field label
  ///
  /// In en, this message translates to:
  /// **'Secret Access Key'**
  String get labelSecretAccessKey;

  /// S3 bucket name field label
  ///
  /// In en, this message translates to:
  /// **'Bucket Name'**
  String get labelBucketName;

  /// S3 path field label
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get labelPath;

  /// S3 region field label
  ///
  /// In en, this message translates to:
  /// **'Region (optional, default cn-east-1)'**
  String get labelRegion;

  /// App lock toggle label
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get labelAppLock;

  /// Screenshot lock toggle label
  ///
  /// In en, this message translates to:
  /// **'Screenshot Lock'**
  String get labelScreenshotLock;

  /// Status: not configured
  ///
  /// In en, this message translates to:
  /// **'Not Configured'**
  String get statusNotConfigured;

  /// Status: configured
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get statusConfigured;

  /// Unknown version placeholder
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknownVersion;

  /// Unknown timestamp placeholder
  ///
  /// In en, this message translates to:
  /// **'Unknown Time'**
  String get statusUnknownTime;

  /// Biometric unavailable label
  ///
  /// In en, this message translates to:
  /// **'Device does not support biometrics'**
  String get biometricNotSupported;

  /// Android-only feature label
  ///
  /// In en, this message translates to:
  /// **'Android Only'**
  String get androidOnly;

  /// Password set indicator
  ///
  /// In en, this message translates to:
  /// **'Backup password is set'**
  String get passwordAlreadySet;

  /// Backup password tip message
  ///
  /// In en, this message translates to:
  /// **'The backup password is used to encrypt backup files. Multiple devices must use the same password to share backups.'**
  String get passwordTipMessage;

  /// HTTP warning message
  ///
  /// In en, this message translates to:
  /// **'HTTPS connection is recommended. Credentials are sent in plaintext over HTTP.'**
  String get httpsWarning;

  /// How to get config link label
  ///
  /// In en, this message translates to:
  /// **'How to configure'**
  String get howToGetConfig;

  /// Qiniu promotional banner title
  ///
  /// In en, this message translates to:
  /// **'Recommended: Qiniu Cloud Object Storage'**
  String get qiniuPromoTitle;

  /// Qiniu promotional banner link text
  ///
  /// In en, this message translates to:
  /// **'Sign up for Qiniu Cloud now for free credits'**
  String get qiniuPromoLink;

  /// Generic required field validation
  ///
  /// In en, this message translates to:
  /// **'This field cannot be empty'**
  String get validationRequired;

  /// Secret key required validation
  ///
  /// In en, this message translates to:
  /// **'Please enter the 2FA key'**
  String get validationSecretRequired;

  /// Invalid Base32 validation
  ///
  /// In en, this message translates to:
  /// **'Invalid Base32 key format'**
  String get validationSecretInvalidBase32;

  /// Counter required validation
  ///
  /// In en, this message translates to:
  /// **'Please enter a counter value'**
  String get validationCounterRequired;

  /// Counter invalid number validation
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get validationCounterInvalidNumber;

  /// Backup password required
  ///
  /// In en, this message translates to:
  /// **'Backup password cannot be empty'**
  String get validationBackupPasswordRequired;

  /// Backup password min length
  ///
  /// In en, this message translates to:
  /// **'Backup password must be at least 8 characters'**
  String get validationBackupPasswordMinLength;

  /// Confirm password required
  ///
  /// In en, this message translates to:
  /// **'Confirm password cannot be empty'**
  String get validationConfirmPasswordRequired;

  /// Password mismatch validation
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordMismatch;

  /// History count validation
  ///
  /// In en, this message translates to:
  /// **'Please enter a number no less than 0'**
  String get validationHistoryCountInvalid;

  /// WebDAV URL required
  ///
  /// In en, this message translates to:
  /// **'WebDAV URL cannot be empty'**
  String get validationWebDavUrlRequired;

  /// WebDAV username required
  ///
  /// In en, this message translates to:
  /// **'Username cannot be empty'**
  String get validationWebDavUsernameRequired;

  /// WebDAV password required
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get validationWebDavPasswordRequired;

  /// Storage path required
  ///
  /// In en, this message translates to:
  /// **'Storage path cannot be empty'**
  String get validationStoragePathRequired;

  /// Endpoint URL required
  ///
  /// In en, this message translates to:
  /// **'Endpoint URL cannot be empty'**
  String get validationEndpointRequired;

  /// Access Key ID required
  ///
  /// In en, this message translates to:
  /// **'Access Key ID cannot be empty'**
  String get validationAccessKeyRequired;

  /// Secret Access Key required
  ///
  /// In en, this message translates to:
  /// **'Secret Access Key cannot be empty'**
  String get validationSecretKeyRequired;

  /// Bucket Name required
  ///
  /// In en, this message translates to:
  /// **'Bucket Name cannot be empty'**
  String get validationBucketNameRequired;

  /// SnackBar: account added
  ///
  /// In en, this message translates to:
  /// **'Added successfully'**
  String get snackAddedSuccess;

  /// SnackBar: account modified
  ///
  /// In en, this message translates to:
  /// **'Modified successfully'**
  String get snackModifiedSuccess;

  /// SnackBar: backup successful
  ///
  /// In en, this message translates to:
  /// **'Backup successful'**
  String get snackBackupSuccess;

  /// SnackBar: backup failed
  ///
  /// In en, this message translates to:
  /// **'Backup failed'**
  String get snackBackupFailed;

  /// SnackBar: restore successful
  ///
  /// In en, this message translates to:
  /// **'Restore successful'**
  String get snackRestoreSuccess;

  /// SnackBar: restore failed
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get snackRestoreFailed;

  /// SnackBar: sort order saved
  ///
  /// In en, this message translates to:
  /// **'Sort order saved'**
  String get snackSortSaved;

  /// SnackBar: sort save failed
  ///
  /// In en, this message translates to:
  /// **'Failed to save sort order'**
  String get snackSortSaveFailed;

  /// SnackBar: init failed with error
  ///
  /// In en, this message translates to:
  /// **'Initialization failed: {error}'**
  String snackInitFailed(String error);

  /// SnackBar: config load failed
  ///
  /// In en, this message translates to:
  /// **'Failed to load config: {error}'**
  String snackLoadConfigFailed(String error);

  /// SnackBar: config save failed
  ///
  /// In en, this message translates to:
  /// **'Failed to save config: {error}'**
  String snackSaveConfigFailed(String error);

  /// SnackBar: backup not configured
  ///
  /// In en, this message translates to:
  /// **'Backup parameters not configured'**
  String get snackNotConfigured;

  /// SnackBar: select backup type first
  ///
  /// In en, this message translates to:
  /// **'Please select a backup type first'**
  String get snackSelectBackupTypeFirst;

  /// SnackBar: configure backup first
  ///
  /// In en, this message translates to:
  /// **'Please configure complete backup parameters first'**
  String get snackConfigureBackupFirst;

  /// SnackBar: screenshot lock on
  ///
  /// In en, this message translates to:
  /// **'Screenshot lock enabled'**
  String get snackScreenshotLockOn;

  /// SnackBar: screenshot lock off
  ///
  /// In en, this message translates to:
  /// **'Screenshot lock disabled'**
  String get snackScreenshotLockOff;

  /// SnackBar: screenshot lock error
  ///
  /// In en, this message translates to:
  /// **'Failed to update screenshot lock: {error}'**
  String snackScreenshotLockError(String error);

  /// SnackBar: biometric not available
  ///
  /// In en, this message translates to:
  /// **'Device does not support biometrics, cannot enable app lock'**
  String get snackBiometricNotAvailable;

  /// SnackBar: app lock on
  ///
  /// In en, this message translates to:
  /// **'App lock enabled'**
  String get snackAppLockEnabled;

  /// SnackBar: app lock off
  ///
  /// In en, this message translates to:
  /// **'App lock disabled'**
  String get snackAppLockDisabled;

  /// SnackBar: app lock disable failed
  ///
  /// In en, this message translates to:
  /// **'Authentication failed, cannot disable app lock'**
  String get snackAppLockDisableFailed;

  /// SnackBar: delete success
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get snackDeleteSuccess;

  /// SnackBar: delete failed
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get snackDeleteFailed;

  /// SnackBar: load failed
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String snackLoadFailed(String error);

  /// SnackBar: import success count
  ///
  /// In en, this message translates to:
  /// **'Successfully imported {count} accounts'**
  String snackImportSuccess(int count);

  /// SnackBar: no accounts imported
  ///
  /// In en, this message translates to:
  /// **'No accounts were successfully imported'**
  String get snackImportNone;

  /// SnackBar: import error
  ///
  /// In en, this message translates to:
  /// **'Error importing accounts'**
  String get snackImportError;

  /// SnackBar: no accounts selected
  ///
  /// In en, this message translates to:
  /// **'Please select accounts to import'**
  String get snackSelectAccountsToImport;

  /// SnackBar: select at least one
  ///
  /// In en, this message translates to:
  /// **'Please select at least one account'**
  String get snackSelectAtLeastOne;

  /// SnackBar: QR code generation error
  ///
  /// In en, this message translates to:
  /// **'Error generating QR code'**
  String get snackQrCodeGenerateError;

  /// Dialog: delete account title
  ///
  /// In en, this message translates to:
  /// **'Delete 2FA Account'**
  String get dialogTitleDeleteAccount;

  /// Dialog: confirm delete account body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String dialogConfirmDeleteAccount(String name);

  /// Dialog: confirm restore title
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get dialogTitleConfirmRestore;

  /// Dialog: confirm restore body
  ///
  /// In en, this message translates to:
  /// **'Restoring will overwrite current data. Are you sure you want to continue?'**
  String get dialogConfirmRestoreBody;

  /// Dialog: confirm restore button
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get dialogButtonConfirmRestore;

  /// Dialog: error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get dialogTitleError;

  /// Dialog: scan failed title
  ///
  /// In en, this message translates to:
  /// **'Scan Failed'**
  String get dialogTitleScanFailed;

  /// Dialog: QR code error title
  ///
  /// In en, this message translates to:
  /// **'QR Code Format Error'**
  String get dialogTitleQrCodeError;

  /// Dialog: confirm delete title
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get dialogTitleConfirmDelete;

  /// Dialog: confirm delete backups body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected {count} backup files? This action cannot be undone.'**
  String dialogConfirmDeleteBackups(int count);

  /// Dialog: confirm restore file body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore \"{name}\"?\nThis will overwrite all current data.'**
  String dialogConfirmRestoreFile(String name);

  /// Loading: config
  ///
  /// In en, this message translates to:
  /// **'Loading config...'**
  String get loadingConfig;

  /// Loading: operation in progress
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get loadingOperation;

  /// Loading: please wait
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get loadingPleaseWait;

  /// Loading: authenticating
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get loadingAuthenticating;

  /// Loading: biometric prompt
  ///
  /// In en, this message translates to:
  /// **'Please verify your biometrics'**
  String get loadingAuthPrompt;

  /// Auth: access reason
  ///
  /// In en, this message translates to:
  /// **'Please verify your identity to access the app'**
  String get authReasonAccess;

  /// Auth: enable lock reason
  ///
  /// In en, this message translates to:
  /// **'Please verify your identity to enable app lock'**
  String get authReasonEnable;

  /// Auth: disable lock reason
  ///
  /// In en, this message translates to:
  /// **'Please verify your identity to disable app lock'**
  String get authReasonDisable;

  /// Empty state: no accounts title
  ///
  /// In en, this message translates to:
  /// **'No 2FA accounts yet'**
  String get emptyNoAccounts;

  /// Empty state: add prompt
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add an account'**
  String get emptyAddPrompt;

  /// Empty state: no backups
  ///
  /// In en, this message translates to:
  /// **'No backup files found'**
  String get emptyNoBackupFiles;

  /// Search field hint
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get hintSearch;

  /// Drawer: import/export
  ///
  /// In en, this message translates to:
  /// **'Import/Export'**
  String get drawerImportExport;

  /// Drawer: settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// Drawer: about
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get drawerAbout;

  /// Backup config dialog title
  ///
  /// In en, this message translates to:
  /// **'Backup Parameter Configuration'**
  String get backupConfigTitle;

  /// Button: backup to remote
  ///
  /// In en, this message translates to:
  /// **'Backup to Remote'**
  String get backupToRemote;

  /// Button: restore from remote
  ///
  /// In en, this message translates to:
  /// **'Restore from Remote'**
  String get restoreFromRemote;

  /// Button: manage remote backups
  ///
  /// In en, this message translates to:
  /// **'Manage Remote Backups'**
  String get manageRemoteBackups;

  /// Scan: hint text
  ///
  /// In en, this message translates to:
  /// **'Place the QR code in the frame to scan'**
  String get scanHintText;

  /// Export: scan prompt
  ///
  /// In en, this message translates to:
  /// **'Please scan this QR code with another device'**
  String get exportScanPrompt;

  /// FAB: scan QR code
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get fabScanQr;

  /// FAB: enter key
  ///
  /// In en, this message translates to:
  /// **'Enter 2FA Key'**
  String get fabEnterKey;

  /// HOTP: increment counter tooltip
  ///
  /// In en, this message translates to:
  /// **'Increment counter (current: {counter})'**
  String hotpIncrementTooltip(int counter);

  /// Import/Export: description
  ///
  /// In en, this message translates to:
  /// **'You can transfer your 2FA accounts to a new device\nCompatible with Google Authenticator migration'**
  String get importExportDescription;

  /// Button: export accounts
  ///
  /// In en, this message translates to:
  /// **'Export Accounts'**
  String get exportAccounts;

  /// Button: import accounts
  ///
  /// In en, this message translates to:
  /// **'Import Accounts'**
  String get importAccounts;

  /// About: copyright notice
  ///
  /// In en, this message translates to:
  /// **'2016-2026 EasyDebug.NET All rights reserved.'**
  String get copyrightNotice;

  /// Error: QR format
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code format. Must be otpauth:// URI.'**
  String get errorQrFormat;

  /// Error: missing secret
  ///
  /// In en, this message translates to:
  /// **'QR code is missing the required secret key'**
  String get errorQrMissingSecret;

  /// Error: invalid Base32
  ///
  /// In en, this message translates to:
  /// **'Invalid key format. Must be Base32 encoded.'**
  String get errorSecretInvalidBase32;

  /// Error: cannot recognize QR
  ///
  /// In en, this message translates to:
  /// **'Cannot recognize this QR code'**
  String get errorCannotRecognizeQr;

  /// Error: TOTP only
  ///
  /// In en, this message translates to:
  /// **'Only TOTP type is supported, HOTP is not supported in QR scan'**
  String get errorTotpOnly;

  /// Error: QR data format
  ///
  /// In en, this message translates to:
  /// **'QR code data format error'**
  String get errorQrDataFormat;

  /// Error: invalid migration QR
  ///
  /// In en, this message translates to:
  /// **'Invalid migration QR code'**
  String get errorInvalidMigrationQr;

  /// Error: invalid QR data format
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code data format'**
  String get errorInvalidQrDataFormat;

  /// Error: cannot open URL
  ///
  /// In en, this message translates to:
  /// **'Cannot open link. Please check if a browser is installed.'**
  String get errorCannotOpenUrl;

  /// Error: open URL failed
  ///
  /// In en, this message translates to:
  /// **'Failed to open link: {error}'**
  String errorOpenUrlFailed(String error);

  /// Exception: invalid config
  ///
  /// In en, this message translates to:
  /// **'Invalid backup configuration'**
  String get exceptionConfigInvalid;

  /// Exception: check config params
  ///
  /// In en, this message translates to:
  /// **'Please check that backup parameters are complete'**
  String get exceptionConfigCheckParams;

  /// Exception: generate data failed
  ///
  /// In en, this message translates to:
  /// **'Failed to generate backup data'**
  String get exceptionGenerateDataFailed;

  /// Exception: cannot read accounts
  ///
  /// In en, this message translates to:
  /// **'Cannot read 2FA account data'**
  String get exceptionCannotReadAccounts;

  /// Exception: set password first
  ///
  /// In en, this message translates to:
  /// **'Please set a backup password first'**
  String get exceptionSetPasswordFirst;

  /// Exception: password not set
  ///
  /// In en, this message translates to:
  /// **'Backup password not set'**
  String get exceptionPasswordNotSet;

  /// Exception: network failed
  ///
  /// In en, this message translates to:
  /// **'Network connection failed'**
  String get exceptionNetworkFailed;

  /// Exception: check network
  ///
  /// In en, this message translates to:
  /// **'Please check your network connection'**
  String get exceptionCheckNetwork;

  /// Exception: upload error
  ///
  /// In en, this message translates to:
  /// **'Error occurred while uploading backup'**
  String get exceptionUploadError;

  /// Exception: backup error
  ///
  /// In en, this message translates to:
  /// **'An error occurred during backup'**
  String get exceptionBackupError;

  /// Exception: restore config invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid restore configuration'**
  String get exceptionRestoreConfigInvalid;

  /// Exception: unsupported backup type
  ///
  /// In en, this message translates to:
  /// **'Unsupported backup type'**
  String get exceptionUnsupportedBackupType;

  /// Exception: download error
  ///
  /// In en, this message translates to:
  /// **'Error occurred while downloading backup'**
  String get exceptionDownloadError;

  /// Exception: restore data failed
  ///
  /// In en, this message translates to:
  /// **'Failed to restore data'**
  String get exceptionRestoreDataFailed;

  /// Exception: backup corrupted
  ///
  /// In en, this message translates to:
  /// **'Backup file may be corrupted or password is incorrect'**
  String get exceptionBackupCorrupted;

  /// Exception: restore error
  ///
  /// In en, this message translates to:
  /// **'An error occurred during restore'**
  String get exceptionRestoreError;

  /// Exception: no backup found
  ///
  /// In en, this message translates to:
  /// **'No backup files found'**
  String get exceptionNoBackupFound;

  /// Exception: no backup in WebDAV
  ///
  /// In en, this message translates to:
  /// **'No backup files found in WebDAV storage. Please run a backup first.'**
  String get exceptionNoBackupWebDav;

  /// Exception: no backup in S3
  ///
  /// In en, this message translates to:
  /// **'No backup files found in S3 storage. Please run a backup first.'**
  String get exceptionNoBackupS3;

  /// Exception: missing salt
  ///
  /// In en, this message translates to:
  /// **'Backup file format error: missing salt'**
  String get exceptionFormatMissingSalt;

  /// Exception: missing data
  ///
  /// In en, this message translates to:
  /// **'Backup file format error: missing data'**
  String get exceptionFormatMissingData;

  /// Exception: decrypt failed
  ///
  /// In en, this message translates to:
  /// **'Failed to decrypt backup data. Please verify the backup password is correct.'**
  String get exceptionDecryptFailed;

  /// Version label on about screen
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.scriptCode) {
    case 'Hans': return AppLocalizationsZhHans();
case 'Hant': return AppLocalizationsZhHant();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
