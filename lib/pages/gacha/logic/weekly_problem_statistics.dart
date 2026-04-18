// lib/pages/gacha/logic/weekly_problem_statistics.dart
// 週ごとの問題統計

import 'package:flutter/material.dart';

import '../../../problems/unit/problems.dart' show unitGachaItems;
import '../../../problems/unit/symbol.dart' show UnitCategory;
import '../../../services/problems/simple_data_manager.dart';
import '../../common/problem_status.dart';
import '../../../managers/app_logger.dart';

/// 1日の統計データ
class DailyStatistics {
  final DateTime date;
  final int solvedCount;
  final int failedCount;

  DailyStatistics({
    required this.date,
    required this.solvedCount,
    required this.failedCount,
  });
}

/// 週間の学習履歴（正解/不正解）の1レコード
/// - expr: 数式（例: "m*g"）
/// - time: 記録時刻（ISO文字列をDateTime.parseしたもの）
/// - status: solved / failed
class WeeklyExerciseRecord {
  final String expr;
  final String answer; // UnitProblem.answer（単位文字列）
  final UnitCategory category;
  final DateTime time;
  final ProblemStatus status;

  WeeklyExerciseRecord({
    required this.expr,
    required this.answer,
    required this.category,
    required this.time,
    required this.status,
  });
}

/// 週ごとの問題統計を計算するクラス
class WeeklyProblemStatistics {
  static const int _daysInWeek = 7;
  static const int _daysToSunday = 6;
  /// 指定された週の日付範囲を取得
  /// [weekOffset] 0が今週、-1が先週、1が来週
  static DateTimeRange getWeekRange(int weekOffset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 今週の月曜日を取得（月曜日を週の始まりとする）
    final weekday = today.weekday; // 1=月曜日, 7=日曜日
    final daysFromMonday = weekday - 1;
    final monday = today.subtract(Duration(days: daysFromMonday));
    
    // 週オフセットを適用
    final targetMonday = monday.add(Duration(days: weekOffset * _daysInWeek));
    final targetSunday = targetMonday.add(const Duration(days: _daysToSunday));
    
    return DateTimeRange(start: targetMonday, end: targetSunday);
  }

  /// 指定された週の日付別統計を計算
  static Future<List<DailyStatistics>> calculateWeeklyStatistics(int weekOffset) async {
    final weekRange = getWeekRange(weekOffset);
    final dailyStats = _initializeDailyStats(weekRange);
    
    // 全問題の学習履歴を取得
    for (final item in unitGachaItems) {
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
        _updateDailyStatistics(dailyStats, recordDate, status);
      }
    }
    
    // 日付順にソートして返す
    final sortedDates = dailyStats.keys.toList()..sort();
    return sortedDates.map((date) => dailyStats[date]!).toList();
  }

  /// 指定された週の「正解した数式」「不正解だった数式」を新しい順で返す
  ///
  /// - 週の判定は「日付（yyyy-MM-dd）」で行い、週範囲（start〜end）に含まれるものを対象
  /// - 正解/不正解以外（none/understood等）は対象外
  static Future<({List<WeeklyExerciseRecord> solved, List<WeeklyExerciseRecord> failed})>
      calculateWeeklyExerciseRecords(int weekOffset) async {
    final weekRange = getWeekRange(weekOffset);

    final solved = <WeeklyExerciseRecord>[];
    final failed = <WeeklyExerciseRecord>[];

    for (final gachaItem in unitGachaItems) {
      final history = await SimpleDataManager.getLearningHistory(gachaItem.unitProblem);

      for (final record in history) {
        final timeStr = record['time'] as String?;
        if (timeStr == null || timeStr.isEmpty) continue;

        DateTime recordTime;
        try {
          recordTime = DateTime.parse(timeStr);
        } catch (e) {
          AppLogger.warning(
            '日付のパースに失敗しました',
            details: 'timeStr: $timeStr, error: $e',
          );
          continue;
        }

        final recordDate = DateTime(recordTime.year, recordTime.month, recordTime.day);
        if (!_isInWeekRange(recordDate, weekRange)) continue;

        final status = _parseProblemStatus(record['status'] as String?);
        if (status == null) continue;

        final exerciseRecord = WeeklyExerciseRecord(
          expr: gachaItem.exprProblem.expr,
          answer: gachaItem.unitProblem.answer,
          category: gachaItem.exprProblem.category,
          time: recordTime,
          status: status,
        );

        if (status == ProblemStatus.solved) {
          solved.add(exerciseRecord);
        } else if (status == ProblemStatus.failed) {
          failed.add(exerciseRecord);
        }
      }
    }

    solved.sort((a, b) => b.time.compareTo(a.time));
    failed.sort((a, b) => b.time.compareTo(a.time));

    return (solved: solved, failed: failed);
  }

  /// 週の各日を初期化
  static Map<DateTime, DailyStatistics> _initializeDailyStats(DateTimeRange weekRange) {
    final dailyStats = <DateTime, DailyStatistics>{};
    for (int i = 0; i < _daysInWeek; i++) {
      final date = weekRange.start.add(Duration(days: i));
      dailyStats[date] = DailyStatistics(
        date: date,
        solvedCount: 0,
        failedCount: 0,
      );
    }
    return dailyStats;
  }

  /// 日付文字列をパースし、週の範囲内かチェック
  /// 範囲外の場合はnullを返す
  static DateTime? _parseRecordDate(String timeStr, DateTimeRange weekRange) {
    try {
      final recordTime = DateTime.parse(timeStr);
      final recordDate = DateTime(recordTime.year, recordTime.month, recordTime.day);
      
      // 週の範囲内かチェック（早期除外）
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

  /// 該当日の統計を更新
  static void _updateDailyStatistics(
    Map<DateTime, DailyStatistics> dailyStats,
    DateTime recordDate,
    ProblemStatus status,
  ) {
    final stats = dailyStats[recordDate];
    if (stats == null) return;
    
    switch (status) {
      case ProblemStatus.solved:
        dailyStats[recordDate] = DailyStatistics(
          date: stats.date,
          solvedCount: stats.solvedCount + 1,
          failedCount: stats.failedCount,
        );
        break;
      case ProblemStatus.failed:
        dailyStats[recordDate] = DailyStatistics(
          date: stats.date,
          solvedCount: stats.solvedCount,
          failedCount: stats.failedCount + 1,
        );
        break;
      default:
        // solved/failed以外は処理しない
        break;
    }
  }
}



