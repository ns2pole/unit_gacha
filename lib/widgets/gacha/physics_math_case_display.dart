// physics_math_case_display.dart
// 微分方程式ガチャ専用のCASE形式表示ウィジェット

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// 物理数学の問題をCASE形式で表示するウィジェット
/// 微分方程式と初期条件を2行程度でコンパクトに表示
class PhysicsMathCaseDisplay extends StatefulWidget {
  final String equation;
  final String conditions;
  final String? constants;
  final double? fontSize;
  
  const PhysicsMathCaseDisplay({
    Key? key,
    required this.equation,
    required this.conditions,
    this.constants,
    this.fontSize,
  }) : super(key: key);

  @override
  State<PhysicsMathCaseDisplay> createState() => _PhysicsMathCaseDisplayState();
}

class _PhysicsMathCaseDisplayState extends State<PhysicsMathCaseDisplay> {
  @override
  Widget build(BuildContext context) {
    // conditionsが空の場合はcases形式を使わない
    if (widget.conditions.trim().isEmpty) {
      return RepaintBoundary(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Math.tex(
            widget.equation,
            textStyle: TextStyle(fontSize: widget.fontSize ?? 16),
          ),
        ),
      );
    }

    // cases形式のTeX文字列を構築
    // conditions内の\\（\\[で始まらないもの）を\\[4pt]に置き換えて、行間を統一する
    // \\[で始まるもの（例：\\[4pt]）は除外し、単純な\\のみを\\[4pt]に置き換える
    String normalizedConditions = widget.conditions.replaceAllMapped(
      RegExp(r'\\\s*(?!\[)'),
      (match) => r'\\[4pt]',
    );
    
    String casesTex;
    if (widget.constants != null && widget.constants!.trim().isNotEmpty) {
      casesTex = r"""
\begin{cases}
$equation \\[4pt]
$conditions \\[4pt]
$constants
\end{cases}
""".replaceAll('\$equation', widget.equation)
          .replaceAll('\$conditions', normalizedConditions)
          .replaceAll('\$constants', widget.constants!);
    } else {
      casesTex = r"""
\begin{cases}
$equation \\[4pt]
$conditions
\end{cases}
""".replaceAll('\$equation', widget.equation)
          .replaceAll('\$conditions', normalizedConditions);
    }

    return RepaintBoundary(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Math.tex(
          casesTex,
          textStyle: TextStyle(fontSize: widget.fontSize ?? 16),
        ),
      ),
    );
  }
}
