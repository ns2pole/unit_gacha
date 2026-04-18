// lib/pages/gacha_settings_page.dart
// ガチャ設定ページ（gacha_page.dartから分離）

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/problems/simple_data_manager.dart';
import '../../../models/learning_status.dart';
import '../../common/aggregation_mode.dart';
import '../../../services/problems/exclusion_logic.dart' show ExclusionMode;
import '../../../localization/app_localizations.dart';

// 共通のラベル配列（0: 初級, 1: 中級, 2: 上級）
const List<String> kLevelOrder = ['初級', '中級', '上級'];

enum GachaFilterMode {
  random,
  excludeSolved,
  excludeSolvedGE1,
  excludeSolvedGE2,
  excludeSolvedGE3,
  onlyUnsolved;
}

extension GachaFilterModeExt on GachaFilterMode {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case GachaFilterMode.random:
        return l10n.filterModeRandom;
      case GachaFilterMode.excludeSolved:
        return l10n.filterModeExcludeSolved;
      case GachaFilterMode.excludeSolvedGE1:
        return l10n.filterModeLatest1;
      case GachaFilterMode.excludeSolvedGE2:
        return l10n.filterModeLatest2;
      case GachaFilterMode.excludeSolvedGE3:
        return l10n.filterModeLatest3;
      case GachaFilterMode.onlyUnsolved:
        return l10n.filterModeUnsolvedOnly;
    }
  }

  int toInt() => index;
}

class GachaFilterModeFactory {
  static GachaFilterMode fromInt(int v) {
    if (v < 0 || v >= GachaFilterMode.values.length) {
      return GachaFilterMode.random;
    }
    return GachaFilterMode.values[v];
  }
}

/// 表示順（保存値の互換性を損なわないため enum 自体は変更せず、ここで表示順を定義）
const List<GachaFilterMode> kGachaDisplayOrder = [
  GachaFilterMode.random,
  GachaFilterMode.excludeSolvedGE3,
  GachaFilterMode.excludeSolvedGE2,
  GachaFilterMode.excludeSolvedGE1,
];

/// GachaFilterMode と ExclusionMode の相互変換
extension GachaFilterModeConversion on GachaFilterMode {
  ExclusionMode toExclusionMode() {
    switch (this) {
      case GachaFilterMode.random:
        return ExclusionMode.none;
      case GachaFilterMode.excludeSolvedGE1:
        return ExclusionMode.latest1;
      case GachaFilterMode.excludeSolvedGE2:
        return ExclusionMode.latest2;
      case GachaFilterMode.excludeSolvedGE3:
        return ExclusionMode.latest3;
      default:
        return ExclusionMode.none;
    }
  }
}

extension ExclusionModeConversion on ExclusionMode {
  GachaFilterMode toGachaFilterMode() {
    switch (this) {
      case ExclusionMode.none:
        return GachaFilterMode.random;
      case ExclusionMode.latest1:
        return GachaFilterMode.excludeSolvedGE1;
      case ExclusionMode.latest2:
        return GachaFilterMode.excludeSolvedGE2;
      case ExclusionMode.latest3:
        return GachaFilterMode.excludeSolvedGE3;
    }
  }
}

/// 設定ページ（prefsPrefix を受け取って同じキーで保存する）
class GachaSettingsPage extends StatefulWidget {
  final GachaFilterMode initialMode;
  final List<int> initialSlotLevels;
  final String prefsPrefix;

  const GachaSettingsPage({
    Key? key,
    required this.initialMode,
    this.initialSlotLevels = const [0, 1, 2],
    required this.prefsPrefix,
  }) : super(key: key);

  @override
  State<GachaSettingsPage> createState() => _GachaSettingsPageState();
}

class _GachaSettingsPageState extends State<GachaSettingsPage> {
  late GachaFilterMode _selected;
  late List<int> _selectedSlotLevels;

  // prefs keys local to settings (derived from widget.prefsPrefix)
  late final String _gachaFilterPrefLocal;
  late final String _slotLevelsPrefLocal;

  // スナックバー重複表示ガード（タイミングは現状維持）
  bool _snackGuard = false;
  Timer? _snackTimer;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMode;
    _selectedSlotLevels = List.from(widget.initialSlotLevels);
    while (_selectedSlotLevels.length < 3) _selectedSlotLevels.add(0);
    if (_selectedSlotLevels.length > 3) _selectedSlotLevels = _selectedSlotLevels.sublist(0, 3);

    final prefix = widget.prefsPrefix;
    _gachaFilterPrefLocal = '${prefix}_gacha_filter_mode_v1';
    _slotLevelsPrefLocal = '${prefix}_gacha_slot_levels_v1';
  }

  @override
  void dispose() {
    _snackTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveAllPrefsSilently() async {
    // SimpleDataManagerに設定を保存
    final settings = await SimpleDataManager.getGachaSettings(widget.prefsPrefix);
    
    // フィルタモードを保存
    switch (_selected) {
      case GachaFilterMode.random:
        settings['filterMode'] = 'random';
        break;
      case GachaFilterMode.excludeSolved:
        settings['filterMode'] = 'exclude_solved';
        break;
      case GachaFilterMode.excludeSolvedGE1:
        settings['filterMode'] = 'exclude_solved_ge1';
        break;
      case GachaFilterMode.excludeSolvedGE2:
        settings['filterMode'] = 'exclude_solved_ge2';
        break;
      case GachaFilterMode.excludeSolvedGE3:
        settings['filterMode'] = 'exclude_solved_ge3';
        break;
      case GachaFilterMode.onlyUnsolved:
        settings['filterMode'] = 'only_unsolved';
        break;
    }
    
    // スロットレベルを保存（unitガチャの場合は保存しない）
    if (widget.prefsPrefix != 'unit') {
      settings['slotLevels'] = _selectedSlotLevels;
    }
    
    await SimpleDataManager.saveGachaSettings(widget.prefsPrefix, settings);
  }

  Future<bool> _onWillPop() {
    Navigator.of(context).pop(_selected);
    return Future.value(false);
  }

  Future<void> _saveAndNotify() async {
    await _saveAllPrefsSilently();
    if (!mounted) return;
    _showSavedSnack();
  }

  // AggregationSettingsPage と同じ見た目（シンプルな SnackBar）に合わせる
  void _showSavedSnack() {
    if (_snackGuard) return;
    _snackGuard = true;

    // 現在のスナックを消してから表示（AggregationSettingsPage と同様の見た目）
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));

    _snackTimer?.cancel();
    _snackTimer = Timer(const Duration(milliseconds: 1200), () {
      _snackGuard = false;
    });
  }

  Widget _buildSlotDifficultyRow(int idx) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.problemDifficulty(idx), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var j = 0; j < kLevelOrder.length; j++) ...[
              GestureDetector(
                onTap: () async {
                  setState(() {
                    _selectedSlotLevels[idx] = j;
                  });
                  await _saveAndNotify();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: j,
                      groupValue: _selectedSlotLevels[idx],
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() {
                          _selectedSlotLevels[idx] = v;
                        });
                        await _saveAndNotify();
                      },
                    ),
                    Text(kLevelOrder[j], style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // 設定画面で表示するタイトルウィジェット（ラベルを丸バッジ表現に揃える）
  Widget _gachaModeTitleWidget(GachaFilterMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case GachaFilterMode.random:
        return Text(mode.label(context));
      case GachaFilterMode.excludeSolved:
        return Text(mode.label(context));
      case GachaFilterMode.onlyUnsolved:
        return Text(mode.label(context));
      case GachaFilterMode.excludeSolvedGE1:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.filterModeLatest1} ', style: TextStyle(fontSize: 14, color: Colors.grey[900])),
              _statusBadgeSmall(LearningStatus.solved, diameter: 18.0),
              const SizedBox(width: 2),
              Text(' ${l10n.filterThenExclude}', style: TextStyle(fontSize: 14, color: Colors.grey[900])),
            ],
          ),
        );
      case GachaFilterMode.excludeSolvedGE2:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.filterModeLatest2} ', style: TextStyle(fontSize: 14, color: Colors.grey[900])),
              _statusBadgeSmall(LearningStatus.solved, diameter: 18.0),
              const SizedBox(width: 2),
              Text(' ${l10n.filterThenExclude}', style: TextStyle(fontSize: 14, color: Colors.grey[900])),
            ],
          ),
        );
      case GachaFilterMode.excludeSolvedGE3:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.filterModeLatest3} ', style: TextStyle(fontSize: 14, color: Colors.grey[900])),
              _statusBadgeSmall(LearningStatus.solved, diameter: 18.0),
              const SizedBox(width: 2),
              Text(' ${l10n.filterThenExclude}', style: TextStyle(fontSize: 14, color: Colors.grey[900])),
            ],
          ),
        );
    }
  }

  Widget _statusBadgeSmall(LearningStatus status, {double diameter = 18.0}) {
    final double iconSize = diameter * 0.6;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: status.color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        status.icon,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context).gachaSettings,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B7355), // クリーム色っぽい色
            ),
          ),
          backgroundColor: Colors.grey[50], // Scaffoldのデフォルト背景色と同じ
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  children: [
                    Text(
                      AppLocalizations.of(context).filterSettings,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B7355),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final mode in GachaFilterMode.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              setState(() => _selected = mode);
                              await _saveAndNotify();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selected == mode
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selected == mode
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  width: _selected == mode ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<GachaFilterMode>(
                                    value: mode,
                                    groupValue: _selected,
                                    onChanged: (v) async {
                                      if (v == null) return;
                                      setState(() => _selected = v);
                                      await _saveAndNotify();
                                    },
                                  ),
                                  // 最小限の間隔
                                  const SizedBox(width: 4),
                                  // タイトル部分を展開
                                  Expanded(
                                    child: _gachaModeTitleWidget(mode),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // 微分方程式ガチャとunitガチャの場合はlevel選択を非表示
                    if (widget.prefsPrefix != 'physics_math' && widget.prefsPrefix != 'unit') ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context).selectDifficultyForSlot, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      _buildSlotDifficultyRow(0),
                      _buildSlotDifficultyRow(1),
                      _buildSlotDifficultyRow(2),
                      const SizedBox(height: 12),
                    ],
                    Text(AppLocalizations.of(context).exclusionRuleNote, style: const TextStyle(fontSize: 16)),
                    // 微分方程式ガチャの場合はカテゴリー選択の説明を追加
                    if (widget.prefsPrefix == 'physics_math') ...[
                      const SizedBox(height: 12),
                      Text(AppLocalizations.of(context).differentialEquationNote1, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                      Text(AppLocalizations.of(context).differentialEquationNote2, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

