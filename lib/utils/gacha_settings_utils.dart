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
import '../../services/auth/firebase_auth_service.dart';
import '../../services/auth/firestore_settings_service.dart';

/// ガチャ設定を読み込む
class GachaSettingsLoader {
  /// 除外モードを読み込む
  static Future<ExclusionMode> loadExclusionMode(String prefsPrefix) async {
    // まずローカルデータを即座に取得（遅延なし）
    final prefs = await SharedPreferences.getInstance();
    final key = '${prefsPrefix}_gacha_exclusion_mode';
    var exclusionIndex = prefs.getInt(key);
    
    // バックグラウンドでFirestoreから取得を試みる（非同期、エラーは無視）
    if (FirebaseAuthService.isAuthenticated) {
      final userId = FirebaseAuthService.userId;
      if (userId != null) {
        FirestoreSettingsService.getOtherSetting(
          userId: userId,
          key: key,
        ).timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        ).then((firestoreValue) async {
          if (firestoreValue != null && firestoreValue is int) {
            await prefs.setInt(key, firestoreValue);
            print('Background sync: Updated local exclusion mode from Firestore');
          }
        }).catchError((e) {
          print('Background sync error (ignored): $e');
        });
      }
    }
    
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
    // まずローカルデータを即座に取得（遅延なし）
    final prefs = await SharedPreferences.getInstance();
    final key = '${prefsPrefix}_gacha_max_selections';
    var maxSelections = prefs.getInt(key);
    
    // バックグラウンドでFirestoreから取得を試みる（非同期、エラーは無視）
    if (FirebaseAuthService.isAuthenticated) {
      final userId = FirebaseAuthService.userId;
      if (userId != null) {
        FirestoreSettingsService.getOtherSetting(
          userId: userId,
          key: key,
        ).timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        ).then((firestoreValue) async {
          if (firestoreValue != null && firestoreValue is int) {
            await prefs.setInt(key, firestoreValue);
            print('Background sync: Updated local max selections from Firestore');
          }
        }).catchError((e) {
          print('Background sync error (ignored): $e');
        });
      }
    }
    
    if (maxSelections != null && maxSelections >= 1 && maxSelections <= 3) {
      return maxSelections;
    }
    return defaultValue;
  }

  /// 単位ガチャの選択カテゴリーを読み込む
  static Future<Set<UnitCategory>> loadSelectedCategories() async {
    // まずローカルデータを即座に取得（遅延なし）
    final prefs = await SharedPreferences.getInstance();
    final key = 'unit_gacha_selected_categories';
    var categoriesJson = prefs.getString(key);
    
    // バックグラウンドでFirestoreから取得を試みる（非同期、エラーは無視）
    if (FirebaseAuthService.isAuthenticated) {
      final userId = FirebaseAuthService.userId;
      if (userId != null) {
        FirestoreSettingsService.getOtherSetting(
          userId: userId,
          key: key,
        ).timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        ).then((firestoreValue) async {
          if (firestoreValue != null && firestoreValue is String) {
            await prefs.setString(key, firestoreValue);
            print('Background sync: Updated local selected categories from Firestore');
          }
        }).catchError((e) {
          print('Background sync error (ignored): $e');
        });
      }
    }
    
    if (categoriesJson != null) {
      try {
        final categoriesList = json.decode(categoriesJson) as List<dynamic>;
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
    // まずローカルデータを即座に取得（遅延なし）
    final prefs = await SharedPreferences.getInstance();
    const key = 'unit_reference_table_selected_category';
    final storedName = prefs.getString(key);

    // バックグラウンドでFirestoreから取得を試みる（非同期、エラーは無視）
    if (FirebaseAuthService.isAuthenticated) {
      final userId = FirebaseAuthService.userId;
      if (userId != null) {
        FirestoreSettingsService.getOtherSetting(
          userId: userId,
          key: key,
        ).timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        ).then((firestoreValue) async {
          if (firestoreValue != null && firestoreValue is String) {
            await prefs.setString(key, firestoreValue);
            print('Background sync: Updated local reference table category from Firestore');
          }
        }).catchError((e) {
          print('Background sync error (ignored): $e');
        });
      }
    }

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
    final prefs = await SharedPreferences.getInstance();
    final key = '${prefsPrefix}_gacha_exclusion_mode';
    
    // ローカルに即座に保存（UXを下げない）
    await prefs.setInt(key, mode.index);
    
    // 認証済みユーザーの場合、Firestoreにも同時に保存（非同期、エラーは無視）
    if (FirebaseAuthService.isAuthenticated) {
      final userId = FirebaseAuthService.userId;
      if (userId != null) {
        FirestoreSettingsService.saveOtherSetting(
          userId: userId,
          key: key,
          value: mode.index,
        ).then((success) {
          if (success) {
            print('Successfully saved exclusion mode to Firestore');
          }
        }).catchError((e) {
          print('Error saving exclusion mode to Firestore (continuing with local save): $e');
        });
      }
    }
  }

  /// 集計モードを保存
  static Future<void> saveAggregationMode(String prefsPrefix, AggregationMode mode) async {
    // ガチャ設定として保存
    final settings = await SimpleDataManager.getGachaSettings(prefsPrefix);
    settings['aggregationMode'] = mode.index;
    await SimpleDataManager.saveGachaSettings(prefsPrefix, settings);
    
    // 後方互換性: 古いキーにも保存（移行期間中）
    final prefs = await SharedPreferences.getInstance();
    final oldKey = '${prefsPrefix}_gacha_aggregation_mode';
    await prefs.setInt(oldKey, mode.index);
  }

  /// 選択枚数を保存
  static Future<void> saveMaxSelections(String prefsPrefix, int maxSelections) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${prefsPrefix}_gacha_max_selections';
    
    // ローカルに即座に保存（UXを下げない）
    await prefs.setInt(key, maxSelections);
    
    // 認証済みユーザーの場合、Firestoreにも同時に保存（非同期、エラーは無視）
    if (FirebaseAuthService.isAuthenticated) {
      final userId = FirebaseAuthService.userId;
      if (userId != null) {
        FirestoreSettingsService.saveOtherSetting(
          userId: userId,
          key: key,
          value: maxSelections,
        ).then((success) {
          if (success) {
            print('Successfully saved max selections to Firestore');
          }
        }).catchError((e) {
          print('Error saving max selections to Firestore (continuing with local save): $e');
        });
      }
    }
  }

  /// 単位ガチャの選択カテゴリーを保存
  static Future<void> saveSelectedCategories(Set<UnitCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'unit_gacha_selected_categories';
    final categoriesList = categories.map((c) => c.name).toList();
    final categoriesJson = json.encode(categoriesList);
    
    // ローカルに即座に保存（UXを下げない）
    await prefs.setString(key, categoriesJson);
    
    // 認証済みユーザーの場合、Firestoreにも同時に保存（非同期、エラーは無視）
    if (FirebaseAuthService.isAuthenticated) {
      final userId = FirebaseAuthService.userId;
      if (userId != null) {
        FirestoreSettingsService.saveOtherSetting(
          userId: userId,
          key: key,
          value: categoriesJson,
        ).then((success) {
          if (success) {
            print('Successfully saved selected categories to Firestore');
          }
        }).catchError((e) {
          print('Error saving selected categories to Firestore (continuing with local save): $e');
        });
      }
    }
  }

  /// 単位参照（物理量/定数一覧）の選択カテゴリを保存（単一選択）
  static Future<void> saveReferenceTableSelectedCategory(ReferenceCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'unit_reference_table_selected_category';
    final value = category.name;

    // ローカルに即座に保存（UXを下げない）
    await prefs.setString(key, value);

    // 認証済みユーザーの場合、Firestoreにも同時に保存（非同期、エラーは無視）
    if (FirebaseAuthService.isAuthenticated) {
      final userId = FirebaseAuthService.userId;
      if (userId != null) {
        FirestoreSettingsService.saveOtherSetting(
          userId: userId,
          key: key,
          value: value,
        ).then((success) {
          if (success) {
            print('Successfully saved reference table category to Firestore');
          }
        }).catchError((e) {
          print('Error saving reference table category to Firestore (continuing with local save): $e');
        });
      }
    }
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




