// lib/services/unit_calculator_service.dart
// 単位計算・採点ロジック

import '../../problems/unit/symbol.dart';

/// 単位の正規化表現
class NormalizedUnit {
  final Map<String, int> baseUnits; // 例: {'kg': 1, 'm': 1, 's': -2}
  
  NormalizedUnit(this.baseUnits);
  
  /// 文字列から正規化単位を作成
  /// 複合単位（N, Paなど）も基本単位に変換して処理
  factory NormalizedUnit.fromString(String unitStr) {
    // 複合単位のマッピング
    final compoundUnitMap = {
      'J': 'kg m^2 s^-2', // Joule
      'N': 'kg m s^-2', // Newton
      'W': 'kg m^2 s^-3', // Watt
      'Pa': 'kg m^-1 s^-2', // Pascal
      'Hz': 's^-1', // Hertz
      'C': 'A s', // Coulomb
      'V': 'kg m^2 s^-3 A^-1', // Volt
      'Ω': 'kg m^2 s^-3 A^-2', // Ohm
      'F': 'kg^-1 m^-2 s^4 A^2', // Farad
      'H': 'kg m^2 s^-2 A^-2', // Henry
      'T': 'kg s^-2 A^-1', // Tesla
      'Wb': 'kg m^2 s^-2 A^-1', // Weber
      // アプリ内データの揺れ対策（次元のみ合わせたい用途のため、スケール差は無視）
      'g': 'kg', // gram (treat as kg for dimension check)
    };
    
    // バックスラッシュを除去（TeXコマンドの誤入力などを防ぐ）
    // "/", "()" を含む単位表記（例: "N/m", "J/(mol·K)"）も扱えるようにする。
    String normalized = unitStr
        .replaceAll('\\', '')
        .replaceAll('·', ' ')
        .replaceAll('*', ' ')
        .replaceAll('×', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .trim();

    // "/" をトークンとして扱うため、間に空白を入れる
    normalized = normalized.replaceAll('/', ' / ');

    final rawParts = normalized.split(RegExp(r'\s+'));
    final units = <String, int>{};

    // a/b/c = a/(b*c) なので、最初の/以降は分母として扱う
    var denom = false;

    void addToken(String token, {required bool denomSide}) {
      // "kg", "m^2", "s^-2", "Ω", "mol" など（Ωにも対応）
      final m = RegExp(r'^([\wΩ]+)(?:\^([+-]?\d+))?$').firstMatch(token);
      if (m == null) return;
      final unit = m.group(1)!;
      final powerStr = m.group(2);
      final power = powerStr != null ? int.parse(powerStr) : 1;
      final signedPower = denomSide ? -power : power;

      // 複合単位を基本単位に展開
      if (compoundUnitMap.containsKey(unit)) {
        final base = compoundUnitMap[unit]!;
        final baseParts = base.split(RegExp(r'\s+'));
        for (final bp in baseParts) {
          // 展開先は常に「基本単位の積」なので denomSide は signedPower の符号に吸収する
          final bm = RegExp(r'^([\wΩ]+)(?:\^([+-]?\d+))?$').firstMatch(bp);
          if (bm == null) continue;
          final bu = bm.group(1)!;
          final bpStr = bm.group(2);
          final bpPow = bpStr != null ? int.parse(bpStr) : 1;
          units[bu] = (units[bu] ?? 0) + bpPow * signedPower;
        }
        return;
      }

      units[unit] = (units[unit] ?? 0) + signedPower;
    }

    for (final p in rawParts) {
      if (p.isEmpty) continue;
      if (p == '/') {
        denom = true;
        continue;
      }
      addToken(p, denomSide: denom);
    }
    
    // 0の指数を削除
    units.removeWhere((key, value) => value == 0);
    
    return NormalizedUnit(units);
  }
  
  /// 1文字単位（J, N, Wなど）を基本単位に変換
  static NormalizedUnit fromSingleUnit(String unit) {
    // バックスラッシュを除去（TeXコマンドの誤入力などを防ぐ）
    // "(無次元)"などを除去
    final cleanedUnit = unit
        .replaceAll('\\', '')  // バックスラッシュを除去
        .replaceAll(RegExp(r'\s*\(.*\)'), '')
        .trim();
    
    // 1または空文字列は無次元
    if (cleanedUnit == '1' || cleanedUnit.isEmpty) {
      return NormalizedUnit({});
    }

    // よく使われる単位のマッピング
    final unitMap = {
      'J': NormalizedUnit.fromString('kg m^2 s^-2'), // Joule
      'N': NormalizedUnit.fromString('kg m s^-2'), // Newton
      'W': NormalizedUnit.fromString('kg m^2 s^-3'), // Watt
      'Pa': NormalizedUnit.fromString('kg m^-1 s^-2'), // Pascal
      'Hz': NormalizedUnit.fromString('s^-1'), // Hertz
      'C': NormalizedUnit.fromString('A s'), // Coulomb
      'V': NormalizedUnit.fromString('kg m^2 s^-3 A^-1'), // Volt
      'Ω': NormalizedUnit.fromString('kg m^2 s^-3 A^-2'), // Ohm
      'F': NormalizedUnit.fromString('kg^-1 m^-2 s^4 A^2'), // Farad
      'H': NormalizedUnit.fromString('kg m^2 s^-2 A^-2'), // Henry
      'T': NormalizedUnit.fromString('kg s^-2 A^-1'), // Tesla
      'Wb': NormalizedUnit.fromString('kg m^2 s^-2 A^-1'), // Weber
      // 基本単位も追加（singleUnitモードでも基本単位が正解の場合があるため）
      'kg': NormalizedUnit({'kg': 1}),
      'm': NormalizedUnit({'m': 1}),
      's': NormalizedUnit({'s': 1}),
      'A': NormalizedUnit({'A': 1}),
      'K': NormalizedUnit({'K': 1}),
      'mol': NormalizedUnit({'mol': 1}),
      'cd': NormalizedUnit({'cd': 1}),
      'rad': NormalizedUnit({'rad': 1}),
    };
    
    if (unitMap.containsKey(cleanedUnit)) {
      return unitMap[cleanedUnit]!;
    }

    // マッピングにない場合は、通常の単位パースを試みる
    // これにより "N s" や "m s^-1" などの複合単位も受け入れられるようになる
    try {
      return NormalizedUnit.fromString(cleanedUnit);
    } catch (e) {
      // パース失敗時はエラー
      throw FormatException('Unknown unit: $unit');
    }
  }
  
  /// 等価性チェック
  bool equals(NormalizedUnit other) {
    if (baseUnits.length != other.baseUnits.length) return false;
    
    for (final entry in baseUnits.entries) {
      if (other.baseUnits[entry.key] != entry.value) {
        return false;
      }
    }
    
    return true;
  }
  
  /// 文字列表現
  @override
  String toString() {
    if (baseUnits.isEmpty) return '1';
    
    // kg m s A の順にソート
    const unitOrder = ['kg', 'm', 's', 'A'];
    final parts = <String>[];
    
    // 順序に従ってソート
    final sortedUnits = <String>[];
    for (final orderedUnit in unitOrder) {
      if (baseUnits.containsKey(orderedUnit)) {
        sortedUnits.add(orderedUnit);
      }
    }
    // 順序にない単位も追加
    for (final unitKey in baseUnits.keys) {
      if (!unitOrder.contains(unitKey)) {
        sortedUnits.add(unitKey);
      }
    }
    
    for (final unitKey in sortedUnits) {
      final value = baseUnits[unitKey]!;
      if (value == 1) {
        parts.add(unitKey);
      } else {
        parts.add('$unitKey^$value');
      }
    }
    return parts.join('·');
  }
}

/// 単位計算サービス
class UnitCalculatorService {
  /// 単位の日本語名マッピング
  static const Map<String, String> unitNamesJa = {
    'J': 'ジュール',
    'N': 'ニュートン',
    'W': 'ワット',
    'Pa': 'パスカル',
    'Hz': 'ヘルツ',
    'C': 'クーロン',
    'V': 'ボルト',
    'Ω': 'オーム',
    'F': 'ファラド',
    'H': 'ヘンリー',
    'T': 'テスラ',
    'Wb': 'ウェーバー',
    'A': 'アンペア',
    'K': 'ケルビン',
    'm': 'メートル',
    's': '秒',
    'kg': 'キログラム',
    'rad': 'ラジアン',
  };

  /// 式から正解単位を計算
  /// expr: "m*g", defs: [SymbolDef for m, SymbolDef for g]
  static NormalizedUnit calculateCorrectUnit(String expr, List<SymbolDef> defs) {
    // TeX/暗黙の掛け算（Ft, GMm, mv^2 など）を含む式でも
    // 指数法則で安定して単位計算できるようにする。
    try {
      return _calculateCorrectUnitByParsing(expr, defs);
    } catch (_) {
      // 予期せぬ入力で落ちないように保険（UIが壊れるのを防ぐ）
      return NormalizedUnit({});
    }
  }

  // ===== Robust parser (TeX/implicit multiplication supported) =====

  static NormalizedUnit _calculateCorrectUnitByParsing(
    String expr,
    List<SymbolDef> defs,
  ) {
    final normalized = _normalizeExprForUnitCalc(expr, defs);
    var tokens = _tokenizeExpr(normalized, defs);
    tokens = _fillEmptyParensWithOne(tokens);

    // 例外データ対策:
    // exprが1文字だがdefsが別記号のみ、などで記号が拾えない場合は「唯一のdefs」を採用する。
    final hasAnySymbol = tokens.any((t) => t.kind == _ExprTokKind.sym);
    if (!hasAnySymbol && defs.length == 1) {
      tokens = [_ExprTok.sym(defs.first.symbol)];
    }
    final withImplicitMul = _insertImplicitMultiplication(tokens);
    final rpn = _toRpn(withImplicitMul);
    final unitMap = _evalRpn(rpn, defs);
    return _doubleMapToNormalized(unitMap);
  }

  static String _normalizeExprForUnitCalc(String expr, List<SymbolDef> defs) {
    var s = expr.replaceAll(' ', '');

    // TeX layout helpers
    s = s.replaceAll(r'\left', '').replaceAll(r'\right', '');

    // Multiplication markers
    s = s.replaceAll(r'\cdot', '*').replaceAll(r'\times', '*');
    s = s.replaceAll('·', '*').replaceAll('×', '*');

    // Expand \frac{a}{b} -> (a)/(b) (nested)
    s = _expandLatexFrac(s);
    // Expand \sqrt{a} -> (a)^(1/2)
    s = _expandLatexSqrt(s);
    // Expand √(a) / sqrt(a)
    s = _processSquareRoots(s);

    // Common TeX macros
    const macroMap = <String, String>{
      r'\pi': '',
      r'\cos': '',
      r'\sin': '',
      r'\tan': '',
      r'\log': '',
      r'\ln': '',
      r'\exp': '',
      r'\Delta': 'Δ',
      r'\mu': 'μ',
      r'\epsilon': 'ε',
      r'\omega': 'ω',
      r'\theta': 'θ',
      r'\lambda': 'λ',
      r'\rho': 'ρ',
      r'\Phi': 'Φ',
      r'\ell': 'ℓ',
    };
    for (final e in macroMap.entries) {
      s = s.replaceAll(e.key, e.value);
    }

    // defsのtexSymbolがある場合は、それをsymbolに寄せる（長い順）
    final texDefs = defs.where((d) => (d.texSymbol ?? '').isNotEmpty).toList()
      ..sort((a, b) => b.texSymbol!.length.compareTo(a.texSymbol!.length));
    for (final d in texDefs) {
      s = s.replaceAll(d.texSymbol!, d.symbol);
    }

    // {} は評価には不要
    s = s.replaceAll('{', '').replaceAll('}', '');
    return s;
  }

  static String _expandLatexFrac(String s) {
    var out = s;
    while (true) {
      final idx = out.indexOf(r'\frac');
      if (idx < 0) break;
      final start = idx + r'\frac'.length;
      final (num, numEnd) = _readBraced(out, start);
      if (numEnd < 0) break;
      final (den, denEnd) = _readBraced(out, numEnd);
      if (denEnd < 0) break;
      out = out.replaceRange(idx, denEnd, '($num)/($den)');
    }
    return out;
  }

  static String _expandLatexSqrt(String s) {
    var out = s;
    while (true) {
      final idx = out.indexOf(r'\sqrt');
      if (idx < 0) break;
      final start = idx + r'\sqrt'.length;
      if (start < out.length && out[start] == '{') {
        final (inner, end) = _readBraced(out, start);
        if (end < 0) break;
        out = out.replaceRange(idx, end, '($inner)^(1/2)');
        continue;
      }
      break;
    }
    return out;
  }

  /// Reads a braced group starting at '{'. Returns (content, endIndexExclusive).
  static (String content, int end) _readBraced(String s, int braceStart) {
    if (braceStart < 0 || braceStart >= s.length || s[braceStart] != '{') {
      return ('', -1);
    }
    var depth = 0;
    for (var i = braceStart; i < s.length; i++) {
      final ch = s[i];
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      if (depth == 0) {
        return (s.substring(braceStart + 1, i), i + 1);
      }
    }
    return ('', -1);
  }

  static List<_ExprTok> _tokenizeExpr(String s, List<SymbolDef> defs) {
    final candidateToCanonical = <String, String>{};
    final candidates = <String>[];
    for (final d in defs) {
      final sym = d.symbol;
      candidates.add(sym);
      candidateToCanonical[sym] = sym;

      // ε0 / μ0 のような「下付き数字」が、TeX由来で ε_0 になるケースに対応
      if (!sym.contains('_')) {
        final m = RegExp(r'^(.*?)(\d+)$').firstMatch(sym);
        if (m != null) {
          final alt = '${m.group(1)}_${m.group(2)}';
          candidates.add(alt);
          candidateToCanonical[alt] = sym;
        }
      }
    }
    candidates.sort((a, b) => b.length.compareTo(a.length));
    final out = <_ExprTok>[];
    var i = 0;

    while (i < s.length) {
      final ch = s[i];

      if (ch == '(') {
        out.add(const _ExprTok.lparen());
        i++;
        continue;
      }
      if (ch == ')') {
        out.add(const _ExprTok.rparen());
        i++;
        continue;
      }
      if (ch == '*' || ch == '/' || ch == '^') {
        out.add(_ExprTok.op(ch));
        i++;
        continue;
      }
      if (ch == '+' || ch == '-') {
        i++;
        continue;
      }

      if (_isDigit(ch) || ch == '.') {
        final (v, next) = _readNumber(s, i);
        out.add(_ExprTok.num(v));
        i = next;
        continue;
      }

      // derivative prefix: dS, dt
      if (ch == 'd' && i + 1 < s.length) {
        final (cand, len) = _matchSymbolAt(s, i + 1, candidates);
        if (len > 0) {
          out.add(_ExprTok.sym(candidateToCanonical[cand] ?? cand));
          i = i + 1 + len;
          continue;
        }
      }

      final (cand, len) = _matchSymbolAt(s, i, candidates);
      if (len > 0) {
        out.add(_ExprTok.sym(candidateToCanonical[cand] ?? cand));
        i += len;
        continue;
      }

      // Unknown char → ignore (dimensionless)
      i++;
    }

    return out;
  }

  static List<_ExprTok> _fillEmptyParensWithOne(List<_ExprTok> toks) {
    // 記号が拾えないことで "()" だけが残るケース（例: \frac{mv^2}{r} で r がdefsに無い）
    // ここを「1（無次元）」として扱わないと、RPN評価で演算子のオペランド不足が起きて逆数になる。
    final out = <_ExprTok>[];
    for (var i = 0; i < toks.length; i++) {
      final t = toks[i];
      out.add(t);
      if (t.kind == _ExprTokKind.lparen &&
          i + 1 < toks.length &&
          toks[i + 1].kind == _ExprTokKind.rparen) {
        out.add(const _ExprTok.num(1.0));
      }
    }
    return out;
  }

  static List<_ExprTok> _insertImplicitMultiplication(List<_ExprTok> toks) {
    bool canEnd(_ExprTok t) =>
        t.kind == _ExprTokKind.sym ||
        t.kind == _ExprTokKind.num ||
        t.kind == _ExprTokKind.rparen;
    bool canStart(_ExprTok t) =>
        t.kind == _ExprTokKind.sym ||
        t.kind == _ExprTokKind.num ||
        t.kind == _ExprTokKind.lparen;

    final out = <_ExprTok>[];
    for (var i = 0; i < toks.length; i++) {
      if (i > 0 && canEnd(toks[i - 1]) && canStart(toks[i])) {
        if (out.isNotEmpty &&
            out.last.kind == _ExprTokKind.op &&
            out.last.op == '^') {
          // no-op
        } else {
          out.add(const _ExprTok.op('*'));
        }
      }
      out.add(toks[i]);
    }
    return out;
  }

  static List<_ExprTok> _toRpn(List<_ExprTok> toks) {
    int prec(String op) {
      switch (op) {
        case '^':
          return 3;
        case '*':
        case '/':
          return 2;
        default:
          return 0;
      }
    }

    bool rightAssoc(String op) => op == '^';

    final out = <_ExprTok>[];
    final stack = <_ExprTok>[];

    for (final t in toks) {
      switch (t.kind) {
        case _ExprTokKind.sym:
        case _ExprTokKind.num:
          out.add(t);
          break;
        case _ExprTokKind.op:
          while (stack.isNotEmpty && stack.last.kind == _ExprTokKind.op) {
            final top = stack.last;
            final p1 = prec(t.op!);
            final p2 = prec(top.op!);
            final shouldPop = rightAssoc(t.op!) ? p1 < p2 : p1 <= p2;
            if (!shouldPop) break;
            out.add(stack.removeLast());
          }
          stack.add(t);
          break;
        case _ExprTokKind.lparen:
          stack.add(t);
          break;
        case _ExprTokKind.rparen:
          while (stack.isNotEmpty && stack.last.kind != _ExprTokKind.lparen) {
            out.add(stack.removeLast());
          }
          if (stack.isNotEmpty && stack.last.kind == _ExprTokKind.lparen) {
            stack.removeLast();
          }
          break;
      }
    }

    while (stack.isNotEmpty) {
      out.add(stack.removeLast());
    }
    return out;
  }

  static Map<String, double> _evalRpn(List<_ExprTok> rpn, List<SymbolDef> defs) {
    final symbolMap = <String, SymbolDef>{for (final d in defs) d.symbol: d};
    final stack = <Object>[];

    Map<String, double> asUnit(Object o) {
      if (o is Map<String, double>) return o;
      return <String, double>{};
    }

    double asNum(Object o) => o is double ? o : 1.0;

    for (final t in rpn) {
      if (t.kind == _ExprTokKind.num) {
        stack.add(t.number!);
        continue;
      }
      if (t.kind == _ExprTokKind.sym) {
        final def = symbolMap[t.symbol!];
        final unitSource = def?.baseUnits ?? def?.unitSymbol;
        if (unitSource == null ||
            unitSource.trim().isEmpty ||
            unitSource.trim() == '1' ||
            unitSource.trim() == '無次元') {
          stack.add(<String, double>{});
          continue;
        }
        final u = NormalizedUnit.fromString(unitSource);
        stack.add(u.baseUnits.map((k, v) => MapEntry(k, v.toDouble())));
        continue;
      }
      if (t.kind == _ExprTokKind.op) {
        final op = t.op!;
        if (op == '^') {
          final exp = stack.isNotEmpty ? stack.removeLast() : 1.0;
          final base = stack.isNotEmpty ? stack.removeLast() : <String, double>{};
          final e = asNum(exp);
          final b = asUnit(base);
          final out = <String, double>{};
          for (final ent in b.entries) {
            out[ent.key] = ent.value * e;
          }
          stack.add(out);
        } else if (op == '*' || op == '/') {
          final right = stack.isNotEmpty ? stack.removeLast() : <String, double>{};
          final left = stack.isNotEmpty ? stack.removeLast() : <String, double>{};
          final a = asUnit(left);
          final b = asUnit(right);
          final out = <String, double>{}..addAll(a);
          for (final ent in b.entries) {
            out[ent.key] = (out[ent.key] ?? 0.0) + (op == '*' ? ent.value : -ent.value);
          }
          out.removeWhere((k, v) => v.abs() < 1e-12);
          stack.add(out);
        }
      }
    }

    if (stack.isEmpty) return <String, double>{};
    return asUnit(stack.last);
  }

  static NormalizedUnit _doubleMapToNormalized(Map<String, double> m) {
    final out = <String, int>{};
    for (final e in m.entries) {
      final v = e.value;
      if (v.abs() < 1e-12) continue;
      final r = v.round();
      out[e.key] = (v - r).abs() < 1e-9 ? r : r;
    }
    out.removeWhere((k, v) => v == 0);
    return NormalizedUnit(out);
  }

  static bool _isDigit(String ch) =>
      ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

  static (double v, int next) _readNumber(String s, int start) {
    var i = start;
    var hasSlash = false;
    while (i < s.length) {
      final ch = s[i];
      if (_isDigit(ch) || ch == '.') {
        i++;
        continue;
      }
      if (ch == '/' && !hasSlash) {
        hasSlash = true;
        i++;
        continue;
      }
      break;
    }
    final raw = s.substring(start, i);
    if (raw.contains('/')) {
      final parts = raw.split('/');
      if (parts.length == 2) {
        final a = double.tryParse(parts[0]) ?? 0.0;
        final b = double.tryParse(parts[1]) ?? 1.0;
        return (b == 0 ? 0.0 : a / b, i);
      }
    }
    return (double.tryParse(raw) ?? 0.0, i);
  }

  static (String sym, int len) _matchSymbolAt(
    String s,
    int start,
    List<String> candidates,
  ) {
    for (final c in candidates) {
      if (c.isEmpty) continue;
      if (start + c.length <= s.length &&
          s.substring(start, start + c.length) == c) {
        return (c, c.length);
      }
    }
    return ('', 0);
  }
  
  /// 単位の乗算
  static NormalizedUnit _multiplyUnits(NormalizedUnit a, NormalizedUnit b) {
    final result = Map<String, int>.from(a.baseUnits);
    
    for (final entry in b.baseUnits.entries) {
      result[entry.key] = (result[entry.key] ?? 0) + entry.value;
    }
    
    result.removeWhere((key, value) => value == 0);
    return NormalizedUnit(result);
  }
  
  /// 単位の除算
  static NormalizedUnit _divideUnits(NormalizedUnit a, NormalizedUnit b) {
    final result = Map<String, int>.from(a.baseUnits);
    
    for (final entry in b.baseUnits.entries) {
      result[entry.key] = (result[entry.key] ?? 0) - entry.value;
    }
    
    result.removeWhere((key, value) => value == 0);
    return NormalizedUnit(result);
  }
  
  /// ルート記号（√）を処理: √(x) → (x)^(1/2)
  static String _processSquareRoots(String expr) {
    // 全角・半角の√記号に対応
    String result = expr;
    
    // √記号を検出（全角√、またはsqrt）
    while (true) {
      // 全角√を検出
      int sqrtIndex = result.indexOf('√');
      if (sqrtIndex == -1) {
        // sqrt( の形式を検出
        sqrtIndex = result.indexOf('sqrt');
        if (sqrtIndex == -1) {
          break;
        }
        // sqrt( の形式を処理
        final afterSqrt = result.substring(sqrtIndex + 4);
        if (afterSqrt.isEmpty || afterSqrt[0] != '(') {
          break;
        }
        // 括弧内の式を抽出（最初の'('を含む）
        final innerExpr = _extractParenthesized(afterSqrt);
        if (innerExpr == null) {
          break;
        }
        // sqrt(式) → (式)^(1/2) に変換（innerExprは既に括弧を含んでいる）
        final before = result.substring(0, sqrtIndex);
        final after = afterSqrt.substring(innerExpr.length);
        result = '$before$innerExpr^(1/2)$after';
        continue;
      }
      
      // √の後の文字を確認
      final afterSqrt = result.substring(sqrtIndex + 1);
      if (afterSqrt.isEmpty) {
        break;
      }
      
      // √( の形式を処理
      if (afterSqrt[0] == '(') {
        // 括弧内の式を抽出（最初の'('を含む）
        final innerExpr = _extractParenthesized(afterSqrt);
        if (innerExpr == null) {
          break;
        }
        // √(式) → (式)^(1/2) に変換（innerExprは既に括弧を含んでいる）
        final before = result.substring(0, sqrtIndex);
        final after = afterSqrt.substring(innerExpr.length);
        result = '$before$innerExpr^(1/2)$after';
      } else {
        // √の直後に括弧がない場合は、次の記号までを抽出（簡易実装）
        // ただし、通常は√(式)の形式なので、ここではスキップ
        break;
      }
    }
    
    return result;
  }
  
  /// 括弧内の式を抽出（ネストされた括弧にも対応）
  /// 入力は '(' から始まる文字列を想定
  static String? _extractParenthesized(String expr) {
    if (expr.isEmpty || expr[0] != '(') {
      return null;
    }
    
    int depth = 0;
    int endIndex = -1;
    
    for (int i = 0; i < expr.length; i++) {
      if (expr[i] == '(') {
        depth++;
      } else if (expr[i] == ')') {
        depth--;
        if (depth == 0) {
          endIndex = i + 1;
          break;
        }
      }
    }
    
    if (endIndex == -1) {
      return null; // 対応する閉じ括弧が見つからない
    }
    
    // '('を含めて返す（例: "(ε0*μ0)"）
    return expr.substring(0, endIndex);
  }
  
  /// ユーザー入力と正解単位を比較
  static bool compareUnits(String userInput, NormalizedUnit correctUnit, {bool isSingleUnitMode = false}) {
    try {
      NormalizedUnit userUnit;
      
      if (isSingleUnitMode) {
        // 1文字単位モード
        userUnit = NormalizedUnit.fromSingleUnit(userInput.trim());
      } else {
        // 基本単位系モード
        userUnit = NormalizedUnit.fromString(userInput);
      }
      
      return userUnit.equals(correctUnit);
    } catch (e) {
      return false;
    }
  }
  
  /// 正解単位を文字列で取得（表示用）
  static String getCorrectUnitString(String expr, List<SymbolDef> defs, {bool preferSingleUnit = false}) {
    final unit = calculateCorrectUnit(expr, defs);
    
    if (preferSingleUnit) {
      // 1文字単位に変換できるかチェック
      final singleUnitMap = {
        'kg·m^2·s^-2': 'J',
        'kg·m·s^-2': 'N',
        'kg·m^2·s^-3': 'W',
        'kg·m^-1·s^-2': 'Pa',
        's^-1': 'Hz',
        'A·s': 'C',
        'kg·m^2·s^-3·A^-1': 'V',
        'kg·m^2·s^-3·A^-2': 'Ω',
        'kg^-1·m^-2·s^4·A^2': 'F',
        'kg·m^2·s^-2·A^-2': 'H',
        'kg·s^-2·A^-1': 'T',
        'kg·m^2·s^-2·A^-1': 'Wb',
      };
      
      // 単位文字列を取得（・区切り）
      final unitStr = unit.toString();
      // マッピングのキーと比較（・区切りで統一）
      if (singleUnitMap.containsKey(unitStr)) {
        return singleUnitMap[unitStr]!;
      }
      // マッピングにない場合は基本単位系で返す（1文字電卓でも基本単位系で答える場合がある）
      // ただし、通常はマッピングに含まれるはず
    }
    
    // 基本単位系の場合、スペース区切りで返す（入力しやすいように）
    // kg m s A の順にソート
    const unitOrder = ['kg', 'm', 's', 'A'];
    final parts = <String>[];
    
    // 順序に従ってソート
    final sortedUnits = <String>[];
    for (final orderedUnit in unitOrder) {
      if (unit.baseUnits.containsKey(orderedUnit)) {
        sortedUnits.add(orderedUnit);
      }
    }
    // 順序にない単位も追加
    for (final unitKey in unit.baseUnits.keys) {
      if (!unitOrder.contains(unitKey)) {
        sortedUnits.add(unitKey);
      }
    }
    
    for (final unitKey in sortedUnits) {
      final value = unit.baseUnits[unitKey]!;
      if (value == 1) {
        parts.add(unitKey);
      } else if (value == -1) {
        parts.add('$unitKey^-1');
      } else {
        parts.add('$unitKey^$value');
      }
    }
    if (parts.isEmpty) {
      return '1';
    }
    return parts.join(' ');
  }
}

// ===== Expression token model (unit calculation) =====

enum _ExprTokKind { sym, num, op, lparen, rparen }

class _ExprTok {
  final _ExprTokKind kind;
  final String? symbol;
  final double? number;
  final String? op;

  const _ExprTok._(this.kind, {this.symbol, this.number, this.op});

  const _ExprTok.lparen() : this._(_ExprTokKind.lparen);
  const _ExprTok.rparen() : this._(_ExprTokKind.rparen);
  const _ExprTok.op(String op) : this._(_ExprTokKind.op, op: op);
  const _ExprTok.sym(String symbol) : this._(_ExprTokKind.sym, symbol: symbol);
  const _ExprTok.num(double number) : this._(_ExprTokKind.num, number: number);
}

