import 'step_item.dart';

class MathProblem {
  final String id;        // ← 新しく追加
  final dynamic no; // int または String (予備問題は "op1", "op2" など)
  final String category;
  final String level;
  final String question; // TeX を含む文字列
  final String answer; // TeX
  final List<StepItem> steps;
  final String? imageAsset; // assets/graphs/....png
  final String? hint; // ヒント（【方針】の内容）
  final String? shortExplanation; // ワンフレーズ解説（オプショナル）
  final List<StepItem>? detailedExplanation; // 詳細解説（StepItemの配列、オプショナル）
  
  // 物理数学専用フィールド
  final String? equation; // 微分方程式
  final String? conditions; // 初期条件
  final String? constants; // 定数
  
  // キーワード（複数選択可能）
  final List<String> keywords; // 例: ['等加速度直線運動', '一般'], ['空気抵抗', 'RL回路', '具体']

  const MathProblem({
    required this.id,        // ← 新しく追加
    required this.no,
    required this.category,
    required this.level,
    required this.question,
    required this.answer,
    required this.steps,
    this.imageAsset,
    this.hint,
    this.shortExplanation,
    this.detailedExplanation,
    this.equation,
    this.conditions,
    this.constants,
    this.keywords = const [], // デフォルトは空リスト
  });
}