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
    return {
      'isPurchased': true,
      'isFreeEnabled': true,
      'isEnabled': true,
    };
  }
  
  /// Pro版購入状態を確認
  static Future<bool> checkProVersionStatus() async {
    try {
      return await RevenueCatService.isProductPurchased('learning_history_management_option');
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
    // ProblemStatusに変換（できた=solved, できなかった=failed）
    final status = isCorrect ? ProblemStatus.solved : ProblemStatus.failed;

    // 学習記録を保存
    final history = await SimpleDataManager.getLearningHistory(unitProblem);
    final current = <Map<String, dynamic>>[];

    const slotCount = 3;
    for (var i = 0; i < slotCount; i++) {
      if (i < history.length) {
        final h = history[i];
        final status = ProblemStatus.values.firstWhere(
          (s) => s.name == h['status'],
          orElse: () => ProblemStatus.none,
        );
        final timeStr = h['time'] as String?;
        final byCalc = h['byCalculator'];
        current.add({
          'status': status,
          'time': timeStr,
          if (byCalc is bool) 'byCalculator': byCalc,
        });
      } else {
        current.add({'status': ProblemStatus.none, 'time': null, 'byCalculator': false});
      }
    }

    while (current.length < slotCount) {
      current.add({'status': ProblemStatus.none, 'time': null, 'byCalculator': false});
    }

    // 最初の空いているスロットを見つける
    int targetSlot = -1;
    for (var i = 0; i < slotCount; i++) {
      final slotStatus = current[i]['status'] as ProblemStatus? ?? ProblemStatus.none;
      if (slotStatus == ProblemStatus.none) {
        targetSlot = i;
        break;
      }
    }

    // すべてのスロットが埋まっている場合は、slot0に上書き
    if (targetSlot == -1) {
      targetSlot = 0;
    }

    // 新しい記録をスロットに保存
    final t = DateTime.now().toIso8601String();
    current[targetSlot] = {'status': status, 'time': t, 'byCalculator': byCalculator};

    // 保存したスロットより後ろをクリア（前詰め制約）
    for (var j = targetSlot + 1; j < current.length; j++) {
      current[j] = {'status': ProblemStatus.none, 'time': null, 'byCalculator': false};
    }

    // SimpleDataManagerに保存
    await SimpleDataManager.saveLearningHistory(unitProblem, current);
  }
}





