// lib/pages/gacha/ui/builders/answer_display_builder.dart
// 答え表示の構築

import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../localization/app_locale.dart';
import '../../../../problems/unit/symbol.dart' show UnitProblem;
import '../../../common/common.dart' show MixedTextMath;
import '../../formatting/unit_formatters.dart' show formatUnitString;
import '../../formatting/unit_alternative_names.dart' show getAlternativeUnitNames, formatAlternativeNames;

class AnswerDisplayBuilder {
  final AppLocalizations _l10n;
  
  AnswerDisplayBuilder(this._l10n);
  
  TextStyle _buildAnswerTextStyle({required bool isCorrect, double fontSize = 20}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
    );
  }
  
  TextStyle _buildAnswerMathStyle({required bool isCorrect, double fontSize = 24}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
    );
  }
  
  Widget _buildMixedTextMath({
    required String text,
    required bool isCorrect,
    bool forceTex = true,
    double labelFontSize = 20,
    double mathFontSize = 24,
  }) {
    return MixedTextMath(
      text,
      forceTex: forceTex,
      labelStyle: _buildAnswerTextStyle(isCorrect: isCorrect, fontSize: labelFontSize),
      mathStyle: _buildAnswerMathStyle(isCorrect: isCorrect, fontSize: mathFontSize),
    );
  }
  
  Widget buildAnswerDisplay({
    required UnitProblem problem,
    required String correctAnswer,
    required bool isCorrect,
    required bool isAnswered,
  }) {
    if (!isAnswered) return const SizedBox.shrink();

    final lang = AppLocale.languageCodeFromL10n(_l10n);
    
    final alternativeNames = getAlternativeUnitNames(correctAnswer);
    final alternativeText = alternativeNames.isNotEmpty 
        ? formatAlternativeNames(alternativeNames)
        : '';
    
    final unitText = formatUnitString(correctAnswer);
    final firstLineText = isCorrect
        ? (lang == 'en'
            ? _l10n.answerCorrectWithUnit + unitText + alternativeText
            : _l10n.answerCorrect + ' ' + _l10n.answerCorrectWithUnit + unitText + alternativeText)
        : _l10n.answerIncorrect + unitText;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            // 2行目（shortExplanation）と同じ MixedTextMath 経路に揃えて、
            // 自然改行とフォントの見え方（行の組まれ方）を統一する。
            child: _buildMixedTextMath(
              text: firstLineText,
              isCorrect: isCorrect,
              forceTex: false,
            ),
          ),
        ),
        if (problem.shortExplanation != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildMixedTextMath(
                text: problem.localizedShortExplanation(lang)!,
                isCorrect: isCorrect,
                // 解説は自然改行させたいので forceTex:false を基本にする。
                // \text{} を含むTeX文章も MixedTextMath 側で安全に混在解釈できる。
                forceTex: false,
                // 1行解説の日本語（\text{...}）が小さすぎたので、"Correct!" 行に近いサイズへ。
                labelFontSize: 20,
                mathFontSize: 24,
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget buildAnswerMark({
    required bool isCorrect,
    required bool isAnswered,
    Offset offset = const Offset(0, -16),
    double iconSize = 32,
  }) {
    if (!isAnswered) return const SizedBox.shrink();
    
    return Transform.translate(
      offset: offset,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // アイコン内部を白で塗りつぶす（背景色に左右されないようにする）
          Container(
            width: iconSize * 0.72,
            height: iconSize * 0.72,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: iconSize,
            color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ],
      ),
    );
  }
}






