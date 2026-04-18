import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter/material.dart';
import '../../models/math_problem.dart';

/// テキストと数式（TeX）を混在表示するウィジェット
///
/// 主な機能:
/// - TeXマクロ（\displaystyle, \int等）を検出して数式として表示
/// - Math.texのビルドエラー時はプレーンテキストでフォールバック
/// - ブロック数式（\[...\]）は横スクロール表示
/// - インライン数式（\(...\)）は数式部分のみ横スクロール可能
/// - 段落間パディング: vertical:4.0、行間: height:1.35
///
/// 入力例:
/// - "これは \(x^2 + y^2 = 1\) の式です"
/// - "\[\int_0^1 x\,dx = \frac{1}{2}\]"
/// - "tex: \sum_{i=1}^{n} i = \frac{n(n+1)}{2}"
class MixedTextMath extends StatelessWidget {
  final String mixed;
  final TextStyle? labelStyle;
  final TextStyle? mathStyle;
  final bool forceTex;

  const MixedTextMath(
    this.mixed, {
    this.labelStyle,
    this.mathStyle,
    this.forceTex = false,
    super.key,
  });

  /// "tex:" または "tex：" プレフィックスを除去
  String _stripTexPrefix(String s) {
    var t = s.trim();
    if (t.toLowerCase().startsWith('tex:')) return t.substring(4).trim();
    if (t.toLowerCase().startsWith('tex：')) return t.substring(4).trim();
    return t;
  }

  /// 1行説明の数式（インライン相当）では \frac が小さく見えやすいので、
  /// 分数を含む場合は displaystyle に寄せる。
  ///
  /// - `\tfrac` は `\frac` に正規化
  /// - `\displaystyle` が未指定なら先頭に付与
  String _promoteFractionsToDisplayStyle(String tex) {
    final core = tex.trim();
    if (core.isEmpty) return tex;
    if (!core.contains(r'\frac') && !core.contains(r'\tfrac')) return tex;

    var out = core.replaceAll(r'\tfrac', r'\frac');
    if (out.startsWith(r'\displaystyle')) return out;
    return r'\displaystyle ' + out;
  }

  /// 文字列が数式（TeX）かどうかを判定
  bool _looksLikeMath(String s) {
    if (s.isEmpty) return false;
    final t = s.trim();
    final lower = t.toLowerCase();

    if (t.startsWith(r'\')) return true;

    final keywords = [
      r'\displaystyle',
      r'\int',
      r'\sum',
      r'\frac',
      r'\sqrt',
      r'\lim',
      r'\begin',
      r'\end',
      r'\alpha',
      r'\beta',
      r'\gamma',
      r'\,',
    ];
    for (final k in keywords) {
      if (t.contains(k) || lower.contains(k.replaceAll(r'\', ''))) return true;
    }

    final macroRe = RegExp(r'\\[A-Za-z]+');
    if (macroRe.hasMatch(t)) return true;

    if (t.contains('^') || t.contains('_')) return true;

    // インライン/ブロックのTeXマーカー
    if (t.contains(r'\(') || t.contains(r'\)') || t.contains(r'\[') || t.contains(r'\]')) {
      return true;
    }

    final mathChars = RegExp(r'[(){}\[\]\+\-\*/=]');
    if (mathChars.hasMatch(t)) return true;

    return false;
  }

  /// TeX文字列をMath.texでレンダリング。エラー時はプレーンテキストでフォールバック
  Widget _mathCoreSafe(String tex, TextStyle style, {MathStyle? mathStyle}) {
    try {
      return Math.tex(
        tex,
        textStyle: style,
        mathStyle: mathStyle ?? MathStyle.text,
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('MixedTextMath: Math.tex build error: $e\ntex: $tex\n$st');
      return SelectableText(tex, style: style);
    }
  }

  /// ブロック数式（独立行の数式）を表示するウィジェット
  Widget _blockMathWidget(String tex, TextStyle? style) {
    final effective = style ?? const TextStyle(fontSize: 26);
    final core = _mathCoreSafe(tex, effective, mathStyle: MathStyle.display);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 0),
          child: core,
        ),
      ),
    );
  }

  /// インライン数式（文中の数式）を表示するウィジェット
  Widget _inlineMathWidgetConstrained(String tex, double maxWidth, TextStyle? style) {
    final effective = style ?? const TextStyle(fontSize: 22);
    final core = _mathCoreSafe(tex, effective, mathStyle: MathStyle.text);

    final maxAllowed = maxWidth.isFinite ? maxWidth * 0.95 : 300.0;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxAllowed),
      child: Padding(
        // 数式の直後の文言（特に日本語）が詰まって見えやすいので、右側だけ少し広めにする
        padding: const EdgeInsets.fromLTRB(2.0, 2.0, 3.0, 2.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: core,
        ),
      ),
    );
  }

  // 正規表現パターン定義
  static final RegExp _paraSplit = RegExp(r'\n\s*\n', dotAll: true);

  /// インライン数式を検出: "\(x^2\)" → "x^2"
  static final RegExp _inlineParen = RegExp(r'\\\((.+?)\\\)', dotAll: true);

  /// ブロック数式を検出: "\[x^2 + y^2 = 1\]" → "x^2 + y^2 = 1"
  static final RegExp _blockBracket = RegExp(r'^\s*\\\[(.+?)\\\]\s*$', dotAll: true);

  static final RegExp _textMacro = RegExp(r'\\text\s*\{([^}]*)\}', dotAll: true);

  static final RegExp _envBlock = RegExp(
    r'^\s*\\begin\{(aligned|align\*?|alignedat|gather\*?|equation\*?|multline\*?)\}(.+?)\\end\{\1\}\s*$',
    dotAll: true,
  );

  List<Map<String, dynamic>> _splitByTextMacro(String s) {
    final out = <Map<String, dynamic>>[];
    int last = 0;
    for (final m in _textMacro.allMatches(s)) {
      if (m.start > last) {
        final between = s.substring(last, m.start);
        if (between.isNotEmpty) out.add({'isText': false, 'text': between});
      }
      final inner = m.group(1) ?? '';
      out.add({'isText': true, 'text': inner});
      last = m.end;
    }
    if (last < s.length) {
      final tail = s.substring(last);
      if (tail.isNotEmpty) out.add({'isText': false, 'text': tail});
    }
    return out;
  }

  Map<String, String> _extractPad(String s) {
    final leadingMatch = RegExp(r'^\s+').firstMatch(s);
    final trailingMatch = RegExp(r'\s+$').firstMatch(s);
    final leading = leadingMatch?.group(0) ?? '';
    final trailing = trailingMatch?.group(0) ?? '';
    final start = leading.length;
    final end = s.length - trailing.length;
    final core = (end > start) ? s.substring(start, end) : '';
    return {'leading': leading, 'core': core, 'trailing': trailing};
  }

  TextStyle _defaultLabelStyle(BuildContext context) {
    return labelStyle ?? const TextStyle(fontSize: 17, height: 1.35);
  }

  /// 1行の「TeX文章」（`\text{...}` を含む）を `Text.rich`（WidgetSpan）で描画する。
  ///
  /// - `\text{...}` の中身は通常テキストとして描画
  /// - `\text{...}` の外側は数式扱いで Math.tex を WidgetSpan として挿入
  /// - 数式とテキストの縦位置は baseline 基準で揃え、数式直後の文言との間に
  ///   ほんの少しだけスペース（thin space）を入れる
  Widget _buildSingleLineTextMacroRich(
    BuildContext context,
    String text,
    double maxW,
  ) {
    final parts = _splitByTextMacro(text);
    final defaultLabel = _defaultLabelStyle(context);
    final effectiveMath = mathStyle ?? const TextStyle(fontSize: 22);

    bool shouldAddThinSpaceAfterMath(String nextText) {
      if (nextText.isEmpty) return false;
      final first = nextText[0];
      if (first.trim().isEmpty) return false;
      // 句読点や閉じ括弧で始まるならスペース不要
      const noSpaceStarts = '。、，．,.)]}』」）';
      if (noSpaceStarts.contains(first)) return false;
      return true;
    }

    final spans = <InlineSpan>[];
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final isText = part['isText'] as bool;
      final content = (part['text'] as String);
      if (content.isEmpty) continue;

      if (isText) {
        spans.add(TextSpan(text: content, style: labelStyle ?? defaultLabel));
        continue;
      }

      final pad = _extractPad(content);
      final leading = pad['leading'] ?? '';
      final core = pad['core'] ?? '';
      final trailing = pad['trailing'] ?? '';

      if (leading.isNotEmpty) {
        spans.add(TextSpan(text: leading, style: labelStyle ?? defaultLabel));
      }

      final coreTrim = core.trim();
      if (coreTrim.isNotEmpty) {
        final tex = _promoteFractionsToDisplayStyle(_stripTexPrefix(coreTrim));
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              // 数式→直後の文言が詰まらないように、右側を少しだけ広げる
              padding: const EdgeInsets.only(left: 1.0, right: 2.0),
              child: _mathCoreSafe(tex, effectiveMath, mathStyle: MathStyle.text),
            ),
          ),
        );

        // 直後が \text{...} で、空白なしで続くなら薄いスペースを挿入
        if (i + 1 < parts.length) {
          final next = parts[i + 1];
          final nextIsText = next['isText'] as bool;
          final nextText = (next['text'] as String?) ?? '';
          if (nextIsText && shouldAddThinSpaceAfterMath(nextText)) {
            spans.add(TextSpan(text: '\u2009', style: labelStyle ?? defaultLabel));
          }
        }
      }

      if (trailing.isNotEmpty) {
        spans.add(TextSpan(text: trailing, style: labelStyle ?? defaultLabel));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(children: spans),
        softWrap: true,
        textAlign: TextAlign.left,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = mixed;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    // 1行ごとに見せたい用途（point等）向けに、単純な改行は「行分割して縦に積む」。
    // （空行を含む段落分割は従来通り _paraSplit で扱う）
    if (text.contains('\n') && !_paraSplit.hasMatch(text)) {
      final lines = text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (lines.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            MixedTextMath(
              line,
              labelStyle: labelStyle,
              mathStyle: mathStyle,
              forceTex: forceTex,
            ),
        ],
      );
    }

    // ★ LayoutBuilder撤去: 画面幅から安全なmaxWを作る（Dialogでも落ちない）
    final mediaW = MediaQuery.of(context).size.width;
    final maxW = (mediaW.isFinite && mediaW > 0) ? mediaW : 360.0;

    final hasTextMacro = text.contains(r'\text{');

    if (forceTex) {
      final tex = _stripTexPrefix(trimmed);
      // forceTex でも「\text{} を含む1行TeX文章」は自然改行させたい。
      // 例: 解答表示「\text{正解！} \text{単位は} ...」
      final isSingleLine = !tex.contains('\n') && !_paraSplit.hasMatch(tex);
      final hasInlineMath = tex.contains(r'\(') || tex.contains(r'\)');
      final hasBlockMath = tex.contains(r'\[') || tex.contains(r'\]');
      if (isSingleLine && hasTextMacro && !hasInlineMath && !hasBlockMath) {
        return _buildSingleLineTextMacroRich(context, tex, maxW);
      }

      return _blockMathWidget(tex, mathStyle ?? const TextStyle(fontSize: 22));
    }

    final bool hasParaBreak = _paraSplit.hasMatch(text);
    final bool isSingleLine = !hasParaBreak && !text.contains('\n');

    if (isSingleLine && _looksLikeMath(trimmed) && !hasTextMacro) {
      // 単独行で数式っぽいならブロックとして扱う
      final tex = _stripTexPrefix(trimmed);

      // \[...\] で包まれてたら中身だけにする
      final blockMatch = _blockBracket.firstMatch(tex);
      if (blockMatch != null) {
        return _blockMathWidget(blockMatch.group(1) ?? '', mathStyle ?? const TextStyle(fontSize: 22));
      }

      return _blockMathWidget(tex, mathStyle ?? const TextStyle(fontSize: 22));
    }

    final bool hasInlineMath = text.contains(r'\(') || text.contains(r'\)');
    final bool hasBlockMath = text.contains(r'\[') || text.contains(r'\]');
    final bool isLongPlain = text.length > 60 && text.contains(' ');

    if (hasParaBreak || hasInlineMath || hasBlockMath || hasTextMacro || isLongPlain) {
      // 1行の TeX（\text{} を含む）を「テキストspan + 数式widget」に分解すると、
      // inline側の SingleChildScrollView が baseline を提供できず、分数 + 後続英語の高さがズレやすい。
      // ここは丸ごと TeX として描画して、TeX内での \text{} に任せる。
      if (isSingleLine && hasTextMacro && !hasInlineMath && !hasBlockMath) {
        // 解答後に表示される「1行説明」はカード幅に合わせて自然改行させたい。
        // Math.tex で丸ごと描くと改行されず横スクロールになるため、\text{...} を境界に分割して Wrap する。
        return _buildSingleLineTextMacroRich(context, text, maxW);
      }

      final paragraphs = text.split(_paraSplit);
      final defaultLabel = _defaultLabelStyle(context);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.map((para) {
          final paraTrim = para.trim();
          if (paraTrim.isEmpty) return const SizedBox.shrink();

          // TeX環境ブロック
          final envMatch = _envBlock.firstMatch(paraTrim);
          if (envMatch != null) {
            final envBody = envMatch.group(0) ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Center(child: _blockMathWidget(envBody, mathStyle ?? const TextStyle(fontSize: 26))),
            );
          }

          // \[...\] のブロック数式
          final blockMatch = _blockBracket.firstMatch(paraTrim);
          if (blockMatch != null) {
            final mathBody = blockMatch.group(1) ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Center(child: _blockMathWidget(mathBody, mathStyle ?? const TextStyle(fontSize: 26))),
            );
          }

          // 文章でなく、明らかに数式だけの段落
          if (_looksLikeMath(paraTrim) && !paraTrim.contains(r'\text{') && !_inlineParen.hasMatch(paraTrim)) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: _blockMathWidget(paraTrim, mathStyle ?? const TextStyle(fontSize: 26)),
            );
          }

          // \text{} を含む場合は「数式中のテキスト」として処理
          if (para.contains(r'\text{')) {
            final parts = _splitByTextMacro(para);
            final spans = <InlineSpan>[];

            for (final part in parts) {
              final isText = part['isText'] as bool;
              final content = part['text'] as String;

              if (isText) {
                spans.add(TextSpan(text: content, style: labelStyle ?? defaultLabel));
              } else {
                final pad = _extractPad(content);
                final leading = pad['leading'] ?? '';
                final core = pad['core'] ?? '';
                final trailing = pad['trailing'] ?? '';

                if (leading.isNotEmpty) {
                  spans.add(TextSpan(text: leading, style: labelStyle ?? defaultLabel));
                }

                if (core.isNotEmpty) {
                  int lastIndex = 0;
                  bool foundInline = false;

                  for (final m in _inlineParen.allMatches(core)) {
                    foundInline = true;
                    if (m.start > lastIndex) {
                      spans.add(TextSpan(
                        text: core.substring(lastIndex, m.start),
                        style: labelStyle ?? defaultLabel,
                      ));
                    }
                    final mathBody = m.group(1) ?? '';
                    spans.add(WidgetSpan(
                      // テキストとインライン数式の高さを揃える（middleだと上下ズレしやすい）
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: _inlineMathWidgetConstrained(
                        mathBody,
                        maxW,
                        mathStyle ?? const TextStyle(fontSize: 22),
                      ),
                    ));
                    lastIndex = m.end;
                  }

                  if (foundInline) {
                    if (lastIndex < core.length) {
                      spans.add(TextSpan(text: core.substring(lastIndex), style: labelStyle ?? defaultLabel));
                    }
                  } else {
                    // \text{...} を含むTeX表現では、\text{} の外側は通常「数式モード」。
                    // ここをテキスト扱いにすると "g\text{...} m \cdot s^{-2}" のような
                    // 典型表現がTeXとして描画されず、単なる生文字になる。
                    final coreTrim = core.trim();
                    if (coreTrim.isNotEmpty) {
                      spans.add(WidgetSpan(
                        // テキストとインライン数式の高さを揃える（middleだと上下ズレしやすい）
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: _inlineMathWidgetConstrained(
                          coreTrim,
                          maxW,
                          mathStyle ?? const TextStyle(fontSize: 22),
                        ),
                      ));
                    }
                  }
                }

                if (trailing.isNotEmpty) {
                  spans.add(TextSpan(text: trailing, style: labelStyle ?? defaultLabel));
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text.rich(
                TextSpan(children: spans),
                softWrap: true,
                textAlign: TextAlign.left,
              ),
            );
          }

          // 通常段落：\(...\) だけインライン数式として拾う
          final spans = <InlineSpan>[];
          int lastIndex = 0;

          for (final m in _inlineParen.allMatches(para)) {
            if (m.start > lastIndex) {
              spans.add(TextSpan(
                text: para.substring(lastIndex, m.start),
                style: labelStyle ?? defaultLabel,
              ));
            }
            final mathBody = m.group(1) ?? '';
            spans.add(WidgetSpan(
              // テキストとインライン数式の高さを揃える（middleだと上下ズレしやすい）
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _inlineMathWidgetConstrained(
                mathBody,
                maxW,
                mathStyle ?? const TextStyle(fontSize: 22),
              ),
            ));
            lastIndex = m.end;
          }

          if (lastIndex < para.length) {
            spans.add(TextSpan(text: para.substring(lastIndex), style: labelStyle ?? defaultLabel));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text.rich(
              TextSpan(children: spans),
              softWrap: true,
              textAlign: TextAlign.left,
            ),
          );
        }).toList(),
      );
    }

    // "tex: ...." 形式
    final colonIndex = text.indexOf(':');
    final colonIndexFull = colonIndex >= 0 ? colonIndex : text.indexOf('：');
    if (colonIndexFull >= 0) {
      final leftRaw = text.substring(0, colonIndexFull).trim();
      final rightRaw = text.substring(colonIndexFull + 1).trim();

      if (leftRaw.toLowerCase() == 'tex') {
        final rightTex = _stripTexPrefix(rightRaw);
        final blockMatch = _blockBracket.firstMatch(rightTex);
        if (blockMatch != null) {
          return _blockMathWidget(blockMatch.group(1) ?? '', mathStyle ?? const TextStyle(fontSize: 22));
        }
        return _blockMathWidget(rightTex, mathStyle ?? const TextStyle(fontSize: 22));
      }

      final leftWidget = _looksLikeMath(leftRaw)
          ? _blockMathWidget(leftRaw, mathStyle ?? const TextStyle(fontSize: 20))
          : Text('$leftRaw:', style: labelStyle ?? _defaultLabelStyle(context));

      final rightWidget = rightRaw.isEmpty
          ? const SizedBox.shrink()
          : _blockMathWidget(rightRaw, mathStyle ?? const TextStyle(fontSize: 22));

      final leftCompact = Row(mainAxisSize: MainAxisSize.min, children: [leftWidget]);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(flex: 0, child: leftCompact),
          const SizedBox(width: 6),
          Expanded(child: rightWidget),
        ],
      );
    }

    // それっぽい境界推定（現状維持）
    final mathStartRegexp = RegExp(r'[=\\_\^]|\\bI_\\w|\\bint\\b|\\bfrac\\b', caseSensitive: false);
    final match = mathStartRegexp.firstMatch(text);
    if (match != null) {
      final idx = match.start;
      final left = text.substring(0, idx).trim();
      final right = text.substring(idx).trim();
      if (left.isEmpty) {
        return _blockMathWidget(right, mathStyle ?? const TextStyle(fontSize: 22));
      } else {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(flex: 0, child: Text('$left ', style: labelStyle ?? _defaultLabelStyle(context))),
            Flexible(child: _blockMathWidget(right, mathStyle ?? const TextStyle(fontSize: 22))),
          ],
        );
      }
    }

    // 最後のフォールバック（現状維持）
    return _blockMathWidget(trimmed, mathStyle ?? const TextStyle(fontSize: 22));
  }
}

/// 微分方程式ガチャ用のキーワードフィルタリング共通関数
Map<String, Set<String>> categorizeKeywords4Groups(Set<String> selected) {
  final group1 = {'数値', '一般'};
  final group2 = {'等加速度直線運動', '空気抵抗', '単振動'};
  final group3 = {'直流', '交流', '電圧0'};
  final group4 = {'コンデンサ', 'コイル', '抵抗'};

  return {
    'group1': selected.intersection(group1),
    'group2': selected.intersection(group2),
    'group3': selected.intersection(group3),
    'group4': selected.intersection(group4),
  };
}

List<MathProblem> filterProblemsByKeywords(List<MathProblem> problems, Set<String> selected) {
  if (selected.isEmpty) return [];

  final groups = categorizeKeywords4Groups(selected);
  final group1 = groups['group1']!;
  final group2 = groups['group2']!;
  final group3 = groups['group3']!;
  final group4 = groups['group4']!;

  final group2All = {'等加速度直線運動', '空気抵抗', '単振動'};
  final group4All = {'コンデンサ', 'コイル', '抵抗'};

  final filtered = problems.where((p) {
    if (p.keywords.isEmpty) return false;

    bool group1Match = false;
    if (group1.isNotEmpty) {
      group1Match = p.keywords.any((k) => group1.contains(k));
    }

    bool group2Match = false;
    if (group2.isNotEmpty) {
      final hasSelected = p.keywords.any((k) => group2.contains(k));
      if (hasSelected) {
        final unselected = group2All.difference(group2);
        final hasUnselected = p.keywords.any((k) => unselected.contains(k));
        if (!hasUnselected) {
          group2Match = true;
        }
      }
    }

    bool group3Match = false;
    if (group3.isNotEmpty) {
      group3Match = p.keywords.any((k) => group3.contains(k));
    }

    bool group4Match = false;
    if (group4.isNotEmpty) {
      final hasSelected = p.keywords.any((k) => group4.contains(k));
      if (hasSelected) {
        final unselected = group4All.difference(group4);
        final hasUnselected = p.keywords.any((k) => unselected.contains(k));
        if (!hasUnselected) {
          group4Match = true;
        }
      }
    }

    bool x = false;
    if (group3.isNotEmpty && group4.isNotEmpty) {
      x = group3Match && group4Match;
    }

    bool y = group2.isNotEmpty ? (group2Match || x) : x;

    bool matches = group1.isNotEmpty ? (group1Match && y) : false;

    return matches;
  }).toList();

  if (selected.contains('大学')) {
    final hasNumerical = selected.contains('数値');
    final hasGeneral = selected.contains('一般');

    final yg = <MathProblem>[];
    if (hasGeneral) {
      yg.addAll(problems.where((p) {
        final keywordsSet = p.keywords.toSet();
        return keywordsSet.length == 2 && keywordsSet.contains('大学') && keywordsSet.contains('一般');
      }));
    }

    final yc = <MathProblem>[];
    if (hasNumerical) {
      yc.addAll(problems.where((p) {
        final keywordsSet = p.keywords.toSet();
        return keywordsSet.length == 2 && keywordsSet.contains('大学') && keywordsSet.contains('数値');
      }));
    }

    final universityProblems = <MathProblem>[];
    if (hasNumerical && hasGeneral) {
      final resultIds = <String>{};
      for (final p in yg) {
        if (!resultIds.contains(p.id)) {
          resultIds.add(p.id);
          universityProblems.add(p);
        }
      }
      for (final p in yc) {
        if (!resultIds.contains(p.id)) {
          resultIds.add(p.id);
          universityProblems.add(p);
        }
      }
    } else if (hasGeneral) {
      universityProblems.addAll(yg);
    } else if (hasNumerical) {
      universityProblems.addAll(yc);
    }

    final resultIds = <String>{};
    final result = <MathProblem>[];

    for (final p in filtered) {
      if (!resultIds.contains(p.id)) {
        resultIds.add(p.id);
        result.add(p);
      }
    }

    for (final p in universityProblems) {
      if (!resultIds.contains(p.id)) {
        resultIds.add(p.id);
        result.add(p);
      }
    }

    return result;
  }

  return filtered;
}
