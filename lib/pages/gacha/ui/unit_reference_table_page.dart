// lib/pages/gacha/ui/unit_reference_table_page.dart
// 単位参照テーブルページ

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/unit_reference_data.dart';
import '../../../../widgets/home/background_image_widget.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../localization/app_locale.dart';
import '../../../../managers/timer_manager.dart';
import '../ui/unit_gacha_common_header.dart' show UnitGachaCommonHeader;
import 'reference_data_processor.dart' show ReferenceCategory, ReferenceDataProcessor;
import 'reference_table_builder.dart' show ReferenceTableBuilder;
import '../../../../utils/gacha_settings_utils.dart' show GachaSettingsLoader, GachaSettingsSaver;

class UnitReferenceTablePage extends StatefulWidget {
  final VoidCallback? onClose;
  final TimerManager? timerManager;
  final bool isHelpPageVisible;
  final bool isProblemListVisible;
  final bool isReferenceTableVisible;
  final bool isScratchPaperMode;
  final bool showFilterSettings;
  final VoidCallback? onHelpToggle;
  final VoidCallback? onProblemListToggle;
  final VoidCallback? onReferenceTableToggle;
  final VoidCallback? onScratchPaperToggle;
  final VoidCallback? onFilterToggle;
  final VoidCallback? onLoginTap;
  final VoidCallback? onDataAnalysisNavigate;
  final bool isDataAnalysisActive;
  
  const UnitReferenceTablePage({
    Key? key,
    this.onClose,
    this.timerManager,
    this.isHelpPageVisible = false,
    this.isProblemListVisible = false,
    this.isReferenceTableVisible = true,
    this.isScratchPaperMode = false,
    this.showFilterSettings = false,
    this.onHelpToggle,
    this.onProblemListToggle,
    this.onReferenceTableToggle,
    this.onScratchPaperToggle,
    this.onFilterToggle,
    this.onLoginTap,
    this.onDataAnalysisNavigate,
    this.isDataAnalysisActive = false,
  }) : super(key: key);

  @override
  State<UnitReferenceTablePage> createState() => _UnitReferenceTablePageState();
}

class _UnitReferenceTablePageState extends State<UnitReferenceTablePage>
    with SingleTickerProviderStateMixin {
  UnitReferenceData? _data;
  bool _isLoading = true;
  String? _errorMessage;
  ReferenceDataProcessor? _processor;
  ReferenceCategory _selectedCategory = ReferenceCategory.mechanics;
  bool _isCategoryLoaded = false;

  String _categoryLabel(ReferenceCategory category, AppLocalizations l10n) {
    switch (category) {
      case ReferenceCategory.mechanics:
        return l10n.categoryLabelMechanics;
      case ReferenceCategory.thermodynamics:
        return l10n.categoryLabelThermodynamics;
      case ReferenceCategory.waves:
        return l10n.categoryLabelWaves;
      case ReferenceCategory.electromagnetism:
        return l10n.categoryLabelElectromagnetism;
      case ReferenceCategory.atom:
        return l10n.categoryLabelAtom;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeData() async {
    // カテゴリを先に読み込んでからデータを読み込む（チラつき防止）
    await _loadSelectedCategory();
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _loadSelectedCategory() async {
    final category = await GachaSettingsLoader.loadReferenceTableSelectedCategory();
    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
      _isCategoryLoaded = true;
    });
  }

  Future<void> _saveSelectedCategory(ReferenceCategory category) async {
    await GachaSettingsSaver.saveReferenceTableSelectedCategory(category);
  }

  Future<void> _loadData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/unit_reference_data.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final data = UnitReferenceData.fromJson(jsonData);
      setState(() {
        _data = data;
        _processor = ReferenceDataProcessor(data);
        _isLoading = false;
      });
    } catch (e) {
      final isEnglish = AppLocale.isEnglish(context);
      setState(() {
        _errorMessage = isEnglish ? 'Failed to load data: $e' : 'データの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildCategoryContent(ReferenceCategory category, bool isEnglish) {
    if (_data == null || _processor == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final quantities = _processor!.getQuantitiesByCategory(category);
    final constants = _processor!.getConstantsByCategory(category);
    final tableBuilder = ReferenceTableBuilder(_processor!, isEnglish);
    
    if (quantities.isEmpty && constants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            isEnglish ? 'No data available for this category.' : 'このカテゴリにはデータがありません。',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quantities.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                isEnglish ? 'Physical Quantities' : '物理量',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B7355),
                ),
              ),
            ),
            tableBuilder.buildQuantitiesTable(quantities, category),
          ],
          if (quantities.isNotEmpty && constants.isNotEmpty) const SizedBox(height: 24),
          if (constants.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                isEnglish ? 'Constants' : '定数',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B7355),
                ),
              ),
            ),
            tableBuilder.buildConstantsTable(constants, category),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final isEnglish = AppLocale.isEnglish(context);

    final timerMgr = widget.timerManager ?? TimerManager();
    
    return Scaffold(
      body: Stack(
        children: [
          // ヘルプページ同様、ヘッダー2行目まで背景を表示
          const Positioned.fill(child: BackgroundImageWidget()),
          Column(
            children: [
              // 共通ヘッダー
              SafeArea(
                bottom: false,
                child: UnitGachaCommonHeader(
                  timerManager: timerMgr,
                  l10n: locale,
                  isHelpPageVisible: widget.isHelpPageVisible,
                  isProblemListVisible: widget.isProblemListVisible,
                  isReferenceTableVisible: widget.isReferenceTableVisible,
                  isScratchPaperMode: widget.isScratchPaperMode,
                  showFilterSettings: widget.showFilterSettings,
                  disableTimer: true,
                  disableFilter: true,
                  onHelpToggle: widget.onHelpToggle ?? (widget.onClose ?? () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }),
                  onProblemListToggle: widget.onProblemListToggle ?? (widget.onClose ?? () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }),
                  onReferenceTableToggle: widget.onReferenceTableToggle ?? (widget.onClose ?? () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }),
                  onScratchPaperToggle: widget.onScratchPaperToggle ?? (widget.onClose ?? () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }),
                  onFilterToggle: widget.onFilterToggle ?? () {},
                  onLoginTap: widget.onLoginTap,
                  onDataAnalysisNavigate: widget.onDataAnalysisNavigate ?? (widget.onClose ?? () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }),
                  isDataAnalysisActive: widget.isDataAnalysisActive,
                  // カテゴリ選択をフィルタリングガジェットと同じ方法で表示
                  filterSettingsPanel: _isCategoryLoaded ? _buildCategorySelectorPanel(isEnglish: isEnglish) : null,
                  showFilterPanel: _isCategoryLoaded,
                ),
              ),
              // コンテンツ
              Expanded(
                child: Stack(
                  children: [
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (_data != null && _processor != null)
                      _buildCategoryContent(_selectedCategory, isEnglish),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelectorButton({
    required ReferenceCategory category,
    required bool isSelected,
    required VoidCallback onTap,
    required AppLocalizations l10n,
  }) {
    // フィルタリングのカテゴリボタンと同じ配色/形状に寄せる
    Color? selectedColor;
    Color? selectedBorderColor;
    LinearGradient? selectedGradient;

    switch (category) {
      case ReferenceCategory.mechanics:
        selectedColor = Colors.purple;
        selectedBorderColor = Colors.purple.shade700;
        break;
      case ReferenceCategory.thermodynamics:
        selectedGradient = const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        selectedBorderColor = const Color(0xFFFF5722);
        break;
      case ReferenceCategory.waves:
        selectedColor = Colors.cyan;
        selectedBorderColor = Colors.cyan.shade700;
        break;
      case ReferenceCategory.electromagnetism:
        selectedColor = Colors.amber;
        selectedBorderColor = Colors.amber.shade700;
        break;
      case ReferenceCategory.atom:
        selectedColor = Colors.green;
        selectedBorderColor = Colors.green.shade700;
        break;
    }

    // 最初のフレームから端末言語で表示する（データ読込前でも英語ちらつきを起こさない）
    final label = _categoryLabel(category, l10n);

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
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelectorPanel({required bool isEnglish}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final l10n = AppLocalizations.of(context);

    void onSelect(ReferenceCategory category) {
      if (category == _selectedCategory) return;
      setState(() {
        _selectedCategory = category;
      });
      _saveSelectedCategory(category);
    }

    Widget buildRow(List<ReferenceCategory> categories) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < categories.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _buildCategorySelectorButton(
                category: categories[i],
                isSelected: _selectedCategory == categories[i],
                onTap: () => onSelect(categories[i]),
                l10n: l10n,
              ),
            ],
          ],
        ),
      );
    }

    // フィルタリングガジェットと同じ形式で返す
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isSmallScreen) ...[
            // 小さい画面の場合: 2段レイアウト
            buildRow(const [ReferenceCategory.mechanics, ReferenceCategory.thermodynamics]),
            const SizedBox(height: 8),
            buildRow(const [ReferenceCategory.waves, ReferenceCategory.electromagnetism, ReferenceCategory.atom]),
          ] else ...[
            // 大きい画面の場合: 1段レイアウト
            buildRow(const [
              ReferenceCategory.mechanics,
              ReferenceCategory.thermodynamics,
              ReferenceCategory.waves,
              ReferenceCategory.electromagnetism,
              ReferenceCategory.atom,
            ]),
          ],
        ],
      ),
    );
  }
}
