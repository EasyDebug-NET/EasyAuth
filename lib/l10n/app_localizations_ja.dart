// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'EasyAuth';

  @override
  String get settingsTitle => '設定';

  @override
  String get aboutTitle => '概要';

  @override
  String get importExportTitle => 'インポート/エクスポート';

  @override
  String get addManualTitle => '2FA 詳細を入力';

  @override
  String get addScanTitle => 'QR コードをスキャン';

  @override
  String get editTitle => '2FA 情報を編集';

  @override
  String get exportTitle => '2FA をエクスポート';

  @override
  String get importTitle => '2FA をインポート';

  @override
  String get buttonSave => '保存';

  @override
  String get buttonCancel => 'キャンセル';

  @override
  String get buttonConfirm => '確認';

  @override
  String get buttonDelete => '削除';

  @override
  String get buttonImport => 'インポート';

  @override
  String get buttonExport => 'エクスポート';

  @override
  String get buttonRetry => '再試行';

  @override
  String get buttonOK => 'OK';

  @override
  String get buttonModify => '変更';

  @override
  String get buttonSelectAll => 'すべて選択';

  @override
  String get buttonRestore => '復元';

  @override
  String get sectionBackupSettings => 'バックアップ設定';

  @override
  String get sectionSecuritySettings => 'セキュリティ設定';

  @override
  String get sectionLanguage => '言語';

  @override
  String get labelIssuer => '発行者名';

  @override
  String get hintIssuer => '例：Google';

  @override
  String get labelAccountName => 'アカウント名';

  @override
  String get hintAccountName => '例：user@example.com';

  @override
  String get labelSecretKey => '2FA キー';

  @override
  String get hintSecretKey => 'Base32';

  @override
  String get labelSecretType => 'キータイプ';

  @override
  String get secretTypeTime => '時間ベース（TOTP）';

  @override
  String get secretTypeCounter => 'カウンターベース（HOTP）';

  @override
  String get labelCounterInitial => '初期カウンター値';

  @override
  String get hintCounterInitial => 'デフォルト 0';

  @override
  String get labelBackupType => 'バックアップタイプ';

  @override
  String get backupTypeOff => 'オフ';

  @override
  String get backupTypeWebDAV => 'WebDAV';

  @override
  String get backupTypeS3 => 'オブジェクトストレージ';

  @override
  String get labelBackupPassword => 'バックアップパスワード';

  @override
  String get hintBackupPassword => 'バックアップ暗号化パスワードを設定';

  @override
  String get labelConfirmBackupPassword => 'バックアップパスワードの確認';

  @override
  String get hintConfirmBackupPassword => 'バックアップパスワードを再入力';

  @override
  String get labelHistoryCount => '履歴バージョンの保持数';

  @override
  String get hintHistoryCount => 'デフォルト 10、0 で無制限';

  @override
  String get labelWebDavUrl => 'WebDAV URL';

  @override
  String get labelWebDavUsername => 'ユーザー名';

  @override
  String get labelWebDavPassword => 'パスワード';

  @override
  String get labelStoragePath => '保存パス';

  @override
  String get labelEndpointUrl => 'エンドポイント URL';

  @override
  String get labelAccessKeyId => 'アクセスキー ID';

  @override
  String get labelSecretAccessKey => 'シークレットアクセスキー';

  @override
  String get labelBucketName => 'バケット名';

  @override
  String get labelPath => 'パス';

  @override
  String get labelRegion => 'リージョン（任意、デフォルト cn-east-1）';

  @override
  String get labelAppLock => 'アプリロック';

  @override
  String get labelScreenshotLock => 'スクリーンショットロック';

  @override
  String get statusNotConfigured => '未設定';

  @override
  String get statusConfigured => '設定済み';

  @override
  String get statusUnknownVersion => '不明';

  @override
  String get statusUnknownTime => '不明な時間';

  @override
  String get biometricNotSupported => 'デバイスが生体認証をサポートしていません';

  @override
  String get androidOnly => 'Android のみ';

  @override
  String get passwordAlreadySet => 'バックアップパスワードは設定済みです';

  @override
  String get passwordTipMessage =>
      'バックアップパスワードはバックアップファイルの暗号化に使用されます。複数のデバイスでバックアップを共有するには同じパスワードが必要です。';

  @override
  String get httpsWarning => 'HTTPS 接続を推奨します。HTTP では認証情報が平文で送信されます。';

  @override
  String get howToGetConfig => '設定情報の取得方法';

  @override
  String get qiniuPromoTitle => '推奨：Qiniu Cloud オブジェクトストレージ';

  @override
  String get qiniuPromoLink => '今すぐ Qiniu Cloud に登録して無料クレジットを取得';

  @override
  String get validationRequired => 'このフィールドは必須です';

  @override
  String get validationSecretRequired => '2FA キーを入力してください';

  @override
  String get validationSecretInvalidBase32 => '無効な Base32 キー形式です';

  @override
  String get validationCounterRequired => 'カウンター値を入力してください';

  @override
  String get validationCounterInvalidNumber => '有効な数値を入力してください';

  @override
  String get validationBackupPasswordRequired => 'バックアップパスワードは必須です';

  @override
  String get validationBackupPasswordMinLength => 'バックアップパスワードは8文字以上必要です';

  @override
  String get validationConfirmPasswordRequired => '確認用パスワードは必須です';

  @override
  String get validationPasswordMismatch => 'パスワードが一致しません';

  @override
  String get validationHistoryCountInvalid => '0 以上の数値を入力してください';

  @override
  String get validationWebDavUrlRequired => 'WebDAV URL は必須です';

  @override
  String get validationWebDavUsernameRequired => 'ユーザー名は必須です';

  @override
  String get validationWebDavPasswordRequired => 'パスワードは必須です';

  @override
  String get validationStoragePathRequired => '保存パスは必須です';

  @override
  String get validationEndpointRequired => 'エンドポイント URL は必須です';

  @override
  String get validationAccessKeyRequired => 'アクセスキー ID は必須です';

  @override
  String get validationSecretKeyRequired => 'シークレットアクセスキーは必須です';

  @override
  String get validationBucketNameRequired => 'バケット名は必須です';

  @override
  String get snackAddedSuccess => '追加しました';

  @override
  String get snackModifiedSuccess => '変更しました';

  @override
  String get snackBackupSuccess => 'バックアップ成功';

  @override
  String get snackBackupFailed => 'バックアップ失敗';

  @override
  String get snackRestoreSuccess => '復元成功';

  @override
  String get snackRestoreFailed => '復元失敗';

  @override
  String get snackSortSaved => '並び順を保存しました';

  @override
  String get snackSortSaveFailed => '並び順の保存に失敗しました';

  @override
  String snackInitFailed(String error) {
    return '初期化に失敗しました: $error';
  }

  @override
  String snackLoadConfigFailed(String error) {
    return '設定の読み込みに失敗しました: $error';
  }

  @override
  String snackSaveConfigFailed(String error) {
    return '設定の保存に失敗しました: $error';
  }

  @override
  String get snackNotConfigured => 'バックアップパラメータが未設定です';

  @override
  String get snackSelectBackupTypeFirst => '先にバックアップタイプを選択してください';

  @override
  String get snackConfigureBackupFirst => '先にバックアップパラメータを完全に設定してください';

  @override
  String get snackScreenshotLockOn => 'スクリーンショットロックを有効にしました';

  @override
  String get snackScreenshotLockOff => 'スクリーンショットロックを無効にしました';

  @override
  String snackScreenshotLockError(String error) {
    return 'スクリーンショットロックの更新に失敗しました: $error';
  }

  @override
  String get snackBiometricNotAvailable =>
      'デバイスが生体認証をサポートしていないため、アプリロックを有効にできません';

  @override
  String get snackAppLockEnabled => 'アプリロックを有効にしました';

  @override
  String get snackAppLockDisabled => 'アプリロックを無効にしました';

  @override
  String get snackAppLockDisableFailed => '認証に失敗しました。アプリロックを無効にできません';

  @override
  String get snackDeleteSuccess => '削除しました';

  @override
  String get snackDeleteFailed => '削除に失敗しました';

  @override
  String snackLoadFailed(String error) {
    return '読み込みに失敗しました: $error';
  }

  @override
  String snackImportSuccess(int count) {
    return '$count 個のアカウントをインポートしました';
  }

  @override
  String get snackImportNone => 'インポートされたアカウントはありません';

  @override
  String get snackImportError => 'アカウントのインポート中にエラーが発生しました';

  @override
  String get snackSelectAccountsToImport => 'インポートするアカウントを選択してください';

  @override
  String get snackSelectAtLeastOne => '少なくとも1つのアカウントを選択してください';

  @override
  String get snackQrCodeGenerateError => 'QR コードの生成中にエラーが発生しました';

  @override
  String get dialogTitleDeleteAccount => '2FA アカウントの削除';

  @override
  String dialogConfirmDeleteAccount(String name) {
    return '\"$name\" を削除してもよろしいですか？';
  }

  @override
  String get dialogTitleConfirmRestore => '復元の確認';

  @override
  String get dialogConfirmRestoreBody => '復元すると現在のデータが上書きされます。続行しますか？';

  @override
  String get dialogButtonConfirmRestore => '復元する';

  @override
  String get dialogTitleError => 'エラー';

  @override
  String get dialogTitleScanFailed => 'スキャン失敗';

  @override
  String get dialogTitleQrCodeError => 'QR コード形式エラー';

  @override
  String get dialogTitleConfirmDelete => '削除の確認';

  @override
  String dialogConfirmDeleteBackups(int count) {
    return '選択した $count 個のバックアップファイルを削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String dialogConfirmRestoreFile(String name) {
    return '\"$name\" に復元してもよろしいですか？\n現在のすべてのデータが上書きされます。';
  }

  @override
  String get loadingConfig => '設定を読み込み中...';

  @override
  String get loadingOperation => '処理中...';

  @override
  String get loadingPleaseWait => 'お待ちください';

  @override
  String get loadingAuthenticating => '認証中...';

  @override
  String get loadingAuthPrompt => '生体情報を確認してください';

  @override
  String get authReasonAccess => 'アプリにアクセスするために本人確認を行ってください';

  @override
  String get authReasonEnable => 'アプリロックを有効にするために本人確認を行ってください';

  @override
  String get authReasonDisable => 'アプリロックを無効にするために本人確認を行ってください';

  @override
  String get emptyNoAccounts => 'まだ 2FA アカウントがありません';

  @override
  String get emptyAddPrompt => '+ ボタンをタップしてアカウントを追加';

  @override
  String get emptyNoBackupFiles => 'バックアップファイルが見つかりません';

  @override
  String get hintSearch => '検索...';

  @override
  String get drawerImportExport => 'インポート/エクスポート';

  @override
  String get drawerSettings => '設定';

  @override
  String get drawerAbout => '概要';

  @override
  String get backupConfigTitle => 'バックアップパラメータ設定';

  @override
  String get backupToRemote => 'リモートにバックアップ';

  @override
  String get restoreFromRemote => 'リモートから復元';

  @override
  String get manageRemoteBackups => 'リモートバックアップの管理';

  @override
  String get scanHintText => '枠内に QR コードを入れると自動スキャンされます';

  @override
  String get exportScanPrompt => '別のデバイスでこの QR コードをスキャンしてください';

  @override
  String get fabScanQr => 'QR コードをスキャン';

  @override
  String get fabEnterKey => '2FA キーを入力';

  @override
  String hotpIncrementTooltip(int counter) {
    return 'カウンターを増加（現在: $counter）';
  }

  @override
  String get importExportDescription =>
      '2FA アカウントを新しいデバイスに転送できます\nGoogle Authenticator の移行に対応';

  @override
  String get exportAccounts => 'アカウントをエクスポート';

  @override
  String get importAccounts => 'アカウントをインポート';

  @override
  String get copyrightNotice => '2016-2026 EasyDebug.NET All rights reserved.';

  @override
  String get errorQrFormat => '無効な QR コード形式です。otpauth:// URI である必要があります。';

  @override
  String get errorQrMissingSecret => 'QR コードに必要なシークレットキーがありません';

  @override
  String get errorSecretInvalidBase32 => '無効なキー形式です。Base32 エンコードが必要です。';

  @override
  String get errorCannotRecognizeQr => 'この QR コードを認識できません';

  @override
  String get errorTotpOnly =>
      'TOTP タイプのみサポートされています。HOTP は QR スキャンではサポートされていません。';

  @override
  String get errorQrDataFormat => 'QR コードデータ形式エラー';

  @override
  String get errorInvalidMigrationQr => '無効な移行 QR コードです';

  @override
  String get errorInvalidQrDataFormat => '無効な QR コードデータ形式です';

  @override
  String get errorCannotOpenUrl => 'リンクを開けません。ブラウザがインストールされているか確認してください。';

  @override
  String errorOpenUrlFailed(String error) {
    return 'リンクを開けませんでした: $error';
  }

  @override
  String get exceptionConfigInvalid => '無効なバックアップ設定';

  @override
  String get exceptionConfigCheckParams => 'バックアップパラメータが完全か確認してください';

  @override
  String get exceptionGenerateDataFailed => 'バックアップデータの生成に失敗しました';

  @override
  String get exceptionCannotReadAccounts => '2FA アカウントデータを読み取れません';

  @override
  String get exceptionSetPasswordFirst => '先にバックアップパスワードを設定してください';

  @override
  String get exceptionPasswordNotSet => 'バックアップパスワードが設定されていません';

  @override
  String get exceptionNetworkFailed => 'ネットワーク接続に失敗しました';

  @override
  String get exceptionCheckNetwork => 'ネットワーク接続を確認してください';

  @override
  String get exceptionUploadError => 'バックアップのアップロード中にエラーが発生しました';

  @override
  String get exceptionBackupError => 'バックアップ中にエラーが発生しました';

  @override
  String get exceptionRestoreConfigInvalid => '無効な復元設定';

  @override
  String get exceptionUnsupportedBackupType => 'サポートされていないバックアップタイプです';

  @override
  String get exceptionDownloadError => 'バックアップのダウンロード中にエラーが発生しました';

  @override
  String get exceptionRestoreDataFailed => 'データの復元に失敗しました';

  @override
  String get exceptionBackupCorrupted => 'バックアップファイルが破損しているか、パスワードが間違っています';

  @override
  String get exceptionRestoreError => '復元中にエラーが発生しました';

  @override
  String get exceptionNoBackupFound => 'バックアップファイルが見つかりません';

  @override
  String get exceptionNoBackupWebDav =>
      'WebDAV ストレージにバックアップファイルが見つかりません。先にバックアップを実行してください。';

  @override
  String get exceptionNoBackupS3 =>
      'S3 ストレージにバックアップファイルが見つかりません。先にバックアップを実行してください。';

  @override
  String get exceptionFormatMissingSalt => 'バックアップファイル形式エラー：ソルトがありません';

  @override
  String get exceptionFormatMissingData => 'バックアップファイル形式エラー：データがありません';

  @override
  String get exceptionDecryptFailed =>
      'バックアップデータの復号に失敗しました。バックアップパスワードが正しいか確認してください。';

  @override
  String versionLabel(String version) {
    return 'バージョン $version';
  }
}
