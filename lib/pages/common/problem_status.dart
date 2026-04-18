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

/// スロット数（定数）
const int slotCount = 3;

