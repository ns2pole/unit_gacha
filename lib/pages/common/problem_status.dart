/// スロットが取りうる状態
enum ProblemStatus { none, solved, failed }

/// 文字列キーからProblemStatusに変換
ProblemStatus keyToStatus(String k) {
  switch (k) {
    case 'solved':
      return ProblemStatus.solved;
    case 'failed':
      return ProblemStatus.failed;
    // understood is deprecated/removed; treat as solved to preserve progress if it ever appears.
    case 'understood':
      return ProblemStatus.solved;
    default:
      return ProblemStatus.none;
  }
}

/// 問題一覧などで表示する履歴バッジ数
const int slotCount = 3;

/// 保持する学習履歴の最大件数
const int learningHistoryRetentionCount = 10;
