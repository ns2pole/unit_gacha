// lib/pages/gacha/formatting/unit_formatters.dart
// 単位ガチャページ用のフォーマッター（TeX形式への変換など）
// 単位ガチャページ用のフォーマッター（TeX形式への変換など）

/// 単位文字列をTeX形式に変換（例：kg m s^-1 → \frac{kg \cdot m}{s}）
String formatUnitString(String unitStr) {
  String formatted = unitStr.trim();
  
  // 無次元やdimensionlessはテキストとして表示
  if (formatted == '無次元' || formatted.toLowerCase() == 'dimensionless') {
    return r'\text{' + formatted + r'}';
  }
  
  if (formatted.contains('(') && formatted.contains(')')) {
    final openParenIndex = formatted.indexOf('(');
    final closeParenIndex = formatted.lastIndexOf(')');
    
    if (openParenIndex < closeParenIndex) {
      final beforeParen = formatted.substring(0, openParenIndex);
      final inParen = formatted.substring(openParenIndex + 1, closeParenIndex);
      final afterParen = formatted.substring(closeParenIndex + 1);
      final processedInParen = inParen.replaceAll('·', r' \cdot ');
      
      String processedBefore = '';
      if (beforeParen.isNotEmpty) {
        if (beforeParen.contains('/')) {
          final parts = beforeParen.split('/');
          processedBefore = (parts.length == 2 ? parts[0].trim() : beforeParen.trim()) + 
              r'/\left(' + processedInParen + r'\right)';
        } else {
          processedBefore = beforeParen.trim() + r'/\left(' + processedInParen + r'\right)';
        }
      } else {
        processedBefore = r'\left(' + processedInParen + r'\right)';
      }
      
      return afterParen.isNotEmpty ? processedBefore + ' ' + afterParen.trim() : processedBefore;
    }
  }
  
  final parts = formatted.split(RegExp(r'\s+'));
  final numeratorParts = <String>[];
  final denominatorParts = <String>[];
  
  for (final part in parts) {
    if (part.isEmpty) continue;
    
    if (part.contains('^-')) {
      final match = RegExp(r'(\w+)\^(-?\d+)').firstMatch(part);
      if (match != null) {
        final base = match.group(1)!;
        final power = match.group(2)!;
        final absPower = power.startsWith('-') ? power.substring(1) : power;
        denominatorParts.add(absPower == '1' ? base : '$base^{$absPower}');
      }
    } else if (part.contains('^')) {
      final match = RegExp(r'(\w+)\^(\d+)').firstMatch(part);
      numeratorParts.add(match != null ? '${match.group(1)}^{${match.group(2)}}' : part);
    } else {
      numeratorParts.add(part);
    }
  }
  
  if (denominatorParts.isEmpty) {
    return numeratorParts.join(r' \cdot ');
  } else if (numeratorParts.isEmpty) {
    return '1/' + denominatorParts.join(r' \cdot ');
  } else {
    return r'\frac{' + numeratorParts.join(r' \cdot ') + '}{' + denominatorParts.join(r' \cdot ') + '}';
  }
}

/// 記号定義の「単位」表示用:
/// - 元データの unitSymbol は "N·m^2/kg^2", "kg·m·s^-2", "m/s^2" など（TeXではない）
/// - MixedTextMath の「\text{}境界でWrap」ロジックを使うため、区切り記号を \text{...} に寄せる
///
/// 例:
/// - "kg·m·s^-2" -> r"kg\text{·}m\text{·}s^{-2}"
/// - "N/m" -> r"N\text{/}m"
String formatUnitSymbolForMixedTextMath(String unitSymbol) {
  var s = unitSymbol.trim();
  if (s.isEmpty) return s;

  // dimensionless はテキストとして見せる
  if (s == '無次元' || s.toLowerCase() == 'dimensionless') {
    return r'\text{' + s + r'}';
  }

  // まず指数表記をTeXとして安定化: m^2 / s^-2 / kg^-1 など
  // - 既に ^{...} になっているものは触らない
  s = s.replaceAllMapped(RegExp(r'\^(-?\d+)(?!\})'), (m) {
    return '^{' + (m.group(1) ?? '') + '}';
  });

  // 区切り文字を \text{...} に寄せて自然改行できるようにする
  s = s.replaceAll('·', r'\text{·}');
  s = s.replaceAll('/', r'\text{/}');

  return s;
}

/// 記号定義の「単位」表示用（Math.tex 前提）:
/// - "/" を含む（例: "m/s^2", "kg/m^3"）場合でも崩れない形にする
/// - \text{...} を生成しない（\text の入れ子で描画が欠けるケースがあるため）
///
/// 例:
/// - "m/s^2" -> r"m/s^{2}"
/// - "kg/m^3" -> r"kg/m^{3}"
/// - "kg·m·s^-2" -> r"kg \cdot m \cdot s^{-2}"
String formatUnitSymbolForTexMath(String unitSymbol) {
  var s = unitSymbol.trim();
  if (s.isEmpty) return s;

  // dimensionless は text として見せる（Math.tex上で安全）
  if (s == '無次元' || s.toLowerCase() == 'dimensionless') {
    return r'\text{' + s + r'}';
  }

  // 指数表記をTeXとして安定化（m^2, s^-2 など）
  s = s.replaceAllMapped(RegExp(r'\^(-?\d+)(?!\})'), (m) {
    return '^{' + (m.group(1) ?? '') + '}';
  });

  // 中点は \cdot に寄せる（Math.tex上で安定）
  s = s.replaceAll('·', r' \cdot ');

  // "/" はそのまま（\text{/} は使わない）
  return s;
}

/// 記号をTeX形式に変換する関数（記号定義用）
String formatSymbolToTex(String symbol) {
  String formatted = symbol;
  
  formatted = formatted.replaceAllMapped(RegExp(r'\bmu_(\d+)\b'), 
      (match) => r'\mu_{' + match.group(1)! + r'}');
  formatted = formatted.replaceAllMapped(RegExp(r'\bepsilon_(\d+)\b'), 
      (match) => r'\epsilon_{' + match.group(1)! + r'}');
  formatted = formatted.replaceAllMapped(RegExp(r'(\w)_(\d+)(?![\w}])'), 
      (match) => match.group(1)! + '_{' + match.group(2)! + '}');
  
  formatted = formatted.replaceAllMapped(RegExp(r'(\b\w+)(\d+)(?![\^\{_])'), (match) {
    final base = match.group(1)!;
    final sub = match.group(2)!;
    if (base == 'μ' || base.contains('μ')) return r'\mu_{' + sub + r'}';
    if (base == 'ε' || base.contains('ε')) return r'\epsilon_{' + sub + r'}';
    return base + '_{' + sub + '}';
  });
  
  formatted = formatted.replaceAllMapped(RegExp(r'ε(\d+)'), 
      (match) => r'\epsilon_{' + match.group(1)! + r'}');
  formatted = formatted.replaceAllMapped(RegExp(r'μ(\d+)'), 
      (match) => r'\mu_{' + match.group(1)! + r'}');
  formatted = formatted.replaceAllMapped(RegExp(r'μ([a-zA-Z])'), 
      (match) => r'\mu_{' + match.group(1)! + r'}');
  formatted = formatted.replaceAll('μ', r'\mu');
  formatted = formatted.replaceAll('ε', r'\epsilon');
  formatted = formatted.replaceAllMapped(RegExp(r'\bpi\b'), (match) => r'\pi');
  
  return formatted;
}

// 三角関数の処理
String _formatTrigonometricFunctions(String expr) {
  return expr.replaceAllMapped(
    RegExp(r'\b(cos|sin|tan|sec|csc|cot)\(([^)]+)\)', caseSensitive: false),
    (match) => r'\' + match.group(1)!.toLowerCase() + match.group(2)!.trim(),
  );
}

// ルート記号の処理
String _formatRootExpressions(String expr) {
  String formatted = expr.replaceAllMapped(
    RegExp(r'√\s*\(\s*([^)]+?)\s*\)'),
    (match) => r'\sqrt{' + match.group(1)!.trim() + r'}',
  );
  formatted = formatted.replaceAllMapped(
    RegExp(r'√\s*([^\s]+)'),
    (match) => r'\sqrt{' + match.group(1)!.trim() + r'}',
  );
  
  final sqrtPlaceholders = <String, String>{};
  int placeholderIndex = 0;
  
  formatted = formatted.replaceAllMapped(RegExp(r'\\sqrt\{([^}]+)\}'), (match) {
    final placeholder = '__SQRT_PLACEHOLDER_${placeholderIndex}__';
    sqrtPlaceholders[placeholder] = match.group(1)!;
    placeholderIndex++;
    return r'\sqrt{' + placeholder + r'}';
  });
  
  for (final entry in sqrtPlaceholders.entries) {
    String content = entry.value;
    content = content.replaceAllMapped(RegExp(r'(\d+)/(\d+)'), 
        (match) => r'\frac{' + match.group(1)! + r'}{' + match.group(2)! + r'}');
    content = content.replaceAllMapped(RegExp(r'([^/]+)/([^/]+)'), (match) {
      final num = match.group(1)!.trim();
      final den = match.group(2)!.trim();
      if (num.contains(r'\frac') || den.contains(r'\frac')) return match.group(0)!;
      return r'\frac{' + num + r'}{' + den + r'}';
    });
    sqrtPlaceholders[entry.key] = content;
  }
  
  for (final entry in sqrtPlaceholders.entries) {
    formatted = formatted.replaceAll(entry.key, entry.value);
  }
  
  return formatted;
}

// 累乗記号の処理
String _formatPowers(String expr) {
  return expr.replaceAllMapped(
    RegExp(r'(\w+)\^(\d+(?:\.\d+)?)'),
    (match) => match.group(1)! + '^{' + match.group(2)! + '}',
  );
}

// 下付き文字の処理
String _formatSubscripts(String expr) {
  String formatted = expr;
  
  formatted = formatted.replaceAllMapped(RegExp(r'\bmu_(\d+)\b'), 
      (match) => r'\mu_{' + match.group(1)! + r'}');
  formatted = formatted.replaceAllMapped(RegExp(r'\bepsilon_(\d+)\b'), 
      (match) => r'\epsilon_{' + match.group(1)! + r'}');
  
  formatted = formatted.replaceAllMapped(RegExp(r'(\w)_(\d+)(?![\w}])'), (match) {
    final before = formatted.substring(0, match.start);
    final openBraces = before.split('{').length - 1;
    final closeBraces = before.split('}').length - 1;
    return (openBraces <= closeBraces) 
        ? match.group(1)! + '_{' + match.group(2)! + '}' 
        : match.group(0)!;
  });
  
  formatted = formatted.replaceAllMapped(RegExp(r'(\b\w+)(\d+)(?![\^\{_])'), (match) {
    final base = match.group(1)!;
    final sub = match.group(2)!;
    if (base == 'μ' || base.contains('μ')) return r'\mu_' + sub;
    if (base == 'ε' || base.contains('ε')) return r'\epsilon_' + sub;
    return base + '_{' + sub + '}';
  });
  
  return formatted;
}

// 特殊文字の処理
String _formatSpecialCharacters(String expr) {
  String formatted = expr;
  
  formatted = formatted.replaceAllMapped(RegExp(r'ε(\d+)'), 
      (match) => r'\epsilon_' + match.group(1)!);
  formatted = formatted.replaceAllMapped(RegExp(r'μ(\d+)'), 
      (match) => r'\mu_{' + match.group(1)! + r'}');
  formatted = formatted.replaceAllMapped(RegExp(r'μ([a-zA-Z])'), 
      (match) => r'\mu_' + match.group(1)!);
  formatted = formatted.replaceAll('μ', r'\mu');
  formatted = formatted.replaceAll('ε', r'\epsilon');
  formatted = formatted.replaceAll('θ', r'\theta');
  formatted = formatted.replaceAllMapped(RegExp(r'\bpi\b'), (match) => r'\pi');
  
  return formatted;
}

// 分数の処理
String _formatFractions(String expr) {
  String formatted = expr;
  
  formatted = formatted.replaceAllMapped(RegExp(r'0\.5'), (match) => r'\frac{1}{2}');
  
  formatted = formatted.replaceAllMapped(RegExp(r'(\d+)/(\d+)'), (match) {
    final before = formatted.substring(0, match.start);
    final sqrtCount = before.split(r'\sqrt{').length - 1;
    final sqrtCloseCount = before.split('}').length - 1;
    if (sqrtCount <= sqrtCloseCount) {
      return r'\frac{' + match.group(1)! + r'}{' + match.group(2)! + r'}';
    }
    return match.group(0)!;
  });
  
  formatted = formatted.replaceAllMapped(RegExp(r'([^/]+)/([^/]+)'), (match) {
    final before = formatted.substring(0, match.start);
    final sqrtCount = before.split(r'\sqrt{').length - 1;
    final sqrtCloseCount = before.split('}').length - 1;
    final fracCount = before.split(r'\frac{').length - 1;
    final fracCloseCount = before.split('}{').length - 1;
    
    if (sqrtCount <= sqrtCloseCount && fracCount <= fracCloseCount) {
      final num = match.group(1)!.trim();
      final den = match.group(2)!.trim();
      if (num.contains(r'\frac') || den.contains(r'\frac')) return match.group(0)!;
      
      var denProcessed = den;
      if (denProcessed.startsWith('(') && denProcessed.endsWith(')')) {
        denProcessed = denProcessed.substring(1, denProcessed.length - 1);
      }
      return r'\frac{' + num + r'}{' + denProcessed + r'}';
    }
    return match.group(0)!;
  });
  
  return formatted;
}

/// 数式をTeX形式に変換
String formatExpression(String expr) {
  final latexMacroPattern = RegExp(r'\\[a-zA-Z]+');
  if (latexMacroPattern.hasMatch(expr)) return expr;
  
  String formatted = expr;
  formatted = _formatTrigonometricFunctions(formatted);
  formatted = _formatRootExpressions(formatted);
  formatted = _formatPowers(formatted);
  formatted = formatted.replaceAll('*', ' ');
  formatted = _formatSubscripts(formatted);
  formatted = _formatSpecialCharacters(formatted);
  formatted = _formatFractions(formatted);
  
  return formatted;
}





