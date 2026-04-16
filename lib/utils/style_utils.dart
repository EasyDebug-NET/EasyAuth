import 'package:flutter/material.dart';

/// 样式工具类
///
/// 统一管理应用中使用的样式，包括图标、按钮等，确保样式一致性。
class StyleUtils {
  /// 主要按钮样式
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// 左对齐主要按钮样式（用于设置页面）
  static ButtonStyle primaryButtonStyleLeft(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    );
  }

  /// 图标按钮样式
  static ButtonStyle iconButtonStyle() {
    return IconButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// 菜单图标
  static const Icon menuIcon = Icon(Icons.menu);

  /// 云图标
  static const Icon cloudIcon = Icon(Icons.cloud);

  /// 锁容器样式
  static BoxDecoration lockContainerStyle(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withAlpha(230),
      borderRadius: BorderRadius.circular(8),
    );
  }

  /// 锁文本样式
  static TextStyle lockTextStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
  }

  /// 次要按钮样式
  static ButtonStyle secondaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// 文本样式
  static TextStyle titleTextStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold);
  }

  static TextStyle subtitleTextStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle bodyTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!;
  }

  /// 间距常量
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  static const SizedBox smallSpacing = SizedBox(height: 8);
  static const SizedBox mediumSpacing = SizedBox(height: 16);
  static const SizedBox largeSpacing = SizedBox(height: 24);

  /// 输入框样式
  static InputDecoration inputDecoration(String labelText, String? hintText) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  /// 显示成功通知
  static void successSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 显示错误通知
  static void errorSnackBar(
    BuildContext context,
    String message, [
    String? details,
  ]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null)
              Text(
                details,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 显示普通通知
  static void normalSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
