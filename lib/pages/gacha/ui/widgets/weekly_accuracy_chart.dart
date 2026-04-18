// lib/pages/gacha/ui/widgets/weekly_accuracy_chart.dart
// 週間データの単元ごとの正答率を横棒グラフで表示

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../problems/unit/symbol.dart' show UnitCategory;
import '../../../../localization/app_localizations.dart';
import '../../logic/weekly_category_statistics.dart'
    show WeeklyCategoryStatistics, CategoryWeeklyStats;
import '../utils/category_color_helper.dart' show getCategoryColor;

/// 単元カテゴリーの名前を取得
String _getCategoryName(UnitCategory category, AppLocalizations l10n) {
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

/// 週間データの単元ごとの正答率を横棒グラフで表示
class WeeklyAccuracyChart extends StatefulWidget {
  final int weekOffset;

  const WeeklyAccuracyChart({
    Key? key,
    required this.weekOffset,
  }) : super(key: key);

  @override
  State<WeeklyAccuracyChart> createState() => _WeeklyAccuracyChartState();
}

class _WeeklyAccuracyChartState extends State<WeeklyAccuracyChart> {
  Map<UnitCategory, CategoryWeeklyStats> _categoryStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(WeeklyAccuracyChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekOffset != widget.weekOffset) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats =
        await WeeklyCategoryStatistics.calculateWeeklyCategoryStats(
      widget.weekOffset,
    );
    if (mounted) {
      setState(() {
        _categoryStats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // データを準備
    final categories = UnitCategory.values;
    final maxPercentage = 100.0;

    // バーグループデータを作成
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final stats = _categoryStats[category] ?? CategoryWeeklyStats(
        solvedCount: 0,
        failedCount: 0,
        totalCount: 0,
        accuracyRate: 0.0,
      );

      // 未回答単元（totalCount == 0）はバー非表示
      if (stats.totalCount == 0) {
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
                toY: stats.accuracyRate,
                color: getCategoryColor(category),
                width: 20,
                // 両端を角丸にして「右だけ丸い」見た目を解消
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
    }

    return ClipRect(
      child: Column(
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
                      final stats =
                          _categoryStats[category] ?? CategoryWeeklyStats(
                        solvedCount: 0,
                        failedCount: 0,
                        totalCount: 0,
                        accuracyRate: 0.0,
                      );

                      if (stats.totalCount == 0) {
                        return BarTooltipItem(
                          '${_getCategoryName(category, l10n)}\n未回答',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }

                      return BarTooltipItem(
                        '${_getCategoryName(category, l10n)}\n'
                        '正答率: ${stats.accuracyRate.toStringAsFixed(1)}%\n'
                        '正解: ${stats.solvedCount}問 / 不正解: ${stats.failedCount}問',
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
                        final stats =
                            _categoryStats[category] ?? CategoryWeeklyStats(
                          solvedCount: 0,
                          failedCount: 0,
                          totalCount: 0,
                          accuracyRate: 0.0,
                        );

                        if (stats.totalCount == 0)
                          return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${stats.accuracyRate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
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
                    return FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                        color: Colors.grey.withOpacity(0.4), width: 1),
                    bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.4), width: 1),
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
              final stats = _categoryStats[category];
              if (stats == null || stats.totalCount == 0)
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
                    _getCategoryName(category, l10n),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}



