// Verifies unit derivation across all UnitExprProblems.
//
// Run:
//   dart run tool/check_unit_explanations.dart
//
import '../lib/problems/unit/problems.dart';
import '../lib/services/calculator/unit_calculator_service.dart';

void main() {
  var totalExpr = 0;
  var totalUnitProblems = 0;
  var mismatchExpr = 0;
  var mismatchUnitProblems = 0;

  final samples = <String>[];

  for (final ep in unitExprProblems) {
    totalExpr++;
    final correct = UnitCalculatorService.calculateCorrectUnit(ep.expr, ep.defs);
    final correctStr = correct.toString().replaceAll('·', ' ');

    var okForThisExpr = false;
    for (final up in ep.unitProblems) {
      totalUnitProblems++;
      final ans = up.answer;
      final cand = NormalizedUnit.fromSingleUnit(ans);
      final ok = cand.equals(correct);
      if (!ok) mismatchUnitProblems++;
      if (ok) okForThisExpr = true;
    }

    if (!okForThisExpr) {
      mismatchExpr++;
      if (samples.length < 30) {
        final answers = ep.unitProblems.map((u) => u.answer).join(' / ');
        samples.add(
          '[${ep.category.name}] expr=${ep.expr}  correct=$correctStr  answers=$answers',
        );
      }
    }
  }

  print('Total exprProblems: $totalExpr');
  print('Total unitProblems: $totalUnitProblems');
  print('Expr with no matching answer: $mismatchExpr');
  print('UnitProblems mismatching correct: $mismatchUnitProblems');
  print('');
  if (samples.isNotEmpty) {
    print('--- first ${samples.length} mismatched expr samples ---');
    for (final s in samples) {
      print(s);
    }
  } else {
    print('All exprProblems have at least one matching answer.');
  }
}

