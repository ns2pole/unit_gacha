// lib/pages/gacha/unit_gacha_answer_handler.dart
// 単位ガチャページの解答処理関連

import '../../../problems/unit/symbol.dart' show UnitProblem;
import '../../../widgets/unit/unit_calculator.dart' show CalculatorType;
import '../../../services/calculator/unit_calculator_service.dart' show NormalizedUnit;
import '../data/unit_gacha_history.dart' show UnitGachaHistoryManager;
import '../../../services/problems/simple_data_manager.dart';

/// 解答処理クラス
class UnitGachaAnswerHandler {
  /// 解答を処理する
  /// 
  /// [input] ユーザー入力
  /// [currentProblem] 現在の問題
  /// [currentCalculatorType] 現在の電卓タイプ
  /// [isAnswered] 既に解答済みかどうか
  /// 
  /// 戻り値: (isAnswered, isCorrect, userInput, solvedCount)
  static AnswerResult handleAnswer({
    required String input,
    required UnitProblem currentProblem,
    required CalculatorType currentCalculatorType,
    required bool isAnswered,
    required int currentSolvedCount,
  }) {
    if (isAnswered) {
      return AnswerResult(
        isAnswered: true,
        isCorrect: false,
        userInput: input,
        solvedCount: currentSolvedCount,
      );
    }

    // 空欄での確定は正解とする
    if (input.trim().isEmpty) {
      return AnswerResult(
        isAnswered: true,
        isCorrect: true,
        userInput: '',
        solvedCount: currentSolvedCount + 1,
      );
    }
    
    // バックスラッシュを除去（入力文字列をクリーンアップ）
    final cleanedInput = input.trim().replaceAll('\\', '');
    
    // 正解の単位を計算（NormalizedUnit形式）
    final correctUnit = _calculateCorrectUnit(
      currentProblem.answer,
      currentCalculatorType,
    );
    
    // 入力と正解を比較
    final isCorrect = _compareAnswer(
      cleanedInput,
      correctUnit,
      currentCalculatorType,
    );

    return AnswerResult(
      isAnswered: true,
      isCorrect: isCorrect,
      userInput: input,
      solvedCount: currentSolvedCount + 1,
    );
  }

  /// 正解の単位を計算
  static NormalizedUnit _calculateCorrectUnit(
    String answer,
    CalculatorType calculatorType,
  ) {
    if (calculatorType == CalculatorType.singleUnit) {
      return NormalizedUnit.fromSingleUnit(answer);
    } else {
      return NormalizedUnit.fromString(answer);
    }
  }

  /// 入力と正解を比較
  static bool _compareAnswer(
    String cleanedInput,
    NormalizedUnit correctUnit,
    CalculatorType calculatorType,
  ) {
    if (calculatorType == CalculatorType.singleUnit) {
      // 1文字電卓：入力が1文字単位として正解と等価かチェック
      try {
        final userUnit = NormalizedUnit.fromSingleUnit(cleanedInput);
        return userUnit.equals(correctUnit);
      } catch (e) {
        // パースエラーの場合は不正解
        return false;
      }
    } else {
      // 基本単位系：入力が基本単位系として正解と等価かチェック
      // 複合単位（N m^-2など）も含めて正規化して比較
      try {
        final userUnit = NormalizedUnit.fromString(cleanedInput);
        return userUnit.equals(correctUnit);
      } catch (e) {
        // パースエラーの場合は不正解
        return false;
      }
    }
  }

  /// 学習記録を保存
  static Future<void> saveLearningRecord({
    required UnitProblem unitProblem,
    required bool isCorrect,
    required bool isHistoryEnabled,
  }) async {
    // 履歴管理が有効かどうかをチェック
    if (!isHistoryEnabled) {
      return;
    }
    
    await UnitGachaHistoryManager.saveLearningRecord(
      unitProblem: unitProblem,
      isCorrect: isCorrect,
      byCalculator: true,
    );

    // ランキング用の解答イベント（電卓Enter由来のみ）
    // - オフライン時はローカルに溜め、ログイン後の同期でアップロードする
    await SimpleDataManager.enqueueUnitGachaAttemptEvent(
      problemId: unitProblem.id,
      isCorrect: isCorrect,
    );
  }
}

/// 解答結果
class AnswerResult {
  final bool isAnswered;
  final bool isCorrect;
  final String userInput;
  final int solvedCount;

  AnswerResult({
    required this.isAnswered,
    required this.isCorrect,
    required this.userInput,
    required this.solvedCount,
  });
}

