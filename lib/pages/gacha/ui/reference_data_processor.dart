// lib/pages/gacha/ui/reference_data_processor.dart
// 参照テーブルのデータ処理

import 'package:flutter/material.dart';
import '../../../../models/unit_reference_data.dart';

enum ReferenceCategory {
  mechanics,
  waves,
  thermodynamics,
  electromagnetism,
  atom,
}

class ReferenceDataProcessor {
  final UnitReferenceData? data;
  
  ReferenceDataProcessor(this.data);
  
  List<Quantity> getQuantitiesByCategory(ReferenceCategory category) {
    if (data == null) return [];
    
    switch (category) {
      case ReferenceCategory.mechanics:
        return data!.quantities.where((q) => q.no >= 1 && q.no <= 29).toList();
      case ReferenceCategory.waves:
        return data!.quantities.where((q) => (q.no >= 30 && q.no <= 33) || q.no == 40).toList();
      case ReferenceCategory.thermodynamics:
        return data!.quantities.where((q) => q.no >= 34 && q.no <= 39).toList();
      case ReferenceCategory.electromagnetism:
        return data!.quantities.where((q) => q.no >= 41 && q.no <= 63).toList();
      case ReferenceCategory.atom:
        // 原子物理の物理量はNo. 64以降とする（将来用）
        return data!.quantities.where((q) => q.no >= 64).toList();
    }
  }
  
  List<Constant> getConstantsByCategory(ReferenceCategory category) {
    if (data == null) return [];
    
    switch (category) {
      case ReferenceCategory.mechanics:
        return data!.constants.where((c) => c.no >= 1 && c.no <= 2).toList();
      case ReferenceCategory.waves:
        return data!.constants.where((c) => c.no >= 10 && c.no <= 11).toList();
      case ReferenceCategory.thermodynamics:
        return data!.constants.where((c) => c.no >= 3 && c.no <= 9).toList();
      case ReferenceCategory.electromagnetism:
        return data!.constants.where((c) => c.no >= 12 && c.no <= 25).toList();
      case ReferenceCategory.atom:
        // 原子物理の定数はNo. 26以降とする（将来用）
        return data!.constants.where((c) => c.no >= 26).toList();
    }
  }
  
  Color getCategoryBackgroundColor(ReferenceCategory category) {
    switch (category) {
      case ReferenceCategory.mechanics:
        return Colors.purple.shade50;
      case ReferenceCategory.thermodynamics:
        return const Color(0xFFFF5722).withOpacity(0.1);
      case ReferenceCategory.waves:
        return Colors.cyan.shade50;
      case ReferenceCategory.electromagnetism:
        return Colors.amber.shade50;
      case ReferenceCategory.atom:
        return Colors.green.shade50;
    }
  }
  
  Color getRowColor(ReferenceCategory category, int index) {
    final isEven = index % 2 == 0;
    switch (category) {
      case ReferenceCategory.mechanics:
        return isEven ? const Color(0xFFF9F5FB) : const Color(0xFFF3E5F5);
      case ReferenceCategory.thermodynamics:
        return isEven ? const Color(0xFFFEF5F0) : const Color(0xFFFCE4D6);
      case ReferenceCategory.waves:
        return isEven ? const Color(0xFFF0FDFE) : const Color(0xFFE0F7FA);
      case ReferenceCategory.electromagnetism:
        return isEven ? const Color(0xFFFFFEF5) : const Color(0xFFFFF8E1);
      case ReferenceCategory.atom:
        return isEven ? const Color(0xFFF1F8E9) : const Color(0xFFE8F5E9);
    }
  }
  
  String getCategoryName(ReferenceCategory category, bool isEnglish) {
    switch (category) {
      case ReferenceCategory.mechanics:
        return isEnglish ? 'Mechanics' : '力学';
      case ReferenceCategory.waves:
        return isEnglish ? 'Waves' : '波動';
      case ReferenceCategory.thermodynamics:
        return isEnglish ? 'Thermodynamics' : '熱力学';
      case ReferenceCategory.electromagnetism:
        return isEnglish ? 'Electromagnetism' : '電磁気学';
      case ReferenceCategory.atom:
        return isEnglish ? 'Atom' : '原子物理';
    }
  }
}





