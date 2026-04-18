// lib/pages/gacha/formatting/reference_tex_formatter.dart
// 参照テーブル用のTeX変換

/// 単位記号や単位名、単位の関係などをTeX形式に変換する関数
String formatToTex(String text) {
  if (text.isEmpty) return text;
  
  String formatted = text;
  
  formatted = formatted.replaceAllMapped(RegExp(r'(\w+)\^(\d+)'), 
      (match) => '${match.group(1)}^{${match.group(2)}}');
  formatted = formatted.replaceAllMapped(RegExp(r'(\w+)\^-(\d+)'), 
      (match) => '${match.group(1)}^{-${match.group(2)}}');
  formatted = formatted.replaceAllMapped(RegExp(r'(\w+)_([a-zA-Z0-9]+)'), (match) {
    final base = match.group(1)!;
    final sub = match.group(2)!;
    if (base.contains('\\') || sub.contains('\\')) return match.group(0)!;
    return '${base}_{$sub}';
  });
  
  formatted = formatted.replaceAll('ε', r'\epsilon');
  formatted = formatted.replaceAll('μ', r'\mu');
  formatted = formatted.replaceAll('θ', r'\theta');
  formatted = formatted.replaceAll('φ', r'\phi');
  formatted = formatted.replaceAll('ρ', r'\rho');
  formatted = formatted.replaceAll('ω', r'\omega');
  formatted = formatted.replaceAll('λ', r'\lambda');
  formatted = formatted.replaceAll('Φ', r'\Phi');
  formatted = formatted.replaceAll('·', r' \cdot ');
  
  int maxIterations = 10;
  int iteration = 0;
  while (formatted.contains('/') && iteration < maxIterations) {
    iteration++;
    final beforeReplace = formatted;
    formatted = formatted.replaceFirstMapped(RegExp(r'([a-zA-Z0-9\^_\{\}\-]+)\s*/\s*([a-zA-Z0-9\^_\{\}\-]+)'), (match) {
      final num = match.group(1)!.trim();
      final den = match.group(2)!.trim();
      if (num.contains(r'\frac') || den.contains(r'\frac')) return match.group(0)!;
      return r'\displaystyle\frac{' + num + r'}{' + den + r'}';
    });
    if (formatted == beforeReplace) break;
  }
  
  if (formatted.contains(r'\frac') && !formatted.contains(r'\displaystyle')) {
    formatted = formatted.replaceAll(r'\frac', r'\displaystyle\frac');
  }
  
  return formatted;
}

/// テキストが数式を含むかどうかを判定
bool containsMath(String text) {
  if (text.isEmpty) return false;
  if (text.contains('^') || text.contains('_')) return true;
  if (RegExp(r'[εμθφρωλΦ]').hasMatch(text)) return true;
  if (text.contains('·')) return true;
  if (RegExp(r'\\[a-zA-Z]+').hasMatch(text)) return true;
  return false;
}





