// 問題詳細ページ（履歴操作付き簡易版）
import 'package:flutter/material.dart';

import '../../widgets/home/background_image_widget.dart';
import '../../widgets/common/back_button.dart' as custom;
import '../../widgets/constants/app_constants.dart';
import '../common/problem_status.dart';
import '../common/common.dart';
import '../../localization/app_localizations.dart';
import '../../localization/app_locale.dart';
import '../../problems/unit/unit_expr_problem.dart';
import '../../problems/unit/symbol.dart' show UnitProblem, SymbolDef;
import '../../services/problems/simple_data_manager.dart';
import '../../services/problems/exclusion_logic.dart'
    show sortHistoryByTimeNewestFirst;
import 'unit_expr_explanation_sample_page.dart';

class ProblemDetailPage extends StatefulWidget {
  final UnitExprProblem exprProblem;
  final String prefsPrefix;
  final List<Map<String, dynamic>> initialHistory;
  final int? displayNo;
  final void Function(int idx, ProblemStatus status)? onAddSlot;
  final VoidCallback? onClear;

  const ProblemDetailPage({
    super.key,
    required this.exprProblem,
    required this.prefsPrefix,
    this.initialHistory = const [],
    this.displayNo,
    this.onAddSlot,
    this.onClear,
  });

  @override
  State<ProblemDetailPage> createState() => _ProblemDetailPageState();
}

class _ProblemDetailPageState extends State<ProblemDetailPage> {
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;
  VoidCallback? _learningEpochListener;

  Future<void> _openExplanationSample() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            UnitExprExplanationSamplePage(exprProblem: widget.exprProblem),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSlots();
    // 学習履歴が更新されたら、詳細のスロットも再読み込みする
    _learningEpochListener = () {
      if (!mounted) return;
      _loadSlots();
    };
    SimpleDataManager.learningDataEpochListenable.addListener(_learningEpochListener!);
  }

  @override
  void dispose() {
    final l = _learningEpochListener;
    if (l != null) {
      SimpleDataManager.learningDataEpochListenable.removeListener(l);
    }
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
    });

    final slots = await _getSlots(widget.exprProblem);

    setState(() {
      _slots = slots;
      _isLoading = false;
    });
  }

  /// 全履歴を取得してスロットを作成（詳細画面用）
  Future<List<Map<String, dynamic>>> _getSlots(UnitExprProblem ep) async {
    final unitProblemsForExpr = ep.unitProblems;
    if (unitProblemsForExpr.isEmpty) return [];

    final slots = <Map<String, dynamic>>[];

    for (
      var unitProblemIndex = 0;
      unitProblemIndex < unitProblemsForExpr.length;
      unitProblemIndex++
    ) {
      final unitProblem = unitProblemsForExpr[unitProblemIndex];

      final history = await SimpleDataManager.getLearningHistory(unitProblem);
      final sortedHistory = sortHistoryByTimeNewestFirst(history);

      final unitProblemSlots = sortedHistory
          .asMap()
          .entries
          .map((entry) {
            final originalIndex = entry.key;
            final h = entry.value;
            final status = ProblemStatus.values.firstWhere(
              (s) => s.name == h['status'],
              orElse: () => ProblemStatus.none,
            );
            final timeStr = h['time'] as String?;
            DateTime? dt;
            if (timeStr != null) {
              try {
                dt = DateTime.parse(timeStr);
              } catch (_) {
                dt = null;
              }
            }
            return {
              'status': status,
              'time': dt,
              'unitProblemId': unitProblem.id,
              'unitProblemIndex': unitProblemIndex,
              'isDivider': false,
              '_originalIndex': originalIndex,
            };
          })
          .toList()
          .reversed
          .toList();

      slots.addAll(unitProblemSlots);

      if (unitProblemIndex < unitProblemsForExpr.length - 1) {
        slots.add({'isDivider': true});
      }
    }

    return slots;
  }

  /// スロットを更新（全履歴対応）
  Future<void> _setSlot(
    UnitExprProblem ep,
    int idx,
    ProblemStatus newStatus,
  ) async {
    if (_isLoading) return;

    if (idx >= _slots.length) return;

    final slot = _slots[idx];
    if (slot['isDivider'] == true) return;

    final unitProblemId = slot['unitProblemId'] as String?;
    final UnitProblem target = unitProblemId != null
        ? ep.unitProblems.firstWhere((up) => up.id == unitProblemId)
        : ep.unitProblems.first;

    // 全履歴を取得してソート
    final history = await SimpleDataManager.getLearningHistory(target);
    final sortedHistory = sortHistoryByTimeNewestFirst(history);

    // 元の履歴インデックスを取得
    final originalIndex = slot['_originalIndex'] as int?;

    if (originalIndex != null && originalIndex < sortedHistory.length) {
      // 電卓Enter由来（byCalculator=true）の履歴は変更しない（ランキング/実績の整合性のため）
      final original = sortedHistory[originalIndex];
      if (original['byCalculator'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('電卓で解いた履歴は変更できません'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // 既存の履歴を更新
      sortedHistory[originalIndex] = {
        'status': newStatus.name,
        'time': newStatus == ProblemStatus.none
            ? null
            : DateTime.now().toIso8601String(),
        // Preserve byCalculator flag if present (defensive; should be false here)
        if (original['byCalculator'] is bool) 'byCalculator': original['byCalculator'] as bool,
      };
    } else {
      // 新しい履歴を追加
      sortedHistory.add({
        'status': newStatus.name,
        'time': newStatus == ProblemStatus.none
            ? null
            : DateTime.now().toIso8601String(),
        // Detail-page edits are always treated as manual (non-ranking) entries.
        'byCalculator': false,
      });
    }

    // 保存
    await SimpleDataManager.saveLearningHistory(target, sortedHistory);

    // 再読み込み
    await _loadSlots();

    // コールバック呼び出し
    if (widget.onAddSlot != null) {
      widget.onAddSlot!(idx, newStatus);
    }

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final unitProblems = widget.exprProblem.unitProblems;
    final hasMultipleUnits = unitProblems.length > 1;

    // カテゴリーを文字列に変換
    final categoryStr = l10n.unitCategory(widget.exprProblem.category);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: BackgroundImageWidget(opacity: 0.1)),
          const custom.BackButton(),
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: AppConstants.defaultPadding + 40, // 戻るボタンのスペース
              left: AppConstants.defaultPadding,
              right: AppConstants.defaultPadding,
              bottom: AppConstants.defaultPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.displayNo != null)
                  Text(
                    l10n.problemNumberLabel(widget.displayNo!),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                if (categoryStr.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    categoryStr,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
                const SizedBox(height: AppConstants.defaultPadding),
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppConstants.defaultPadding,
                  ),
                  child: MixedTextMath(
                    _formatExpressionToTex(widget.exprProblem.expr),
                    forceTex: true,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    mathStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _openExplanationSample,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('解説'),
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                _buildDefsSection(context, widget.exprProblem.defs),
                if (hasMultipleUnits) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  _buildUnitProblemsSection(context, unitProblems),
                ] else ...[
                  if (unitProblems.isNotEmpty &&
                      unitProblems.first.shortExplanation != null &&
                      unitProblems.first.shortExplanation!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.defaultPadding,
                      ),
                      child: MixedTextMath(
                        unitProblems.first.shortExplanation!,
                        // 解説は自然改行させたいので forceTex:false を基本にする。
                        // \text{} を含むTeX文章も MixedTextMath 側で安全に混在解釈できる。
                        forceTex: false,
                        labelStyle: const TextStyle(fontSize: 16),
                        mathStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  if (unitProblems.isNotEmpty &&
                      unitProblems.first.answer.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.defaultPadding,
                      ),
                      child: Text(
                        l10n.problemAnswerLabel(
                          l10n.localizeAnswer(
                            unitProblems.first.answer,
                            AppLocale.languageCode(context),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: AppConstants.defaultPadding),
                if (widget.onAddSlot != null && !hasMultipleUnits)
                  _buildHistorySection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitProblemsSection(
    BuildContext context,
    List<UnitProblem> unitProblems,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final lang = AppLocale.languageCode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 各UnitProblemごとに単位とスロットを表示
        ...unitProblems.asMap().entries.map((entry) {
          final unitProblemIndex = entry.key;
          final unitProblem = entry.value;

          // このUnitProblemに対応するスロットを取得
          final unitProblemSlots = <Map<String, dynamic>>[];
          for (int j = 0; j < _slots.length; j++) {
            if (_slots[j]['isDivider'] != true) {
              final slotUnitProblemIndex =
                  _slots[j]['unitProblemIndex'] as int?;
              if (slotUnitProblemIndex == unitProblemIndex) {
                unitProblemSlots.add(_slots[j]);
              }
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 単位表示とスロット
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context).unitLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          unitProblem.localizedAnswer(
                            lang,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '|',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        // 全履歴を横スクロールで表示
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: unitProblemSlots.asMap().entries.map((
                                slotEntry,
                              ) {
                                final slotIndexInUnitProblem = slotEntry.key;
                                final slot = slotEntry.value;
                                final status =
                                    slot['status'] as ProblemStatus? ??
                                    ProblemStatus.none;

                                // _slotsのインデックスを直接使用
                                int actualGlobalIndex = -1;
                                int foundCount = 0;
                                for (int i = 0; i < _slots.length; i++) {
                                  if (_slots[i]['isDivider'] != true) {
                                    final slotUnitProblemIndex =
                                        _slots[i]['unitProblemIndex'] as int?;
                                    if (slotUnitProblemIndex ==
                                        unitProblemIndex) {
                                      if (foundCount ==
                                          slotIndexInUnitProblem) {
                                        actualGlobalIndex = i;
                                        break;
                                      }
                                      foundCount++;
                                    }
                                  }
                                }
                                if (actualGlobalIndex == -1) {
                                  // フォールバック：スロット全体から該当するものを探す
                                  for (int i = 0; i < _slots.length; i++) {
                                    if (_slots[i] == slot) {
                                      actualGlobalIndex = i;
                                      break;
                                    }
                                  }
                                }

                                return GestureDetector(
                                  onTap: () {
                                    final current = status;
                                    final next = current == ProblemStatus.none
                                        ? ProblemStatus.solved
                                        : current == ProblemStatus.solved
                                            ? ProblemStatus.failed
                                            : ProblemStatus.none;
                                    _setSlot(
                                      widget.exprProblem,
                                      actualGlobalIndex,
                                      next,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: _statusBadgeSmall(status),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 式の説明を表示
                    if (unitProblem.shortExplanation != null) ...[
                      const SizedBox(height: AppConstants.smallPadding),
                      MixedTextMath(
                        unitProblem.localizedShortExplanation(
                              lang,
                            ) ??
                            '',
                        // 解説は自然改行させたいので forceTex:false を基本にする。
                        // \text{} を含むTeX文章も MixedTextMath 側で安全に混在解釈できる。
                        forceTex: false,
                        labelStyle: const TextStyle(fontSize: 14),
                        mathStyle: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    // 仕切りを除外してスロットのみを取得
    final actualSlots = _slots.where((s) => s['isDivider'] != true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.historyTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actualSlots.asMap().entries.map((entry) {
              final idx = entry.key;
              final slot = entry.value;
              final status =
                  slot['status'] as ProblemStatus? ?? ProblemStatus.none;

              return GestureDetector(
                onTap: () {
                  if (widget.onAddSlot != null) {
                    final cur = status;
                    ProblemStatus next;
                    switch (cur) {
                      case ProblemStatus.none:
                        next = ProblemStatus.solved;
                        break;
                      case ProblemStatus.solved:
                        next = ProblemStatus.failed;
                        break;
                      case ProblemStatus.failed:
                        next = ProblemStatus.none;
                        break;
                    }
                    // 実際のスロットインデックスを計算（仕切りを除く）
                    int actualIndex = 0;
                    for (int i = 0; i < _slots.length; i++) {
                      if (_slots[i]['isDivider'] != true) {
                        if (actualIndex == idx) {
                          _setSlot(widget.exprProblem, i, next);
                          break;
                        }
                        actualIndex++;
                      }
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _statusBadgeSmall(status),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDefsSection(BuildContext context, List<SymbolDef> defs) {
    if (defs.isEmpty) return const SizedBox.shrink();
    final lang = AppLocale.languageCode(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '記号の定義',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final d in defs)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${d.symbol}: ${d.localizedName(lang)}'
                  '${(d.localizedUnitSymbol(lang) ?? '').isNotEmpty ? '（${d.localizedUnitSymbol(lang)}）' : ''}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 数式をTeX形式に変換する関数（0.5を1/2に変換など）
  /// 例: 0.5mv^2 → \frac{1}{2}mv^2
  String _formatExpressionToTex(String expression) {
    String formatted = expression;

    // 分数の変換（0.5 を 1/2 に）
    formatted = formatted.replaceAllMapped(
      RegExp(r'0\.5'),
      (match) => r'\frac{1}{2}',
    );

    return formatted;
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}
