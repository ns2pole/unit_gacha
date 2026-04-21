// lib/utils/gacha_settings_utils.dart
// ガチャ設定の読み込み/保存に関する共通ユーティリティ関数

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../pages/common/aggregation_mode.dart';
import '../services/problems/exclusion_logic.dart';
import '../services/problems/simple_data_manager.dart';
import '../managers/timer_manager.dart';
import '../problems/unit/symbol.dart';
import '../pages/gacha/pages/gacha_settings_page.dart' show GachaFilterMode;
import '../pages/gacha/ui/reference_data_processor.dart' show ReferenceCategory;

/// ガチャ設定を読み込む
class GachaSettingsLoader {
  /// 除外モードを読み込む
  static Future<ExclusionMode> loadExclusionMode(String prefsPrefix) async {
    final key = '${prefsPrefix}_gacha_exclusion_mode';
    final raw = await SimpleDataManager.getOtherSettingValue(key);
    final exclusionIndex = raw is int ? raw : null;

    if (exclusionIndex != null && 
        exclusionIndex >= 0 && 
        exclusionIndex < ExclusionMode.values.length) {
      return ExclusionMode.values[exclusionIndex];
    }
    return ExclusionMode.none;
  }

  /// 集計モードを読み込む
  static Future<AggregationMode> loadAggregationMode(String prefsPrefix) async {
    // ガチャ設定から読み込む
    final settings = await SimpleDataManager.getGachaSettings(prefsPrefix);
    final aggregationIndex = settings['aggregationMode'] as int?;
    
    // 後方互換性: 古いキーからも読み込む（移行期間中）
    if (aggregationIndex == null) {
      final prefs = await SharedPreferences.getInstance();
      final oldKey = '${prefsPrefix}_gacha_aggregation_mode';
      final oldValue = prefs.getInt(oldKey);
      if (oldValue != null && oldValue >= 0 && oldValue < AggregationMode.values.length) {
        // 古いキーから値を取得した場合、ガチャ設定に移行
        await GachaSettingsSaver.saveAggregationMode(prefsPrefix, AggregationMode.values[oldValue]);
        await prefs.remove(oldKey);
        return AggregationMode.values[oldValue];
      }
    }
    
    if (aggregationIndex != null && 
        aggregationIndex >= 0 && 
        aggregationIndex < AggregationMode.values.length) {
      return AggregationMode.values[aggregationIndex];
    }
    return AggregationMode.latest1;
  }

  /// 選択枚数を読み込む
  static Future<int> loadMaxSelections(String prefsPrefix, {int defaultValue = 2}) async {
    final key = '${prefsPrefix}_gacha_max_selections';
    final raw = await SimpleDataManager.getOtherSettingValue(key);
    final maxSelections = raw is int ? raw : null;

    if (maxSelections != null && maxSelections >= 1 && maxSelections <= 3) {
      return maxSelections;
    }
    return defaultValue;
  }

  /// 単位ガチャの選択カテゴリーを読み込む
  static Future<Set<UnitCategory>> loadSelectedCategories() async {
    final key = 'unit_gacha_selected_categories';
    final raw = await SimpleDataManager.getOtherSettingValue(
      key,
      legacyDecoder: (legacyRaw) {
        if (legacyRaw is List) return legacyRaw;
        if (legacyRaw is! String || legacyRaw.isEmpty) return null;
        try {
          return json.decode(legacyRaw);
        } catch (_) {
          return null;
        }
      },
    );

    if (raw != null) {
      try {
        final categoriesList = raw is List
            ? raw.cast<dynamic>()
            : raw is String
            ? (json.decode(raw) as List<dynamic>)
            : const <dynamic>[];
        return categoriesList
            .map((c) => UnitCategory.values.firstWhere(
                  (cat) => cat.name == c,
                  orElse: () => UnitCategory.mechanics,
                ))
            .toSet();
      } catch (e) {
        print('Error loading categories: $e');
        return {};
      }
    }
    return {};
  }

  /// 単位参照（物理量/定数一覧）の選択カテゴリを読み込む（単一選択）
  static Future<ReferenceCategory> loadReferenceTableSelectedCategory({
    ReferenceCategory defaultValue = ReferenceCategory.mechanics,
  }) async {
    const key = 'unit_reference_table_selected_category';
    final raw = await SimpleDataManager.getOtherSettingValue(key);
    final storedName = raw is String ? raw : null;

    if (storedName != null) {
      try {
        return ReferenceCategory.values.firstWhere(
          (c) => c.name == storedName,
          orElse: () => defaultValue,
        );
      } catch (e) {
        print('Error loading reference table category: $e');
        return defaultValue;
      }
    }

    return defaultValue;
  }

  /// タイマー設定を読み込む
  static Future<void> loadTimerSettings(TimerManager timerManager, String prefsPrefix) async {
    await timerManager.loadTimerSettings(prefsPrefix);
  }

  /// タイマーの初期時間を設定（選択枚数に基づく）
  static Future<void> initializeTimerBasedOnSelection(
    String prefsPrefix,
    int maxSelections,
    TimerManager timerManager,
  ) async {
    final timerSettings = await SimpleDataManager.getGachaSettings(prefsPrefix);
    if (timerSettings['timerMinutes'] == null) {
      final settings = await SimpleDataManager.getGachaSettings(prefsPrefix);
      settings['timerMinutes'] = maxSelections;
      settings['remainingSeconds'] = maxSelections * 60;
      await SimpleDataManager.saveGachaSettings(prefsPrefix, settings);
      await timerManager.loadTimerSettings(prefsPrefix);
    }
  }

  /// GachaFilterModeを読み込む
  static Future<GachaFilterMode> loadGachaFilterMode(String prefsPrefix) async {
    final settings = await SimpleDataManager.getGachaSettings(prefsPrefix);
    final filterModeStr = settings['filterMode'] as String?;
    
    if (filterModeStr != null) {
      switch (filterModeStr) {
        case 'exclude_solved_ge1':
          return GachaFilterMode.excludeSolvedGE1;
        case 'exclude_solved_ge2':
          return GachaFilterMode.excludeSolvedGE2;
        case 'exclude_solved_ge3':
          return GachaFilterMode.excludeSolvedGE3;
        case 'exclude_solved':
          return GachaFilterMode.excludeSolved;
        case 'only_unsolved':
          return GachaFilterMode.onlyUnsolved;
        case 'random':
        default:
          return GachaFilterMode.random;
      }
    }
    return GachaFilterMode.random;
  }
}

/// ガチャ設定を保存する
class GachaSettingsSaver {
  /// 除外モードを保存
  static Future<void> saveExclusionMode(String prefsPrefix, ExclusionMode mode) async {
    final key = '${prefsPrefix}_gacha_exclusion_mode';
    await SimpleDataManager.saveOtherSettingValue(key, mode.index);
  }

  /// 集計モードを保存
  static Future<void> saveAggregationMode(String prefsPrefix, AggregationMode mode) async {
    // ガチャ設定として保存
    final settings = await SimpleDataManager.getGachaSettings(prefsPrefix);
    settings['aggregationMode'] = mode.index;
    await SimpleDataManager.saveGachaSettings(prefsPrefix, settings);

    // 後方互換性キーは移行後に削除する
    final prefs = await SharedPreferences.getInstance();
    final oldKey = '${prefsPrefix}_gacha_aggregation_mode';
    await prefs.remove(oldKey);
  }

  /// 選択枚数を保存
  static Future<void> saveMaxSelections(String prefsPrefix, int maxSelections) async {
    final key = '${prefsPrefix}_gacha_max_selections';
    await SimpleDataManager.saveOtherSettingValue(key, maxSelections);
  }

  /// 単位ガチャの選択カテゴリーを保存
  static Future<void> saveSelectedCategories(Set<UnitCategory> categories) async {
    final key = 'unit_gacha_selected_categories';
    final categoriesList = categories.map((c) => c.name).toList();
    await SimpleDataManager.saveOtherSettingValue(key, categoriesList);
  }

  /// 単位参照（物理量/定数一覧）の選択カテゴリを保存（単一選択）
  static Future<void> saveReferenceTableSelectedCategory(ReferenceCategory category) async {
    const key = 'unit_reference_table_selected_category';
    final value = category.name;
    await SimpleDataManager.saveOtherSettingValue(key, value);
  }

  /// GachaFilterModeを保存
  static Future<void> saveGachaFilterMode(String prefsPrefix, GachaFilterMode mode) async {
    final settings = await SimpleDataManager.getGachaSettings(prefsPrefix);
    String filterModeStr;
    switch (mode) {
      case GachaFilterMode.random:
        filterModeStr = 'random';
        break;
      case GachaFilterMode.excludeSolved:
        filterModeStr = 'exclude_solved';
        break;
      case GachaFilterMode.excludeSolvedGE1:
        filterModeStr = 'exclude_solved_ge1';
        break;
      case GachaFilterMode.excludeSolvedGE2:
        filterModeStr = 'exclude_solved_ge2';
        break;
      case GachaFilterMode.excludeSolvedGE3:
        filterModeStr = 'exclude_solved_ge3';
        break;
      case GachaFilterMode.onlyUnsolved:
        filterModeStr = 'only_unsolved';
        break;
    }
    settings['filterMode'] = filterModeStr;
    await SimpleDataManager.saveGachaSettings(prefsPrefix, settings);
  }
}




