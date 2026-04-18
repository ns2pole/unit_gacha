// lib/pages/gacha/ui/widgets/weekly_category_pie_chart.dart
// 週間データの単元ごとの解いた量の割合を円グラフで表示

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

/// 週間データの単元ごとの解いた量の割合を円グラフで表示
class WeeklyCategoryPieChart extends StatefulWidget {
  final int weekOffset;

  const WeeklyCategoryPieChart({
    Key? key,
    required this.weekOffset,
  }) : super(key: key);

  @override
  State<WeeklyCategoryPieChart> createState() => _WeeklyCategoryPieChartState();
}

class _WeeklyCategoryPieChartState extends State<WeeklyCategoryPieChart> {
  Map<UnitCategory, CategoryWeeklyStats> _categoryStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(WeeklyCategoryPieChart oldWidget) {
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

    // 総問題数を計算
    int totalCount = 0;
    for (final stats in _categoryStats.values) {
      totalCount += stats.totalCount;
    }

    // データがない場合はメッセージを表示
    if (totalCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.noProblemsSolvedThisWeek,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    // 円グラフのデータを準備
    final pieChartSections = <PieChartSectionData>[];
    for (final category in UnitCategory.values) {
      final stats = _categoryStats[category] ?? CategoryWeeklyStats(
        solvedCount: 0,
        failedCount: 0,
        totalCount: 0,
        accuracyRate: 0.0,
      );

      if (stats.totalCount > 0) {
        final percentage = (stats.totalCount / totalCount) * 100;
        pieChartSections.add(
          PieChartSectionData(
            value: stats.totalCount.toDouble(),
            title: '${percentage.toStringAsFixed(1)}%',
            color: getCategoryColor(category),
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    // 凡例を作成
    final legendItems = <Widget>[];
    for (final category in UnitCategory.values) {
      final stats = _categoryStats[category] ?? CategoryWeeklyStats(
        solvedCount: 0,
        failedCount: 0,
        totalCount: 0,
        accuracyRate: 0.0,
      );

      if (stats.totalCount > 0) {
        legendItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: getCategoryColor(category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_getCategoryName(category, l10n)}: ${stats.totalCount}${l10n.problemCountUnit(stats.totalCount)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PieChart(
            PieChartData(
              sections: pieChartSections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // タッチ時の処理（必要に応じて実装）
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: legendItems,
        ),
      ],
    );
  }
}



