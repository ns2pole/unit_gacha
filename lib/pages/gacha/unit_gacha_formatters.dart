// lib/pages/gacha/unit_gacha_formatters.dart
// 単位ガチャページ用のフォーマッター（TeX形式への変換など）

/// 単位文字列をTeX形式に変換（例：kg m s^-1 → \frac{kg \cdot m}{s}）
String formatUnitString(String unitStr) {
  String formatted = unitStr.trim();
  
  // カッコが含まれている場合（例：J/(mol·K)）は、カッコ全体を保持
  if (formatted.contains('(') && formatted.contains(')')) {
    // カッコの位置を確認
    final openParenIndex = formatted.indexOf('(');
    final closeParenIndex = formatted.lastIndexOf(')');
    
    if (openParenIndex < closeParenIndex) {
      // カッコの前後を処理
      final beforeParen = formatted.substring(0, openParenIndex);
      final inParen = formatted.substring(openParenIndex + 1, closeParenIndex);
      final afterParen = formatted.substring(closeParenIndex + 1);
      
      // カッコ内を処理（中点を\cdotに変換）
      final processedInParen = inParen.replaceAll('·', r' \cdot ');
      
      // カッコ前の部分を処理
      String processedBefore = '';
      if (beforeParen.isNotEmpty) {
        // スラッシュがある場合は分数形式
        if (beforeParen.contains('/')) {
          final parts = beforeParen.split('/');
          if (parts.length == 2) {
            processedBefore = parts[0].trim() + r'/\left(' + processedInParen + r'\right)';
          } else {
            processedBefore = beforeParen.trim() + r'/\left(' + processedInParen + r'\right)';
          }
        } else {
          processedBefore = beforeParen.trim() + r'/\left(' + processedInParen + r'\right)';
        }
      } else {
        processedBefore = r'\left(' + processedInParen + r'\right)';
      }
      
      // カッコ後の部分を処理
      if (afterParen.isNotEmpty) {
        return processedBefore + ' ' + afterParen.trim();
      }
      return processedBefore;
    }
  }
  
  // スペースで分割して各単位を処理
  final parts = formatted.split(RegExp(r'\s+'));
  final numeratorParts = <String>[];  // 分子（正の指数または指数なし）
  final denominatorParts = <String>[];  // 分母（負の指数を正に変換）
  
  for (final part in parts) {
    if (part.isEmpty) continue;
    
    // 負の指数をチェック（s^-1 など）
    if (part.contains('^-')) {
      final match = RegExp(r'(\w+)\^(-?\d+)').firstMatch(part);
      if (match != null) {
        final base = match.group(1)!;
        final power = match.group(2)!;
        final absPower = power.startsWith('-') ? power.substring(1) : power;
        
        // 分母に追加（指数を正の数に変換）
        if (absPower == '1') {
          denominatorParts.add(base);
        } else {
          denominatorParts.add('$base^{$absPower}');
        }
      }
    } else if (part.contains('^')) {
      // 正の指数（m^2 など）
      final match = RegExp(r'(\w+)\^(\d+)').firstMatch(part);
      if (match != null) {
        final base = match.group(1)!;
        final power = match.group(2)!;
        numeratorParts.add('$base^{$power}');
      } else {
        numeratorParts.add(part);
      }
    } else {
      // 指数なし
      numeratorParts.add(part);
    }
  }
  
  // 分数形式で返す
  if (denominatorParts.isEmpty) {
    // 分母がない場合は通常の形式
    return numeratorParts.join(r' \cdot ');
  } else if (numeratorParts.isEmpty) {
    // 分子がない場合は 1/分母 の形式（\fracではなく/を使用）
    final denominator = denominatorParts.join(r' \cdot ');
    return '1/' + denominator;
  } else {
    // 分子と分母の両方がある場合は分数形式
    final numerator = numeratorParts.join(r' \cdot ');
    final denominator = denominatorParts.join(r' \cdot ');
    return r'\frac{' + numerator + '}{' + denominator + '}';
  }
}

/// 記号をTeX形式に変換する関数（記号定義用）
/// 例: k_0 → k_{0}, mu_0 → \mu_{0}, epsilon_0 → \epsilon_{0}
String formatSymbolToTex(String symbol) {
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
  formatted = formatted.replaceAllMapped(
    RegExp(r'(\w)_(\d+)(?![\w}])'),
    (match) {
      return match.group(1)! + '_{' + match.group(2)! + '}';
    },
  );
  
  // 下付き文字を処理（m1 → m_1, m2 → m_2, N1 → N_1, N2 → N_2）
  formatted = formatted.replaceAllMapped(
    RegExp(r'(\b\w+)(\d+)(?![\^\{_])'),
    (match) {
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
    },
  );
  
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

/// 数式をTeX形式に変換
String formatExpression(String expr) {
  String formatted = expr;
  
  // 既にLaTeX形式の式かどうかをチェック
  // バックスラッシュで始まるLaTeXマクロが含まれている場合はそのまま返す
  final latexMacroPattern = RegExp(r'\\[a-zA-Z]+');
  if (latexMacroPattern.hasMatch(formatted)) {
    return formatted; // 既にLaTeX形式なのでそのまま返す
  }
  
  // 三角関数の括弧を削除（cos(θ) → \cos\theta, sin(θ) → \sin\theta）
  // 一般的な三角関数（cos, sin, tan, sec, csc, cot）を処理
  formatted = formatted.replaceAllMapped(
    RegExp(r'\b(cos|sin|tan|sec|csc|cot)\(([^)]+)\)', caseSensitive: false),
    (match) {
      final funcName = match.group(1)!.toLowerCase();
      final arg = match.group(2)!.trim();
      return r'\' + funcName + arg;
    },
  );
  
  // ルート記号を変換（√(x) → \sqrt{x}, √x → \sqrt{x}）
  // 最初に処理する必要がある
  formatted = formatted.replaceAllMapped(
    RegExp(r'√\s*\(\s*([^)]+?)\s*\)'),
    (match) => r'\sqrt{' + match.group(1)!.trim() + r'}',
  );
  formatted = formatted.replaceAllMapped(
    RegExp(r'√\s*([^\s]+)'),
    (match) => r'\sqrt{' + match.group(1)!.trim() + r'}',
  );
  
  // \sqrt{...}内の/を\fracに変換する処理
  // 一時的にプレースホルダーで保護してから処理
  final sqrtPlaceholders = <String, String>{};
  int placeholderIndex = 0;
  
  // \sqrt{...}の内容を一時的に置き換え
  formatted = formatted.replaceAllMapped(
    RegExp(r'\\sqrt\{([^}]+)\}'),
    (match) {
      final sqrtContent = match.group(1)!;
      final placeholder = '__SQRT_PLACEHOLDER_${placeholderIndex}__';
      sqrtPlaceholders[placeholder] = sqrtContent;
      placeholderIndex++;
      return r'\sqrt{' + placeholder + r'}';
    },
  );
  
  // \sqrt内の/を\fracに変換（プレースホルダー内で処理）
  for (final entry in sqrtPlaceholders.entries) {
    String content = entry.value;
    
    // まず数値の分数パターンを変換（例: 1/2, 1/3など）
    content = content.replaceAllMapped(
      RegExp(r'(\d+)/(\d+)'),
      (match) {
        final num = match.group(1)!;
        final den = match.group(2)!;
        return r'\frac{' + num + r'}{' + den + r'}';
      },
    );
    
    // その他の割り算を分数に変換
    content = content.replaceAllMapped(
      RegExp(r'([^/]+)/([^/]+)'),
      (match) {
        final num = match.group(1)!.trim();
        final den = match.group(2)!.trim();
        // 既に\fracが含まれている場合はスキップ
        if (num.contains(r'\frac') || den.contains(r'\frac')) {
          return match.group(0)!;
        }
        return r'\frac{' + num + r'}{' + den + r'}';
      },
    );
    
    sqrtPlaceholders[entry.key] = content;
  }
  
  // プレースホルダーを元の内容に戻す
  for (final entry in sqrtPlaceholders.entries) {
    formatted = formatted.replaceAll(entry.key, entry.value);
  }
  
  // まず累乗記号を変換（v^2 → v^{2}, r^2 → r^{2}）
  formatted = formatted.replaceAllMapped(
    RegExp(r'(\w+)\^(\d+(?:\.\d+)?)'),
    (match) {
      final base = match.group(1)!;
      final power = match.group(2)!;
      return base + '^{' + power + '}';
    },
  );
  
  // * を削除（2・π・r -> 2πr）
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
  
  // 既にLaTeX形式の下付き文字（k_0, N_1など）を保護
  // 単一文字の下付き文字（k_0 → k_{0}）を正規化
  formatted = formatted.replaceAllMapped(
    RegExp(r'(\w)_(\d+)(?![\w}])'),
    (match) {
      // \sqrt{...}や\frac{...}{...}内でないことを確認
      final before = formatted.substring(0, match.start);
      final openBraces = before.split('{').length - 1;
      final closeBraces = before.split('}').length - 1;
      // 既にLaTeXマクロ内でない場合のみ処理
      if (openBraces <= closeBraces) {
        return match.group(1)! + '_{' + match.group(2)! + '}';
      }
      return match.group(0)!;
    },
  );
  
  // 下付き文字を処理（m1 → m_1, m2 → m_2, N1 → N_1, N2 → N_2）
  // 累乗記号が含まれていない単純な変数名+数字のパターンのみ処理
  // ただし、μ0やε0のような特殊文字を含む場合は特別処理
  formatted = formatted.replaceAllMapped(
    RegExp(r'(\b\w+)(\d+)(?![\^\{_])'),
    (match) {
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
    },
  );
  
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
  
  // θを\thetaに変換
  formatted = formatted.replaceAll('θ', r'\theta');
  
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
  // \sqrt{...}内は既に処理済みなのでスキップ
  formatted = formatted.replaceAllMapped(
    RegExp(r'(\d+)/(\d+)'),
    (match) {
      // \sqrt{...}や\frac{...}{...}内でないことを確認
      final before = formatted.substring(0, match.start);
      final sqrtCount = before.split(r'\sqrt{').length - 1;
      final sqrtCloseCount = before.split('}').length - 1;
      // \sqrt内でない場合のみ処理
      if (sqrtCount <= sqrtCloseCount) {
        final num = match.group(1)!;
        final den = match.group(2)!;
        return r'\frac{' + num + r'}{' + den + r'}';
      }
      return match.group(0)!;
    },
  );
  
  // 割り算を分数に変換（例: m v^2 / r → \frac{m v^{2}}{r}）
  // 分子と分母が複数の項を含む場合も処理
  // \sqrt{...}内は既に処理済みなのでスキップ
  formatted = formatted.replaceAllMapped(
    RegExp(r'([^/]+)/([^/]+)'),
    (match) {
      // \sqrt{...}や\frac{...}{...}内でないことを確認
      final before = formatted.substring(0, match.start);
      final sqrtCount = before.split(r'\sqrt{').length - 1;
      final sqrtCloseCount = before.split('}').length - 1;
      final fracCount = before.split(r'\frac{').length - 1;
      final fracCloseCount = before.split('}{').length - 1;
      
      // \sqrt内または\frac内でない場合のみ処理
      if (sqrtCount <= sqrtCloseCount && fracCount <= fracCloseCount) {
        final num = match.group(1)!.trim();
        final den = match.group(2)!.trim();
        // 既に\fracが含まれている場合はスキップ
        if (num.contains(r'\frac') || den.contains(r'\frac')) {
          return match.group(0)!;
        }
        // 分母の不要な括弧を削除（例: (2 π r) → 2 π r, (2πr) → 2πr）
        // 先頭と末尾が括弧で囲まれている場合のみ削除
        var denProcessed = den;
        if (denProcessed.startsWith('(') && denProcessed.endsWith(')')) {
          denProcessed = denProcessed.substring(1, denProcessed.length - 1);
        }
        return r'\frac{' + num + r'}{' + denProcessed + r'}';
      }
      return match.group(0)!;
    },
  );
  
  return formatted;
}
