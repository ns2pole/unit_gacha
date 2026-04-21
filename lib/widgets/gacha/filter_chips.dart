// lib/widgets/filter_chips.dart
import 'package:flutter/material.dart';
import '../../pages/common/aggregation_mode.dart';
import '../../services/problems/exclusion_logic.dart';
import '../../models/learning_status.dart';
import '../../pages/gacha/pages/gacha_settings_page.dart' show GachaFilterMode, GachaFilterModeExt, kGachaDisplayOrder;
import '../../pages/gacha/data/unit_gacha_history.dart' show UnitGachaHistoryManager;
import '../../services/problems/simple_data_manager.dart';
import '../../localization/app_localizations.dart';

/// 除外設定フィルターチップ（共通化）
class ExclusionFilterChip extends StatelessWidget {
  final ExclusionMode exclusionMode;
  final GlobalKey filterChipKey;
  final VoidCallback onTap;
  final Widget Function() buildContent;

  const ExclusionFilterChip({
    super.key,
    required this.exclusionMode,
    required this.filterChipKey,
    required this.onTap,
    required this.buildContent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          key: filterChipKey,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list, size: 18, color: Colors.purple[700]),
                const SizedBox(width: 4),
                buildContent(),
                const SizedBox(width: 4),
                Icon(Icons.expand_more, size: 20, color: Colors.purple[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 集計設定フィルターチップ（共通化）
class AggregationFilterChip extends StatelessWidget {
  final AggregationMode aggregationMode;
  final VoidCallback onTap;

  const AggregationFilterChip({
    super.key,
    required this.aggregationMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Builder(
        builder: (context) {
          final GlobalKey aggregationChipKey = GlobalKey();
          return GestureDetector(
            onTap: () {
              final RenderBox? renderBox = aggregationChipKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final position = renderBox.localToGlobal(Offset.zero);
                final size = renderBox.size;
                onTap();
              } else {
                onTap();
              }
            },
            child: Container(
              key: aggregationChipKey,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF4E6), Color(0xFFFFF9F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 18, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        aggregationMode == AggregationMode.latest1
                            ? l10n.menuLatest1
                            : l10n.menuLatest3,
                        style: TextStyle(fontSize: 17, color: Colors.orange[700], fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more, size: 20, color: Colors.orange[600]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 青色フィルタリングガジェット（共通化）
class BlueFilterChip extends StatelessWidget {
  final GlobalKey filterChipKey;
  final VoidCallback onTap;
  final String filterLabel;
  final String? problemCountText; // 例: "10問/20問" または null
  final double iconSize;
  final Widget? statusBadge; // ステータスバッジ（オプション）
  final String? additionalText; // 追加テキスト（例: "ならガチャから外す"）
  final bool showProblemCountOnSecondLine; // 問題数を2行目に表示するか

  const BlueFilterChip({
    super.key,
    required this.filterChipKey,
    required this.onTap,
    required this.filterLabel,
    this.problemCountText,
    this.iconSize = 26,
    this.statusBadge,
    this.additionalText,
    this.showProblemCountOnSecondLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: filterChipKey,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE6F4FF), Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1行目: Filter Settings
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.filter_list,
                      color: Colors.blue[700],
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).filterSettings,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            // 2行目: remaining (problemCountText)
            if (problemCountText != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  problemCountText!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            // 3行目: latest (filterLabel + statusBadge + additionalText)
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (filterLabel.isNotEmpty) ...[
                    Text(
                      filterLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (statusBadge != null) ...[
                      const SizedBox(width: 4),
                      statusBadge!,
                    ],
                    if (additionalText != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        additionalText!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 20, color: Colors.blue[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// フィルター設定部分（除外設定と集計設定）
class FilterSection extends StatelessWidget {
  final ExclusionMode exclusionMode;
  final AggregationMode aggregationMode;
  final GlobalKey filterChipKey;
  final Widget Function() buildExclusionContent;
  final VoidCallback onExclusionTap;
  final VoidCallback onAggregationTap;

  const FilterSection({
    super.key,
    required this.exclusionMode,
    required this.aggregationMode,
    required this.filterChipKey,
    required this.buildExclusionContent,
    required this.onExclusionTap,
    required this.onAggregationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 除外設定（1行目）- パープル系
          ExclusionFilterChip(
            exclusionMode: exclusionMode,
            filterChipKey: filterChipKey,
            onTap: onExclusionTap,
            buildContent: buildExclusionContent,
          ),
          const SizedBox(height: 8),
          // 集計設定（2行目）- オレンジ系
          AggregationFilterChip(
            aggregationMode: aggregationMode,
            onTap: onAggregationTap,
          ),
        ],
      ),
    );
  }
}

/// ガチャページ用のフィルタリングガジェット（除外設定のみ）
/// unit_gacha_page.dart、congruence_gacha_page.dart、gacha_page.dartで使用
class GachaExclusionFilterWidget extends StatefulWidget {
  final ExclusionMode? exclusionMode; // ExclusionModeを使用する場合
  final GachaFilterMode? gachaFilterMode; // GachaFilterModeを使用する場合
  final ValueChanged<ExclusionMode>? onExclusionModeChanged; // ExclusionMode用コールバック
  final ValueChanged<GachaFilterMode>? onGachaFilterModeChanged; // GachaFilterMode用コールバック
  final String prefsPrefix; // 'unit'、'congruence'、'integral' など
  final String? problemCountText; // 問題数表示（例: "10問/20問"）
  final bool showStatusBadge; // ステータスバッジを表示するか
  final String? additionalText; // 追加テキスト（例: "ならガチャから外す"）
  final double iconSize; // アイコンサイズ
  final bool isProblemListMode; // 問題一覧モード（文言を一覧向けにする）

  const GachaExclusionFilterWidget({
    super.key,
    this.exclusionMode,
    this.gachaFilterMode,
    this.onExclusionModeChanged,
    this.onGachaFilterModeChanged,
    required this.prefsPrefix,
    this.problemCountText,
    this.showStatusBadge = false,
    this.additionalText,
    this.iconSize = 20,
    this.isProblemListMode = false,
  }) : assert(
          (exclusionMode != null && onExclusionModeChanged != null && gachaFilterMode == null && onGachaFilterModeChanged == null) ||
          (gachaFilterMode != null && onGachaFilterModeChanged != null && exclusionMode == null && onExclusionModeChanged == null),
          'Either exclusionMode or gachaFilterMode must be provided, but not both',
        );

  @override
  State<GachaExclusionFilterWidget> createState() => _GachaExclusionFilterWidgetState();
}

class _GachaExclusionFilterWidgetState extends State<GachaExclusionFilterWidget> {
  final GlobalKey _filterChipKey = GlobalKey();

  /// ステータスバッジを生成（gacha_page.dartと同じスタイル）
  Widget _buildStatusBadge(LearningStatus status, {double diameter = 20.8}) {
    final double iconSize = diameter * 0.6;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: status.color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(status.icon, size: iconSize, color: Colors.white),
    );
  }

  /// Pro版購入状態を確認
  Future<void> _checkProVersionStatus() async {
    await UnitGachaHistoryManager.checkProVersionStatus();
  }

  Future<void> _showFilterMenu(BuildContext context, {Offset? position, Size? size}) async {
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // GachaFilterModeを使用する場合のメニュー表示
    if (widget.gachaFilterMode != null && widget.onGachaFilterModeChanged != null) {
      // Pro版のチェックを更新
      await _checkProVersionStatus();
      
      // フィルタリングは常に画面中央に表示（positionパラメータを無視）
      final menuWidth = screenWidth * 0.98;
      final leftMargin = (screenWidth - menuWidth) / 2;
      
      // メニューのY位置は、フィルタリングチップの下に表示
      double menuY = 0;
      if (position != null && size != null && overlay != null) {
        menuY = position.dy + size.height;
      } else {
        menuY = 100;
      }
      
      // すべてのモードを利用可能にする
      final availableModes = kGachaDisplayOrder;
      
      final GachaFilterMode? selected = await showMenu<GachaFilterMode>(
        context: context,
        position: overlay != null
            ? RelativeRect.fromLTRB(
                leftMargin,
                menuY,
                leftMargin,
                overlay.size.height - menuY,
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        items: availableModes.map((mode) {
          final l10n = AppLocalizations.of(context);
          Widget title;
          if (mode == GachaFilterMode.random) {
            title = Text(l10n.noExclusion, style: TextStyle(fontSize: 14, color: Colors.grey[900]));
          } else {
            int n;
            switch (mode) {
              case GachaFilterMode.excludeSolvedGE1:
                n = 1;
                break;
              case GachaFilterMode.excludeSolvedGE2:
                n = 2;
                break;
              case GachaFilterMode.excludeSolvedGE3:
              default:
                n = 3;
                break;
            }
            // 問題一覧モードとホーム/計算用紙モードで文言を分ける
            final thenText = widget.isProblemListMode ? l10n.filterThenHide : l10n.filterThenExclude;
            
            title = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${l10n.latestN(n)} ', style: TextStyle(fontSize: 14, color: Colors.grey[900])),
                _buildStatusBadge(LearningStatus.solved, diameter: 16.0),
                Text(' $thenText', style: TextStyle(fontSize: 14, color: Colors.grey[900])),
              ],
            );
          }
          
          return PopupMenuItem<GachaFilterMode>(
            value: mode,
            child: Row(
              children: [
                if (widget.gachaFilterMode == mode)
                  const Icon(Icons.check, size: 20, color: Colors.blue)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                Expanded(child: title),
              ],
            ),
          );
        }).toList(),
      );
      
      if (selected != null && selected != widget.gachaFilterMode) {
        widget.onGachaFilterModeChanged!(selected);
        // 設定を保存（SimpleDataManagerを使用）
        final settings = await SimpleDataManager.getGachaSettings(widget.prefsPrefix);
        String filterModeStr;
        switch (selected) {
          case GachaFilterMode.random:
            filterModeStr = 'random';
            break;
          case GachaFilterMode.excludeSolved:
            filterModeStr = 'exclude_solved';
            break;
          case GachaFilterMode.excludeSolvedGE1:
            filterModeStr = 'exclude_solved_ge1';
            break;
          case GachaFilterMode.excludeSolvedGE2:
            filterModeStr = 'exclude_solved_ge2';
            break;
          case GachaFilterMode.excludeSolvedGE3:
            filterModeStr = 'exclude_solved_ge3';
            break;
          case GachaFilterMode.onlyUnsolved:
            filterModeStr = 'only_unsolved';
            break;
        }
        settings['filterMode'] = filterModeStr;
        await SimpleDataManager.saveGachaSettings(widget.prefsPrefix, settings);
      }
      return;
    }
    
    // ExclusionModeを使用する場合のメニュー表示（既存のロジック）
    Offset? menuPosition;
    if (position != null && size != null && overlay != null) {
      menuPosition = Offset(position.dx, position.dy + size.height);
    }
    
    final ExclusionMode? selected = await showMenu<ExclusionMode>(
      context: context,
      position: (menuPosition != null && size != null && overlay != null)
          ? RelativeRect.fromLTRB(
              menuPosition.dx,
              menuPosition.dy,
              overlay.size.width - menuPosition.dx - size.width,
              overlay.size.height - menuPosition.dy,
            )
          : null,
      items: kExclusionDisplayOrder.map((mode) {
        final l10n = AppLocalizations.of(context);
        Widget title;
        if (mode == ExclusionMode.none) {
          title = Text(l10n.showAll, style: TextStyle(fontSize: 14, color: Colors.grey[900]));
        } else {
          // 因数分解ガチャと同じ形式で表示
          int n;
          switch (mode) {
            case ExclusionMode.latest1:
              n = 1;
              break;
            case ExclusionMode.latest2:
              n = 2;
              break;
            case ExclusionMode.latest3:
              n = 3;
              break;
            case ExclusionMode.none:
              n = 0;
              break;
          }
          // 問題一覧モードとホーム/計算用紙モードで文言を分ける
          final thenText = widget.isProblemListMode ? l10n.filterThenHide : l10n.filterThenExclude;
          
          // 1行だけで完結させる（2行目は不要）
          title = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.latestN(n)} ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[900])),
              _buildStatusBadge(LearningStatus.solved, diameter: 16.0),
              Text(' $thenText', style: TextStyle(fontSize: 14, color: Colors.grey[900])),
            ],
          );
        }
        return PopupMenuItem<ExclusionMode>(
          value: mode,
          child: title,
        );
      }).toList(),
    );
    
    if (selected != null && selected != widget.exclusionMode) {
      widget.onExclusionModeChanged!(selected);
      // 設定を保存
      await SimpleDataManager.saveOtherSettingValue(
        '${widget.prefsPrefix}_gacha_exclusion_mode',
        selected.index,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 因数分解ガチャと同じ形式で表示
    String filterLabel;
    Widget? statusBadge;
    String? additionalText;
    
    // GachaFilterModeを使用する場合
    if (widget.gachaFilterMode != null) {
      final l10n = AppLocalizations.of(context);
      if (widget.gachaFilterMode == GachaFilterMode.random) {
        // 問題一覧モードでは「完全ランダム」等の文言を出さず「除外なし」に統一
        filterLabel = widget.isProblemListMode ? l10n.noExclusion : l10n.filterModeRandom;
        statusBadge = null;
        additionalText = null;
      } else {
        filterLabel = widget.gachaFilterMode!.label(context);
        statusBadge = _buildStatusBadge(LearningStatus.solved, diameter: 20.8);
        additionalText =
            widget.isProblemListMode ? l10n.filterThenHide : l10n.filterThenExclude;
      }
    } 
    // ExclusionModeを使用する場合
    else if (widget.exclusionMode != null) {
      final l10n = AppLocalizations.of(context);
      if (widget.exclusionMode == ExclusionMode.none) {
        filterLabel = l10n.showAll;
        statusBadge = null;
        additionalText = null;
      } else {
        // 「Latest N」の形式に変換
        int n;
        switch (widget.exclusionMode!) {
          case ExclusionMode.latest1:
            n = 1;
            break;
          case ExclusionMode.latest2:
            n = 2;
            break;
          case ExclusionMode.latest3:
            n = 3;
            break;
          case ExclusionMode.none:
            n = 0;
            break;
        }
        filterLabel = l10n.latestN(n);
        statusBadge = _buildStatusBadge(LearningStatus.solved, diameter: 20.8);
        additionalText = l10n.filterThenExclude;
      }
    } else {
      // フォールバック（通常は到達しない）
      final l10n = AppLocalizations.of(context);
      filterLabel = l10n.showAll;
      statusBadge = null;
      additionalText = null;
    }
    
    return BlueFilterChip(
      filterChipKey: _filterChipKey,
      onTap: () async {
        final RenderBox? renderBox = _filterChipKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          _showFilterMenu(context, position: position, size: size);
        } else {
          _showFilterMenu(context);
        }
      },
      filterLabel: filterLabel,
      iconSize: widget.iconSize,
      problemCountText: widget.problemCountText,
      statusBadge: statusBadge,
      additionalText: additionalText,
      showProblemCountOnSecondLine: widget.gachaFilterMode == GachaFilterMode.random,
    );
  }
}

