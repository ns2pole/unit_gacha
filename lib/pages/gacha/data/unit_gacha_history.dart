// lib/pages/gacha/unit_gacha_history.dart
// 単位ガチャページの学習履歴関連

import 'package:flutter/material.dart';
import '../../../services/payment/revenuecat_service.dart';
import '../../../services/problems/simple_data_manager.dart';
import '../../../problems/unit/symbol.dart' show UnitProblem;
import '../../common/problem_status.dart';

/// 学習履歴管理クラス
class UnitGachaHistoryManager {
  /// 学習履歴オプションの購入状態を確認
  /// 常に有効として返す
  static Future<Map<String, bool>> checkLearningHistoryOptionStatus() async {
    // 学習履歴機能は常に有効
    return {'isPurchased': true, 'isFreeEnabled': true, 'isEnabled': true};
  }

  /// Pro版購入状態を確認
  static Future<bool> checkProVersionStatus() async {
    try {
      return await RevenueCatService.isProductPurchased(
        'learning_history_management_option',
      );
    } catch (e) {
      debugPrint('Error checking Pro version status: $e');
      return false;
    }
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
