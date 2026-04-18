// unit_gacha.dart
// 単位ガチャ

import 'package:flutter/material.dart';

import '../../localization/app_localizations.dart';
import 'problems.dart';
import 'symbol.dart';
import 'unit_expr_problem.dart';
import 'unit_gacha_item.dart';

/// 記号をTeX形式に変換する関数（記号定義用）
/// 例: k_0 → k_{0}, mu_0 → \mu_{0}, epsilon_0 → \epsilon_{0}
String _formatSymbolToTex(String symbol) {
  String formatted = symbol;

  // mu_0 のような形式（アンダースコア付きの下付き文字）を処理
  formatted = formatted.replaceAllMapped(
    RegExp(r'\bmu_(\d+)\b'),
    (match) => r'\mu_{' + match.group(1)! + r'}',
  );

  // epsilon_0 のような形式（アンダースコア付きの下付き文字）を処理
  formatted = formatted.replaceAllMapped(
    RegExp(r'\bepsilon_(\d+)\b'),
    (match) => r'\epsilon_{' + match.group(1)! + r'}',
  );

  // k_0 のような形式（アンダースコア付きの下付き文字）を処理
  formatted = formatted.replaceAllMapped(RegExp(r'(\w)_(\d+)(?![\w}])'), (
    match,
  ) {
    return match.group(1)! + '_{' + match.group(2)! + '}';
  });

  // 下付き文字を処理（m1 → m_1, m2 → m_2, N1 → N_1, N2 → N_2）
  formatted = formatted.replaceAllMapped(RegExp(r'(\b\w+)(\d+)(?![\^\{_])'), (
    match,
  ) {
    final base = match.group(1)!;
    final sub = match.group(2)!;
    // μ0の場合は\mu_0として処理
    if (base == 'μ' || base.contains('μ')) {
      return r'\mu_{' + sub + r'}';
    }
    // ε0の場合は\epsilon_0として処理
    if (base == 'ε' || base.contains('ε')) {
      return r'\epsilon_{' + sub + r'}';
    }
    return base + '_{' + sub + '}';
  });

  // ε0を\epsilon_0に変換（特殊文字の処理）
  formatted = formatted.replaceAllMapped(
    RegExp(r'ε(\d+)'),
    (match) => r'\epsilon_{' + match.group(1)! + r'}',
  );

  // μ0を\mu_0に変換（特殊文字の処理）
  formatted = formatted.replaceAllMapped(
    RegExp(r'μ(\d+)'),
    (match) => r'\mu_{' + match.group(1)! + r'}',
  );

  // μを\muに変換
  formatted = formatted.replaceAllMapped(
    RegExp(r'μ([a-zA-Z])'),
    (match) => r'\mu_{' + match.group(1)! + r'}',
  );
  formatted = formatted.replaceAll('μ', r'\mu');

  // εを\epsilonに変換
  formatted = formatted.replaceAll('ε', r'\epsilon');

  // pi を \pi に変換
  formatted = formatted.replaceAllMapped(RegExp(r'\bpi\b'), (match) => r'\pi');

  return formatted;
}

// 単位ガチャの問題リスト（UnitExprProblem × UnitProblem のペアを返す）
List<UnitGachaItem> getUnitGachaProblems(AppLocalizations l10n) {
  return unitGachaItems;
}

// UnitProblemの総数を計算（実際に生成される問題数）
int getUnitProblemCount() {
  return unitGachaItems.length;
}

/// 実際の問題数を計算（同じexprとmeaningを持つUnitProblemの数を合計）
/// カード数ではなく、実際の問題数を返す
/// 注意: この関数はグループ化して各グループの長さを合計するが、
/// 実際には単にproblems.lengthを返すだけでよい（すべてのUnitProblemをカウント）
int getActualUnitProblemCount(List<UnitProblem> problems) {
  // 実際の問題数は単にproblemsの長さ（すべてのUnitProblemをカウント）
  // グループ化は不要。各UnitProblemは1つの問題を表す
  return problems.length;
}

// 単位ガチャの設定
Map<String, dynamic> unitGachaConfig(AppLocalizations l10n) => {
  'name': l10n.unitGachaName,
  'description': l10n.unitGachaDescription,
  'icon': Icons.straighten,
  'color': Colors.blue,
  'problems': getUnitGachaProblems(l10n),
};
