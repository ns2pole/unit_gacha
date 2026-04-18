// lib/pages/problem_list_menu_utils.dart
// 問題一覧ページのメニュー表示ユーティリティ（problem_list_page.dartから分離）

import 'package:flutter/material.dart';
import 'problem_status.dart';
import 'aggregation_mode.dart';
import '../../services/problems/exclusion_logic.dart';
import '../../localization/app_localizations.dart';

// ヘルパー関数：ProblemStatusから色を取得
Color _colorOfSmall(ProblemStatus s) {
  switch (s) {
    case ProblemStatus.solved:
      return Colors.green;
    case ProblemStatus.failed:
      return Colors.red;
    case ProblemStatus.none:
      return Colors.grey;
  }
}

// ヘルパー関数：ProblemStatusからアイコンを取得
IconData _iconOfSmall(ProblemStatus s) {
  switch (s) {
    case ProblemStatus.solved:
      return Icons.check_circle;
    case ProblemStatus.failed:
      return Icons.cancel;
    case ProblemStatus.none:
      return Icons.help_outline;
  }
}

// ヘルパー関数：ステータスバッジを構築
Widget _statusBadgeSmall(ProblemStatus s, {double diameter = 20.0}) {
  final double iconSize = diameter * 0.6;
  return Container(
    width: diameter,
    height: diameter,
    decoration: BoxDecoration(
      color: _colorOfSmall(s),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Icon(_iconOfSmall(s), size: iconSize, color: Colors.white),
  );
}

/// 集計設定メニューを表示
Future<AggregationMode?> showAggregationMenu(
  BuildContext context,
  AggregationMode currentMode, {
  Offset? position,
  Size? size,
}) async {
  final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  Offset? menuPosition;
  if (position != null && size != null && overlay != null) {
    menuPosition = Offset(position.dx, position.dy + size.height);
  }
  
  final AggregationMode? selected = await showMenu<AggregationMode>(
    context: context,
    position: (menuPosition != null && size != null && overlay != null)
        ? RelativeRect.fromLTRB(
            menuPosition.dx,
            menuPosition.dy,
            overlay.size.width - menuPosition.dx - size.width,
            overlay.size.height - menuPosition.dy,
          )
        : null,
    items: AggregationMode.values.map((mode) {
      final l10n = AppLocalizations.of(context);
      Widget title = Text(mode.label(l10n), style: TextStyle(fontSize: 14, color: Colors.grey[900]));

      return PopupMenuItem<AggregationMode>(
        value: mode,
        child: Row(
          children: [
            if (currentMode == mode)
              const Icon(Icons.check, size: 20, color: Colors.blue)
            else
              const SizedBox(width: 20),
            const SizedBox(width: 8),
            title,
          ],
        ),
      );
    }).toList(),
  );

  return selected;
}

/// フィルタ選択メニューを表示
Future<ExclusionMode?> showFilterMenu(
  BuildContext context,
  ExclusionMode currentMode, {
  Offset? position,
  Size? size,
}) async {
  final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
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
        int n;
        switch (mode) {
          case ExclusionMode.latest1:
            n = 1;
            break;
          case ExclusionMode.latest2:
            n = 2;
            break;
          case ExclusionMode.latest3:
          default:
            n = 3;
            break;
        }
        title = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.excludeMarkedProblemsPrefix(n), style: TextStyle(fontSize: 14, color: Colors.grey[900])),
            _statusBadgeSmall(ProblemStatus.solved, diameter: 16.0),
            const SizedBox(width: 4),
            Text(l10n.excludeMarkedProblemsSuffix(n), style: TextStyle(fontSize: 14, color: Colors.grey[900])),
          ],
        );
      }

      return PopupMenuItem<ExclusionMode>(
        value: mode,
        child: Row(
          children: [
            if (currentMode == mode)
              const Icon(Icons.check, size: 20, color: Colors.blue)
            else
              const SizedBox(width: 20),
            const SizedBox(width: 8),
            title,
          ],
        ),
      );
    }).toList(),
  );

  return selected;
}

