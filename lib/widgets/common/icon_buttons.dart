// lib/widgets/common/icon_buttons.dart
// 共通のアイコンボタンウィジェット

import 'package:flutter/material.dart';

class IconButtons {
  /// 円形のアイコンボタンを構築
  static Widget buildCircleIconButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.orange.shade100 : Colors.grey.shade200,
            border: Border.all(
              color: active ? Colors.orange.shade400 : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: active ? Colors.orange.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(
      message: tooltip,
      child: button,
    );
  }

  /// 四角形のアイコンボタンを構築
  static Widget buildSquareIconButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active ? Colors.orange.shade100 : Colors.grey.shade200,
            border: Border.all(
              color: active ? Colors.orange.shade400 : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 28,
            color: active ? Colors.orange.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(
      message: tooltip,
      child: button,
    );
  }
}





