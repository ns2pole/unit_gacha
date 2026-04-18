// lib/pages/gacha/logic/completion_rate_calculator.dart
// 達成率計算ヘルパー

import '../../../problems/unit/symbol.dart' show UnitCategory, UnitProblem;
import '../../../problems/unit/problems.dart' show unitGachaItems;
import '../../../services/problems/simple_data_manager.dart';
import '../../../services/problems/exclusion_logic.dart'
    show ExclusionMode, sortHistoryByTimeNewestFirst;
import '../pages/gacha_settings_page.dart'
    show GachaFilterMode, GachaFilterModeConversion;

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

  /// 問題が達成状態かどうかを判定
  ///
  /// [problem] 判定する問題
  /// [gachaFilterMode] フィルタリングモード（達成判定の基準）
  static Future<bool> _isProblemCompleted(
    UnitProblem problem,
    GachaFilterMode gachaFilterMode,
  ) async {
    // randomモードの場合は、excludeSolvedGE1と同じロジックを使用
    if (gachaFilterMode == GachaFilterMode.random) {
      return await _isProblemCompleted(
        problem,
        GachaFilterMode.excludeSolvedGE1,
      );
    }

    // 学習履歴を取得
    final history = await SimpleDataManager.getLearningHistory(problem);
    if (history.isEmpty) {
      return false;
    }

    // 時刻でソート（最新が先頭になるように）
    final reversed = sortHistoryByTimeNewestFirst(history);

    // 必要な連続solved数を取得
    final needed = gachaFilterMode == GachaFilterMode.excludeSolvedGE1
        ? 1
        : gachaFilterMode == GachaFilterMode.excludeSolvedGE2
        ? 2
        : gachaFilterMode == GachaFilterMode.excludeSolvedGE3
        ? 3
        : 1;

    // 最新から順に、solvedが連続して何個並んでいるかを数える
    int count = 0;
    for (final record in reversed) {
      final statusStr = record['status'] as String?;
      if (statusStr == 'solved') {
        count++;
      } else if (statusStr != null && statusStr != 'none') {
        // solved以外のステータスが来たら連続が途切れる
        break;
      }
    }

    // 連続数がneeded以上なら達成
    return count >= needed;
  }

  /// 除外判定（exclusion_logic.dartのshouldExcludeByModeと同じロジック）
  static Future<bool> _shouldExcludeByMode(
    UnitProblem problem,
    ExclusionMode exclusionMode,
  ) async {
    // 除外モードがnoneの場合は除外しない
    if (exclusionMode == ExclusionMode.none) {
      return false;
    }

    // neededの値を取得
    final needed = exclusionMode == ExclusionMode.latest1
        ? 1
        : exclusionMode == ExclusionMode.latest2
        ? 2
        : exclusionMode == ExclusionMode.latest3
        ? 3
        : 0;

    if (needed == 0) {
      return false;
    }

    // 学習履歴を取得
    final history = await SimpleDataManager.getLearningHistory(problem);
    if (history.isEmpty) {
      return false;
    }

    // 時刻でソート（最新が先頭になるように）
    final reversed = sortHistoryByTimeNewestFirst(history);

    // 最新から順に、solvedが連続して何個並んでいるかを数える
    int count = 0;
    for (final record in reversed) {
      final statusStr = record['status'] as String?;
      if (statusStr == 'solved') {
        count++;
      } else if (statusStr != null && statusStr != 'none') {
        // solved以外のステータスが来たら連続が途切れる
        break;
      }
    }

    // 連続数がneeded以上なら除外
    return count >= needed;
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
      counts[category] =
          unitGachaItems.where((i) => i.exprProblem.category == category).length;
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
    // 指定カテゴリーの問題を取得（フィルタリングなし）
    final categoryProblems = unitGachaItems
        .where((i) => i.exprProblem.category == category)
        .map((i) => i.unitProblem)
        .toList();

    if (categoryProblems.isEmpty) {
      return 0;
    }

    int satisfiedCount = 0;
    for (final problem in categoryProblems) {
      // 学習履歴を取得
      final history = await SimpleDataManager.getLearningHistory(problem);
      if (history.isEmpty) {
        continue;
      }

      // 時刻でソート（最新が先頭になるように）
      final reversed = sortHistoryByTimeNewestFirst(history);

      // 最新から順に、solvedが連続して何個並んでいるかを数える
      int count = 0;
      for (final record in reversed) {
        final statusStr = record['status'] as String?;
        if (statusStr == 'solved') {
          count++;
        } else if (statusStr != null && statusStr != 'none') {
          // solved以外のステータスが来たら連続が途切れる
          break;
        }
      }

      // 連続数がlatestN以上なら条件を満たす
      if (count >= latestN) {
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


