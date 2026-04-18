// lib/pages/gacha/ui/widgets/completion_rate_bar_chart.dart
// 達成率の横棒グラフ

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../problems/unit/symbol.dart' show UnitCategory;
import '../../../../localization/app_localizations.dart';
import '../../logic/completion_rate_calculator.dart' show CompletionRateResult;
import '../utils/category_color_helper.dart' show getCategoryColor;

/// 達成率の横棒グラフウィジェット
class CompletionRateBarChart extends StatelessWidget {
  final Map<UnitCategory, CompletionRateResult> results;
  final AppLocalizations l10n;

  const CompletionRateBarChart({
    Key? key,
    required this.results,
    required this.l10n,
  }) : super(key: key);

  String _getCategoryName(UnitCategory category) {
    switch (category) {
      case UnitCategory.mechanics:
        return l10n.categoryLabelMechanics;
      case UnitCategory.thermodynamics:
        return l10n.categoryLabelThermodynamics;
      case UnitCategory.waves:
        return l10n.categoryLabelWaves;
      case UnitCategory.electromagnetism:
        return l10n.categoryLabelElectromagnetism;
      case UnitCategory.atom:
        return l10n.categoryLabelAtom;
    }
  }

  @override
  Widget build(BuildContext context) {
    // データを準備
    final categories = UnitCategory.values;
    final maxPercentage = 100.0;

    // バーグループデータを作成
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final result = results[category];
      final totalCount = result?.totalCount ?? 0;
      final percentage = result?.percentage ?? 0.0;

      // 全くやってない単元はバーを表示しない（0%のバーも表示しない）
      if (totalCount == 0 || percentage == 0.0) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [],
          ),
        );
      } else {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: percentage,
                color: getCategoryColor(category),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxPercentage,
              minY: 0,
              groupsSpace: 16,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.grey[800]!,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final category = categories[groupIndex];
                    final result = results[category];
                    final completedCount = result?.completedCount ?? 0;
                    final totalCount = result?.totalCount ?? 0;
                    final percentage = result?.percentage ?? 0.0;

                    return BarTooltipItem(
                      '${_getCategoryName(category)}\n'
                      '$completedCount/$totalCount (${percentage.toStringAsFixed(1)}%)',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= categories.length) {
                        return const SizedBox.shrink();
                      }
                      final category = categories[index];
                      final result = results[category];
                      final completedCount = result?.completedCount ?? 0;
                      final totalCount = result?.totalCount ?? 0;
                      final percentage = result?.percentage ?? 0.0;

                      if (totalCount == 0) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$completedCount/$totalCount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value % 20 != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Text(
                          '${value.toInt()}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  if (value == 100.0) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.5),
                      strokeWidth: 2,
                    );
                  }
                  return FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left:
                      BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
                  bottom:
                      BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: categories.map((category) {
            final result = results[category];
            if (result == null || result.totalCount == 0)
              return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: getCategoryColor(category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _getCategoryName(category),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}



