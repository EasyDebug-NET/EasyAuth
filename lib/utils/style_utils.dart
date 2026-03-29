import 'package:flutter/material.dart';

/// 样式工具类
///
/// 统一管理应用中使用的样式，包括图标、按钮等，确保样式一致性。
class StyleUtils {
  /// 主要按钮样式
  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// 左对齐主要按钮样式（用于设置页面）
  static ButtonStyle primaryButtonStyleLeft(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
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

  /// 箭头返回图标
  static const Icon backIcon = Icon(Icons.arrow_back);

  /// 手电筒图标
  static const Icon flashIcon = Icon(Icons.flash_on);

  /// 添加图标（白色）
  static const Icon addIcon = Icon(Icons.add, color: Colors.white);

  /// 二维码扫描图标
  static const Icon qrScannerIcon = Icon(Icons.qr_code_scanner);

  /// 键盘图标
  static const Icon keyboardIcon = Icon(Icons.keyboard);

  /// 交换图标
  static const Icon swapIcon = Icon(Icons.swap_horiz);

  /// 设置图标
  static const Icon settingsIcon = Icon(Icons.settings);

  /// 编辑图标
  static const Icon editIcon = Icon(Icons.edit, color: Colors.white, size: 24);

  /// 删除图标
  static const Icon deleteIcon = Icon(
    Icons.delete,
    color: Colors.white,
    size: 24,
  );

  /// 信息图标
  static const Icon infoIcon = Icon(
    Icons.info_outline,
    size: 16,
    color: Colors.grey,
  );
}
