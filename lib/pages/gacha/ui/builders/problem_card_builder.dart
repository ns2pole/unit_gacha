// lib/pages/gacha/ui/builders/problem_card_builder.dart
// 問題カードの構築

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../localization/app_locale.dart';
import '../../../../problems/unit/symbol.dart'
    show UnitCategory, UnitProblem, SymbolDef;
import '../../../../problems/unit/unit_gacha_item.dart' show UnitGachaItem;
import '../../../common/common.dart' show MixedTextMath;
import '../../../common/tablet_utils.dart';
import '../../formatting/unit_formatters.dart'
    show formatSymbolToTex, formatExpression, formatUnitSymbolForMixedTextMath;

class ProblemCardBuilder {
  final AppLocalizations _l10n;

  ProblemCardBuilder(this._l10n);

  Color _getCategoryLightColor(UnitCategory category) {
    // 白をベースにして、その上にカテゴリーの色を薄く塗る（非透過）
    // 単位物理量一覧のような感じで、背景画像が透けないようにする
    switch (category) {
      case UnitCategory.mechanics:
        // 白をベースに紫を薄く混ぜる（不透明）
        return const Color(0xFFF3E5F5); // 白に紫を薄く混ぜた色
      case UnitCategory.thermodynamics:
        // 白をベースにオレンジを薄く混ぜる（不透明）
        return const Color(0xFFFFF3E0); // 白にオレンジを薄く混ぜた色
      case UnitCategory.waves:
        // 白をベースにシアンを薄く混ぜる（不透明）
        return const Color(0xFFE0F7FA); // 白にシアンを薄く混ぜた色
      case UnitCategory.electromagnetism:
        // 白をベースにアンバーを薄く混ぜる（不透明）
        return const Color(0xFFFFF8E1); // 白にアンバーを薄く混ぜた色
      case UnitCategory.atom:
        // 白をベースに緑を薄く混ぜる（不透明）
        return const Color(0xFFF1F8E9); // 白に緑を薄く混ぜた色
    }
  }

  bool _hasFraction(String formattedExpr) => formattedExpr.contains(r'\frac');

  Color _getCardBorderColor({required bool isAnswered, required bool isCorrect}) {
    // Unanswered: legacy Home style border (slightly darker than tutorial)
    if (!isAnswered) return Colors.grey.shade400;
    return isCorrect ? Colors.green.shade400 : Colors.red.shade400;
  }

  double _getCardBorderWidth({required bool isAnswered}) {
    // Match tutorial last page style: answered is thicker.
    return isAnswered ? 3.0 : 2.0;
  }

  Color _getCardBackgroundColor({
    required bool isAnswered,
    required bool isCorrect,
    required UnitCategory category,
  }) {
    // Unanswered: category-tinted background (legacy Home style)
    // Answered: green/red tint (same as tutorial)
    if (!isAnswered) return _getCategoryLightColor(category);
    return isCorrect ? Colors.green.shade50 : Colors.red.shade50;
  }

  BoxShadow _getCardShadow({
    required bool isAnswered,
    required bool isCorrect,
  }) {
    // Match tutorial last page style:
    // - unanswered: black shadow
    // - answered: green/red shadow
    final color = isAnswered
        ? (isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3))
        : Colors.black.withOpacity(0.2);
    return BoxShadow(
      color: color,
      blurRadius: 6,
      offset: const Offset(0, 3),
    );
  }

  Widget _buildProblemExpression({required String expr, double fontSize = 60}) {
    final formattedExpr = formatExpression(expr);
    final hasFraction = _hasFraction(formattedExpr);
    final adjustedFontSize = hasFraction ? fontSize * 0.75 : fontSize;

    return MixedTextMath(
      formattedExpr,
      forceTex: true,
      labelStyle: TextStyle(fontSize: adjustedFontSize, fontFamily: 'serif'),
      mathStyle: TextStyle(fontSize: adjustedFontSize, fontFamily: 'serif'),
    );
  }

  Widget _buildSymbolDefinitions(
    List<SymbolDef> defs,
    double fontSizeScale,
    BuildContext context,
    bool isAnswered,
  ) {
    final lang = AppLocale.languageCodeFromL10n(_l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: defs.map((def) {
        final symbolTex = formatSymbolToTex(def.symbol);
        final nameJa = def.localizedName(lang);
        final unitSymbol = isAnswered
            ? def.localizedUnitSymbol(lang)
            : null;
        final hasUnit = unitSymbol != null && unitSymbol.trim().isNotEmpty;
        final unitTex = hasUnit ? formatUnitSymbolForMixedTextMath(unitSymbol!) : '';

        return Padding(
          padding: EdgeInsets.only(bottom: TabletUtils.smallSpacing(context)),
          child: Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: TabletUtils.smallSpacing(context),
            runSpacing: TabletUtils.smallSpacing(context),
            children: [
              Math.tex(
                symbolTex,
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24 * fontSizeScale,
                  color: Colors.black,
                ),
                mathStyle: MathStyle.text,
              ),
              Text(
                ': ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24 * fontSizeScale,
                  color: Colors.black,
                ),
              ),
              Text(
                nameJa,
                style: TextStyle(
                  fontSize: 22 * fontSizeScale,
                  color: Colors.black,
                ),
              ),
              if (hasUnit)
                MixedTextMath(
                  // 1行説明と同様に、\text{...} 境界で分割して自然に折り返す
                  r"\text{ [}" + unitTex + r"\text{]}",
                  forceTex: false,
                  labelStyle: TextStyle(
                    fontSize: 22 * fontSizeScale,
                    color: Colors.black,
                  ),
                  mathStyle: TextStyle(
                    fontSize: 22 * fontSizeScale,
                    color: Colors.black,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildProblemCard({
    required UnitGachaItem item,
    required bool isAnswered,
    required bool isCorrect,
    required double cardWidth,
    double fontSize = 60,
    Widget? answerDisplay,
    Widget? actionButtons,
    required BuildContext context,
    bool isScratchPaperMode = false,
  }) {
    final cardScale = TabletUtils.cardScale(context);
    final fontSizeScale = TabletUtils.fontSizeScale(context);
    final actualCardWidth = cardWidth * cardScale;
    final actualFontSize = fontSize * fontSizeScale;
    final exprProblem = item.exprProblem;
    final problem = item.unitProblem;
    final borderColor = _getCardBorderColor(isAnswered: isAnswered, isCorrect: isCorrect);
    final borderWidth = _getCardBorderWidth(isAnswered: isAnswered);
    final backgroundColor = _getCardBackgroundColor(
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      category: exprProblem.category,
    );
    final shadow = _getCardShadow(isAnswered: isAnswered, isCorrect: isCorrect);
    final horizontalPadding =
        (TabletUtils.cardHorizontalPadding(context) * 0.7).clamp(8.0, 14.0);
    final verticalPadding = TabletUtils.cardVerticalPadding(context);

    return Container(
      width: actualCardWidth,
      // カード外側の左右余白を少し減らして、カード内の横幅を確保する
      margin: const EdgeInsets.only(left: 8, right: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [shadow],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (ctx) {
                final formattedExpr = formatExpression(exprProblem.expr);
                final hasFraction = _hasFraction(formattedExpr);
                return Padding(
                  padding: EdgeInsets.only(
                    // homeのカード上辺と数式の余白が広すぎるため、現状の半分に調整
                    top: hasFraction ? 16 * fontSizeScale : 24 * fontSizeScale,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    physics: const NeverScrollableScrollPhysics(),
                    child: _buildProblemExpression(
                      expr: exprProblem.expr,
                      fontSize: actualFontSize,
                    ),
                  ),
                );
              },
            ),
            if (exprProblem.defs.isNotEmpty) ...[
              SizedBox(height: TabletUtils.cardSpacing(context)),
              _buildSymbolDefinitions(
                exprProblem.defs,
                fontSizeScale,
                context,
                isAnswered,
              ),
            ],
            if (answerDisplay != null) ...[
              SizedBox(height: TabletUtils.cardSpacing(context) * 0.67),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: TabletUtils.smallSpacing(context),
                ),
                child: SizedBox(width: double.infinity, child: answerDisplay),
              ),
            ],
            if (actionButtons != null) ...[
              SizedBox(height: TabletUtils.cardSpacing(context) * 0.67),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: TabletUtils.cardHorizontalPadding(context),
                ),
                child: actionButtons,
              ),
              SizedBox(height: TabletUtils.cardSpacing(context) * 0.67),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildHorizontalCard({
    required UnitGachaItem item,
    required bool isAnswered,
    required bool isCorrect,
    required double cardWidth,
    required double cardHeight,
    double fontSize = 40,
    Widget? answerDisplay,
    Widget? actionButtons,
    required BuildContext context,
    bool isScratchPaperMode = false,
  }) {
    final cardScale = TabletUtils.cardScale(context);
    final fontSizeScale = TabletUtils.fontSizeScale(context);
    final actualCardWidth = cardWidth * cardScale;
    final actualFontSize = fontSize * fontSizeScale;
    final exprProblem = item.exprProblem;
    final problem = item.unitProblem;
    final borderColor = _getCardBorderColor(isAnswered: isAnswered, isCorrect: isCorrect);
    final borderWidth = _getCardBorderWidth(isAnswered: isAnswered);
    final backgroundColor = _getCardBackgroundColor(
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      category: exprProblem.category,
    );
    final shadow = _getCardShadow(isAnswered: isAnswered, isCorrect: isCorrect);
    final horizontalPadding =
        (TabletUtils.cardHorizontalPadding(context) * 0.7).clamp(8.0, 14.0);
    final verticalPadding = TabletUtils.cardVerticalPadding(context);

    return Container(
      width: actualCardWidth,
      // カード外側の左右余白を少し減らして、カード内の横幅を確保する
      margin: const EdgeInsets.only(left: 8, right: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [shadow],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: _buildProblemExpression(
                  expr: exprProblem.expr,
                  fontSize: actualFontSize,
                ),
              ),
            ),
            if (exprProblem.defs.isNotEmpty) ...[
              SizedBox(height: TabletUtils.cardSpacing(context)),
              _buildSymbolDefinitions(
                exprProblem.defs,
                fontSizeScale,
                context,
                isAnswered,
              ),
            ],
            if (answerDisplay != null) ...[
              SizedBox(height: TabletUtils.cardSpacing(context) * 0.67),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: TabletUtils.smallSpacing(context),
                ),
                child: SizedBox(width: double.infinity, child: answerDisplay),
              ),
            ],
            if (actionButtons != null) ...[
              SizedBox(height: TabletUtils.cardSpacing(context) * 0.67),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: TabletUtils.cardHorizontalPadding(context),
                ),
                child: actionButtons,
              ),
              SizedBox(height: TabletUtils.cardSpacing(context) * 0.67),
            ],
          ],
        ),
      ),
    );
  }
}
