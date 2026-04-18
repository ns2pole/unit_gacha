// lib/pages/common/tablet_utils.dart
// タブレット対応のサイズ感を提供する共通ユーティリティ

import 'package:flutter/material.dart';

/// タブレット対応のサイズ感を提供するクラス
class TabletUtils {
  /// タブレット判定（最短辺が600以上）
  static bool isTablet(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return screenSize.shortestSide >= 600;
  }

  /// カードサイズのスケール（タブレット: 2.0倍、スマホ: 1.0倍）
  static double cardScale(BuildContext context) {
    return isTablet(context) ? 2.0 : 1.0;
  }

  /// フォントサイズのスケール（タブレット: 1.2倍、スマホ: 1.0倍）
  static double fontSizeScale(BuildContext context) {
    return isTablet(context) ? 1.2 : 1.0;
  }

  /// 電卓サイズのスケール（タブレット: 1.4倍、スマホ: 0.8倍）
  static double calculatorScale(BuildContext context) {
    // スマホでも文字が見切れないようにしつつ、全体は少しだけコンパクトに
    return isTablet(context) ? 1.4 : 0.76;
  }

  /// 電卓フォントサイズのスケール（タブレット: 1.15倍、スマホ: 1.0倍）
  static double calculatorFontSizeScale(BuildContext context) {
    return isTablet(context) ? 1.15 : 1.0;
  }

  /// カードの横パディング（タブレット: 20、スマホ: 24）
  static double cardHorizontalPadding(BuildContext context) {
    return isTablet(context) ? 20.0 : 24.0;
  }

  /// カードの縦パディング（タブレット: 24、スマホ: 32）
  static double cardVerticalPadding(BuildContext context) {
    return isTablet(context) ? 24.0 : 32.0;
  }

  /// カード間のスペーシング（タブレット: 32、スマホ: 24）
  static double cardSpacing(BuildContext context) {
    return isTablet(context) ? 32.0 : 24.0;
  }

  /// Wrapのスペーシング（タブレット: 20、スマホ: 16）
  static double wrapSpacing(BuildContext context) {
    return isTablet(context) ? 20.0 : 16.0;
  }

  /// WrapのrunSpacing（タブレット: 10、スマホ: 8）
  static double wrapRunSpacing(BuildContext context) {
    return isTablet(context) ? 10.0 : 8.0;
  }

  /// 小さなスペーシング（タブレット: 6、スマホ: 4）
  static double smallSpacing(BuildContext context) {
    return isTablet(context) ? 6.0 : 4.0;
  }

  /// 電卓のパディング（タブレット: 12、スマホ: 16）
  static double calculatorPadding(BuildContext context) {
    return isTablet(context) ? 12.0 : 16.0;
  }

  /// 電卓の内部スペーシング（タブレット: 10、スマホ: 12）
  static double calculatorInternalSpacing(BuildContext context) {
    return isTablet(context) ? 10.0 : 12.0;
  }

  /// 電卓のプレビューエリアの横パディング（タブレット: 10、スマホ: 12）
  static double calculatorPreviewPadding(BuildContext context) {
    return isTablet(context) ? 10.0 : 12.0;
  }

  /// 確定ボタンの横パディング（タブレット: 28、スマホ: 32）
  static double confirmButtonHorizontalPadding(BuildContext context) {
    return isTablet(context) ? 28.0 : 32.0;
  }

  /// 確定ボタンの縦パディング（タブレット: 10、スマホ: 12）
  static double confirmButtonVerticalPadding(BuildContext context) {
    return isTablet(context) ? 10.0 : 12.0;
  }

  // ---- Calculator layout (UnitCalculator) ----
  // 「その場で数字を足す」ではなく、意図が分かる名前でまとめて管理する。

  /// 電卓プレビュー（入力欄）の高さ（スケール込み）
  static double calculatorPreviewHeight(BuildContext context) {
    final scale = calculatorScale(context);
    return 84.0 * scale;
  }

  /// 電卓キー（ボタン）の高さ（スケール込み）
  static double calculatorKeyHeight(BuildContext context) {
    final scale = calculatorScale(context);
    return (isTablet(context) ? 60.0 : 54.0) * scale;
  }

  /// 電卓キー間のギャップ（スケール込み）
  static double calculatorKeyGap(BuildContext context) {
    final scale = calculatorScale(context);
    return (isTablet(context) ? 8.0 : 6.0) * scale;
  }

  /// 電卓キーの内部パディング（スケール込み）
  static EdgeInsets calculatorKeyPadding(BuildContext context) {
    final scale = calculatorScale(context);
    final base = isTablet(context) ? 8.0 : 6.0;
    return EdgeInsets.symmetric(horizontal: base * scale, vertical: base * scale);
  }

  /// キーパッド左右の余白（親制約幅の中で使う分）
  static double calculatorKeypadHorizontalMargin(BuildContext context) {
    return isTablet(context) ? 12.0 : 6.0;
  }

  /// 問題カードの固定高さ（通常モード、タブレット: 600、スマホ: 400）
  static double problemCardHeight(BuildContext context, {bool isScratchPaperMode = false}) {
    if (isScratchPaperMode) {
      // 計算用紙モードでは少し詰める
      return isTablet(context) ? 200.0 : 180.0;
    }
    // 通常モード：記号定義が複数ある場合も考慮して大きめに
    return isTablet(context) ? 600.0 : 400.0;
  }

  /// 横長カードの固定高さ（計算用紙モード、タブレット: 280、スマホ: 200）
  static double horizontalCardHeight(BuildContext context) {
    return isTablet(context) ? 280.0 : 200.0;
  }
}
