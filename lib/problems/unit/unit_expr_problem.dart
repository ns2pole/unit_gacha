import 'symbol.dart';

/// EXPR（+meaning）単位の集約モデル。
/// - 1つのEXPR詳細ページ = 1つのUnitExprProblem
/// - 単位ごとの問題（解答候補）は unitProblems にぶら下げる
class UnitExprProblem {
  final String expr;
  final String? meaning;
  final String? meaningEn;
  final UnitCategory category;
  final List<SymbolDef> defs;
  final List<UnitProblem> unitProblems;

  const UnitExprProblem({
    required this.expr,
    required this.category,
    required this.defs,
    required this.unitProblems,
    this.meaning,
    this.meaningEn,
  });

  String? localizedMeaning(String languageCode) {
    if (languageCode == 'en' && (meaningEn ?? '').isNotEmpty) {
      return meaningEn;
    }
    return meaning;
  }
}



