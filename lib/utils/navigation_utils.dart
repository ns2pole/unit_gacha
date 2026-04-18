// lib/utils/navigation_utils.dart
// ナビゲーション関連の共通ユーティリティ関数

import 'package:flutter/material.dart';
import '../problems/unit/unit_expr_problem.dart' show UnitExprProblem;
import '../pages/common/problem_status.dart';
import '../pages/problem/problem_detail_page.dart';
import '../pages/problem/problem_list_page.dart';
import '../pages/gacha/pages/gacha_settings_page.dart' show GachaFilterMode;
import '../problems/unit/symbol.dart' show UnitCategory;

/// 問題一覧ページに遷移する
Future<void> navigateToProblemList({
  required BuildContext context,
  required List<UnitExprProblem> problemPool,
  required String prefsPrefix,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProblemListPage(
        problemPool: problemPool,
        prefsPrefix: prefsPrefix,
        selectedCategories: const <UnitCategory>{},
        gachaFilterMode: GachaFilterMode.random,
      ),
    ),
  );
}

/// 問題詳細ページに遷移する（簡易版）
Future<void> navigateToProblemDetail({
  required BuildContext context,
  required UnitExprProblem exprProblem,
  required String prefsPrefix,
  List<Map<String, dynamic>>? initialHistory,
  int? displayNo,
  required void Function(int idx, ProblemStatus status) onAddSlot,
  required VoidCallback onClear,
}) async {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProblemDetailPage(
        exprProblem: exprProblem,
        prefsPrefix: prefsPrefix,
        initialHistory: initialHistory ?? const [],
        displayNo: displayNo,
        onAddSlot: onAddSlot,
        onClear: onClear,
      ),
    ),
  );
}
