import 'unit_expr_problem.dart';
import 'symbol.dart';

/// ガチャで扱う最小単位（1つの式カード + その解答候補1つ）
class UnitGachaItem {
  final UnitExprProblem exprProblem;
  final UnitProblem unitProblem;

  const UnitGachaItem({required this.exprProblem, required this.unitProblem});
}




