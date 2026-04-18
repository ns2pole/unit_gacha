// lib/models/unit_reference_data.dart
// 単位参照データのモデルクラス

class UnitReferenceData {
  final Schema schema;
  final List<Quantity> quantities;
  final List<Constant> constants;

  UnitReferenceData({
    required this.schema,
    required this.quantities,
    required this.constants,
  });

  factory UnitReferenceData.fromJson(Map<String, dynamic> json) {
    return UnitReferenceData(
      schema: Schema.fromJson(json['schema'] as Map<String, dynamic>),
      quantities: (json['quantities'] as List<dynamic>)
          .map((item) => Quantity.fromJson(item as Map<String, dynamic>))
          .toList(),
      constants: (json['constants'] as List<dynamic>)
          .map((item) => Constant.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Schema {
  final List<String> quantityFields;
  final List<String> constantFields;

  Schema({
    required this.quantityFields,
    required this.constantFields,
  });

  factory Schema.fromJson(Map<String, dynamic> json) {
    return Schema(
      quantityFields: (json['quantities']?['fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      constantFields: (json['constants']?['fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class Quantity {
  final int no;
  final String jp;
  final String en;
  final String unitSymbol;
  final String unitName;
  final String unitNameEn;
  final List<String> mainQuantitySymbols;
  final List<String> unitRelations;

  Quantity({
    required this.no,
    required this.jp,
    required this.en,
    required this.unitSymbol,
    required this.unitName,
    required this.unitNameEn,
    required this.mainQuantitySymbols,
    required this.unitRelations,
  });

  factory Quantity.fromJson(Map<String, dynamic> json) {
    return Quantity(
      no: json['no'] as int,
      jp: json['jp'] as String,
      en: json['en'] as String,
      unitSymbol: json['unit_symbol'] as String? ?? '',
      unitName: json['unit_name'] as String? ?? '',
      unitNameEn: json['unit_name_en'] as String? ?? '',
      mainQuantitySymbols: (json['main_quantity_symbols'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      unitRelations: (json['unit_relations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class Constant {
  final int no;
  final String jp;
  final String symbol;
  final String approxValue;
  final String exactValue;

  Constant({
    required this.no,
    required this.jp,
    required this.symbol,
    required this.approxValue,
    required this.exactValue,
  });

  factory Constant.fromJson(Map<String, dynamic> json) {
    return Constant(
      no: json['no'] as int,
      jp: json['jp'] as String,
      symbol: json['symbol'] as String? ?? '',
      approxValue: json['approx_value'] as String? ?? '',
      exactValue: json['exact_value'] as String? ?? '',
    );
  }
}









