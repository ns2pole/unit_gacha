// lib/widgets/unit_card.dart
// 単位問題カードウィジェット

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../problems/unit/unit_gacha_item.dart';
import '../../localization/app_localizations.dart';

/// 単位問題カード
class UnitCard extends StatelessWidget {
  final UnitGachaItem item;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? fixedWidth; // 固定幅（指定された場合はこれを使用）
  final double? fixedHeight; // 固定高さ（指定された場合はこれを使用）
  final String? question; // 問題文（オプショナル）
  final String? answer; // 答え（オプショナル）

  const UnitCard({
    Key? key,
    required this.item,
    this.isSelected = false,
    this.onTap,
    this.fixedWidth,
    this.fixedHeight,
    this.question,
    this.answer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 縦5横4の比率でカードサイズを計算
    // 固定サイズが指定されている場合はそれを使用
    final double cardWidth;
    final double cardHeight;

    if (fixedWidth != null && fixedHeight != null) {
      cardWidth = fixedWidth!;
      cardHeight = fixedHeight!;
    } else {
      // スマホの場合は画面幅に応じて調整、PCの場合は固定サイズ
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 600;

      cardWidth = isSmallScreen
          ? (screenWidth - 32) / 3 -
                8 // 画面幅からpadding(16*2)を引いて3で割り、マージン(8*2)を引く
          : 150.0;
      cardHeight = cardWidth * 5 / 4;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade300 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.grey.shade600 : Colors.grey.shade300,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isSelected
            ? // 選択時はグレーで中身を見せない
              Container(
                color: Colors.grey.shade300,
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.grey.shade600,
                    size: 40,
                  ),
                ),
              )
            : // 非選択時のみ中身を表示
              Padding(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // 問題文表示（questionがある場合）
                    if (question != null && question!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          question!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    // 数式表示（大きく、手書き風）
                    Flexible(
                      fit: FlexFit.loose,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Builder(
                          builder: (context) {
                            final formattedExpr = _formatExpression(
                              item.exprProblem.expr,
                            );
                            final hasFraction = _hasFraction(formattedExpr);
                            return Padding(
                              padding: EdgeInsets.only(
                                top: hasFraction ? -8 : -4,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Math.tex(
                                    formattedExpr,
                                    textStyle: TextStyle(
                                      fontSize: hasFraction ? 18 : 24,
                                      fontFamily: 'serif',
                                    ),
                                    mathStyle: MathStyle.display,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 答え表示（answerがある場合）
                    if (answer != null && answer!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              AppLocalizations.of(context).answerPrefix,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                answer!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // 記号定義（単位は書かない、TeX形式で表示）- カード内部の下段に表示
                    Flexible(
                      fit: FlexFit.loose,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...item.exprProblem.defs.map(
                              (def) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    // 記号部分をTeX形式で表示
                                    Math.tex(
                                      _formatSymbolToTex(def.symbol),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                      mathStyle: MathStyle.text,
                                    ),
                                    const Text(
                                      ': ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      def.nameJa,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// 記号をTeX形式に変換する関数（記号定義用）
  /// 例: k_0 → k_{0}, mu_0 → \mu_{0}, epsilon_0 → \epsilon_{0}
  String _formatSymbolToTex(String symbol) {
    String formatted = symbol;

    // mu_0 のような形式（アンダースコア付きの下付き文字）を処理
    formatted = formatted.replaceAllMapped(
      RegExp(r'\bmu_(\d+)\b'),
      (match) => r'\mu_{' + match.group(1)! + r'}',
    );

    // epsilon_0 のような形式（アンダースコア付きの下付き文字）を処理
    formatted = formatted.replaceAllMapped(
      RegExp(r'\bepsilon_(\d+)\b'),
      (match) => r'\epsilon_{' + match.group(1)! + r'}',
    );

    // k_0 のような形式（アンダースコア付きの下付き文字）を処理
    formatted = formatted.replaceAllMapped(RegExp(r'(\w)_(\d+)(?![\w}])'), (
      match,
    ) {
      return match.group(1)! + '_{' + match.group(2)! + '}';
    });

    // C_v のような形式（アンダースコア付きの文字の下付き文字）を処理
    formatted = formatted.replaceAllMapped(
      RegExp(r'([A-Z])_([a-z])(?![\w}])'),
      (match) {
        return match.group(1)! + '_{' + match.group(2)! + '}';
      },
    );

    // 下付き文字を処理（m1 → m_1, m2 → m_2, N1 → N_1, N2 → N_2）
    formatted = formatted.replaceAllMapped(RegExp(r'(\b\w+)(\d+)(?![\^\{_])'), (
      match,
    ) {
      final base = match.group(1)!;
      final sub = match.group(2)!;
      // μ0の場合は\mu_0として処理
      if (base == 'μ' || base.contains('μ')) {
        return r'\mu_{' + sub + r'}';
      }
      // ε0の場合は\epsilon_0として処理
      if (base == 'ε' || base.contains('ε')) {
        return r'\epsilon_{' + sub + r'}';
      }
      return base + '_{' + sub + '}';
    });

    // ε0を\epsilon_0に変換（特殊文字の処理）
    formatted = formatted.replaceAllMapped(
      RegExp(r'ε(\d+)'),
      (match) => r'\epsilon_{' + match.group(1)! + r'}',
    );

    // μ0を\mu_0に変換（特殊文字の処理）
    formatted = formatted.replaceAllMapped(
      RegExp(r'μ(\d+)'),
      (match) => r'\mu_{' + match.group(1)! + r'}',
    );

    // μを\muに変換
    formatted = formatted.replaceAllMapped(
      RegExp(r'μ([a-zA-Z])'),
      (match) => r'\mu_{' + match.group(1)! + r'}',
    );
    formatted = formatted.replaceAll('μ', r'\mu');

    // εを\epsilonに変換
    formatted = formatted.replaceAll('ε', r'\epsilon');

    // pi を \pi に変換
    formatted = formatted.replaceAllMapped(
      RegExp(r'\bpi\b'),
      (match) => r'\pi',
    );

    return formatted;
  }

  /// 式をLaTeX形式に変換（手書き風）
  String _formatExpression(String expr) {
    String formatted = expr;

    // ルート記号を変換（√(x) → \sqrt{x}, √x → \sqrt{x}）
    formatted = formatted.replaceAllMapped(
      RegExp(r'√\s*\(\s*([^)]+?)\s*\)'),
      (match) => r'\sqrt{' + match.group(1)!.trim() + r'}',
    );
    formatted = formatted.replaceAllMapped(
      RegExp(r'√\s*([^\s]+)'),
      (match) => r'\sqrt{' + match.group(1)!.trim() + r'}',
    );

    // まず累乗記号を変換（v^2 → v^{2}, r^2 → r^{2}）
    formatted = formatted.replaceAllMapped(RegExp(r'(\w+)\^(\d+(?:\.\d+)?)'), (
      match,
    ) {
      final base = match.group(1)!;
      final power = match.group(2)!;
      return base + '^{' + power + '}';
    });

    // * を半角スペースに変換
    formatted = formatted.replaceAll('*', ' ');

    // mu_0 のような形式（アンダースコア付きの下付き文字）を処理
    formatted = formatted.replaceAllMapped(
      RegExp(r'\bmu_(\d+)\b'),
      (match) => r'\mu_{' + match.group(1)! + r'}',
    );

    // epsilon_0 のような形式（アンダースコア付きの下付き文字）を処理
    formatted = formatted.replaceAllMapped(
      RegExp(r'\bepsilon_(\d+)\b'),
      (match) => r'\epsilon_{' + match.group(1)! + r'}',
    );

    // C_v のような形式（アンダースコア付きの文字の下付き文字）を処理
    formatted = formatted.replaceAllMapped(
      RegExp(r'([A-Z])_([a-z])(?![\w}])'),
      (match) {
        return match.group(1)! + '_{' + match.group(2)! + '}';
      },
    );

    // 下付き文字を処理（m1 → m_1, m2 → m_2）
    // 累乗記号が含まれていない単純な変数名+数字のパターンのみ処理
    // ただし、μ0やε0のような特殊文字を含む場合は特別処理
    formatted = formatted.replaceAllMapped(RegExp(r'(\b\w+)(\d+)(?![\^\{_])'), (
      match,
    ) {
      final base = match.group(1)!;
      final sub = match.group(2)!;
      // μ0の場合は\mu_0として処理（μは特殊文字なのでLaTeXでは\mu）
      if (base == 'μ' || base.contains('μ')) {
        return r'\mu_' + sub;
      }
      // ε0の場合は\epsilon_0として処理（εは特殊文字なのでLaTeXでは\epsilon）
      if (base == 'ε' || base.contains('ε')) {
        return r'\epsilon_' + sub;
      }
      return base + '_{' + sub + '}';
    });

    // ε0を\epsilon_0に変換（特殊文字の処理）
    formatted = formatted.replaceAllMapped(
      RegExp(r'ε(\d+)'),
      (match) => r'\epsilon_' + match.group(1)!,
    );

    // μ0を\mu_0に変換（特殊文字の処理）
    formatted = formatted.replaceAllMapped(
      RegExp(r'μ(\d+)'),
      (match) => r'\mu_{' + match.group(1)! + r'}',
    );

    // μを\muに変換（μ0の処理の後）
    // μの後に英字が続く場合は下付き文字として処理（例: μs → \mu_s）
    formatted = formatted.replaceAllMapped(
      RegExp(r'μ([a-zA-Z])'),
      (match) => r'\mu_' + match.group(1)!,
    );
    // 残りのμを\muに変換
    formatted = formatted.replaceAll('μ', r'\mu');

    // εを\epsilonに変換（ε0の処理の後）
    formatted = formatted.replaceAll('ε', r'\epsilon');

    // pi を \pi に変換
    formatted = formatted.replaceAllMapped(
      RegExp(r'\bpi\b'),
      (match) => r'\pi',
    );

    // 分数の変換（0.5 を 1/2 に）
    formatted = formatted.replaceAllMapped(
      RegExp(r'0\.5'),
      (match) => r'\frac{1}{2}',
    );

    // 数値の分数パターンを変換（例: 1/2, 1/3など）
    formatted = formatted.replaceAllMapped(RegExp(r'(\d+)/(\d+)'), (match) {
      final num = match.group(1)!;
      final den = match.group(2)!;
      return r'\frac{' + num + r'}{' + den + r'}';
    });

    // 割り算を分数に変換（例: m v^2 / r → \frac{m v^{2}}{r}）
    // 分子と分母が複数の項を含む場合も処理
    formatted = formatted.replaceAllMapped(RegExp(r'([^/]+)/([^/]+)'), (match) {
      var num = match.group(1)!.trim();
      var den = match.group(2)!.trim();
      // 既に\fracが含まれている場合はスキップ
      if (num.contains(r'\frac') || den.contains(r'\frac')) {
        return match.group(0)!;
      }
      // 分母の不要な括弧を削除（例: (2 π r) → 2 π r, (2πr) → 2πr）
      // 先頭と末尾が括弧で囲まれている場合のみ削除
      if (den.startsWith('(') && den.endsWith(')')) {
        den = den.substring(1, den.length - 1);
      }
      return r'\frac{' + num + r'}{' + den + r'}';
    });

    return formatted;
  }

  /// 数式に分数が含まれているかどうかを判定
  bool _hasFraction(String formattedExpr) {
    return formattedExpr.contains(r'\frac');
  }
}
