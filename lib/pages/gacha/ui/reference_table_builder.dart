// lib/pages/gacha/ui/reference_table_builder.dart
// 参照テーブルの構築

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../../models/unit_reference_data.dart';
import '../formatting/reference_tex_formatter.dart' show formatToTex, containsMath;
import 'reference_data_processor.dart' show ReferenceCategory, ReferenceDataProcessor;

class ReferenceTableBuilder {
  final ReferenceDataProcessor _processor;
  final bool _isEnglish;
  
  ReferenceTableBuilder(this._processor, this._isEnglish);

  double get _headerFontSize => _isEnglish ? 14 : 12;
  double get _cellFontSize => _isEnglish ? 13 : 11;
  double get _mathFontSize => _isEnglish ? 16 : 14;
  
  Widget buildQuantitiesTable(List<Quantity> quantities, ReferenceCategory category) {
    final columnWidths = _isEnglish
        ? const {
            0: FixedColumnWidth(50),
            1: FixedColumnWidth(150),
            2: FixedColumnWidth(100),
            3: FixedColumnWidth(180),
            4: FixedColumnWidth(120),
            5: FixedColumnWidth(200),
          }
        : const {
            0: FixedColumnWidth(50),
            1: FixedColumnWidth(120),
            2: FixedColumnWidth(150),
            3: FixedColumnWidth(100),
            4: FixedColumnWidth(180),
            5: FixedColumnWidth(120),
            6: FixedColumnWidth(200),
          };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              columnWidths: columnWidths,
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: _isEnglish
                      ? [
                          _TableHeaderCell('No.', fontSize: _headerFontSize),
                          _TableHeaderCell('English', fontSize: _headerFontSize),
                          _TableHeaderCell('Unit Symbol', fontSize: _headerFontSize),
                          _TableHeaderCell('Unit Name', fontSize: _headerFontSize),
                          _TableHeaderCell('Main Quantity Symbols', fontSize: _headerFontSize),
                          _TableHeaderCell('Unit Relations', fontSize: _headerFontSize),
                        ]
                      : [
                          _TableHeaderCell('No.', fontSize: _headerFontSize),
                          _TableHeaderCell('日本語名', fontSize: _headerFontSize),
                          _TableHeaderCell('English', fontSize: _headerFontSize),
                          _TableHeaderCell('単位記号', fontSize: _headerFontSize),
                          _TableHeaderCell('単位名', fontSize: _headerFontSize),
                          _TableHeaderCell('主な量記号', fontSize: _headerFontSize),
                          _TableHeaderCell('単位の関係', fontSize: _headerFontSize),
                        ],
                ),
                ...quantities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final quantity = entry.value;
                  final rowColor = _processor.getRowColor(category, index);
                  return TableRow(
                    decoration: BoxDecoration(
                      color: rowColor, // 行全体の背景色
                    ),
                    children: _isEnglish
                        ? [
                            _TableCell(quantity.no.toString(), fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(quantity.en, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(quantity.unitSymbol, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(
                              quantity.unitNameEn.isNotEmpty ? quantity.unitNameEn : quantity.unitName,
                              fontSize: _cellFontSize,
                              mathFontSize: _mathFontSize,
                            ),
                            _TableCell(quantity.mainQuantitySymbols.join(', '), fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(quantity.unitRelations.join('\n'), fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                          ]
                        : [
                            _TableCell(quantity.no.toString(), fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(quantity.jp, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(quantity.en, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(quantity.unitSymbol, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(quantity.unitName, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(quantity.mainQuantitySymbols.join(', '), fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(quantity.unitRelations.join('\n'), fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                          ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget buildConstantsTable(List<Constant> constants, ReferenceCategory category) {
    final columnWidths = _isEnglish
        ? const {
            0: FixedColumnWidth(50),
            1: FixedColumnWidth(120),
            2: FixedColumnWidth(180),
            3: FixedColumnWidth(200),
          }
        : const {
            0: FixedColumnWidth(50),
            1: FixedColumnWidth(200),
            2: FixedColumnWidth(120),
            3: FixedColumnWidth(180),
            4: FixedColumnWidth(200),
          };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300, width: 1),
              columnWidths: columnWidths,
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: _isEnglish
                      ? [
                          _TableHeaderCell('No.', fontSize: _headerFontSize),
                          _TableHeaderCell('Symbol', fontSize: _headerFontSize),
                          _TableHeaderCell('Approx Value', fontSize: _headerFontSize),
                          _TableHeaderCell('Exact Value', fontSize: _headerFontSize),
                        ]
                      : [
                          _TableHeaderCell('No.', fontSize: _headerFontSize),
                          _TableHeaderCell('日本語名', fontSize: _headerFontSize),
                          _TableHeaderCell('記号', fontSize: _headerFontSize),
                          _TableHeaderCell('近似値', fontSize: _headerFontSize),
                          _TableHeaderCell('正確な値', fontSize: _headerFontSize),
                        ],
                ),
                ...constants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final constant = entry.value;
                  final rowColor = _processor.getRowColor(category, index);
                  return TableRow(
                    decoration: BoxDecoration(
                      color: rowColor, // 行全体の背景色
                    ),
                    children: _isEnglish
                        ? [
                            _TableCell(constant.no.toString(), fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(constant.symbol, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(constant.approxValue, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(constant.exactValue, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                          ]
                        : [
                            _TableCell(constant.no.toString(), fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(constant.jp, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(constant.symbol, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(constant.approxValue, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                            _TableCell(constant.exactValue, fontSize: _cellFontSize, mathFontSize: _mathFontSize),
                          ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final double fontSize;
  const _TableHeaderCell(this.text, {required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final double fontSize;
  final double mathFontSize;
  const _TableCell(this.text, {required this.fontSize, required this.mathFontSize});

  Widget _buildContent() {
    if (text.isEmpty) {
      return Text('-', style: TextStyle(fontSize: fontSize), textAlign: TextAlign.left);
    }
    
    if (text.contains('\n')) {
      final lines = text.split('\n');
      final widgets = <Widget>[];
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.isEmpty) {
          widgets.add(const SizedBox(height: 4));
          continue;
        }
        
        if (containsMath(line)) {
          try {
            widgets.add(
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Math.tex(
                  formatToTex(line),
                  textStyle: TextStyle(fontSize: mathFontSize),
                  mathStyle: MathStyle.text,
                ),
              ),
            );
          } catch (e) {
            widgets.add(Text(line, style: TextStyle(fontSize: fontSize), textAlign: TextAlign.left));
          }
        } else {
          widgets.add(Text(line, style: TextStyle(fontSize: fontSize), textAlign: TextAlign.left));
        }
        
        if (i < lines.length - 1) widgets.add(const SizedBox(height: 4));
      }
      
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
    }
    
    if (containsMath(text)) {
      try {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(formatToTex(text), textStyle: TextStyle(fontSize: mathFontSize), mathStyle: MathStyle.text),
        );
      } catch (e) {
        return Text(text, style: TextStyle(fontSize: fontSize), textAlign: TextAlign.left, softWrap: true, maxLines: null);
      }
    }
    
    return Text(text, style: TextStyle(fontSize: fontSize), textAlign: TextAlign.left, softWrap: true, maxLines: null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      child: _buildContent(),
    );
  }
}





