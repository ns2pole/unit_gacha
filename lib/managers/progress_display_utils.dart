// lib/utils/progress_display_utils.dart
// 達成率表示用のユーティリティ

import '../models/math_problem.dart';
import '../pages/common/problem_status.dart';
import '../services/problems/simple_data_manager.dart';
import '../services/problems/exclusion_logic.dart' show shouldExcludeByMode;
import '../pages/gacha/pages/gacha_settings_page.dart';
import '../problems/unit/symbol.dart' show UnitProblem;
import '../problems/unit/problems.dart' show unitGachaItems;

/// 達成率情報
class ProgressInfo {
  final int achievedCount; // 達成数（除外された問題数）
  final int totalCount;
  final String filterDescription; // 例: "最新2回の" または "除外なし"
  final int filterCount; // フィルタリングの回数（1, 2, 3 または 0）

  ProgressInfo({
    required this.achievedCount,
    required this.totalCount,
    required this.filterDescription,
    required this.filterCount,
  });
}

/// スロット数（定数）
const int _slotCount = 3;

/// 実際のガチャの除外判定ロジックと同じ方法で問題をフィルタリングし、
/// フィルタリングに引っかかった問題数を返す
/// 単位ガチャの場合はUnitProblem単位でカウント（UnitProblemにつき1問）
Future<int> getFilteredProblemCount({
  required String prefsPrefix,
  required List<MathProblem> problemPool,
  required GachaFilterMode filterMode,
}) async {
  if (filterMode == GachaFilterMode.random) {
    return 0;
  }

  int needed = 0;
  switch (filterMode) {
    case GachaFilterMode.excludeSolvedGE1:
      needed = 1;
      break;
    case GachaFilterMode.excludeSolvedGE2:
      needed = 2;
      break;
    case GachaFilterMode.excludeSolvedGE3:
      needed = 3;
      break;
    default:
      return 0;
  }

  // 単位ガチャの場合は実際の問題数をカウント（同じexprとmeaningを持つUnitProblemの数を合計）
  if (prefsPrefix == 'unit') {
    final exclusionMode = filterMode.toExclusionMode();
    final nonExcludedProblems = <UnitProblem>[];
    for (final item in unitGachaItems) {
      final shouldExclude = await shouldExcludeByMode(
        item.unitProblem,
        exclusionMode,
      );
      if (!shouldExclude) nonExcludedProblems.add(item.unitProblem);
    }
    return nonExcludedProblems.length;
  }

  // それ以外の場合は従来通りMathProblem単位でカウント
  int filteredCount = 0;
  for (final problem in problemPool) {
    final shouldExclude = await _shouldExcludeProblemByGachaFilterMode(
      problem,
      filterMode,
      needed,
    );
    if (shouldExclude) {
      filteredCount++;
    }
  }

  return filteredCount;
}

/// 実際のガチャの除外判定ロジックを再現
/// gacha_page.dartの_shouldExcludeProblemと同じロジック
Future<bool> _shouldExcludeProblemByGachaFilterMode(
  MathProblem problem,
  GachaFilterMode filterMode,
  int needed,
) async {
  if (filterMode == GachaFilterMode.random) {
    return false;
  }

  // SimpleDataManagerから学習記録データを取得
  final slots = await _getSlotsForProblem(problem);

  // newest to oldest, collect non-none
  final nonNone = <ProblemStatus>[];
  for (var i = slots.length - 1; i >= 0; i--) {
    final st = slots[i]['status'] as ProblemStatus? ?? ProblemStatus.none;
    if (st != ProblemStatus.none) nonNone.add(st);
  }

  // 最新から見て、緑が連続して何個並んでいるかを数える
  int consecutiveSolved = 0;
  for (final status in nonNone) {
    if (status == ProblemStatus.solved) {
      consecutiveSolved++;
    } else {
      // 緑以外が来たら連続が途切れる
      break;
    }
  }

  // 連続数がneeded以上なら除外
  return consecutiveSolved >= needed;
}

/// 問題のスロットを取得（実際のガチャと同じロジック）
/// gacha_page.dartの_getSlotsForProblemと同じロジック
Future<List<Map<String, dynamic>>> _getSlotsForProblem(MathProblem p) async {
  // SimpleDataManagerから学習履歴を取得
  final history = await SimpleDataManager.getLearningHistory(p);

  final slots = <Map<String, dynamic>>[];

  // 履歴を逆順にして、最新の記録を左から表示
  final reversedHistory = history.reversed.toList();

  for (var i = 0; i < _slotCount; i++) {
    if (i < reversedHistory.length) {
      final h = reversedHistory[i];
      final status = ProblemStatus.values.firstWhere(
        (s) => s.name == h['status'],
        orElse: () => ProblemStatus.none,
      );
      final timeStr = h['time'] as String?;
      DateTime? dt;
      if (timeStr != null) {
        try {
          dt = DateTime.parse(timeStr);
        } catch (_) {
          dt = null;
        }
      }
      slots.add({'status': status, 'time': dt});
    } else {
      slots.add({'status': ProblemStatus.none, 'time': null});
    }
  }
  return slots;
}

/// ガチャの達成率情報を取得
Future<ProgressInfo> getGachaProgress({
  required String prefsPrefix,
  required List<MathProblem> problemPool,
}) async {
  // フィルタリング設定を取得
  final settings = await SimpleDataManager.getGachaSettings(prefsPrefix);
  final filterModeStr = settings['filterMode'] as String?;
  
  // 単位ガチャの場合は実際の問題数をカウント（同じexprとmeaningを持つUnitProblemの数を合計）、それ以外はproblemPool.length
  final totalCount = prefsPrefix == 'unit' 
      ? unitGachaItems.length 
      : problemPool.length;
  
  // filterModeが存在する場合はGachaFilterModeとして処理（全ガチャ共通）
  if (filterModeStr != null) {
    GachaFilterMode filterMode;
    switch (filterModeStr) {
      case 'exclude_solved_ge1':
        filterMode = GachaFilterMode.excludeSolvedGE1;
        break;
      case 'exclude_solved_ge2':
        filterMode = GachaFilterMode.excludeSolvedGE2;
        break;
      case 'exclude_solved_ge3':
        filterMode = GachaFilterMode.excludeSolvedGE3;
        break;
      case 'random':
      default:
        filterMode = GachaFilterMode.random;
        break;
    }

    // 除外判定を実行（達成数 = 除外された問題数）
    // 実際のガチャのフィルタリングロジックと同じ方法で計算
    // 完全ランダムの場合は最新1回の条件でフィルタリングして達成率を計算
    int needed = 0;
    GachaFilterMode actualFilterMode = filterMode;
    if (filterMode == GachaFilterMode.random) {
      needed = 1;
      actualFilterMode = GachaFilterMode.excludeSolvedGE1; // 最新1回の条件でフィルタリング
    } else {
      switch (filterMode) {
        case GachaFilterMode.excludeSolvedGE1:
          needed = 1;
          break;
        case GachaFilterMode.excludeSolvedGE2:
          needed = 2;
          break;
        case GachaFilterMode.excludeSolvedGE3:
          needed = 3;
          break;
        default:
          needed = 0;
      }
    }

    final achievedCount = await getFilteredProblemCount(
      prefsPrefix: prefsPrefix,
      problemPool: problemPool,
      filterMode: actualFilterMode,
    );

    final filterDescription = needed > 0 ? '最新$needed回の' : '除外なし';

    return ProgressInfo(
      achievedCount: achievedCount,
      totalCount: totalCount,
      filterDescription: filterDescription,
      filterCount: needed,
    );
  }

  // filterModeが存在しない場合は除外なしとして返す（最新1回で集計）
    // 最新1回の条件でフィルタリングして達成率を計算
    final achievedCount = await getFilteredProblemCount(
      prefsPrefix: prefsPrefix,
      problemPool: problemPool,
      filterMode: GachaFilterMode.excludeSolvedGE1,
    );
    
    return ProgressInfo(
      achievedCount: achievedCount,
      totalCount: totalCount,
      filterDescription: '最新1回の',
      filterCount: 1,
    );
}

