// 単位ガチャページの学習履歴関連

import '../../../services/problems/simple_data_manager.dart';
import '../../../problems/unit/symbol.dart' show UnitProblem;
import '../../common/problem_status.dart';

/// 学習履歴管理クラス
class UnitGachaHistoryManager {
  /// 学習履歴オプションの購入状態を確認（現状は常に有効）
  static Future<Map<String, bool>> checkLearningHistoryOptionStatus() async {
    return {'isPurchased': true, 'isFreeEnabled': true, 'isEnabled': true};
  }

  /// Pro 相当の機能有効フラグ（現状は常に有効）
  static Future<bool> checkProVersionStatus() async {
    return true;
  }

  /// 学習記録を保存
  static Future<void> saveLearningRecord({
    required UnitProblem unitProblem,
    required bool isCorrect,
    bool byCalculator = false,
  }) async {
    final status = isCorrect ? ProblemStatus.solved : ProblemStatus.failed;
    await SimpleDataManager.saveLearningRecord(
      unitProblem,
      status,
      byCalculator: byCalculator,
    );
  }
}
