// lib/pages/gacha/logic/completion_rate_calculator.dart
// 達成率計算ヘルパー

import '../../../problems/unit/symbol.dart' show UnitCategory;
import '../../../problems/unit/problems.dart' show unitExprProblems;
import '../../../services/problems/exclusion_logic.dart'
    show exclusionModeFromLatestN, isExprProblemFullyExcluded;
import '../pages/gacha_settings_page.dart' show GachaFilterMode;

/// 達成率計算結果
class CompletionRateResult {
  final int completedCount; // 達成した問題数
  final int totalCount; // 総問題数
  final double percentage; // 達成率（%）

  CompletionRateResult({
    required this.completedCount,
    required this.totalCount,
    required this.percentage,
  });
}

/// カテゴリー別の問題数統計
class CategoryProblemStats {
  final int totalCount; // 全問台数（B1~B4）
  final int satisfiedCount; // 条件を満たす問題数（A1~A4）
  final double ratio; // A/B の比率

  CategoryProblemStats({
    required this.totalCount,
    required this.satisfiedCount,
    required this.ratio,
  });
}

/// 達成率計算ヘルパークラス
class CompletionRateCalculator {
  /// 指定されたカテゴリーの達成率を計算
  ///
  /// 全問台数B1~B4（フィルタリングやセレクタの状態は無視）と
  /// 最新N回分の条件を満たす問題数A1~A4の比率（A1/B1~A4/B4）を計算
  ///
  /// [category] カテゴリー（力学、熱力学、波動、電磁気学）
  /// [gachaFilterMode] フィルタリングモード（最新N回分のNを取得するため）
  /// [selectedCategories] 選択されたカテゴリー（この計算では使用しない）
  static Future<CompletionRateResult> calculateCompletionRate({
    required UnitCategory category,
    required GachaFilterMode gachaFilterMode,
    required Set<UnitCategory> selectedCategories,
  }) async {
    // 最新N回分のNを取得
    final latestN = getLatestNFromFilterMode(gachaFilterMode);

    // 全問台数B1~B4を取得（フィルタリングやセレクタの状態は無視）
    final totalCounts = getTotalProblemCountsByCategory();
    final totalCount = totalCounts[category] ?? 0;

    if (totalCount == 0) {
      return CompletionRateResult(
        completedCount: 0,
        totalCount: 0,
        percentage: 0.0,
      );
    }

    // 最新N回分の条件を満たす問題数A1~A4を計算
    final satisfiedCount = await countSatisfiedProblemsByLatestN(
      category: category,
      latestN: latestN,
    );

    // 達成率を計算（A/B * 100）
    final percentage = (satisfiedCount / totalCount) * 100.0;

    return CompletionRateResult(
      completedCount: satisfiedCount,
      totalCount: totalCount,
      percentage: percentage,
    );
  }

  /// GachaFilterModeから最新N回分のNを取得
  /// randomの場合は1を返す
  static int getLatestNFromFilterMode(GachaFilterMode gachaFilterMode) {
    switch (gachaFilterMode) {
      case GachaFilterMode.excludeSolvedGE1:
        return 1;
      case GachaFilterMode.excludeSolvedGE2:
        return 2;
      case GachaFilterMode.excludeSolvedGE3:
        return 3;
      case GachaFilterMode.random:
        return 1; // randomの場合は1として扱う
      default:
        return 1;
    }
  }

  /// 4単元ごとの全問台数B1~B4を取得（フィルタリングやセレクタの状態は関係ない）
  static Map<UnitCategory, int> getTotalProblemCountsByCategory() {
    final counts = <UnitCategory, int>{};
    for (final category in UnitCategory.values) {
      counts[category] = unitExprProblems
          .where((ep) => ep.category == category)
          .length;
    }
    return counts;
  }

  /// 最新N回分の条件を満たす問題数を計算
  ///
  /// [category] カテゴリー
  /// [latestN] 最新N回分（1, 2, または3）
  static Future<int> countSatisfiedProblemsByLatestN({
    required UnitCategory category,
    required int latestN,
  }) async {
    final categoryExprs = unitExprProblems
        .where((ep) => ep.category == category)
        .toList();

    if (categoryExprs.isEmpty) {
      return 0;
    }

    final exclusionMode = exclusionModeFromLatestN(latestN);
    var satisfiedCount = 0;
    for (final ep in categoryExprs) {
      if (await isExprProblemFullyExcluded(ep, exclusionMode)) {
        satisfiedCount++;
      }
    }

    return satisfiedCount;
  }

  /// カテゴリー別の問題数統計を計算
  ///
  /// [gachaFilterMode] フィルタリングモード（最新N回分のNを取得するため）
  static Future<Map<UnitCategory, CategoryProblemStats>>
  calculateCategoryStats({required GachaFilterMode gachaFilterMode}) async {
    // 最新N回分のNを取得
    final latestN = getLatestNFromFilterMode(gachaFilterMode);

    // 4単元ごとの全問台数B1~B4を取得
    final totalCounts = getTotalProblemCountsByCategory();

    // 各カテゴリーについて、条件を満たす問題数A1~A4を計算
    final stats = <UnitCategory, CategoryProblemStats>{};
    for (final category in UnitCategory.values) {
      final totalCount = totalCounts[category] ?? 0;
      final satisfiedCount = await countSatisfiedProblemsByLatestN(
        category: category,
        latestN: latestN,
      );
      final ratio = totalCount > 0 ? satisfiedCount / totalCount : 0.0;

      stats[category] = CategoryProblemStats(
        totalCount: totalCount,
        satisfiedCount: satisfiedCount,
        ratio: ratio,
      );
    }

    return stats;
  }
}


