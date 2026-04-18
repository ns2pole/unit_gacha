import 'symbol.dart';
import 'mechanics_problems.dart';
import 'electromagnetism_problems.dart';
import 'thermodynamics_problems.dart';
import 'waves_problems.dart';
import 'atom_problems.dart';
import 'unit_expr_problem.dart';
import 'unit_gacha_item.dart';

/// 全ての式（expr）問題を統合（これが主データ）
final unitExprProblems = <UnitExprProblem>[
  // 高校物理で学ぶ一般的な単元順に並べる（問題一覧の表示順）
  ...mechanicsExprProblems,
  ...thermodynamicsExprProblems,
  ...wavesExprProblems,
  ...electromagnetismExprProblems,
  ...atomExprProblems,
];

/// ガチャで扱う最小単位（UnitExprProblem × UnitProblem）をフラット化
final unitGachaItems = <UnitGachaItem>[
  for (final exprProblem in unitExprProblems)
    for (final unitProblem in exprProblem.unitProblems)
      UnitGachaItem(exprProblem: exprProblem, unitProblem: unitProblem),
];

/// 互換用：全ての UnitProblem をフラットに取得
/// - データの主は `unitExprProblems`
/// - これは `unitGachaItems` から導出するだけ（重複定義は持たない）
final unitProblems = <UnitProblem>[
  for (final item in unitGachaItems) item.unitProblem,
];
