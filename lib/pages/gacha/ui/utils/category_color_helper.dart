// lib/pages/gacha/ui/utils/category_color_helper.dart
// 単元カテゴリーの色定義を統一管理

import 'package:flutter/material.dart';
import '../../../../problems/unit/symbol.dart' show UnitCategory;

/// 単元カテゴリーの色を取得
/// 単元セレクターで使用されている色をそのまま流用
Color getCategoryColor(UnitCategory category) {
  switch (category) {
    case UnitCategory.mechanics:
      // 力学: 紫
      return Colors.purple;
    case UnitCategory.thermodynamics:
      // 熱力学: 赤とオレンジのグラデーションの最初の色
      return const Color(0xFFFF5722);
    case UnitCategory.waves:
      // 波動: 水色
      return Colors.cyan;
    case UnitCategory.electromagnetism:
      // 電磁気学: 黄色
      return Colors.amber;
    case UnitCategory.atom:
      // 原子: 緑
      return Colors.green;
  }
}

/// 単元カテゴリーのボーダー色を取得
Color getCategoryBorderColor(UnitCategory category) {
  switch (category) {
    case UnitCategory.mechanics:
      return Colors.purple.shade700;
    case UnitCategory.thermodynamics:
      return const Color(0xFFFF5722);
    case UnitCategory.waves:
      return Colors.cyan.shade700;
    case UnitCategory.electromagnetism:
      return Colors.amber.shade700;
    case UnitCategory.atom:
      return Colors.green.shade700;
  }
}

/// 熱力学のグラデーションを取得
LinearGradient getThermodynamicsGradient() {
  return const LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}





