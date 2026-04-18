// lib/widgets/constants/app_constants.dart
// アプリ全体で使用する描画系・UI定数
import 'package:flutter/material.dart';

class AppConstants {
  // パディング
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;

  // フォントサイズ
  static const double largeFontSize = 18.0;
  static const double extraLargeFontSize = 24.0;

  // ボーダー半径
  static const double largeBorderRadius = 12.0;

  // 画像の最大幅比率
  static const double maxImageWidthRatio = 0.9;

  // 描画ツール用の色
  static const List<Color> availableColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.pink,
  ];

  // 描画ツール用の線の太さ
  static const List<double> strokeWidths = [
    1.0,
    2.0,
    3.0,
    4.0,
    5.0,
    8.0,
    10.0,
  ];
}












