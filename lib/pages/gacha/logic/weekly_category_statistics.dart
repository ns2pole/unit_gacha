// lib/pages/gacha/logic/weekly_category_statistics.dart
// 週ごとの単元別統計

import 'package:flutter/material.dart';

import '../../../problems/unit/problems.dart' show unitGachaItems;
import '../../../problems/unit/symbol.dart' show UnitCategory;
import '../../../services/problems/simple_data_manager.dart';
import '../../common/problem_status.dart';
import '../../../managers/app_logger.dart';
import 'weekly_problem_statistics.dart' show WeeklyProblemStatistics;

/// 単元ごとの週間統計データ
class CategoryWeeklyStats {
  final int solvedCount; // 正解数
  final int failedCount; // 不正解数
  final int totalCount; // 総問題数
  final double accuracyRate; // 正答率 (%)

  CategoryWeeklyStats({
    required this.solvedCount,
    required this.failedCount,
    required this.totalCount,
    required this.accuracyRate,
  });
}

/// 週ごとの単元別統計を計算するクラス
class WeeklyCategoryStatistics {
  /// 指定された週の単元別統計を計算
  /// [weekOffset] 0が今週、-1が先週、1が来週
  static Future<Map<UnitCategory, CategoryWeeklyStats>>
  calculateWeeklyCategoryStats(int weekOffset) async {
    final weekRange = WeeklyProblemStatistics.getWeekRange(weekOffset);

    // 各単元の統計を初期化
    final categoryStats = <UnitCategory, CategoryWeeklyStats>{};
    for (final category in UnitCategory.values) {
      categoryStats[category] = CategoryWeeklyStats(
        solvedCount: 0,
        failedCount: 0,
        totalCount: 0,
        accuracyRate: 0.0,
      );
    }

    // 全問題の学習履歴を取得
    for (final item in unitGachaItems) {
      final category = item.exprProblem.category;
      final history = await SimpleDataManager.getLearningHistory(item.unitProblem);

      for (final record in history) {
        final timeStr = record['time'] as String?;

        // 早期除外: timeが空の場合はスキップ
        if (timeStr == null || timeStr.isEmpty) continue;

        // 日付パースと範囲チェック
        final recordDate = _parseRecordDate(timeStr, weekRange);
        if (recordDate == null) continue;

        // ProblemStatus enumを使用して型安全に判定
        final status = _parseProblemStatus(record['status'] as String?);
        if (status == null) continue;

        // 統計を更新
        _updateCategoryStatistics(categoryStats, category, status);
      }
    }

    // 正答率を計算
    for (final category in UnitCategory.values) {
      final stats = categoryStats[category]!;
      final total = stats.solvedCount + stats.failedCount;
      final accuracyRate = total > 0
          ? (stats.solvedCount / total) * 100.0
          : 0.0;

      categoryStats[category] = CategoryWeeklyStats(
        solvedCount: stats.solvedCount,
        failedCount: stats.failedCount,
        totalCount: total,
        accuracyRate: accuracyRate,
      );
    }

    return categoryStats;
  }

  /// 日付文字列をパースし、週の範囲内かチェック
  /// 範囲外の場合はnullを返す
  static DateTime? _parseRecordDate(String timeStr, DateTimeRange weekRange) {
    try {
      final recordTime = DateTime.parse(timeStr);
      final recordDate = DateTime(
        recordTime.year,
        recordTime.month,
        recordTime.day,
      );

      // 週の範囲内かチェック
      if (!_isInWeekRange(recordDate, weekRange)) {
        return null;
      }

      return recordDate;
    } catch (e) {
      // 日付のパースエラーをログ出力（デバッグ用）
      AppLogger.warning(
        '日付のパースに失敗しました',
        details: 'timeStr: $timeStr, error: $e',
      );
      return null;
    }
  }

  /// 日付が週の範囲内かチェック
  static bool _isInWeekRange(DateTime date, DateTimeRange weekRange) {
    return !date.isBefore(weekRange.start) && !date.isAfter(weekRange.end);
  }

  /// 文字列からProblemStatusを取得（solved/failedのみ）
  /// それ以外の場合はnullを返す
  static ProblemStatus? _parseProblemStatus(String? statusStr) {
    if (statusStr == null) return null;

    final status = keyToStatus(statusStr);
    // solvedまたはfailedのみを対象とする
    if (status == ProblemStatus.solved || status == ProblemStatus.failed) {
      return status;
    }
    return null;
  }

  /// 該当単元の統計を更新
  static void _updateCategoryStatistics(
    Map<UnitCategory, CategoryWeeklyStats> categoryStats,
    UnitCategory category,
    ProblemStatus status,
  ) {
    final stats = categoryStats[category];
    if (stats == null) return;

    switch (status) {
      case ProblemStatus.solved:
        categoryStats[category] = CategoryWeeklyStats(
          solvedCount: stats.solvedCount + 1,
          failedCount: stats.failedCount,
          totalCount: stats.totalCount,
          accuracyRate: stats.accuracyRate,
        );
        break;
      case ProblemStatus.failed:
        categoryStats[category] = CategoryWeeklyStats(
          solvedCount: stats.solvedCount,
          failedCount: stats.failedCount + 1,
          totalCount: stats.totalCount,
          accuracyRate: stats.accuracyRate,
        );
        break;
      default:
        // solved/failed以外は処理しない
        break;
    }
  }
}


