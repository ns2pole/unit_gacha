// lib/pages/gacha/unit_gacha_filter.dart
// 単位ガチャページのフィルタリング関連

import 'package:flutter/material.dart';
import '../../../problems/unit/problems.dart' show unitGachaItems;
import '../../../problems/unit/symbol.dart' show UnitCategory, UnitProblem;
import '../../../localization/app_localizations.dart';
import '../../../widgets/gacha/filter_chips.dart'
    show GachaExclusionFilterWidget;
import '../pages/gacha_settings_page.dart';
import '../../../utils/gacha_settings_utils.dart' show GachaSettingsSaver;
import '../../../services/problems/exclusion_logic.dart'
    show shouldExcludeByMode;
import '../../../models/math_problem.dart';
import 'unit_gacha_problem_manager.dart' show UnitGachaProblemManager;

/// フィルタリング関連のヘルパークラス
class UnitGachaFilterHelper {
  final AppLocalizations _l10n;
  final UnitGachaProblemManager _problemManager;

  UnitGachaFilterHelper(this._l10n, this._problemManager);

  /// フィルタリング後の問題数を計算（カテゴリーフィルタリング + 除外設定）
  /// 実際の問題数（同じexprとmeaningを持つUnitProblemの数を合計）を返す
  Future<int> getFilteredProblemCount(
    Set<UnitCategory> selectedCategories,
    GachaFilterMode gachaFilterMode,
  ) async {
    if (gachaFilterMode == GachaFilterMode.random) {
      return _problemManager.getTotalProblemCount(selectedCategories);
    }

    // カテゴリーフィルタリング後の問題を取得
    var filteredItems = unitGachaItems.where((item) {
      if (selectedCategories.isEmpty) {
        return true;
      }
      return selectedCategories.contains(
        item.exprProblem.category,
      );
    }).toList();

    if (filteredItems.isEmpty) {
      filteredItems = unitGachaItems;
    }

    // 除外判定を実行（GachaFilterModeをExclusionModeに変換）
    final exclusionMode = gachaFilterMode.toExclusionMode();
    final nonExcludedProblems = <UnitProblem>[];
    for (final item in filteredItems) {
      // UnitProblemを直接渡す（shouldExcludeByModeはdynamicを受け取る）
      final shouldExclude = await shouldExcludeByMode(
        item.unitProblem,
        exclusionMode,
      );
      if (!shouldExclude) {
        nonExcludedProblems.add(item.unitProblem);
      }
    }

    return nonExcludedProblems.length;
  }

  /// フィルター設定部分を構築（除外設定のみ）
  Widget buildFilterSection({
    required Set<UnitCategory> selectedCategories,
    required GachaFilterMode gachaFilterMode,
    required ValueChanged<GachaFilterMode> onGachaFilterModeChanged,
    required VoidCallback onStateChanged,
    bool isProblemListMode = false,
  }) {
    // 実際の問題数を計算（同じexprとmeaningを持つUnitProblemの数を合計）
    final filteredItems = unitGachaItems.where((item) {
      if (selectedCategories.isEmpty) {
        return true;
      }
      return selectedCategories.contains(
        item.exprProblem.category,
      );
    }).toList();
    final totalCount = filteredItems.length;

    return FutureBuilder<int>(
      future: getFilteredProblemCount(selectedCategories, gachaFilterMode),
      builder: (context, snapshot) {
        final filteredCount = snapshot.hasData ? snapshot.data! : totalCount;
        final problemCountText = gachaFilterMode == GachaFilterMode.random
            ? (isProblemListMode
                ? _l10n.totalCountOnly(totalCount)
                : _l10n.filterNoExclusion(totalCount))
            : _l10n.filterRemaining(filteredCount, totalCount);

        return GachaExclusionFilterWidget(
          gachaFilterMode: gachaFilterMode,
          onGachaFilterModeChanged: (GachaFilterMode newMode) async {
            onStateChanged();
            await GachaSettingsSaver.saveGachaFilterMode('unit', newMode);
            onGachaFilterModeChanged(newMode);
          },
          prefsPrefix: 'unit',
          problemCountText: problemCountText,
          showStatusBadge: gachaFilterMode != GachaFilterMode.random,
          additionalText: gachaFilterMode != GachaFilterMode.random
              ? _l10n.filterAdditional
              : null,
          iconSize: 20,
          isProblemListMode: isProblemListMode,
        );
      },
    );
  }

  /// カテゴリーセレクタボタン（複数選択可能）
  Widget buildCategorySelector({
    required UnitCategory category,
    required Set<UnitCategory> selectedCategories,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedCategories.contains(category);

    // カテゴリーごとの色とグラデーションを定義
    Color? selectedColor;
    Color? selectedBorderColor;
    LinearGradient? selectedGradient;

    switch (category) {
      case UnitCategory.mechanics:
        // 力学: 紫
        selectedColor = Colors.purple;
        selectedBorderColor = Colors.purple.shade700;
        break;
      case UnitCategory.thermodynamics:
        // 熱力学: 赤とオレンジのグラデーション
        selectedGradient = const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        selectedBorderColor = const Color(0xFFFF5722);
        break;
      case UnitCategory.waves:
        // 波動: 水色
        selectedColor = Colors.cyan;
        selectedBorderColor = Colors.cyan.shade700;
        break;
      case UnitCategory.electromagnetism:
        // 電磁気学: 黄色
        selectedColor = Colors.amber;
        selectedBorderColor = Colors.amber.shade700;
        break;
      case UnitCategory.atom:
        // 原子: 緑
        selectedColor = Colors.green;
        selectedBorderColor = Colors.green.shade700;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (selectedGradient != null ? null : selectedColor)
              : Colors.grey.shade200,
          gradient: isSelected ? selectedGradient : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (selectedBorderColor ?? Colors.grey.shade400)
                : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Text(
          _l10n.unitCategory(category),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// フィルター設定パネルを構築
  Widget buildFilterSettingsPanel({
    required Set<UnitCategory> selectedCategories,
    required GachaFilterMode gachaFilterMode,
    required ValueChanged<UnitCategory> onCategoryToggled,
    required ValueChanged<GachaFilterMode> onGachaFilterModeChanged,
    required VoidCallback onStateChanged,
    bool isProblemListMode = false,
  }) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400; // 画面幅が400px未満の場合は2段レイアウト

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1段目: mechanics, thermodynamics, waves
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildCategorySelector(
                      category: UnitCategory.mechanics,
                      selectedCategories: selectedCategories,
                      onTap: () => onCategoryToggled(UnitCategory.mechanics),
                    ),
                    const SizedBox(width: 8),
                    buildCategorySelector(
                      category: UnitCategory.thermodynamics,
                      selectedCategories: selectedCategories,
                      onTap: () =>
                          onCategoryToggled(UnitCategory.thermodynamics),
                    ),
                    const SizedBox(width: 8),
                    buildCategorySelector(
                      category: UnitCategory.waves,
                      selectedCategories: selectedCategories,
                      onTap: () => onCategoryToggled(UnitCategory.waves),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 2段目: electromagnetism, atom
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildCategorySelector(
                      category: UnitCategory.electromagnetism,
                      selectedCategories: selectedCategories,
                      onTap: () =>
                          onCategoryToggled(UnitCategory.electromagnetism),
                    ),
                    const SizedBox(width: 8),
                    buildCategorySelector(
                      category: UnitCategory.atom,
                      selectedCategories: selectedCategories,
                      onTap: () => onCategoryToggled(UnitCategory.atom),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              buildFilterSection(
                selectedCategories: selectedCategories,
                gachaFilterMode: gachaFilterMode,
                onGachaFilterModeChanged: onGachaFilterModeChanged,
                onStateChanged: onStateChanged,
                isProblemListMode: isProblemListMode,
              ),
            ],
          ),
        );
      },
    );
  }
}
