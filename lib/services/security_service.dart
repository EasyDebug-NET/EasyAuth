import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// 安全服务
///
/// 提供应用锁和生物识别认证相关功能
/// 采用单例模式，确保认证状态在整个应用中一致
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();

  factory SecurityService() {
    return _instance;
  }

  SecurityService._internal();

  /// 本地认证实例
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// 认证状态
  bool _isAuthenticated = false;

  /// 检查设备是否支持生物识别
  Future<bool> isBiometricAvailable() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      debugPrint(
        '生物识别检查: canCheckBiometrics=$canCheckBiometrics, isDeviceSupported=$isDeviceSupported',
      );
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint('生物识别检查异常: $e');
      return false;
    }
  }

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();
      debugPrint('可用的生物识别类型: $availableBiometrics');
      return availableBiometrics;
    } catch (e) {
      debugPrint('获取生物识别类型异常: $e');
      return [];
    }
  }

  /// 执行生物识别认证
  ///
  /// [reason] 认证原因
  /// [timeout] 认证超时时间（秒）
  /// 返回认证是否成功
  Future<bool> authenticate({required String reason, int timeout = 30}) async {
    try {
      // 检查是否支持生物识别
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      debugPrint(
        '认证前检查: canCheckBiometrics=$canCheckBiometrics, isDeviceSupported=$isDeviceSupported',
      );

      if (!canCheckBiometrics || !isDeviceSupported) {
        debugPrint('设备不支持生物识别');
        return false;
      }

      // 执行认证
      debugPrint('开始执行生物识别认证');
      bool result = await _localAuth.authenticate(localizedReason: reason);
      debugPrint('认证结果: $result');

      // 更新认证状态
      if (result) {
        _isAuthenticated = true;
      }

      return result;
    } catch (e) {
      debugPrint('认证异常: $e');
      return false;
    }
  }

  /// 获取当前认证状态
  bool get isAuthenticated => _isAuthenticated;

  /// 重置认证状态
  void resetAuthentication() {
    _isAuthenticated = false;
    debugPrint('认证状态已重置');
  }

  /// 检查是否需要认证
  ///
  /// [appLockEnabled] 应用锁是否启用
  /// 返回是否需要认证
  bool needsAuthentication(bool appLockEnabled) {
    return appLockEnabled && !_isAuthenticated;
  }

  /// 验证生物识别设置
  ///
  /// 返回是否已设置生物识别
  Future<bool> hasBiometricsEnrolled() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return false;
      }

      List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint('验证生物识别设置异常: $e');
      return false;
    }
  }
}
