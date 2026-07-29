// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'EasyAuth';

  @override
  String get settingsTitle => '设置';

  @override
  String get aboutTitle => '关于';

  @override
  String get importExportTitle => '导入/导出';

  @override
  String get addManualTitle => '输入动态口令详情';

  @override
  String get addScanTitle => '扫描二维码';

  @override
  String get editTitle => '修改动态口令信息';

  @override
  String get exportTitle => '导出动态口令';

  @override
  String get importTitle => '导入动态口令';

  @override
  String get buttonSave => '保存';

  @override
  String get buttonCancel => '取消';

  @override
  String get buttonConfirm => '确认';

  @override
  String get buttonDelete => '删除';

  @override
  String get buttonImport => '导入';

  @override
  String get buttonExport => '导出';

  @override
  String get buttonRetry => '重试';

  @override
  String get buttonOK => '确定';

  @override
  String get buttonModify => '修改';

  @override
  String get buttonSelectAll => '全选';

  @override
  String get buttonRestore => '恢复';

  @override
  String get sectionBackupSettings => '备份设置';

  @override
  String get sectionSecuritySettings => '安全设置';

  @override
  String get sectionLanguage => '语言';

  @override
  String get labelIssuer => '发行者名称';

  @override
  String get hintIssuer => '例如：Google';

  @override
  String get labelAccountName => '动态口令名称';

  @override
  String get hintAccountName => '例如：user@example.com';

  @override
  String get labelSecretKey => '2FA密钥';

  @override
  String get hintSecretKey => 'Base32';

  @override
  String get labelSecretType => '密钥类型';

  @override
  String get secretTypeTime => '基于时间';

  @override
  String get secretTypeCounter => '基于计数器';

  @override
  String get labelCounterInitial => '计数器初始值';

  @override
  String get hintCounterInitial => '默认 0';

  @override
  String get labelBackupType => '备份类型';

  @override
  String get backupTypeOff => '关闭';

  @override
  String get backupTypeWebDAV => 'WebDAV';

  @override
  String get backupTypeS3 => '对象存储';

  @override
  String get labelBackupPassword => '备份密码';

  @override
  String get hintBackupPassword => '请设置备份加密密码';

  @override
  String get labelConfirmBackupPassword => '确认备份密码';

  @override
  String get hintConfirmBackupPassword => '请再次输入备份密码';

  @override
  String get labelHistoryCount => '保留历史版本数';

  @override
  String get hintHistoryCount => '默认 10，设为 0 则不限制';

  @override
  String get labelWebDavUrl => 'WebDAV地址';

  @override
  String get labelWebDavUsername => '授权账号';

  @override
  String get labelWebDavPassword => '授权密码';

  @override
  String get labelStoragePath => '存储路径';

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
  String get labelRegion => 'Region ( 选填，默认cn-east-1)';

  @override
  String get labelAppLock => '应用锁';

  @override
  String get labelScreenshotLock => '截屏锁';

  @override
  String get statusNotConfigured => '未配置';

  @override
  String get statusConfigured => '已配置';

  @override
  String get statusUnknownVersion => '未知';

  @override
  String get statusUnknownTime => '未知时间';

  @override
  String get biometricNotSupported => '设备不支持生物识别';

  @override
  String get androidOnly => '仅支持 Android';

  @override
  String get passwordAlreadySet => '备份密码已设置';

  @override
  String get passwordTipMessage => '备份密码用于加密备份文件。多台设备需设置相同密码才能共享备份。';

  @override
  String get httpsWarning => '建议使用 HTTPS 连接，HTTP 下凭据将明文传输';

  @override
  String get howToGetConfig => '如何获取配置信息';

  @override
  String get qiniuPromoTitle => '推荐使用七牛云对象存储';

  @override
  String get qiniuPromoLink => '立即注册七牛云，即获万元免费额度';

  @override
  String get validationRequired => '该字段不能为空';

  @override
  String get validationSecretRequired => '请输入2FA密钥';

  @override
  String get validationSecretInvalidBase32 => '无效的Base32密钥格式';

  @override
  String get validationCounterRequired => '请输入计数器值';

  @override
  String get validationCounterInvalidNumber => '请输入有效的数字';

  @override
  String get validationBackupPasswordRequired => '备份密码不能为空';

  @override
  String get validationBackupPasswordMinLength => '备份密码长度不能少于8位';

  @override
  String get validationConfirmPasswordRequired => '确认备份密码不能为空';

  @override
  String get validationPasswordMismatch => '两次输入的密码不一致';

  @override
  String get validationHistoryCountInvalid => '请输入不小于 0 的数字';

  @override
  String get validationWebDavUrlRequired => 'WebDAV地址不能为空';

  @override
  String get validationWebDavUsernameRequired => '授权账号不能为空';

  @override
  String get validationWebDavPasswordRequired => '授权密码不能为空';

  @override
  String get validationStoragePathRequired => '存储路径不能为空';

  @override
  String get validationEndpointRequired => 'Endpoint URL不能为空';

  @override
  String get validationAccessKeyRequired => 'Access Key ID不能为空';

  @override
  String get validationSecretKeyRequired => 'Secret Access Key不能为空';

  @override
  String get validationBucketNameRequired => 'Bucket Name不能为空';

  @override
  String get snackAddedSuccess => '添加成功';

  @override
  String get snackModifiedSuccess => '修改成功';

  @override
  String get snackBackupSuccess => '备份成功';

  @override
  String get snackBackupFailed => '备份失败';

  @override
  String get snackRestoreSuccess => '恢复成功';

  @override
  String get snackRestoreFailed => '恢复失败';

  @override
  String get snackSortSaved => '排序已保存';

  @override
  String get snackSortSaveFailed => '保存排序失败';

  @override
  String snackInitFailed(String error) {
    return '初始化失败: $error';
  }

  @override
  String snackLoadConfigFailed(String error) {
    return '加载配置失败: $error';
  }

  @override
  String snackSaveConfigFailed(String error) {
    return '保存配置失败: $error';
  }

  @override
  String get snackNotConfigured => '未配置备份参数';

  @override
  String get snackSelectBackupTypeFirst => '请先选择备份类型';

  @override
  String get snackConfigureBackupFirst => '请先配置完整的备份参数';

  @override
  String get snackScreenshotLockOn => '截屏锁已开启';

  @override
  String get snackScreenshotLockOff => '截屏锁已关闭';

  @override
  String snackScreenshotLockError(String error) {
    return '更新截屏锁状态失败: $error';
  }

  @override
  String get snackBiometricNotAvailable => '设备不支持生物识别，无法开启应用锁';

  @override
  String get snackAppLockEnabled => '应用锁已开启';

  @override
  String get snackAppLockDisabled => '应用锁已关闭';

  @override
  String get snackAppLockDisableFailed => '认证失败，无法关闭应用锁';

  @override
  String get snackDeleteSuccess => '删除成功';

  @override
  String get snackDeleteFailed => '删除失败';

  @override
  String snackLoadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String snackImportSuccess(int count) {
    return '成功导入 $count 个动态口令';
  }

  @override
  String get snackImportNone => '没有成功导入任何动态口令';

  @override
  String get snackImportError => '导入动态口令时出错';

  @override
  String get snackSelectAccountsToImport => '请选择要导入的动态口令';

  @override
  String get snackSelectAtLeastOne => '请至少选择一个动态口令';

  @override
  String get snackQrCodeGenerateError => '生成二维码时出错';

  @override
  String get dialogTitleDeleteAccount => '删除动态口令';

  @override
  String dialogConfirmDeleteAccount(String name) {
    return '确定要删除动态口令 \"$name\" 吗？';
  }

  @override
  String get dialogTitleConfirmRestore => '确认恢复';

  @override
  String get dialogConfirmRestoreBody => '恢复备份将覆盖当前数据，确定要继续吗？';

  @override
  String get dialogButtonConfirmRestore => '确定恢复';

  @override
  String get dialogTitleError => '错误';

  @override
  String get dialogTitleScanFailed => '扫描失败';

  @override
  String get dialogTitleQrCodeError => '二维码格式错误';

  @override
  String get dialogTitleConfirmDelete => '确认删除';

  @override
  String dialogConfirmDeleteBackups(int count) {
    return '确定要删除选中的 $count 个备份文件吗？此操作不可恢复。';
  }

  @override
  String dialogConfirmRestoreFile(String name) {
    return '确定要恢复到 \"$name\" 吗？\n恢复将覆盖当前所有数据。';
  }

  @override
  String get loadingConfig => '加载配置中...';

  @override
  String get loadingOperation => '正在执行操作...';

  @override
  String get loadingPleaseWait => '请稍候';

  @override
  String get loadingAuthenticating => '正在验证身份...';

  @override
  String get loadingAuthPrompt => '请验证您的生物识别信息';

  @override
  String get authReasonAccess => '请验证身份以访问应用';

  @override
  String get authReasonEnable => '请验证身份以开启应用锁';

  @override
  String get authReasonDisable => '请验证身份以关闭应用锁';

  @override
  String get emptyNoAccounts => '此处似乎尚无任何动态口令';

  @override
  String get emptyAddPrompt => '点击右下角 + 添加动态口令';

  @override
  String get emptyNoBackupFiles => '没有找到备份文件';

  @override
  String get hintSearch => '搜索...';

  @override
  String get drawerImportExport => '导入/导出';

  @override
  String get drawerSettings => '设置';

  @override
  String get drawerAbout => '关于';

  @override
  String get backupConfigTitle => '备份参数配置';

  @override
  String get backupToRemote => '备份到远端';

  @override
  String get restoreFromRemote => '从远端恢复';

  @override
  String get manageRemoteBackups => '管理远端备份';

  @override
  String get scanHintText => '将二维码放入框内即可自动扫描';

  @override
  String get exportScanPrompt => '请使用另一台设备扫描此二维码';

  @override
  String get fabScanQr => '扫描二维码';

  @override
  String get fabEnterKey => '输入2FA密钥';

  @override
  String hotpIncrementTooltip(int counter) {
    return '递增计数器 (当前: $counter)';
  }

  @override
  String get importExportDescription => '您可以将自己的动态口令转移到新设备中\n支持Google Authenticator的转移动态口令';

  @override
  String get exportAccounts => '导出动态口令';

  @override
  String get importAccounts => '导入动态口令';

  @override
  String get copyrightNotice => '2016-2026 EasyDebug.NET All rights reserved.';

  @override
  String get errorQrFormat => '二维码格式错误，必须是 otpauth:// 格式的URI';

  @override
  String get errorQrMissingSecret => '二维码缺少必要的密钥信息（secret）';

  @override
  String get errorSecretInvalidBase32 => '密钥格式无效，必须是Base32编码';

  @override
  String get errorCannotRecognizeQr => '无法识别此二维码';

  @override
  String get errorTotpOnly => '仅支持TOTP类型的动态口令，不支持HOTP';

  @override
  String get errorQrDataFormat => '二维码数据格式错误';

  @override
  String get errorInvalidMigrationQr => '无效的迁移二维码';

  @override
  String get errorInvalidQrDataFormat => '无效的二维码数据格式';

  @override
  String get errorCannotOpenUrl => '无法打开链接，请检查是否安装了浏览器';

  @override
  String errorOpenUrlFailed(String error) {
    return '打开链接失败: $error';
  }

  @override
  String get exceptionConfigInvalid => '备份配置无效';

  @override
  String get exceptionConfigCheckParams => '请检查备份参数是否完整';

  @override
  String get exceptionGenerateDataFailed => '生成备份数据失败';

  @override
  String get exceptionCannotReadAccounts => '无法读取动态口令数据';

  @override
  String get exceptionSetPasswordFirst => '请先设置备份密码';

  @override
  String get exceptionPasswordNotSet => '备份密码未设置';

  @override
  String get exceptionNetworkFailed => '网络连接失败';

  @override
  String get exceptionCheckNetwork => '请检查网络连接是否正常';

  @override
  String get exceptionUploadError => '上传备份时发生错误';

  @override
  String get exceptionBackupError => '备份过程中发生错误';

  @override
  String get exceptionRestoreConfigInvalid => '恢复配置无效';

  @override
  String get exceptionUnsupportedBackupType => '不支持的备份类型';

  @override
  String get exceptionDownloadError => '下载备份时发生错误';

  @override
  String get exceptionRestoreDataFailed => '恢复数据失败';

  @override
  String get exceptionBackupCorrupted => '备份文件可能已损坏或密码错误';

  @override
  String get exceptionRestoreError => '恢复过程中发生错误';

  @override
  String get exceptionNoBackupFound => '没有找到备份文件';

  @override
  String get exceptionNoBackupWebDav => 'WebDAV 存储中没有找到备份文件，请确保已经执行过备份操作';

  @override
  String get exceptionNoBackupS3 => 'S3 存储中没有找到备份文件，请确保已经执行过备份操作';

  @override
  String get exceptionFormatMissingSalt => '备份文件格式错误：缺少盐值';

  @override
  String get exceptionFormatMissingData => '备份文件格式错误：缺少数据';

  @override
  String get exceptionDecryptFailed => '恢复数据解密失败，请确认备份密码是否正确。';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans(): super('zh_Hans');

  @override
  String get appTitle => 'EasyAuth';

  @override
  String get settingsTitle => '设置';

  @override
  String get aboutTitle => '关于';

  @override
  String get importExportTitle => '导入/导出';

  @override
  String get addManualTitle => '输入动态口令详情';

  @override
  String get addScanTitle => '扫描二维码';

  @override
  String get editTitle => '修改动态口令信息';

  @override
  String get exportTitle => '导出动态口令';

  @override
  String get importTitle => '导入动态口令';

  @override
  String get buttonSave => '保存';

  @override
  String get buttonCancel => '取消';

  @override
  String get buttonConfirm => '确认';

  @override
  String get buttonDelete => '删除';

  @override
  String get buttonImport => '导入';

  @override
  String get buttonExport => '导出';

  @override
  String get buttonRetry => '重试';

  @override
  String get buttonOK => '确定';

  @override
  String get buttonModify => '修改';

  @override
  String get buttonSelectAll => '全选';

  @override
  String get buttonRestore => '恢复';

  @override
  String get sectionBackupSettings => '备份设置';

  @override
  String get sectionSecuritySettings => '安全设置';

  @override
  String get sectionLanguage => '语言';

  @override
  String get labelIssuer => '发行者名称';

  @override
  String get hintIssuer => '例如：Google';

  @override
  String get labelAccountName => '动态口令名称';

  @override
  String get hintAccountName => '例如：user@example.com';

  @override
  String get labelSecretKey => '2FA密钥';

  @override
  String get hintSecretKey => 'Base32';

  @override
  String get labelSecretType => '密钥类型';

  @override
  String get secretTypeTime => '基于时间';

  @override
  String get secretTypeCounter => '基于计数器';

  @override
  String get labelCounterInitial => '计数器初始值';

  @override
  String get hintCounterInitial => '默认 0';

  @override
  String get labelBackupType => '备份类型';

  @override
  String get backupTypeOff => '关闭';

  @override
  String get backupTypeWebDAV => 'WebDAV';

  @override
  String get backupTypeS3 => '对象存储';

  @override
  String get labelBackupPassword => '备份密码';

  @override
  String get hintBackupPassword => '请设置备份加密密码';

  @override
  String get labelConfirmBackupPassword => '确认备份密码';

  @override
  String get hintConfirmBackupPassword => '请再次输入备份密码';

  @override
  String get labelHistoryCount => '保留历史版本数';

  @override
  String get hintHistoryCount => '默认 10，设为 0 则不限制';

  @override
  String get labelWebDavUrl => 'WebDAV地址';

  @override
  String get labelWebDavUsername => '授权账号';

  @override
  String get labelWebDavPassword => '授权密码';

  @override
  String get labelStoragePath => '存储路径';

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
  String get labelRegion => 'Region ( 选填，默认cn-east-1)';

  @override
  String get labelAppLock => '应用锁';

  @override
  String get labelScreenshotLock => '截屏锁';

  @override
  String get statusNotConfigured => '未配置';

  @override
  String get statusConfigured => '已配置';

  @override
  String get statusUnknownVersion => '未知';

  @override
  String get statusUnknownTime => '未知时间';

  @override
  String get biometricNotSupported => '设备不支持生物识别';

  @override
  String get androidOnly => '仅支持 Android';

  @override
  String get passwordAlreadySet => '备份密码已设置';

  @override
  String get passwordTipMessage => '备份密码用于加密备份文件。多台设备需设置相同密码才能共享备份。';

  @override
  String get httpsWarning => '建议使用 HTTPS 连接，HTTP 下凭据将明文传输';

  @override
  String get howToGetConfig => '如何获取配置信息';

  @override
  String get qiniuPromoTitle => '推荐使用七牛云对象存储';

  @override
  String get qiniuPromoLink => '立即注册七牛云，即获万元免费额度';

  @override
  String get validationRequired => '该字段不能为空';

  @override
  String get validationSecretRequired => '请输入2FA密钥';

  @override
  String get validationSecretInvalidBase32 => '无效的Base32密钥格式';

  @override
  String get validationCounterRequired => '请输入计数器值';

  @override
  String get validationCounterInvalidNumber => '请输入有效的数字';

  @override
  String get validationBackupPasswordRequired => '备份密码不能为空';

  @override
  String get validationBackupPasswordMinLength => '备份密码长度不能少于8位';

  @override
  String get validationConfirmPasswordRequired => '确认备份密码不能为空';

  @override
  String get validationPasswordMismatch => '两次输入的密码不一致';

  @override
  String get validationHistoryCountInvalid => '请输入不小于 0 的数字';

  @override
  String get validationWebDavUrlRequired => 'WebDAV地址不能为空';

  @override
  String get validationWebDavUsernameRequired => '授权账号不能为空';

  @override
  String get validationWebDavPasswordRequired => '授权密码不能为空';

  @override
  String get validationStoragePathRequired => '存储路径不能为空';

  @override
  String get validationEndpointRequired => 'Endpoint URL不能为空';

  @override
  String get validationAccessKeyRequired => 'Access Key ID不能为空';

  @override
  String get validationSecretKeyRequired => 'Secret Access Key不能为空';

  @override
  String get validationBucketNameRequired => 'Bucket Name不能为空';

  @override
  String get snackAddedSuccess => '添加成功';

  @override
  String get snackModifiedSuccess => '修改成功';

  @override
  String get snackBackupSuccess => '备份成功';

  @override
  String get snackBackupFailed => '备份失败';

  @override
  String get snackRestoreSuccess => '恢复成功';

  @override
  String get snackRestoreFailed => '恢复失败';

  @override
  String get snackSortSaved => '排序已保存';

  @override
  String get snackSortSaveFailed => '保存排序失败';

  @override
  String snackInitFailed(String error) {
    return '初始化失败: $error';
  }

  @override
  String snackLoadConfigFailed(String error) {
    return '加载配置失败: $error';
  }

  @override
  String snackSaveConfigFailed(String error) {
    return '保存配置失败: $error';
  }

  @override
  String get snackNotConfigured => '未配置备份参数';

  @override
  String get snackSelectBackupTypeFirst => '请先选择备份类型';

  @override
  String get snackConfigureBackupFirst => '请先配置完整的备份参数';

  @override
  String get snackScreenshotLockOn => '截屏锁已开启';

  @override
  String get snackScreenshotLockOff => '截屏锁已关闭';

  @override
  String snackScreenshotLockError(String error) {
    return '更新截屏锁状态失败: $error';
  }

  @override
  String get snackBiometricNotAvailable => '设备不支持生物识别，无法开启应用锁';

  @override
  String get snackAppLockEnabled => '应用锁已开启';

  @override
  String get snackAppLockDisabled => '应用锁已关闭';

  @override
  String get snackAppLockDisableFailed => '认证失败，无法关闭应用锁';

  @override
  String get snackDeleteSuccess => '删除成功';

  @override
  String get snackDeleteFailed => '删除失败';

  @override
  String snackLoadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String snackImportSuccess(int count) {
    return '成功导入 $count 个动态口令';
  }

  @override
  String get snackImportNone => '没有成功导入任何动态口令';

  @override
  String get snackImportError => '导入动态口令时出错';

  @override
  String get snackSelectAccountsToImport => '请选择要导入的动态口令';

  @override
  String get snackSelectAtLeastOne => '请至少选择一个动态口令';

  @override
  String get snackQrCodeGenerateError => '生成二维码时出错';

  @override
  String get dialogTitleDeleteAccount => '删除动态口令';

  @override
  String dialogConfirmDeleteAccount(String name) {
    return '确定要删除动态口令 \"$name\" 吗？';
  }

  @override
  String get dialogTitleConfirmRestore => '确认恢复';

  @override
  String get dialogConfirmRestoreBody => '恢复备份将覆盖当前数据，确定要继续吗？';

  @override
  String get dialogButtonConfirmRestore => '确定恢复';

  @override
  String get dialogTitleError => '错误';

  @override
  String get dialogTitleScanFailed => '扫描失败';

  @override
  String get dialogTitleQrCodeError => '二维码格式错误';

  @override
  String get dialogTitleConfirmDelete => '确认删除';

  @override
  String dialogConfirmDeleteBackups(int count) {
    return '确定要删除选中的 $count 个备份文件吗？此操作不可恢复。';
  }

  @override
  String dialogConfirmRestoreFile(String name) {
    return '确定要恢复到 \"$name\" 吗？\n恢复将覆盖当前所有数据。';
  }

  @override
  String get loadingConfig => '加载配置中...';

  @override
  String get loadingOperation => '正在执行操作...';

  @override
  String get loadingPleaseWait => '请稍候';

  @override
  String get loadingAuthenticating => '正在验证身份...';

  @override
  String get loadingAuthPrompt => '请验证您的生物识别信息';

  @override
  String get authReasonAccess => '请验证身份以访问应用';

  @override
  String get authReasonEnable => '请验证身份以开启应用锁';

  @override
  String get authReasonDisable => '请验证身份以关闭应用锁';

  @override
  String get emptyNoAccounts => '此处似乎尚无任何动态口令';

  @override
  String get emptyAddPrompt => '点击右下角 + 添加动态口令';

  @override
  String get emptyNoBackupFiles => '没有找到备份文件';

  @override
  String get hintSearch => '搜索...';

  @override
  String get drawerImportExport => '导入/导出';

  @override
  String get drawerSettings => '设置';

  @override
  String get drawerAbout => '关于';

  @override
  String get backupConfigTitle => '备份参数配置';

  @override
  String get backupToRemote => '备份到远端';

  @override
  String get restoreFromRemote => '从远端恢复';

  @override
  String get manageRemoteBackups => '管理远端备份';

  @override
  String get scanHintText => '将二维码放入框内即可自动扫描';

  @override
  String get exportScanPrompt => '请使用另一台设备扫描此二维码';

  @override
  String get fabScanQr => '扫描二维码';

  @override
  String get fabEnterKey => '输入2FA密钥';

  @override
  String hotpIncrementTooltip(int counter) {
    return '递增计数器 (当前: $counter)';
  }

  @override
  String get importExportDescription => '您可以将自己的动态口令转移到新设备中\n支持Google Authenticator的转移动态口令';

  @override
  String get exportAccounts => '导出动态口令';

  @override
  String get importAccounts => '导入动态口令';

  @override
  String get copyrightNotice => '2016-2026 EasyDebug.NET All rights reserved.';

  @override
  String get errorQrFormat => '二维码格式错误，必须是 otpauth:// 格式的URI';

  @override
  String get errorQrMissingSecret => '二维码缺少必要的密钥信息（secret）';

  @override
  String get errorSecretInvalidBase32 => '密钥格式无效，必须是Base32编码';

  @override
  String get errorCannotRecognizeQr => '无法识别此二维码';

  @override
  String get errorTotpOnly => '仅支持TOTP类型的动态口令，不支持HOTP';

  @override
  String get errorQrDataFormat => '二维码数据格式错误';

  @override
  String get errorInvalidMigrationQr => '无效的迁移二维码';

  @override
  String get errorInvalidQrDataFormat => '无效的二维码数据格式';

  @override
  String get errorCannotOpenUrl => '无法打开链接，请检查是否安装了浏览器';

  @override
  String errorOpenUrlFailed(String error) {
    return '打开链接失败: $error';
  }

  @override
  String get exceptionConfigInvalid => '备份配置无效';

  @override
  String get exceptionConfigCheckParams => '请检查备份参数是否完整';

  @override
  String get exceptionGenerateDataFailed => '生成备份数据失败';

  @override
  String get exceptionCannotReadAccounts => '无法读取动态口令数据';

  @override
  String get exceptionSetPasswordFirst => '请先设置备份密码';

  @override
  String get exceptionPasswordNotSet => '备份密码未设置';

  @override
  String get exceptionNetworkFailed => '网络连接失败';

  @override
  String get exceptionCheckNetwork => '请检查网络连接是否正常';

  @override
  String get exceptionUploadError => '上传备份时发生错误';

  @override
  String get exceptionBackupError => '备份过程中发生错误';

  @override
  String get exceptionRestoreConfigInvalid => '恢复配置无效';

  @override
  String get exceptionUnsupportedBackupType => '不支持的备份类型';

  @override
  String get exceptionDownloadError => '下载备份时发生错误';

  @override
  String get exceptionRestoreDataFailed => '恢复数据失败';

  @override
  String get exceptionBackupCorrupted => '备份文件可能已损坏或密码错误';

  @override
  String get exceptionRestoreError => '恢复过程中发生错误';

  @override
  String get exceptionNoBackupFound => '没有找到备份文件';

  @override
  String get exceptionNoBackupWebDav => 'WebDAV 存储中没有找到备份文件，请确保已经执行过备份操作';

  @override
  String get exceptionNoBackupS3 => 'S3 存储中没有找到备份文件，请确保已经执行过备份操作';

  @override
  String get exceptionFormatMissingSalt => '备份文件格式错误：缺少盐值';

  @override
  String get exceptionFormatMissingData => '备份文件格式错误：缺少数据';

  @override
  String get exceptionDecryptFailed => '恢复数据解密失败，请确认备份密码是否正确。';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant(): super('zh_Hant');

  @override
  String get appTitle => 'EasyAuth';

  @override
  String get settingsTitle => '設定';

  @override
  String get aboutTitle => '關於';

  @override
  String get importExportTitle => '匯入/匯出';

  @override
  String get addManualTitle => '輸入動態密碼詳情';

  @override
  String get addScanTitle => '掃描 QR 碼';

  @override
  String get editTitle => '修改動態密碼資訊';

  @override
  String get exportTitle => '匯出動態密碼';

  @override
  String get importTitle => '匯入動態密碼';

  @override
  String get buttonSave => '儲存';

  @override
  String get buttonCancel => '取消';

  @override
  String get buttonConfirm => '確認';

  @override
  String get buttonDelete => '刪除';

  @override
  String get buttonImport => '匯入';

  @override
  String get buttonExport => '匯出';

  @override
  String get buttonRetry => '重試';

  @override
  String get buttonOK => '確定';

  @override
  String get buttonModify => '修改';

  @override
  String get buttonSelectAll => '全選';

  @override
  String get buttonRestore => '還原';

  @override
  String get sectionBackupSettings => '備份設定';

  @override
  String get sectionSecuritySettings => '安全設定';

  @override
  String get sectionLanguage => '語言';

  @override
  String get labelIssuer => '發行者名稱';

  @override
  String get hintIssuer => '例如：Google';

  @override
  String get labelAccountName => '動態密碼名稱';

  @override
  String get hintAccountName => '例如：user@example.com';

  @override
  String get labelSecretKey => '2FA 金鑰';

  @override
  String get hintSecretKey => 'Base32';

  @override
  String get labelSecretType => '金鑰類型';

  @override
  String get secretTypeTime => '基於時間';

  @override
  String get secretTypeCounter => '基於計數器';

  @override
  String get labelCounterInitial => '計數器初始值';

  @override
  String get hintCounterInitial => '預設 0';

  @override
  String get labelBackupType => '備份類型';

  @override
  String get backupTypeOff => '關閉';

  @override
  String get backupTypeWebDAV => 'WebDAV';

  @override
  String get backupTypeS3 => '物件儲存';

  @override
  String get labelBackupPassword => '備份密碼';

  @override
  String get hintBackupPassword => '請設定備份加密密碼';

  @override
  String get labelConfirmBackupPassword => '確認備份密碼';

  @override
  String get hintConfirmBackupPassword => '請再次輸入備份密碼';

  @override
  String get labelHistoryCount => '保留歷史版本數';

  @override
  String get hintHistoryCount => '預設 10，設為 0 則不限制';

  @override
  String get labelWebDavUrl => 'WebDAV 位址';

  @override
  String get labelWebDavUsername => '授權帳號';

  @override
  String get labelWebDavPassword => '授權密碼';

  @override
  String get labelStoragePath => '儲存路徑';

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
  String get labelRegion => 'Region (選填，預設 cn-east-1)';

  @override
  String get labelAppLock => '應用程式鎖';

  @override
  String get labelScreenshotLock => '螢幕截圖鎖';

  @override
  String get statusNotConfigured => '未設定';

  @override
  String get statusConfigured => '已設定';

  @override
  String get statusUnknownVersion => '未知';

  @override
  String get statusUnknownTime => '未知時間';

  @override
  String get biometricNotSupported => '裝置不支援生物辨識';

  @override
  String get androidOnly => '僅支援 Android';

  @override
  String get passwordAlreadySet => '備份密碼已設定';

  @override
  String get passwordTipMessage => '備份密碼用於加密備份檔案。多台裝置需設定相同密碼才能共享備份。';

  @override
  String get httpsWarning => '建議使用 HTTPS 連線，HTTP 下憑證將明文傳輸';

  @override
  String get howToGetConfig => '如何取得設定資訊';

  @override
  String get qiniuPromoTitle => '推薦使用七牛雲物件儲存';

  @override
  String get qiniuPromoLink => '立即註冊七牛雲，即獲萬元免費額度';

  @override
  String get validationRequired => '此欄位不能為空';

  @override
  String get validationSecretRequired => '請輸入 2FA 金鑰';

  @override
  String get validationSecretInvalidBase32 => '無效的 Base32 金鑰格式';

  @override
  String get validationCounterRequired => '請輸入計數器值';

  @override
  String get validationCounterInvalidNumber => '請輸入有效的數字';

  @override
  String get validationBackupPasswordRequired => '備份密碼不能為空';

  @override
  String get validationBackupPasswordMinLength => '備份密碼長度不能少於 8 位';

  @override
  String get validationConfirmPasswordRequired => '確認備份密碼不能為空';

  @override
  String get validationPasswordMismatch => '兩次輸入的密碼不一致';

  @override
  String get validationHistoryCountInvalid => '請輸入不小於 0 的數字';

  @override
  String get validationWebDavUrlRequired => 'WebDAV 位址不能為空';

  @override
  String get validationWebDavUsernameRequired => '授權帳號不能為空';

  @override
  String get validationWebDavPasswordRequired => '授權密碼不能為空';

  @override
  String get validationStoragePathRequired => '儲存路徑不能為空';

  @override
  String get validationEndpointRequired => 'Endpoint URL 不能為空';

  @override
  String get validationAccessKeyRequired => 'Access Key ID 不能為空';

  @override
  String get validationSecretKeyRequired => 'Secret Access Key 不能為空';

  @override
  String get validationBucketNameRequired => 'Bucket Name 不能為空';

  @override
  String get snackAddedSuccess => '新增成功';

  @override
  String get snackModifiedSuccess => '修改成功';

  @override
  String get snackBackupSuccess => '備份成功';

  @override
  String get snackBackupFailed => '備份失敗';

  @override
  String get snackRestoreSuccess => '還原成功';

  @override
  String get snackRestoreFailed => '還原失敗';

  @override
  String get snackSortSaved => '排序已儲存';

  @override
  String get snackSortSaveFailed => '儲存排序失敗';

  @override
  String snackInitFailed(String error) {
    return '初始化失敗: $error';
  }

  @override
  String snackLoadConfigFailed(String error) {
    return '載入設定失敗: $error';
  }

  @override
  String snackSaveConfigFailed(String error) {
    return '儲存設定失敗: $error';
  }

  @override
  String get snackNotConfigured => '未設定備份參數';

  @override
  String get snackSelectBackupTypeFirst => '請先選擇備份類型';

  @override
  String get snackConfigureBackupFirst => '請先設定完整的備份參數';

  @override
  String get snackScreenshotLockOn => '螢幕截圖鎖已開啟';

  @override
  String get snackScreenshotLockOff => '螢幕截圖鎖已關閉';

  @override
  String snackScreenshotLockError(String error) {
    return '更新螢幕截圖鎖狀態失敗: $error';
  }

  @override
  String get snackBiometricNotAvailable => '裝置不支援生物辨識，無法開啟應用程式鎖';

  @override
  String get snackAppLockEnabled => '應用程式鎖已開啟';

  @override
  String get snackAppLockDisabled => '應用程式鎖已關閉';

  @override
  String get snackAppLockDisableFailed => '驗證失敗，無法關閉應用程式鎖';

  @override
  String get snackDeleteSuccess => '刪除成功';

  @override
  String get snackDeleteFailed => '刪除失敗';

  @override
  String snackLoadFailed(String error) {
    return '載入失敗: $error';
  }

  @override
  String snackImportSuccess(int count) {
    return '成功匯入 $count 個動態密碼';
  }

  @override
  String get snackImportNone => '沒有成功匯入任何動態密碼';

  @override
  String get snackImportError => '匯入動態密碼時發生錯誤';

  @override
  String get snackSelectAccountsToImport => '請選擇要匯入的動態密碼';

  @override
  String get snackSelectAtLeastOne => '請至少選擇一個動態密碼';

  @override
  String get snackQrCodeGenerateError => '產生 QR 碼時發生錯誤';

  @override
  String get dialogTitleDeleteAccount => '刪除動態密碼';

  @override
  String dialogConfirmDeleteAccount(String name) {
    return '確定要刪除動態密碼 \"$name\" 嗎？';
  }

  @override
  String get dialogTitleConfirmRestore => '確認還原';

  @override
  String get dialogConfirmRestoreBody => '還原備份將覆蓋目前資料，確定要繼續嗎？';

  @override
  String get dialogButtonConfirmRestore => '確定還原';

  @override
  String get dialogTitleError => '錯誤';

  @override
  String get dialogTitleScanFailed => '掃描失敗';

  @override
  String get dialogTitleQrCodeError => 'QR 碼格式錯誤';

  @override
  String get dialogTitleConfirmDelete => '確認刪除';

  @override
  String dialogConfirmDeleteBackups(int count) {
    return '確定要刪除選取的 $count 個備份檔案嗎？此操作無法復原。';
  }

  @override
  String dialogConfirmRestoreFile(String name) {
    return '確定要還原到 \"$name\" 嗎？\n還原將覆蓋目前所有資料。';
  }

  @override
  String get loadingConfig => '載入設定中...';

  @override
  String get loadingOperation => '正在執行操作...';

  @override
  String get loadingPleaseWait => '請稍候';

  @override
  String get loadingAuthenticating => '正在驗證身份...';

  @override
  String get loadingAuthPrompt => '請驗證您的生物辨識資訊';

  @override
  String get authReasonAccess => '請驗證身份以存取應用程式';

  @override
  String get authReasonEnable => '請驗證身份以開啟應用程式鎖';

  @override
  String get authReasonDisable => '請驗證身份以關閉應用程式鎖';

  @override
  String get emptyNoAccounts => '此處尚無任何動態密碼';

  @override
  String get emptyAddPrompt => '點擊右下角 + 新增動態密碼';

  @override
  String get emptyNoBackupFiles => '沒有找到備份檔案';

  @override
  String get hintSearch => '搜尋...';

  @override
  String get drawerImportExport => '匯入/匯出';

  @override
  String get drawerSettings => '設定';

  @override
  String get drawerAbout => '關於';

  @override
  String get backupConfigTitle => '備份參數設定';

  @override
  String get backupToRemote => '備份到遠端';

  @override
  String get restoreFromRemote => '從遠端還原';

  @override
  String get manageRemoteBackups => '管理遠端備份';

  @override
  String get scanHintText => '將 QR 碼放入框內即可自動掃描';

  @override
  String get exportScanPrompt => '請使用另一台裝置掃描此 QR 碼';

  @override
  String get fabScanQr => '掃描 QR 碼';

  @override
  String get fabEnterKey => '輸入 2FA 金鑰';

  @override
  String hotpIncrementTooltip(int counter) {
    return '遞增計數器 (目前: $counter)';
  }

  @override
  String get importExportDescription => '您可以將自己的動態密碼轉移到新裝置中\n支援 Google Authenticator 的轉移動態密碼';

  @override
  String get exportAccounts => '匯出動態密碼';

  @override
  String get importAccounts => '匯入動態密碼';

  @override
  String get copyrightNotice => '2016-2026 EasyDebug.NET All rights reserved.';

  @override
  String get errorQrFormat => 'QR 碼格式錯誤，必須是 otpauth:// 格式的 URI';

  @override
  String get errorQrMissingSecret => 'QR 碼缺少必要的金鑰資訊（secret）';

  @override
  String get errorSecretInvalidBase32 => '金鑰格式無效，必須是 Base32 編碼';

  @override
  String get errorCannotRecognizeQr => '無法識別此 QR 碼';

  @override
  String get errorTotpOnly => '僅支援 TOTP 類型的動態密碼，不支援 HOTP';

  @override
  String get errorQrDataFormat => 'QR 碼資料格式錯誤';

  @override
  String get errorInvalidMigrationQr => '無效的遷移 QR 碼';

  @override
  String get errorInvalidQrDataFormat => '無效的 QR 碼資料格式';

  @override
  String get errorCannotOpenUrl => '無法開啟連結，請檢查是否安裝了瀏覽器';

  @override
  String errorOpenUrlFailed(String error) {
    return '開啟連結失敗: $error';
  }

  @override
  String get exceptionConfigInvalid => '備份設定無效';

  @override
  String get exceptionConfigCheckParams => '請檢查備份參數是否完整';

  @override
  String get exceptionGenerateDataFailed => '產生備份資料失敗';

  @override
  String get exceptionCannotReadAccounts => '無法讀取動態密碼資料';

  @override
  String get exceptionSetPasswordFirst => '請先設定備份密碼';

  @override
  String get exceptionPasswordNotSet => '備份密碼未設定';

  @override
  String get exceptionNetworkFailed => '網路連線失敗';

  @override
  String get exceptionCheckNetwork => '請檢查網路連線是否正常';

  @override
  String get exceptionUploadError => '上傳備份時發生錯誤';

  @override
  String get exceptionBackupError => '備份過程中發生錯誤';

  @override
  String get exceptionRestoreConfigInvalid => '還原設定無效';

  @override
  String get exceptionUnsupportedBackupType => '不支援的備份類型';

  @override
  String get exceptionDownloadError => '下載備份時發生錯誤';

  @override
  String get exceptionRestoreDataFailed => '還原資料失敗';

  @override
  String get exceptionBackupCorrupted => '備份檔案可能已損壞或密碼錯誤';

  @override
  String get exceptionRestoreError => '還原過程中發生錯誤';

  @override
  String get exceptionNoBackupFound => '沒有找到備份檔案';

  @override
  String get exceptionNoBackupWebDav => 'WebDAV 儲存中沒有找到備份檔案，請確保已經執行過備份操作';

  @override
  String get exceptionNoBackupS3 => 'S3 儲存中沒有找到備份檔案，請確保已經執行過備份操作';

  @override
  String get exceptionFormatMissingSalt => '備份檔案格式錯誤：缺少鹽值';

  @override
  String get exceptionFormatMissingData => '備份檔案格式錯誤：缺少資料';

  @override
  String get exceptionDecryptFailed => '還原資料解密失敗，請確認備份密碼是否正確。';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }
}
