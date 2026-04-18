// lib/widgets/unit_calculator.dart
// 単位入力用電卓ウィジェット

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../problems/unit/symbol.dart';
import '../../localization/app_localizations.dart';
import '../../pages/common/tablet_utils.dart';

/// 電卓タイプ
enum CalculatorType {
  baseUnits, // 基本単位系（kg, m, sなど）
  singleUnit, // 1文字単位（J, N, Wなど）
}

/// 単位入力用電卓
class UnitCalculator extends StatefulWidget {
  final CalculatorType type;
  final Function(String) onEnter;
  final String? initialValue;
  final bool isAnswered;
  final VoidCallback? onNext;
  final String? nextButtonText;
  final UnitProblem? selectedAnswer; // 選択された解答方法（指定されている場合は動的ボタン生成）
  final String? highlightedButtonText; // 点灯させるボタンのテキスト（チュートリアル用）
  final String? displayText; // 外部から入力欄のテキストを制御（チュートリアル用）
  final bool highlightConfirmButton; // 確定ボタンを点灯させる（チュートリアル用）
  final bool disableButtons; // ACボタンと確定ボタンを無効化（チュートリアル用）
  /// 1行目と2行目の間隔だけを少し広げたい場合に使う（他の行間はそのまま）
  /// 例: 1.2 で 20%増し
  final double firstSecondRowGapMultiplier;

  const UnitCalculator({
    Key? key,
    required this.type,
    required this.onEnter,
    this.initialValue,
    this.isAnswered = false,
    this.onNext,
    this.nextButtonText,
    this.selectedAnswer,
    this.highlightedButtonText,
    this.displayText,
    this.highlightConfirmButton = false,
    this.disableButtons = false,
    this.firstSecondRowGapMultiplier = 1.0,
  }) : super(key: key);

  @override
  State<UnitCalculator> createState() => _UnitCalculatorState();
}

class _UnitCalculatorState extends State<UnitCalculator> {
  late TextEditingController _controller;

  ({double keypadWidth, double slotWidth, double slotHeight, double gap, EdgeInsets buttonPadding})
      _getKeypadLayout(double scale, double availableWidth) {
    // 親の制約幅ベースで計算（親のpaddingを無視してはみ出すのを防ぐ）
    // できるだけ横幅を使うが、左右に少し余白は残す
    final horizontalMargin = TabletUtils.calculatorKeypadHorizontalMargin(context);
    var keypadWidth = availableWidth - horizontalMargin * 2;
    if (keypadWidth.isNaN || keypadWidth.isInfinite) {
      keypadWidth = 320;
    }
    if (keypadWidth < 220) keypadWidth = 220;
    // 横に広がりすぎないように上限を設ける（ボタンがデカすぎる問題の抑制）
    if (keypadWidth > 460) keypadWidth = 460;

    const columns = 5; // 単位4 + 制御1
    final gap = TabletUtils.calculatorKeyGap(context);
    final slotWidth = (keypadWidth - gap * (columns - 1)) / columns;
    final slotHeight = TabletUtils.calculatorKeyHeight(context);
    final buttonPadding = TabletUtils.calculatorKeyPadding(context);

    return (
      keypadWidth: keypadWidth,
      slotWidth: slotWidth,
      slotHeight: slotHeight,
      gap: gap,
      buttonPadding: buttonPadding,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.displayText ?? widget.initialValue ?? '');
    _controller.addListener(() {
      // displayTextが設定されている場合は外部制御なので、リスナーで更新しない
      if (widget.displayText == null) {
        setState(() {}); // テキスト変更時にUIを更新
      }
    });
  }

  @override
  void didUpdateWidget(UnitCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayText != oldWidget.displayText) {
      if (widget.displayText != null) {
        _controller.text = widget.displayText!;
      } else {
        // displayTextがnullの場合は、initialValueまたは空文字列に戻す
        _controller.text = widget.initialValue ?? '';
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = TabletUtils.calculatorScale(context);
    final fontSizeScale = TabletUtils.calculatorFontSizeScale(context);
    final isTablet = TabletUtils.isTablet(context);
    final isMobile = !isTablet;
    
    return Container(
      padding: EdgeInsets.all(TabletUtils.calculatorPadding(context)),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 電卓タイプ表示（削除）
          
          // 入力欄（プレビュー）の上は少し詰める
          SizedBox(
            height: (TabletUtils.calculatorInternalSpacing(context) - 6).clamp(4.0, 99.0),
          ),
          // TeX形式のプレビュー（元々のTextFieldの位置に配置）
          SizedBox(
            width: 250 * scale, // 元々のTextFieldと同じ幅
            height: TabletUtils.calculatorPreviewHeight(context),
              child: Container(
              padding: EdgeInsets.symmetric(horizontal: TabletUtils.calculatorPreviewPadding(context)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: _controller.text.trim().isNotEmpty
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Builder(
                          builder: (context) {
                            try {
                              final texString = _formatUnitString(_controller.text);
                              // 空のTeX文字列の場合はプレーンテキストを表示
                              if (texString.isEmpty) {
                                return Text(
                                  _controller.text,
                                  style: TextStyle(
                                    fontSize: 26 * fontSizeScale, // 大きくする
                                    fontFamily: 'serif',
                                  ),
                                );
                              }
                              return Math.tex(
                                texString,
                                textStyle: TextStyle(
                                  fontSize: 26 * fontSizeScale, // 大きくする
                                  fontFamily: 'serif',
                                ),
                                mathStyle: MathStyle.display,
                              );
                            } catch (e) {
                              // パースエラーの場合はプレーンテキストで表示
                              return Text(
                                _controller.text,
                                style: TextStyle(
                                  fontSize: 26 * fontSizeScale, // 大きくする
                                  fontFamily: 'serif',
                                ),
                              );
                            }
                          },
                        ),
                      )
                    : Text(
                        'example. kg m s^-1 s^-1',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14 * fontSizeScale,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: TabletUtils.calculatorInternalSpacing(context)),
          // キーボードボタン（親制約幅に合わせてサイズ計算）
          LayoutBuilder(
            builder: (context, constraints) {
              final keypad = _getKeypadLayout(scale, constraints.maxWidth);
              if (widget.selectedAnswer != null && widget.selectedAnswer!.units.isNotEmpty) {
                return _buildAnswerUnitButtons(scale, fontSizeScale, keypad);
              }
              if (widget.type == CalculatorType.baseUnits) {
                return _buildBaseUnitButtons(scale, fontSizeScale, keypad);
              }
              return _buildSingleUnitButtons(scale, fontSizeScale, keypad);
            },
          ),
          SizedBox(height: TabletUtils.calculatorInternalSpacing(context)),
          // 確定ボタン / 次へボタン（少し大きく）
          // 解答済みでonNextがnullの場合はボタンを非表示
          if (!widget.isAnswered || widget.onNext != null)
            ElevatedButton.icon(
              onPressed: widget.disableButtons
                  ? null
                  : (widget.isAnswered
                      ? widget.onNext
                      : (_controller.text.trim().isNotEmpty ? _handleEnter : null)),
              icon: Icon(
                widget.isAnswered ? Icons.arrow_forward : Icons.check_circle,
                size: 28 * fontSizeScale,
              ),
              label: Text(
                widget.isAnswered
                    ? (widget.nextButtonText ?? AppLocalizations.of(context).next)
                    : AppLocalizations.of(context).confirm,
                style: TextStyle(fontSize: 20 * fontSizeScale),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.disableButtons
                    ? Colors.grey.shade300
                    : (widget.highlightConfirmButton 
                        ? Colors.lightBlue.shade300 
                        : (widget.isAnswered ? Colors.purple : Colors.blue)),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? TabletUtils.confirmButtonHorizontalPadding(context) - 6
                      : TabletUtils.confirmButtonHorizontalPadding(context),
                  vertical: isMobile
                      ? (TabletUtils.confirmButtonVerticalPadding(context) - 2).clamp(6.0, 99.0)
                      : TabletUtils.confirmButtonVerticalPadding(context),
                ),
                minimumSize: Size(0, 60 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20 * scale),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// selectedAnswerに基づく動的ボタン生成
  /// 列の配置（右から左）:
  /// - 列4（一番右）: 7,8, AC/×
  /// - 列1（AC/×のすぐ左）: 1,2
  /// - 列2（列1の左）: 3,4
  /// - 列3（列2の左）: 5,6
  /// ^-1でないものは7,8,5,6,3,4,1,2の順に配置
  /// ^-1のものは1,2,3,4の順に配置
  /// まず^-1でないものを配置して、それから^-1を配置する
  /// unitsのボタンは2行に収める
  Widget _buildAnswerUnitButtons(
    double scale,
    double fontSizeScale,
    ({double keypadWidth, double slotWidth, double slotHeight, double gap, EdgeInsets buttonPadding}) keypad,
  ) {
    if (widget.selectedAnswer == null || widget.selectedAnswer!.units.isEmpty) {
      return const SizedBox.shrink();
    }

    // unitsリストに含まれる単位だけを使用（^-1は自動追加しない）
    final units = widget.selectedAnswer!.units;

    // フィルタリング設定の背景色（^-1ボタン用）
    final filterBackgroundColor = const Color(0xFFE6F4FF);

    // ^-1を含む単位と含まない単位を分離
    final normalUnits = <String>[];
    final inverseUnits = <String>[];

    for (final unit in units) {
      if (unit.contains('^-1')) {
        inverseUnits.add(unit);
      } else {
        normalUnits.add(unit);
      }
    }

    // まず^-1でないものを配置して、それから^-1を配置する
    // 視覚的な左から右の順序: 5, 3, 1, 7 (1行目), 6, 4, 2, 8 (2行目)
    // まず^-1でないものを左から右に配置
    // 次に^-1のものを左から右に配置（空いているスロットのみ）
    final visualOrder = [5, 3, 1, 7, 6, 4, 2, 8]; // 視覚的な左から右の順序
    final normalSlots = <int, String?>{};
    final inverseSlots = <int, String?>{};
    final slots = <int, String?>{};
    
    // まず^-1でないものを左から右に配置
    int normalIndex = 0;
    for (final slotNum in visualOrder) {
      if (normalIndex < normalUnits.length) {
        normalSlots[slotNum] = normalUnits[normalIndex];
        slots[slotNum] = normalUnits[normalIndex];
        normalIndex++;
      }
    }
    
    // 次に^-1のものを左から右に配置（空いているスロットのみ）
    int inverseIndex = 0;
    for (final slotNum in visualOrder) {
      if (inverseIndex < inverseUnits.length && slots[slotNum] == null) {
        inverseSlots[slotNum] = inverseUnits[inverseIndex];
        slots[slotNum] = inverseUnits[inverseIndex];
        inverseIndex++;
      }
    }
    
    // スロットが^-1かどうかを判定するためのマップ
    final isInverseSlot = <int, bool>{};
    for (final slotNum in [1, 2, 3, 4, 5, 6, 7, 8]) {
      if (slots[slotNum] != null) {
        isInverseSlot[slotNum] = inverseUnits.contains(slots[slotNum]);
      }
    }

    // 2行のレイアウトを構築
    // 行1: 列3(5), 列2(3), 列1(1), 列4(7), AC
    // 行2: 列3(6), 列2(4), 列1(2), 列4(8), ×
    // ACと×の左端を揃えるため、常に4つの単位ボタン（または空のスペース）を配置してから制御ボタンを配置
    return Center(
      child: SizedBox(
        width: keypad.keypadWidth,
        child: Column(
      children: [
        // 1行目: 5, 3, 1, 7, AC
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 列3(5)
            _buildSlot(
              slotText: normalSlots[5] ?? inverseSlots[5],
              onPressed: () => _insertText('${normalSlots[5] ?? inverseSlots[5]} '),
              backgroundColor: (inverseSlots[5] != null) ? filterBackgroundColor : Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            // 列2(3)
            _buildSlot(
              slotText: normalSlots[3] ?? inverseSlots[3],
              onPressed: () => _insertText('${normalSlots[3] ?? inverseSlots[3]} '),
              backgroundColor: (inverseSlots[3] != null) ? filterBackgroundColor : Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            // 列1(1)
            _buildSlot(
              slotText: normalSlots[1] ?? inverseSlots[1],
              onPressed: () => _insertText('${normalSlots[1] ?? inverseSlots[1]} '),
              backgroundColor: (inverseSlots[1] != null) ? filterBackgroundColor : Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            // 列4(7)
            _buildSlot(
              slotText: normalSlots[7] ?? inverseSlots[7],
              onPressed: () => _insertText('${normalSlots[7] ?? inverseSlots[7]} '),
              backgroundColor: (inverseSlots[7] != null) ? filterBackgroundColor : Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            // AC（常に同じ位置に配置）
            _buildControlButton(
              'AC',
              widget.disableButtons ? null : (_controller.text.isNotEmpty ? _clearAll : null),
              Colors.red,
              keypad,
              scale,
              fontSizeScale,
            ),
          ],
        ),
        SizedBox(height: keypad.gap * widget.firstSecondRowGapMultiplier),
        // 2行目: 6, 4, 2, 8, ×
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 列3(6)
            _buildSlot(
              slotText: normalSlots[6] ?? inverseSlots[6],
              onPressed: () => _insertText('${normalSlots[6] ?? inverseSlots[6]} '),
              backgroundColor: (inverseSlots[6] != null) ? filterBackgroundColor : Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            // 列2(4)
            _buildSlot(
              slotText: normalSlots[4] ?? inverseSlots[4],
              onPressed: () => _insertText('${normalSlots[4] ?? inverseSlots[4]} '),
              backgroundColor: (inverseSlots[4] != null) ? filterBackgroundColor : Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            // 列1(2)
            _buildSlot(
              slotText: normalSlots[2] ?? inverseSlots[2],
              onPressed: () => _insertText('${normalSlots[2] ?? inverseSlots[2]} '),
              backgroundColor: (inverseSlots[2] != null) ? filterBackgroundColor : Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            // 列4(8)
            _buildSlot(
              slotText: normalSlots[8] ?? inverseSlots[8],
              onPressed: () => _insertText('${normalSlots[8] ?? inverseSlots[8]} '),
              backgroundColor: (inverseSlots[8] != null) ? filterBackgroundColor : Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            // ×（常に同じ位置に配置、ACと左端を揃える）
            _buildControlButton(
              '×',
              _controller.text.isNotEmpty ? _deleteLastChar : null,
              Colors.orange,
              keypad,
              scale,
              fontSizeScale,
            ),
          ],
        ),
      ],
        ),
      ),
    );
  }

  /// 基本単位系のボタン
  Widget _buildBaseUnitButtons(
    double scale,
    double fontSizeScale,
    ({double keypadWidth, double slotWidth, double slotHeight, double gap, EdgeInsets buttonPadding}) keypad,
  ) {
    // 量と量の-1乗を2つのボタンで
    final unitPairs = [
      ['kg', 'kg^-1'],
      ['m', 'm^-1'],
      ['s', 's^-1'],
      ['A', 'A^-1'],
    ];
    
    // フィルタリング設定の背景色（^-1ボタン用）
    final filterBackgroundColor = const Color(0xFFE6F4FF);
    
    // 左側に^-1でないもの、右側に^-1なものを並べる（間隔は開けない）
    // ACと×の左端を揃えるため、常に4つの単位ボタン（または空のスペース）を配置してから制御ボタンを配置
    return Center(
      child: SizedBox(
        width: keypad.keypadWidth,
        child: Column(
      children: [
        // 1行目: kg, m, kg^-1, m^-1, AC
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSlot(
              slotText: unitPairs[0][0],
              onPressed: () => _insertText('${unitPairs[0][0]} '),
              backgroundColor: Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            _buildSlot(
              slotText: unitPairs[1][0],
              onPressed: () => _insertText('${unitPairs[1][0]} '),
              backgroundColor: Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            _buildSlot(
              slotText: unitPairs[0][1],
              onPressed: () => _insertText('${unitPairs[0][1]} '),
              backgroundColor: filterBackgroundColor,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            _buildSlot(
              slotText: unitPairs[1][1],
              onPressed: () => _insertText('${unitPairs[1][1]} '),
              backgroundColor: filterBackgroundColor,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            _buildControlButton(
              'AC',
              widget.disableButtons ? null : _clearAll,
              Colors.red,
              keypad,
              scale,
              fontSizeScale,
            ),
          ],
        ),
        SizedBox(height: keypad.gap * widget.firstSecondRowGapMultiplier),
        // 2行目: s, (空), s^-1, (空), ×
        // ACと×の左端を揃えるため、空のスペースも同じサイズのSizedBoxを使用
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSlot(
              slotText: unitPairs[2][0],
              onPressed: () => _insertText('${unitPairs[2][0]} '),
              backgroundColor: Colors.white,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            _buildEmptySlot(keypad),
            SizedBox(width: keypad.gap),
            _buildSlot(
              slotText: unitPairs[2][1],
              onPressed: () => _insertText('${unitPairs[2][1]} '),
              backgroundColor: filterBackgroundColor,
              keypad: keypad,
              scale: scale,
              fontSizeScale: fontSizeScale,
            ),
            SizedBox(width: keypad.gap),
            _buildEmptySlot(keypad),
            SizedBox(width: keypad.gap),
            _buildControlButton(
              '×',
              _deleteLastChar,
              Colors.orange,
              keypad,
              scale,
              fontSizeScale,
            ),
          ],
        ),
      ],
        ),
      ),
    );
  }
  
  Widget _buildSlot({
    required String? slotText,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required ({double keypadWidth, double slotWidth, double slotHeight, double gap, EdgeInsets buttonPadding}) keypad,
    required double scale,
    required double fontSizeScale,
  }) {
    if (slotText == null) {
      return _buildEmptySlot(keypad);
    }
    return _buildUnitButton(
      text: slotText,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      keypad: keypad,
      scale: scale,
      fontSizeScale: fontSizeScale,
    );
  }
  
  Widget _buildEmptySlot(({double keypadWidth, double slotWidth, double slotHeight, double gap, EdgeInsets buttonPadding}) keypad) {
    return SizedBox(width: keypad.slotWidth, height: keypad.slotHeight);
  }
  
  Widget _buildUnitButton({
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required ({double keypadWidth, double slotWidth, double slotHeight, double gap, EdgeInsets buttonPadding}) keypad,
    required double scale,
    required double fontSizeScale,
  }) {
    // 点灯させるボタンかどうかを判定
    final isHighlighted = widget.highlightedButtonText != null &&
        (text == widget.highlightedButtonText ||
            (widget.highlightedButtonText == 's^-1' && text.contains('s') && text.contains('^-1')));
    final effectiveBackgroundColor = isHighlighted ? Colors.lightBlue.shade300 : backgroundColor;
    
    return SizedBox(
      width: keypad.slotWidth,
      height: keypad.slotHeight,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            onPressed();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: Colors.black87,
          padding: keypad.buttonPadding,
          fixedSize: Size(keypad.slotWidth, keypad.slotHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scale),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(fontSize: 18 * fontSizeScale),
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlButton(
    String text,
    VoidCallback? onPressed,
    Color backgroundColor,
    ({double keypadWidth, double slotWidth, double slotHeight, double gap, EdgeInsets buttonPadding}) keypad,
    double scale,
    double fontSizeScale,
  ) {
    return SizedBox(
      width: keypad.slotWidth,
      height: keypad.slotHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? backgroundColor : Colors.grey.shade300,
          foregroundColor: Colors.white,
          padding: keypad.buttonPadding,
          fixedSize: Size(keypad.slotWidth, keypad.slotHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scale),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20 * fontSizeScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 1文字単位のボタン
  Widget _buildSingleUnitButtons(
    double scale,
    double fontSizeScale,
    ({double keypadWidth, double slotWidth, double slotHeight, double gap, EdgeInsets buttonPadding}) keypad,
  ) {
    final units = ['J', 'N', 'W', 'Pa', 'Hz', 'C', 'V', 'Ω', 'F', 'H', 'T', 'Wb'];
    final inverseUnits = ['J^-1', 'N^-1', 'W^-1', 'Pa^-1', 'Hz^-1', 'C^-1', 'V^-1', 'Ω^-1', 'F^-1', 'H^-1', 'T^-1', 'Wb^-1'];
    
    // フィルタリング設定の背景色（^-1ボタン用）
    final filterBackgroundColor = const Color(0xFFE6F4FF);
    
    // すべての単位を結合（通常単位と^-1単位）
    final allUnits = <String>[];
    for (int i = 0; i < units.length; i++) {
      allUnits.add(units[i]);
      allUnits.add(inverseUnits[i]);
    }
    
    // 4列×6行で配置（通常単位と^-1単位を交互に配置、右側にACと×）
    return Center(
      child: SizedBox(
        width: keypad.keypadWidth,
        child: Column(
          children: [
            for (var row = 0; row < 6; row++) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 4列のボタン（間にgapを挟む）
                  for (var col = 0; col < 4; col++) ...[
                    if (col != 0) SizedBox(width: keypad.gap),
                    if (row * 4 + col < allUnits.length)
                      _buildUnitButton(
                        text: allUnits[row * 4 + col],
                        onPressed: () => _insertText(allUnits[row * 4 + col]),
                        backgroundColor: allUnits[row * 4 + col].contains('^-1')
                            ? filterBackgroundColor
                            : Colors.white,
                        keypad: keypad,
                        scale: scale,
                        fontSizeScale: fontSizeScale,
                      )
                    else
                      _buildEmptySlot(keypad),
                  ],
                  SizedBox(width: keypad.gap),
                  // 右側にAC（1行目）または×（2行目）を配置
                  if (row == 0)
                    _buildControlButton(
                      'AC',
                      widget.disableButtons ? null : (_controller.text.isNotEmpty ? _clearAll : null),
                      Colors.red,
                      keypad,
                      scale,
                      fontSizeScale,
                    )
                  else if (row == 1)
                    _buildControlButton(
                      '×',
                      _controller.text.isNotEmpty ? _deleteLastChar : null,
                      Colors.orange,
                      keypad,
                      scale,
                      fontSizeScale,
                    )
                  else
                    _buildEmptySlot(keypad),
                ],
              ),
              if (row != 5)
                SizedBox(
                  height: row == 0
                      ? keypad.gap * widget.firstSecondRowGapMultiplier
                      : keypad.gap,
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _insertText(String unit) {
    final text = _controller.text.trim();
    // 末尾に追加
    final newText = text.isEmpty ? unit : '$text $unit';
    // 同じ単位の累乗をまとめて、順序を整える
    final normalized = _normalizeUnitString(newText);
    _controller.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(
        offset: normalized.length,
      ),
    );
  }

  /// 単位文字列を正規化（同じ単位の累乗をまとめ、順序を整える）
  String _normalizeUnitString(String input) {
    if (input.trim().isEmpty) return '';
    
    // バックスラッシュを除去（TeXコマンドの誤入力などを防ぐ）
    String cleanedInput = input.replaceAll('\\', '');
    
    // 単位と累乗をパース
    final units = <String, int>{};
    
    // パターン: "kg", "m", "s^-1", "kg^-1" など（スペース区切りまたは・区切り）
    // まずスペースまたは・で分割してから、各要素をパース
    final parts = cleanedInput.trim().split(RegExp(r'[\s・]+'));
    
    for (final part in parts) {
      if (part.isEmpty) continue;
      
      // 単位と累乗を抽出（Ωなどの特殊文字にも対応）
      final regex = RegExp(r'^([\wΩ]+)(?:\^(-?\d+))?$');
      final match = regex.firstMatch(part);
      
      if (match != null) {
        final unit = match.group(1)!;
        final powerStr = match.group(2);
        final power = powerStr != null ? int.parse(powerStr) : 1;
        
        // 累乗を加算（s^-1 + s^-1 = s^-2）
        units[unit] = (units[unit] ?? 0) + power;
      }
    }
    
    // 0の指数を削除
    units.removeWhere((key, value) => value == 0);
    
    if (units.isEmpty) return '';
    
    // selectedAnswerのanswerから正解の順序を取得
    List<String>? answerOrder;
    if (widget.selectedAnswer?.answer != null) {
      answerOrder = _parseAnswerOrder(widget.selectedAnswer!.answer);
    }
    
    // 順序に従ってソート
    final sortedUnits = <String>[];
    
    if (answerOrder != null && answerOrder.isNotEmpty) {
      // 正解の順序に従ってソート
      for (final unit in answerOrder) {
        if (units.containsKey(unit)) {
          sortedUnits.add(unit);
        }
      }
      // 正解にない単位も追加（最後に）
      for (final unit in units.keys) {
        if (!sortedUnits.contains(unit)) {
          sortedUnits.add(unit);
        }
      }
    } else {
      // 正解の順序がない場合は、デフォルトのロジックを使用
      // 複合単位（1文字単位）の優先順序を定義
      const compoundUnits = ['J', 'N', 'W', 'Pa', 'Hz', 'C', 'V', 'Ω', 'F', 'H', 'T', 'Wb'];
      final unitOrder = widget.selectedAnswer?.units ?? ['kg', 'm', 's', 'A'];
      
      // まず複合単位を追加
      for (final compoundUnit in compoundUnits) {
        if (units.containsKey(compoundUnit)) {
          sortedUnits.add(compoundUnit);
        }
      }
      
      // 次にselectedAnswerのunitsの順序に従って基本単位を追加
      for (final orderedUnit in unitOrder) {
        if (units.containsKey(orderedUnit) && !sortedUnits.contains(orderedUnit)) {
          sortedUnits.add(orderedUnit);
        }
      }
      
      // 順序にない単位も追加
      for (final unit in units.keys) {
        if (!unitOrder.contains(unit) && !compoundUnits.contains(unit) && !sortedUnits.contains(unit)) {
          sortedUnits.add(unit);
        }
      }
    }
    
    // 文字列に変換（・で区切る）
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
    
    return resultParts.join(' ・ ');
  }
  
  /// 正解の文字列から単位の順序を抽出
  /// 例: "A m^-1" -> ["A", "m"]
  List<String> _parseAnswerOrder(String answer) {
    final order = <String>[];
    // スペースまたは・で分割
    final parts = answer.trim().split(RegExp(r'[\s・]+'));
    
    for (final part in parts) {
      if (part.isEmpty) continue;
      
      // 単位と累乗を抽出
      final regex = RegExp(r'^([\wΩ]+)(?:\^(-?\d+))?$');
      final match = regex.firstMatch(part);
      
      if (match != null) {
        final unit = match.group(1)!;
        // 順序リストに追加（重複を避ける）
        if (!order.contains(unit)) {
          order.add(unit);
        }
      }
    }
    
    return order;
  }

  void _deleteLastChar() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        // 最後の単位を削除（スペース区切りで、累乗も含む）
        final parts = text.split(RegExp(r'\s+'));
        if (parts.length > 1) {
          parts.removeLast();
          final newText = parts.join(' ');
          final normalized = _normalizeUnitString(newText);
          _controller.value = TextEditingValue(
            text: normalized,
            selection: TextSelection.collapsed(
              offset: normalized.length,
            ),
          );
        } else {
          // 最後の1つだけの場合
          _controller.clear();
        }
      });
    }
  }

  void _clearAll() {
    setState(() {
      _controller.clear();
    });
  }

  void _handleEnter() {
    // バックスラッシュを除去してから渡す
    final input = _controller.text.trim().replaceAll('\\', '');
    if (input.isNotEmpty) {
      widget.onEnter(input);
    }
  }

  /// 単位文字列をTeX形式（分数形式）に変換
  /// 入力: "m s^-2" または "m ・ s^-2"
  /// 出力: "\frac{m}{s^{2}}"
  String _formatUnitString(String unitStr) {
    // バックスラッシュを除去（TeXコマンドの誤入力などを防ぐ）
    String formatted = unitStr.trim().replaceAll('\\', '');
    
    // スペースまたは・で分割して各単位を処理
    final parts = formatted.split(RegExp(r'[\s・]+'));
    final numeratorParts = <String>[];  // 分子（正の指数または指数なし）
    final denominatorParts = <String>[];  // 分母（負の指数を正に変換）
    
    for (final part in parts) {
      if (part.isEmpty) continue;
      
      // 負の指数をチェック（s^-1 など）
      if (part.contains('^-')) {
        final match = RegExp(r'([\wΩ]+)\^(-?\d+)').firstMatch(part);
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
        final match = RegExp(r'([\wΩ]+)\^(\d+)').firstMatch(part);
        if (match != null) {
          final base = match.group(1)!;
          final power = match.group(2)!;
          numeratorParts.add('$base^{$power}');
        } else {
          // パースできない場合は無視（バックスラッシュなどが含まれている可能性）
          // numeratorParts.add(part);
        }
      } else {
        // 指数なし - 有効な単位文字列のみ追加
        final match = RegExp(r'^[\wΩ]+$').firstMatch(part);
        if (match != null) {
          numeratorParts.add(part);
        }
        // パースできない場合は無視
      }
    }
    
    // 分数形式で返す
    if (denominatorParts.isEmpty) {
      // 分母がない場合は通常の形式
      return numeratorParts.join(r' \cdot ');
    } else if (numeratorParts.isEmpty) {
      // 分子がない場合は 1/分母 の形式
      final denominator = denominatorParts.join(r' \cdot ');
      return r'\frac{1}{' + denominator + '}';
    } else {
      // 分子と分母の両方がある場合は分数形式
      final numerator = numeratorParts.join(r' \cdot ');
      final denominator = denominatorParts.join(r' \cdot ');
      return r'\frac{' + numerator + '}{' + denominator + '}';
    }
  }
}

