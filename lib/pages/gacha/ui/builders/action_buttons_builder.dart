// lib/pages/gacha/ui/builders/action_buttons_builder.dart
// アクションボタンの構築

import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../common/common.dart' show MixedTextMath;

class ActionButtonsBuilder {
  final AppLocalizations _l10n;
  
  ActionButtonsBuilder(this._l10n);
  
  Widget buildActionButtons({
    required VoidCallback onNext,
    required bool isLastProblem,
    String? point,
    double iconSize = 18,
    double fontSize = 16,
    double verticalPadding = 14,
    double minHeight = 52,
  }) {
    final trimmedPoint = (point ?? '').trim();
    final hasPoint = trimmedPoint.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPoint)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              // ヒントは主張しすぎないように薄めの黄色にする
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow.shade600),
            ),
            child: MixedTextMath(
              trimmedPoint,
              labelStyle: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
              mathStyle: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        if (hasPoint) const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onNext,
            icon: Icon(Icons.arrow_forward, size: iconSize),
            label: Text(
              isLastProblem ? _l10n.complete : _l10n.next,
              style: TextStyle(fontSize: fontSize),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: 16,
              ),
              minimumSize: Size.fromHeight(minHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}





