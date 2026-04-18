// lib/pages/gacha/unit_gacha_problem_manager.dart
// 単位ガチャページの問題管理関連

import 'dart:math';
import '../../../problems/unit/problems.dart' show unitExprProblems;
import '../../../problems/unit/symbol.dart' show UnitCategory, UnitProblem;
import '../../../problems/unit/unit_expr_problem.dart' show UnitExprProblem;
import '../../../problems/unit/unit_gacha_item.dart' show UnitGachaItem;
import '../../../widgets/unit/unit_calculator.dart' show CalculatorType;
import '../../../localization/app_localizations.dart';
import '../../../services/problems/exclusion_logic.dart'
    show shouldExcludeByMode, ExclusionMode;
import '../../../services/payment/problem_access_service.dart';
import '../pages/gacha_settings_page.dart'
    show GachaFilterMode, GachaFilterModeConversion;

/// 問題管理クラス
class UnitGachaProblemManager {
  final Random _rand = Random();
  final AppLocalizations _l10n;

  UnitGachaProblemManager(this._l10n);

  /// UnitProblemのanswer文字列から電卓タイプを自動決定
  CalculatorType determineCalculatorType(String answer) {
    // スペースや^を含む場合は基本単位系
    if (answer.contains(' ') || answer.contains('^')) {
      return CalculatorType.baseUnits;
    }
    // 短い文字列（通常は1-3文字）の場合は1文字単位
    // ただし、"N m"のような複合単位の可能性もあるので、スペースチェックを優先
    return CalculatorType.singleUnit;
  }

  /// カテゴリーフィルタリングを適用
  List<UnitExprProblem> _filterByCategories(
    List<UnitExprProblem> problems,
    Set<UnitCategory> selectedCategories,
  ) {
    if (selectedCategories.isEmpty) {
      return problems;
    }
    return problems
        .where(
          (exprProblem) => selectedCategories.contains(exprProblem.category),
        )
        .toList();
  }

  Future<List<UnitProblem>> _filterUnitProblemsByExclusionMode(
    List<UnitProblem> problems,
    GachaFilterMode gachaFilterMode,
  ) async {
    if (gachaFilterMode == GachaFilterMode.random) return problems;
    final exclusionMode = gachaFilterMode.toExclusionMode();

    final filtered = <UnitProblem>[];
    for (final p in problems) {
      if (!await shouldExcludeByMode(p, exclusionMode)) {
        filtered.add(p);
      }
    }
    return filtered;
  }

  /// 問題をシャッフル（カテゴリーフィルタリング + 除外設定）
  ///
  /// [selectedCategories] 選択されたカテゴリー
  /// [gachaFilterMode] フィルタリングモード（除外設定）
  ///
  /// 戻り値: フィルタリング後の問題リスト（最大5問）
  Future<List<UnitGachaItem>> shuffleProblems(
    Set<UnitCategory> selectedCategories,
    GachaFilterMode gachaFilterMode,
  ) async {
    // ステップ1: カテゴリーフィルタリング
    var exprCandidates = _filterByCategories(
      unitExprProblems,
      selectedCategories,
    );
    if (exprCandidates.isEmpty) {
      exprCandidates = unitExprProblems; // フィルタ結果が空の場合は全問題を使用
    }

    // ステップ1.5: 課金ロックされた expr カードを除外（購入者のみ出題）
    final unlockedExpr = <UnitExprProblem>[];
    for (final ep in exprCandidates) {
      if (await ProblemAccessService.isExprProblemUnlocked(ep)) {
        unlockedExpr.add(ep);
      }
    }
    exprCandidates = unlockedExpr;

    if (exprCandidates.isEmpty) {
      return [];
    }

    // ステップ2: 各exprカードごとに、除外判定後の候補から1つ選ぶ
    final selected = <UnitGachaItem>[];
    for (final exprProblem in exprCandidates) {
      final candidates = await _filterUnitProblemsByExclusionMode(
        exprProblem.unitProblems,
        gachaFilterMode,
      );
      if (candidates.isEmpty) continue;
      final chosen = candidates[_rand.nextInt(candidates.length)];
      selected.add(
        UnitGachaItem(exprProblem: exprProblem, unitProblem: chosen),
      );
    }

    // ステップ3: より確実にランダムにシャッフルするため、複数回シャッフル
    final shuffled = List<UnitGachaItem>.from(selected);
    for (var i = 0; i < 3; i++) {
      shuffled.shuffle(_rand);
    }

    // ステップ4: 5問に制限
    return shuffled.length > 5 ? shuffled.sublist(0, 5) : shuffled;
  }

  /// 選択されたカテゴリー内に、ロックされていない問題が1つでもあるか確認
  Future<bool> hasAnyUnlockedProblems(Set<UnitCategory> selectedCategories) async {
    final exprCandidates = _filterByCategories(unitExprProblems, selectedCategories);
    if (exprCandidates.isEmpty) return false;

    for (final ep in exprCandidates) {
      if (await ProblemAccessService.isExprProblemUnlocked(ep)) {
        return true;
      }
    }
    return false;
  }

  /// 全問題数を取得（カテゴリーフィルタリング後の実際の問題数）
  /// 実際の問題数（同じexprとmeaningを持つUnitProblemの数を合計）を返す
  int getTotalProblemCount(Set<UnitCategory> selectedCategories) {
    final filtered = _filterByCategories(unitExprProblems, selectedCategories);
    var total = 0;
    for (final ep in filtered) {
      total += ep.unitProblems.length;
    }
    return total;
  }
}
