// lib/pages/gacha/data/settings_manager.dart
// 単位ガチャページの設定管理

import '../../../problems/unit/symbol.dart' show UnitCategory;
import '../../common/aggregation_mode.dart';
import '../pages/gacha_settings_page.dart' show GachaFilterMode;
import '../../../utils/gacha_settings_utils.dart' show GachaSettingsLoader, GachaSettingsSaver;
import '../../../managers/timer_manager.dart';

/// 設定管理クラス
class UnitGachaSettingsManager {
  /// 保存された設定を読み込む
  static Future<UnitGachaSettings> loadSettings({
    required TimerManager timerManager,
  }) async {
    final selectedCategories = await GachaSettingsLoader.loadSelectedCategories();
    final gachaFilterMode = await GachaSettingsLoader.loadGachaFilterMode('unit');
    final aggregationMode = await GachaSettingsLoader.loadAggregationMode('unit');
    
    await GachaSettingsLoader.loadTimerSettings(timerManager, 'unit');
    await GachaSettingsLoader.initializeTimerBasedOnSelection('unit', 1, timerManager);
    
    return UnitGachaSettings(
      selectedCategories: selectedCategories,
      gachaFilterMode: gachaFilterMode,
      aggregationMode: aggregationMode,
    );
  }
  
  /// 設定を保存する
  static Future<void> saveSettings({
    required Set<UnitCategory> selectedCategories,
  }) async {
    await GachaSettingsSaver.saveSelectedCategories(selectedCategories);
  }
}

/// 設定データクラス
class UnitGachaSettings {
  final Set<UnitCategory> selectedCategories;
  final GachaFilterMode gachaFilterMode;
  final AggregationMode aggregationMode;
  
  UnitGachaSettings({
    required this.selectedCategories,
    required this.gachaFilterMode,
    required this.aggregationMode,
  });
}





