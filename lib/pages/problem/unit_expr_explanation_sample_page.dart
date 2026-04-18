import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../localization/app_localizations.dart';
import '../../localization/app_locale.dart';
import '../../problems/unit/symbol.dart' show SymbolDef;
import '../../problems/unit/unit_expr_problem.dart';
import '../../widgets/constants/app_constants.dart';
import '../gacha/formatting/unit_formatters.dart'
    show formatExpression, formatSymbolToTex, formatUnitString;
import '../../services/calculator/unit_calculator_service.dart'
    show NormalizedUnit, UnitCalculatorService;

/// UnitExprProblem 1件分の「解説ページ」サンプル。
///
/// - まずは「ページとして存在する」ことを優先し、表示要素を揃える。
/// - 詳細な解説コンテンツは、今後 problem ごとに追加できるように拡張する想定。
class UnitExprExplanationSamplePage extends StatelessWidget {
  final UnitExprProblem exprProblem;

  const UnitExprExplanationSamplePage({super.key, required this.exprProblem});

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: child,
      ),
    );
  }

  String _buildSymbolDefTex(BuildContext context, SymbolDef def) {
    final symbolTex = def.texSymbol ?? formatSymbolToTex(def.symbol);
    final lang = AppLocale.languageCode(context);
    final name = def.localizedName(lang)
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ');

    String unitPart = '';
    final unit = def.localizedUnitSymbol(lang);
    if (unit != null && unit.isNotEmpty) {
      unitPart = r'\text{（}' + formatUnitString(unit) + r'\text{）}';
    }
    final body = '$symbolTex: \\text{$name}$unitPart';
    return '{\\color{green} $body}';
  }

  Widget _buildDefs(BuildContext context, List<SymbolDef> defs) {
    if (defs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in defs)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Math.tex(
              _buildSymbolDefTex(context, d),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              mathStyle: MathStyle.text,
            ),
          ),
      ],
    );
  }

  bool _isSpringConstantKProblem() {
    // 要件: 「exprの文字にバネ定数kを含む問題」
    // 実データでは defs に symbol:"k", nameJa:"ばね定数" が付くため、これを確実条件にする。
    for (final d in exprProblem.defs) {
      if (d.symbol == 'k' && d.nameJa.contains('ばね定数')) return true;
    }
    return false;
  }

  bool _isSingleCharExprProblem() {
    // 「1文字の問題」= 空白を除いた式が1文字（Unicodeも考慮してrune数で判定）
    final s = exprProblem.expr.replaceAll(RegExp(r'\s+'), '');
    return s.runes.length == 1;
  }

  Widget _buildKAndNewtonNotes(BuildContext context) {
    // 記号定義の直後に挿入する固定テキスト（要求通り）
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, l10n.springConstantKUnitTitle),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.springConstantKUnitBody,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 8),
              Math.tex(
                r'\displaystyle \frac{N}{m}',
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                mathStyle: MathStyle.display,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionTitle(context, l10n.newtonBaseUnitTitle),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.newtonBaseUnitBody,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 8),
              Math.tex(
                r'\displaystyle N = \mathrm{kg}\,\mathrm{m}\,\mathrm{s}^{-2}',
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                mathStyle: MathStyle.display,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatBaseUnitsForComputation(String s) {
    // service側は `*` と空白を想定しているので、表示用の `·` を `*` に寄せる
    return s.replaceAll('·', '*').replaceAll('×', '*');
  }

  String _substituteUnitsExpr(String expr) {
    var out = expr.replaceAll(' ', '');
    // できるだけ崩れないように、defs を長い順で置換
    final defs = List<SymbolDef>.from(exprProblem.defs)
      ..sort((a, b) => b.symbol.length.compareTo(a.symbol.length));

    for (final d in defs) {
      final base = (d.baseUnits ?? d.unitSymbol);
      if (base == null || base.trim().isEmpty) continue;
      final baseStr = _formatBaseUnitsForComputation(base.trim());
      // 単純置換（このアプリの式表記は基本的に symbol がそのまま出る前提）
      out = out.replaceAll(d.symbol, '($baseStr)');
    }
    return out;
  }

  String _substitutedExprToTex(String substituted) {
    // `\frac{...}{...}` を活かしつつ、単位部分をTeXとして読める形に寄せる
    // - `*` を `\cdot` に
    // - `kg^-1` のような指数は `kg^{-1}` に
    // まずは乗算記号を正規化（Unicodeの中点/掛け算も混ざりうる）
    var s = substituted.replaceAll('·', '*').replaceAll('×', '*');

    // 先頭が乗算記号になってしまうケース（定数除去などの副作用）をケア
    s = s.trim();
    while (s.startsWith('*') || s.startsWith('+')) {
      s = s.substring(1).trimLeft();
    }

    // TeXで解釈できないUnicode記号をマクロに寄せる（flutter_mathのパース安定化）
    // ※指数整形より前にやると \Omega^2 などが残るので、指数整形の後にも追加で処理する
    s = s.replaceAll('μ', r'\mu').replaceAll('ε', r'\epsilon').replaceAll('θ', r'\theta');

    // 乗算記号
    s = s.replaceAll('*', r'\cdot ');
    s = s.replaceAllMapped(
      RegExp(r'([A-Za-zΩ]+)\^([+-]?\d+)'),
      (m) => '${m.group(1)}^{${m.group(2)}}',
    );

    // \Omega のようなマクロに対する指数も整形
    s = s.replaceAllMapped(
      RegExp(r'(\\[A-Za-z]+)\^([+-]?\d+)'),
      (m) => '${m.group(1)}^{${m.group(2)}}',
    );

    // Ohm記号は Unicode を避けて \Omega に統一
    s = s.replaceAll('Ω', r'\Omega');

    // 先頭が \cdot になったら落とす（視覚的にもパース的にも不自然）
    s = s.trimLeft();
    while (s.startsWith(r'\cdot')) {
      s = s.substring(r'\cdot'.length).trimLeft();
    }

    // 0.5 は TeX 的に安全だが、見た目は 1/2 に寄せる
    s = s.replaceAllMapped(RegExp(r'\b0\.5\b'), (_) => r'\frac{1}{2}');
    return s;
  }

  String _normalizedToBaseString(NormalizedUnit u) {
    // NormalizedUnit.toString() は `·` 区切り。表示/TeX用に空白区切りに寄せる。
    return u.toString().replaceAll('·', ' ');
  }

  Widget _buildDerivation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = AppLocale.languageCode(context);
    final rawExpr = exprProblem.expr;
    // 表示側では「定数除外」などの但し書きは不要なので、元の式をそのまま使う
    // （単位計算自体は UnitCalculatorService 側で数値/定数を無次元として扱える）
    final substituted = _substituteUnitsExpr(rawExpr);
    final substitutedTex = _substitutedExprToTex(substituted);
    final answers = exprProblem.unitProblems
        .map((up) => up.localizedAnswer(lang))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final joinedAnswerTex = answers.map(formatUnitString).join(r'\text{,}\,');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, l10n.unitDerivationSectionTitle),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.unitDerivationExpressionHeading,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Math.tex(
                r'\displaystyle ' + formatExpression(rawExpr),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                mathStyle: MathStyle.display,
              ),
              const Divider(height: 20),
              Text(
                l10n.unitDerivationSubstitutionHeading,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Math.tex(
                r'\displaystyle ' + substitutedTex,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                mathStyle: MathStyle.display,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    l10n.unitDerivationResultLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: answers.isEmpty
                        ? const Text('—')
                        : Math.tex(
                            r'\displaystyle ' + joinedAnswerTex,
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            mathStyle: MathStyle.display,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = AppLocale.languageCode(context);
    final meaning =
        (exprProblem.localizedMeaning(lang) ?? '').trim();
    final showDerivation = !_isSingleCharExprProblem();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.unitDerivationPageTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.unitCategory(exprProblem.category),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Math.tex(
                    r'\displaystyle ' + formatExpression(exprProblem.expr),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    mathStyle: MathStyle.display,
                  ),
                  if (meaning.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      meaning,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionTitle(context, l10n.symbolDefinitionsSectionTitle),
            _card(child: _buildDefs(context, exprProblem.defs)),
            if (_isSpringConstantKProblem()) ...[
              const SizedBox(height: 14),
              _buildKAndNewtonNotes(context),
              const SizedBox(height: 14),
            ],
            if (showDerivation) ...[
              const SizedBox(height: 14),
              _buildDerivation(context),
            ],
          ],
        ),
      ),
    );
  }
}




