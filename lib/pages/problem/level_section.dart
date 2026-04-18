import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/math_problem.dart';
import '../../services/problems/simple_data_manager.dart';
import '../common/aggregation_mode.dart';
import '../common/problem_status.dart';
import 'problem_tile.dart';
import '../../localization/app_localizations.dart';

/// LevelSection（展開時にチャンクで徐々に項目を追加）
class LevelSection extends StatefulWidget {
  final String? level; // レベルが無い場合はnullまたは空文字列
  final List<dynamic> items; // MathProblem or UnitProblem
  final Map<ProblemStatus, int>? precomputedCounts;
  final Future<List<Map<String, dynamic>>> Function(dynamic) getSlots;
  final AggregationMode aggregationMode;
  final Future<void> Function(dynamic, int, ProblemStatus) onSetSlot;
  final Future<void> Function(dynamic) onClearAll;
  final void Function(dynamic, int displayNo) onOpenDetail;
  final int startIndex; // 全体を通しての開始インデックス
  final String? prefsPrefix; // ガチャタイプの識別子

  const LevelSection({
    super.key,
    this.level,
    required this.items,
    this.precomputedCounts,
    required this.getSlots,
    required this.aggregationMode,
    required this.onSetSlot,
    required this.onClearAll,
    required this.onOpenDetail,
    this.startIndex = 0,
    this.prefsPrefix,
  });

  @override
  State<LevelSection> createState() => _LevelSectionState();
}

class _LevelSectionState extends State<LevelSection> {
  bool _expanded = false;

  int _visibleCount = 0;
  bool _isPopulating = false;
  bool _disposed = false;

  final int initialChunk = 12;
  final int chunk = 12;
  final int delayMs = 80;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LevelSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length < oldWidget.items.length) {
      final newVisible = math.min(_visibleCount, widget.items.length);
      if (newVisible != _visibleCount) {
        _visibleCount = newVisible;
        if (mounted) setState(() {});
      }
    } else if (widget.items.length > oldWidget.items.length) {
      if (_expanded && !_isPopulating && _visibleCount < widget.items.length) {
        _startLazyPopulate();
      }
    }
  }

  /// 集計（フォールバック用）：precomputedCounts が渡されない場合のみ使用
  Future<Map<ProblemStatus, int>> _aggregateLatestCounts() async {
    var solved = 0, failed = 0;

    for (final p in widget.items) {
      final slots = await widget.getSlots(p);
      final actualSlots = slots.where((s) => s['isDivider'] != true).toList();

      if (widget.aggregationMode == AggregationMode.latest1) {
        for (final slot in actualSlots) {
          final status = slot['status'] as ProblemStatus?;
          if (status != null) {
            switch (status) {
              case ProblemStatus.solved:
                solved++;
                break;
              case ProblemStatus.failed:
                failed++;
                break;
              case ProblemStatus.none:
              default:
                break;
            }
            break;
          }
        }
      } else {
        for (final slot in actualSlots) {
          final status = slot['status'] as ProblemStatus?;
          if (status != null) {
            switch (status) {
              case ProblemStatus.solved:
                solved++;
                break;
              case ProblemStatus.failed:
                failed++;
                break;
              case ProblemStatus.none:
              default:
                break;
            }
          }
        }
      }
    }

    return {
      ProblemStatus.solved: solved,
      ProblemStatus.failed: failed,
    };
  }

  Widget _buildCountChip(IconData icon, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Text(count.toString(), style: const TextStyle(fontSize: 13, color: Colors.black87)),
        const SizedBox(width: 10),
      ],
    );
  }

  Future<void> _startLazyPopulate() async {
    if (_isPopulating) return;
    _isPopulating = true;
    try {
      if (_disposed) return;
      setState(() {
        _visibleCount = widget.items.isEmpty ? 0 : math.min(widget.items.length, initialChunk);
      });

      while (!_disposed && _visibleCount < widget.items.length) {
        await Future.delayed(Duration(milliseconds: delayMs));
        if (_disposed) return;
        final next = math.min(widget.items.length, _visibleCount + chunk);
        if (next == _visibleCount) break;
        if (_disposed) return;
        setState(() {
          _visibleCount = next;
        });
      }
    } finally {
      _isPopulating = false;
    }
  }

  void _stopPopulateAndReset() {
    _visibleCount = 0;
    _isPopulating = false;
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.length;
    final visible = math.min(_visibleCount, widget.items.length);

    final precomputed = widget.precomputedCounts;
    if (precomputed == null) {
      return FutureBuilder<Map<ProblemStatus, int>>(
        future: _aggregateLatestCounts(),
        builder: (context, snapshot) {
          final counts = snapshot.data ??
              const {
                ProblemStatus.solved: 0,
                ProblemStatus.failed: 0,
              };
          return _buildCard(
            context,
            counts: counts,
            itemCount: itemCount,
            visible: visible,
          );
        },
      );
    }

    return _buildCard(
      context,
      counts: precomputed,
      itemCount: itemCount,
      visible: visible,
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required Map<ProblemStatus, int> counts,
    required int itemCount,
    required int visible,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.level != null && widget.level!.isNotEmpty) ...[
                  Text(
                    widget.level!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                _buildCountChip(Icons.check_circle, Colors.green, counts[ProblemStatus.solved] ?? 0),
                _buildCountChip(Icons.cancel, Colors.red, counts[ProblemStatus.failed] ?? 0),
                const Spacer(),
                ElevatedButton(
                  onPressed: itemCount == 0
                      ? null
                      : () async {
                          final l10n = AppLocalizations.of(context);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(l10n.confirmDialog),
                              content: Text(l10n.clearHistoryConfirm),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(l10n.clear),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            for (final p in widget.items) {
                              await SimpleDataManager.clearLearningHistory(p);
                            }
                            if (!mounted) return;
                            setState(() {});
                          }
                        },
                  child: Text(AppLocalizations.of(context).clearHistory),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                      if (_expanded) {
                        _startLazyPopulate();
                      } else {
                        _stopPopulateAndReset();
                      }
                    });
                  },
                ),
              ],
            ),
            if (_expanded)
              Column(
                children: [
                  const SizedBox(height: 8),
                  if (visible == 0 && itemCount > 0)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visible,
                      itemBuilder: (context, index) {
                        final p = widget.items[index];
                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: widget.getSlots(p),
                          builder: (context, snapshot) {
                            final slots = snapshot.data ??
                                List.generate(3, (_) => {'status': ProblemStatus.none, 'time': null});
                            return ProblemTile(
                              problem: p,
                              slots: slots,
                              onSetSlot: (i, st) => widget.onSetSlot(p, i, st),
                              onClearAll: () => widget.onClearAll(p),
                              onOpenDetail: () => widget.onOpenDetail(p, widget.startIndex + index + 1),
                              displayNo: widget.startIndex + index + 1,
                              prefsPrefix: widget.prefsPrefix,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            if (!_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  itemCount == 0 ? '問題はありません' : 'タップして展開 (${itemCount}問)',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

