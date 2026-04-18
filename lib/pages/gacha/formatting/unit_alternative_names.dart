// lib/pages/gacha/unit_alternative_names.dart
// 単位の別表記マッピングテーブル

/// 単位の別表記マッピング
/// キー: 正規化された単位文字列（例: "N m^-2"）
/// 値: 別表記のリスト（例: ["Pa", "kg m^-1 s^-2"]）
const Map<String, List<String>> unitAlternativeNames = {
  // 圧力
  "N m^-2": ["Pa", "kg m^-1 s^-2"],
  "kg m^-1 s^-2": ["Pa", "N m^-2"],
  "Pa": ["N m^-2", "kg m^-1 s^-2"],
  
  // エネルギー・仕事
  "J": ["N m", "W s", "kg m^2 s^-2"],
  "N m": ["J", "W s", "kg m^2 s^-2"],
  "W s": ["J", "N m", "kg m^2 s^-2"],
  "kg m^2 s^-2": ["J", "N m", "W s"],
  
  // 電力
  "W": ["J s^-1", "kg m^2 s^-3"],
  "J s^-1": ["W", "kg m^2 s^-3"],
  "kg m^2 s^-3": ["W", "J s^-1"],
  
  // 力
  "N": ["kg m s^-2"],
  "kg m s^-2": ["N"],
  
  // その他の単位も必要に応じて追加
};

/// 単位文字列を正規化する
/// スペースや順序の違いを統一して、マッピングテーブルのキーと一致させる
String normalizeUnitString(String unitStr) {
  if (unitStr.trim().isEmpty) return '';
  
  // スペースと・を統一（スペースに統一）
  String normalized = unitStr.trim().replaceAll(RegExp(r'[・\s]+'), ' ');
  
  // 単位と指数をパース
  final units = <String, int>{};
  final parts = normalized.split(RegExp(r'\s+'));
  
  for (final part in parts) {
    if (part.isEmpty) continue;
    
    // 単位と指数を抽出（s^-1, m^2 など）
    final regex = RegExp(r'^([\wΩ]+)(?:\^(-?\d+))?$');
    final match = regex.firstMatch(part);
    
    if (match != null) {
      final unit = match.group(1)!;
      final powerStr = match.group(2);
      final power = powerStr != null ? int.parse(powerStr) : 1;
      
      // 累乗を加算
      units[unit] = (units[unit] ?? 0) + power;
    }
  }
  
  // 0の指数を削除
  units.removeWhere((key, value) => value == 0);
  
  if (units.isEmpty) return '';
  
  // 標準的な順序でソート（kg, m, s, A, ...）
  final standardOrder = ['kg', 'm', 's', 'A', 'K', 'mol', 'cd', 'Ω', 'J', 'N', 'W', 'Pa', 'Hz', 'C', 'V', 'F', 'H', 'T', 'Wb'];
  
  final sortedUnits = <String>[];
  
  // まず標準順序の単位を追加
  for (final unit in standardOrder) {
    if (units.containsKey(unit)) {
      sortedUnits.add(unit);
    }
  }
  
  // 標準順序にない単位も追加
  for (final unit in units.keys) {
    if (!sortedUnits.contains(unit)) {
      sortedUnits.add(unit);
    }
  }
  
  // 文字列に変換
  final resultParts = <String>[];
  for (final unit in sortedUnits) {
    final power = units[unit]!;
    if (power == 1) {
      resultParts.add(unit);
    } else if (power == -1) {
      resultParts.add('$unit^-1');
    } else {
      resultParts.add('$unit^$power');
    }
  }
  
  return resultParts.join(' ');
}

/// 単位の別表記を取得
/// [unitStr] 正規化前の単位文字列
/// 戻り値: 別表記のリスト（存在しない場合は空リスト）
List<String> getAlternativeUnitNames(String unitStr) {
  final normalized = normalizeUnitString(unitStr);
  return unitAlternativeNames[normalized] ?? [];
}

/// 別表記をTeX形式の文字列に変換
/// [alternativeNames] 別表記のリスト
/// 戻り値: TeX形式の文字列（例: "（Pa、kg m^-1 s^-2）"）
String formatAlternativeNames(List<String> alternativeNames) {
  if (alternativeNames.isEmpty) return '';
  
  // 各別表記をTeX形式に変換
  final formattedNames = alternativeNames.map((name) {
    // 簡単なTeX形式への変換（formatUnitStringを使う）
    return _formatUnitToTex(name);
  }).toList();
  
  // 「（、）」は \text{} に寄せて、MixedTextMath の Wrap 分割ポイントにする
  // 例: \text{（}Pa\text{、}kg\,m^{-1}\,s^{-2}\text{）}
  return r'\text{（}' + formattedNames.join(r'\text{、}') + r'\text{）}';
}

/// 単位文字列をTeX形式に変換（簡易版）
String _formatUnitToTex(String unitStr) {
  String formatted = unitStr.trim();
  
  // スペースで分割して各単位を処理
  final parts = formatted.split(RegExp(r'\s+'));
  final numeratorParts = <String>[];
  final denominatorParts = <String>[];
  
  for (final part in parts) {
    if (part.isEmpty) continue;
    
    // 負の指数をチェック（s^-1 など）
    if (part.contains('^-')) {
      final match = RegExp(r'(\w+)\^(-?\d+)').firstMatch(part);
      if (match != null) {
        final base = match.group(1)!;
        final power = match.group(2)!;
        final absPower = power.startsWith('-') ? power.substring(1) : power;
        
        // 分母に追加
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
    return numeratorParts.join(r' \cdot ');
  } else if (numeratorParts.isEmpty) {
    final denominator = denominatorParts.join(r' \cdot ');
    return r'\frac{1}{' + denominator + '}';
  } else {
    final numerator = numeratorParts.join(r' \cdot ');
    final denominator = denominatorParts.join(r' \cdot ');
    return r'\frac{' + numerator + '}{' + denominator + '}';
  }
}
