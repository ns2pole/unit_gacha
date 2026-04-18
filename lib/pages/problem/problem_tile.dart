import 'package:flutter/material.dart';

import '../../models/math_problem.dart';
import '../../widgets/gacha/physics_math_case_display.dart' show PhysicsMathCaseDisplay;
import '../common/problem_status.dart';
import '../common/common.dart';
import '../../localization/app_localizations.dart';

/// ProblemTile（学習履歴のバッジと詳細ボタン付き）
class ProblemTile extends StatelessWidget {
  final MathProblem problem;
  final List<Map<String, dynamic>> slots;
  final Future<void> Function(int idx, ProblemStatus st) onSetSlot;
  final Future<void> Function() onClearAll;
  final VoidCallback onOpenDetail;
  final int? displayNo; // 表示用の番号（全体を通しての連番）
  final String? prefsPrefix; // ガチャタイプの識別子

  const ProblemTile({
    super.key,
    required this.problem,
    required this.slots,
    required this.onSetSlot,
    required this.onClearAll,
    required this.onOpenDetail,
    this.displayNo,
    this.prefsPrefix,
  });

  Color _colorOf(ProblemStatus s) {
    switch (s) {
      case ProblemStatus.solved:
        return Colors.green;
      case ProblemStatus.failed:
        return Colors.red;
      case ProblemStatus.none:
      default:
        return Colors.grey;
    }
  }

  String _formatDtShort(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _statusBadgeSmall(ProblemStatus status, {double diameter = 20.0}) {
    final double iconSize = diameter * 0.6;
    IconData icon;
    Color color;
    switch (status) {
      case ProblemStatus.solved:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ProblemStatus.failed:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case ProblemStatus.none:
        icon = Icons.circle_outlined;
        color = Colors.grey;
        break;
    }
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(diameter / 2.5),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        key: ValueKey('problem_${problem.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 通常のレイアウト
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // No、slot、日時、詳細ボタンを1列に並べる
                Row(
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No. ${displayNo ?? problem.no ?? 'N/A'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          for (int i = 0; i < slots.length; i++)
                            Builder(
                              builder: (context) {
                                final status = slots[i]['status'] as ProblemStatus?;
                                if (status == null) return const SizedBox.shrink();
                                return GestureDetector(
                                  onTap: () async {
                                    final current = status;
                                    final next = current == ProblemStatus.none
                                        ? ProblemStatus.solved
                                        : current == ProblemStatus.solved
                                            ? ProblemStatus.failed
                                            : ProblemStatus.none;
                                    await onSetSlot(i, next);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: _statusBadgeSmall(status),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(width: 12),
                          // 最新の更新日時を表示
                          Builder(
                            builder: (context) {
                              // noneでない最後のスロットの日時を取得
                              DateTime? latestTime;
                              for (int i = slots.length - 1; i >= 0; i--) {
                                final status = slots[i]['status'] as ProblemStatus?;
                                if (status != null && status != ProblemStatus.none) {
                                  final time = slots[i]['time'] as DateTime?;
                                  if (time != null) {
                                    latestTime = time;
                                    break;
                                  }
                                }
                              }
                              if (latestTime != null) {
                                return Text(
                                  '${AppLocalizations.of(context).updatedLabel}${_formatDtShort(latestTime)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 4),
                // 問題の数式を大きく表示
                if (problem.equation != null && problem.conditions != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: PhysicsMathCaseDisplay(
                      equation: problem.equation!,
                      conditions: problem.conditions!,
                      constants: problem.constants,
                      fontSize: prefsPrefix == 'sequence' ? 24 : 20,
                    ),
                  )
                else
                  MixedTextMath(
                    problem.question,
                    labelStyle: const TextStyle(
                      fontSize: 18,
                    ),
                    mathStyle: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

