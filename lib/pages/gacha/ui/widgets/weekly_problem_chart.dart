// lib/pages/gacha/ui/widgets/weekly_problem_chart.dart
// 週ごとの問題数棒グラフ（1日=1グループ、solved/failed を2本並べる版）

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../localization/app_localizations.dart';
import '../../logic/weekly_problem_statistics.dart'
    show WeeklyProblemStatistics, DailyStatistics;

/// グラフ関連の定数
class _ChartConstants {
  static const double chartHeight = 300.0;
  static const int defaultMaxValue = 10;
  static const int maxValueMargin = 2;

  static const Color titleColor = Color(0xFF8B7355);
  static const double titleFontSize = 18.0;

  static const double spacing = 16.0;
  static const double legendSpacing = 24.0;

  static const double barWidth = 10.0;
  static const double barsSpace = 6.0;
  static const double groupsSpace = 14.0;

  static const double borderRadius = 4.0;

  static const double tooltipRadius = 8.0;
  static const double tooltipPadding = 8.0;
  static const double tooltipMargin = 8.0;

  static const double bottomTitleReservedSize = 64.0;
  static const double leftTitleReservedSize = 28.0; // 詰めたまま

  static const double labelFontSize = 12.0;
  static const double bottomCountFontSize = 13.0;
  static const double legendFontSize = 14.0;
  // 「正解 / 不正解」の合計表示（見出し直下）だけ少し大きく
  static const double summaryFontSize = 16.0;
  static const double legendIconSize = 24.0;
  static const double legendIconSpacing = 8.0;

  static const double loadingPadding = 32.0;

  static const Color solvedColor = Colors.green;
  static const Color failedColor = Colors.red;

  static const Color gridLineColor = Colors.grey;
  static const Color borderColor = Colors.grey;
  static const double gridLineOpacity = 0.3;
  static const double borderOpacity = 0.4;
  static const double borderWidth = 1.0;
  static const double gridLineWidth = 1.0;

  static const double horizontalInterval = 1.0;
}

class WeeklyProblemChart extends StatefulWidget {
  final int weekOffset;
  final ValueChanged<int>? onWeekOffsetChanged;
  final bool showDateSelector;

  const WeeklyProblemChart({
    Key? key,
    this.weekOffset = 0,
    this.onWeekOffsetChanged,
    this.showDateSelector = true,
  }) : super(key: key);

  @override
  State<WeeklyProblemChart> createState() => _WeeklyProblemChartState();
}

class _WeeklyProblemChartState extends State<WeeklyProblemChart> {
  late int _currentWeekOffset;
  List<DailyStatistics> _dailyStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentWeekOffset = widget.weekOffset;
    _loadData();
  }

  @override
  void didUpdateWidget(WeeklyProblemChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekOffset != widget.weekOffset) {
      _currentWeekOffset = widget.weekOffset;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats =
        await WeeklyProblemStatistics.calculateWeeklyStatistics(_currentWeekOffset);
    if (mounted) {
      setState(() {
        _dailyStats = stats;
        _isLoading = false;
      });
    }
  }

  void _goToPreviousWeek() {
    final newOffset = _currentWeekOffset - 1;
    setState(() => _currentWeekOffset = newOffset);
    widget.onWeekOffsetChanged?.call(newOffset);
    _loadData();
  }

  void _goToNextWeek() {
    final newOffset = _currentWeekOffset + 1;
    setState(() => _currentWeekOffset = newOffset);
    widget.onWeekOffsetChanged?.call(newOffset);
    _loadData();
  }

  String _getWeekLabel() {
    final range = WeeklyProblemStatistics.getWeekRange(_currentWeekOffset);
    return '${DateFormat('yyyy/M/d').format(range.start)} - '
        '${DateFormat('yyyy/M/d').format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(_ChartConstants.loadingPadding),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final maxValue = _calculateMaxValue();
    final totalSolved = _dailyStats.fold<int>(0, (sum, s) => sum + s.solvedCount);
    final totalFailed = _dailyStats.fold<int>(0, (sum, s) => sum + s.failedCount);

    return Column(
      children: [
        if (widget.showDateSelector)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _goToPreviousWeek),
              Text(
                _getWeekLabel(),
                style: const TextStyle(
                  fontSize: _ChartConstants.titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: _ChartConstants.titleColor,
                ),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _goToNextWeek),
            ],
          ),
        if (widget.showDateSelector) const SizedBox(height: _ChartConstants.spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: _ChartConstants.solvedColor,
              size: _ChartConstants.legendIconSize,
            ),
            const SizedBox(width: _ChartConstants.legendIconSpacing),
            Text(
              l10n.correct,
              style: const TextStyle(fontSize: _ChartConstants.summaryFontSize),
            ),
            const SizedBox(width: 6),
            Text(
              totalSolved.toString(),
              style: const TextStyle(
                fontSize: _ChartConstants.summaryFontSize,
                fontWeight: FontWeight.w800,
                color: _ChartConstants.solvedColor,
              ),
            ),
            const SizedBox(width: _ChartConstants.legendSpacing),
            Icon(
              Icons.cancel,
              color: _ChartConstants.failedColor,
              size: _ChartConstants.legendIconSize,
            ),
            const SizedBox(width: _ChartConstants.legendIconSpacing),
            Text(
              l10n.incorrect,
              style: const TextStyle(fontSize: _ChartConstants.summaryFontSize),
            ),
            const SizedBox(width: 6),
            Text(
              totalFailed.toString(),
              style: const TextStyle(
                fontSize: _ChartConstants.summaryFontSize,
                fontWeight: FontWeight.w800,
                color: _ChartConstants.failedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: _ChartConstants.spacing),
        ClipRect(
          child: SizedBox(
            height: _ChartConstants.chartHeight,
            child: BarChart(_buildBarChartData(maxValue)),
          ),
        ),
      ],
    );
  }

  int _calculateMaxValue() {
    if (_dailyStats.isEmpty) return _ChartConstants.defaultMaxValue;
    final maxCount = _dailyStats
        .map((s) => s.solvedCount + s.failedCount)
        .reduce((a, b) => a > b ? a : b);
    return maxCount + _ChartConstants.maxValueMargin;
  }

  BarChartData _buildBarChartData(int maxValue) {
    return BarChartData(
      maxY: maxValue.toDouble(),
      groupsSpace: _ChartConstants.groupsSpace,
      titlesData: _buildTitles(),
      gridData: _buildGrid(),
      borderData: _buildBorder(),
      barGroups: _buildGroups(),
    );
  }

  FlTitlesData _buildTitles() {
    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: _ChartConstants.bottomTitleReservedSize,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= _dailyStats.length) {
              return const SizedBox.shrink();
            }
            final solved = _dailyStats[i].solvedCount;
            final failed = _dailyStats[i].failedCount;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('M/d').format(_dailyStats[i].date),
                    style: const TextStyle(fontSize: _ChartConstants.labelFontSize),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        solved.toString(),
                        style: const TextStyle(
                          fontSize: _ChartConstants.bottomCountFontSize,
                          fontWeight: FontWeight.w700,
                          color: _ChartConstants.solvedColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '/',
                        style: TextStyle(
                          fontSize: _ChartConstants.bottomCountFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        failed.toString(),
                        style: const TextStyle(
                          fontSize: _ChartConstants.bottomCountFontSize,
                          fontWeight: FontWeight.w700,
                          color: _ChartConstants.failedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: _ChartConstants.leftTitleReservedSize,
          getTitlesWidget: (value, meta) {
            if (value % 1 != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 2), // ★ ほんの少し空ける
              child: Text(
                value.toInt().toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: _ChartConstants.labelFontSize),
              ),
            );
          },
        ),
      ),
    );
  }

  FlGridData _buildGrid() => FlGridData(
        drawVerticalLine: false,
        horizontalInterval: _ChartConstants.horizontalInterval,
        getDrawingHorizontalLine: (v) => FlLine(
          color: _ChartConstants.gridLineColor
              .withOpacity(_ChartConstants.gridLineOpacity),
          strokeWidth: _ChartConstants.gridLineWidth,
        ),
      );

  FlBorderData _buildBorder() => FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(
            color: _ChartConstants.borderColor
                .withOpacity(_ChartConstants.borderOpacity),
            width: _ChartConstants.borderWidth,
          ),
          bottom: BorderSide(
            color: _ChartConstants.borderColor
                .withOpacity(_ChartConstants.borderOpacity),
            width: _ChartConstants.borderWidth,
          ),
        ),
      );

  List<BarChartGroupData> _buildGroups() {
    return _dailyStats.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barsSpace: _ChartConstants.barsSpace,
        barRods: [
          BarChartRodData(
            toY: e.value.solvedCount.toDouble(),
            color: _ChartConstants.solvedColor,
            width: _ChartConstants.barWidth,
          ),
          BarChartRodData(
            toY: e.value.failedCount.toDouble(),
            color: _ChartConstants.failedColor,
            width: _ChartConstants.barWidth,
          ),
        ],
      );
    }).toList();
  }

  Widget _legend(Color c, String t) => Row(
        children: [
          Container(
            width: _ChartConstants.legendIconSize,
            height: _ChartConstants.legendIconSize,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: _ChartConstants.legendIconSpacing),
          Text(t, style: const TextStyle(fontSize: _ChartConstants.legendFontSize)),
        ],
      );
}
