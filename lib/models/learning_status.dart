// lib/models/learning_status.dart
import 'package:flutter/material.dart';

/// 学習状態を表す列挙型
enum LearningStatus {
  none,
  solved,
  failed,
}

/// 学習状態の拡張メソッド
extension LearningStatusExtension on LearningStatus {
  /// 学習状態を文字列に変換
  String get key {
    switch (this) {
      case LearningStatus.solved:
        return 'solved';
      case LearningStatus.failed:
        return 'failed';
      case LearningStatus.none:
        return 'none';
    }
  }
  
  /// 表示名を取得
  String get displayName {
    switch (this) {
      case LearningStatus.solved:
        return '解決済み';
      case LearningStatus.failed:
        return '失敗';
      case LearningStatus.none:
        return '未学習';
    }
  }
  
  /// 文字列から学習状態を取得
  static LearningStatus fromKey(String key) {
    switch (key) {
      case 'solved':
        return LearningStatus.solved;
      case 'failed':
        return LearningStatus.failed;
      case 'understood':
        // deprecated/removed; keep compatibility if it ever appears
        return LearningStatus.solved;
      default:
        return LearningStatus.none;
    }
  }
  
  /// 学習状態に対応するアイコンを取得
  IconData get icon {
    switch (this) {
      case LearningStatus.solved:
        return Icons.check_circle;
      case LearningStatus.failed:
        return Icons.cancel;
      case LearningStatus.none:
        return Icons.radio_button_unchecked;
    }
  }
  
  /// 学習状態に対応する色を取得
  Color get color {
    switch (this) {
      case LearningStatus.solved:
        return Colors.green;
      case LearningStatus.failed:
        return Colors.red;
      case LearningStatus.none:
        return Colors.grey;
    }
  }
  
  /// 学習状態のツールチップテキストを取得
  String get tooltip {
    switch (this) {
      case LearningStatus.solved:
        return '解けた';
      case LearningStatus.failed:
        return 'できなかった';
      case LearningStatus.none:
        return '学習状態を選択';
    }
  }
  
  /// 次の学習状態を取得（循環）
  LearningStatus get next {
    switch (this) {
      case LearningStatus.none:
        return LearningStatus.solved;
      case LearningStatus.solved:
        return LearningStatus.failed;
      case LearningStatus.failed:
        return LearningStatus.none;
    }
  }
}
