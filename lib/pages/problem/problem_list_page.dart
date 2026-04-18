// unitGacha 問題一覧（2025/12/17 UI 再現 / UnitExprProblemベース）
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../localization/app_localizations.dart';
import '../../localization/app_locale.dart';
import '../../managers/timer_manager.dart';
import '../../problems/unit/symbol.dart'
    show SymbolDef, UnitCategory, UnitProblem;
import '../../problems/unit/unit_expr_problem.dart';
import '../../services/problems/exclusion_logic.dart'
    show shouldExcludeByMode, sortHistoryByTimeNewestFirst;
import '../../services/problems/simple_data_manager.dart';
import '../../services/payment/problem_access_service.dart';
import '../../services/payment/revenuecat_service.dart';
import '../../widgets/home/background_image_widget.dart';
import '../common/common.dart' show MixedTextMath;
import '../common/problem_status.dart';
import '../gacha/formatting/unit_formatters.dart'
    show
        formatExpression,
        formatSymbolToTex,
        formatUnitString,
        formatUnitSymbolForTexMath;
import '../gacha/ui/unit_gacha_common_header.dart' show UnitGachaCommonHeader;
import '../gacha/pages/gacha_settings_page.dart';

/// unitガチャの問題一覧（1カード=1 UnitExprProblem）
/// 2025/12/17時点の unitGacha の ProblemListPage（UnitProblemベース）を、
/// 現行データ構造（UnitExprProblem + unitProblems）で再現する。
class ProblemListPage extends StatefulWidget {
  final List<UnitExprProblem> problemPool;
  final String prefsPrefix;
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
  final Widget? filterSettingsPanel;
  final bool showFilterPanel;
  final Set<UnitCategory> selectedCategories;
  final GachaFilterMode gachaFilterMode;

  const ProblemListPage({
    super.key,
    required this.problemPool,
    this.prefsPrefix = 'unit',
    this.onClose,
    this.timerManager,
    this.isHelpPageVisible = false,
    this.isProblemListVisible = true,
    this.isReferenceTableVisible = false,
    this.isScratchPaperMode = false,
    this.showFilterSettings = false,
    this.filterSettingsPanel,
    this.showFilterPanel = false,
    this.selectedCategories = const {},
    this.gachaFilterMode = GachaFilterMode.random,
    this.onHelpToggle,
    this.onProblemListToggle,
    this.onReferenceTableToggle,
    this.onScratchPaperToggle,
    this.onFilterToggle,
    this.onLoginTap,
    this.onDataAnalysisNavigate,
    this.isDataAnalysisActive = false,
  });

  @override
  State<ProblemListPage> createState() => _ProblemListPageState();
}

class _ProblemListPageState extends State<ProblemListPage> {
  static const int _slotCount = slotCount; // 3

  /// UnitProblem.id -> latest3 slots
  final Map<String, List<Map<String, dynamic>>> _slotsCache = {};

  /// UnitProblem.id -> whether "point" is expanded in the list UI
  final Map<String, bool> _pointOpenByUnitId = {};

  VoidCallback? _learningEpochListener;

  bool _isPointOpen(UnitProblem p) => _pointOpenByUnitId[p.id] ?? false;

  void _togglePoint(UnitProblem p) {
    setState(() {
      _pointOpenByUnitId[p.id] = !(_pointOpenByUnitId[p.id] ?? false);
    });
  }

  Future<void> _showAndroidBillingPreparingDialog() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          content: Text(l10n.androidBillingPreparing),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // Curriculum ordering (within category)
  // ===========================================================================

  int _categoryCurriculumRank(UnitCategory c) {
    // NOTE: This only matters when multiple categories are visible in one list.
    // The "within each category" ordering is handled by _exprCurriculumRank.
    switch (c) {
      case UnitCategory.mechanics:
        return 10;
      case UnitCategory.waves:
        return 20;
      case UnitCategory.thermodynamics:
        return 30;
      case UnitCategory.electromagnetism:
        return 40;
      case UnitCategory.atom:
        return 50;
    }
  }

  String _exprKey(UnitExprProblem ep) => '${ep.expr}|${ep.meaning ?? ''}';

  int _exprCurriculumRank(UnitExprProblem ep) {
    // If not found, return large rank and keep original order (stable sort).
    final k = _exprKey(ep);
    switch (ep.category) {
      case UnitCategory.mechanics:
        // High school physics typical order (mechanics):
        // kinematics → dynamics → work/energy/power → momentum → circular/rotation → gravitation → fluids → oscillations
        return _mechanicsCurriculumRank[k] ?? 9999;
      case UnitCategory.waves:
        return _wavesCurriculumRank[k] ?? 9999;
      case UnitCategory.thermodynamics:
        return _thermoCurriculumRank[k] ?? 9999;
      case UnitCategory.electromagnetism:
        return _emCurriculumRank[k] ?? 9999;
      case UnitCategory.atom:
        return _atomCurriculumRank[k] ?? 9999;
    }
  }

  List<UnitExprProblem> _sortForCurriculum(List<UnitExprProblem> input) {
    final indexed = <({UnitExprProblem ep, int idx})>[];
    for (int i = 0; i < input.length; i++) {
      indexed.add((ep: input[i], idx: i));
    }

    indexed.sort((a, b) {
      final ca = _categoryCurriculumRank(a.ep.category);
      final cb = _categoryCurriculumRank(b.ep.category);
      if (ca != cb) return ca.compareTo(cb);

      final ra = _exprCurriculumRank(a.ep);
      final rb = _exprCurriculumRank(b.ep);
      if (ra != rb) return ra.compareTo(rb);

      // Stable fallback (keep original relative order).
      return a.idx.compareTo(b.idx);
    });

    return [for (final it in indexed) it.ep];
  }

  // ---- Rank maps ----
  static const Map<String, int> _mechanicsCurriculumRank = {
    // Tutorial-first: gravitational acceleration "g"
    'g|重力加速度': 0,

    // Kinematics (basics)
    'x|変位': 10,
    'v|速度': 20,
    'a|加速度': 30,
    'gt|自由落下の速度': 40,
    r'\frac{1}{2}gt^2|自由落下の変位': 50,

    // Dynamics (mass / acceleration / forces)
    // Requested order (mechanics): free fall, mass/acceleration → force → energy → rigid body → momentum/impulse → circular → oscillation → (end) gravitation
    'm|質量': 100,
    'ma|力': 110,
    'F|力': 120,
    'mg|重力': 130,
    'N|垂直抗力': 140,
    'μ|動摩擦係数': 150,
    r'\mu N|動摩擦力': 160,
    r'\mu_{s} N|最大静止摩擦力': 170,
    r'\mu_{s} N|静止摩擦力': 180,
    'kv|空気抵抗': 190,

    // Work / Energy / Power
    'W|仕事': 200,
    'Pt|仕事': 210,
    r'\frac{1}{2}mv^2|運動エネルギー': 220,
    r'\frac{1}{2}kx^2|ばねの弾性エネルギー': 230,
    'mgh|重力の位置エネルギー': 240,
    'P|電力': 250,
    r'\frac{W}{t}|電力': 260,

    // Rigid body (torque)
    'τ|力のモーメント': 300,
    r'Fx \cos \theta|力のモーメント': 310,
    'mrv|角運動量': 320,

    // Momentum / Impulse / Collision
    'mv|運動量': 400,
    'Ft|力積': 410,
    'e|反発係数': 420,

    // Circular motion
    'ω|角速度': 500,
    r'\omega t|角度': 510,
    r'r\omega^2|遠心力加速度': 520,
    'mrω^2|向心力': 530,
    r'\frac{mv^2}{r}|円運動の向心力': 540,
    // (This entry seems to be a data typo but keep it near circular dynamics.)
    r'\frac{mv^2}{r}|運動エネルギー': 550,

    // Oscillations
    'k|ばね定数': 600,
    'kx|ばねの力': 610,
    r'\frac{mg}{k}|ばねの平衡位置': 620,
    r'2\pi\sqrt{\frac{m}{k}}|ばね振動の周期': 630,
    r'2\pi\sqrt{\frac{l}{g}}|単振り子の周期': 640,
    'f|周波数': 650,
    r'\frac{1}{2}m\omega^2 A^2|調和振動のエネルギー': 660,

    // Fluids
    r'\frac{F}{S}|圧力': 700,
    r'\rho h g|流体の圧力': 710,
    'ρVg|浮力': 720,

    // Gravitation / Celestial (placed at the end in mechanics)
    'G|万有引力定数': 800,
    r'\frac{GMm}{r^2}|万有引力': 810,
    r'\frac{GM}{4\pi^2}|ケプラーの定数': 820,
    r'\frac{dS}{dt}|面積速度': 830,
    r'\sqrt{\frac{GM}{r}}|第一宇宙速度': 840,
    r'\sqrt{\frac{GM}{R}}|万有引力の場合の等速円運動の速度': 850,
    r'\sqrt{\frac{2GM}{r}}|第二宇宙速度': 860,
    r'-\frac{GMm}{r}|重力の位置エネルギー': 870,
  };

  static const Map<String, int> _wavesCurriculumRank = {
    // Basics
    'T|周期': 10,
    'ω|角周波数': 20,
    'λ|波長': 30,
    'k|波数(1mあたりどれだけ位相が変わるか)': 40,
    'v|波の速さ': 50,
    // Relations / applications
    'fλ|波の速さ': 60,
    r'\sqrt{\frac{T}{\rho}}|波の速さ': 70,
    'ρ|質量線密度': 80,
    // Optics / interference
    'mLλ/d|ヤングの実験（同位相2スリット）の明線の位置': 90,
    r'\sqrt{m\lambda R}|ニュートンリング（暗線）の半径': 100,
    r'2nd \cos r|薄膜（斜入射）の光路差': 110,
  };

  static const Map<String, int> _thermoCurriculumRank = {
    // Temperature / Heat
    'T|温度': 10,
    'Q|熱量': 20,
    'c|比熱': 30,
    'C|熱容量': 40,
    'C_v|定積モル比熱': 50,
    'γ|比熱比': 60,

    // Ideal gas basics
    'p|圧力': 100,
    'V|体積': 110,
    'R|気体定数': 120,
    'k|ボルツマン定数': 130,

    // Energy equivalents / internal energy
    'pV|エネルギー相当': 200,
    'nRT|エネルギー相当': 210,
    r'\frac{3}{2}nRT|単原子分子理想気体の内部エネルギー': 220,
    r'\frac{5}{2}nRT|2原子分子理想気体の内部エネルギー': 230,

    // Heat engines
    r'\eta|熱効率': 300,
  };

  static const Map<String, int> _emCurriculumRank = {
    // Requested order (electromagnetism):
    // electric field/charge/potential → capacitor (incl. electric energy) → current/resistance → magnetic field (Ampere etc.)
    // → Lorentz/forces → induction/self/mutual (coils; incl. magnetic energy) → AC/reactance → (end) EM waves (incl. displacement current)

    // Electric field / charge / potential (electrostatics)
    'k_0|クーロン定数': 10,
    'Q|電荷': 20,
    'CV|電荷': 30,
    // Place after the capacitor energy block (requested).
    // NOTE: Access control is NOT based on this rank (paid/free is handled separately).
    'It|電荷': 255,
    'σ|電荷面密度': 50,
    'ε0|真空の誘電率': 60,
    'E|電場': 70,
    r'\frac{V}{\ell}|電場': 80,
    'ES|電束（電場の面積積）': 90,
    'ε0ES|電束': 100,
    r'\frac{Q}{\epsilon_0}|電束': 110,
    'V|電圧': 120,
    'Ed|起電力(電圧)': 130,
    'qEd|電場による仕事': 140,

    // Capacitors (incl. electric energy)
    'C|静電容量': 200,
    r'\frac{\epsilon_0 S}{d}|静電容量': 210,
    r'\frac{Q^2}{2\epsilon_{0} S}|コンデンサ極板間引力': 220,
    r'\frac{1}{2}CV^2|静電エネルギー': 230,
    r'\frac{1}{2}QV|静電エネルギー': 240,
    r'\frac{Q^2}{2C}|静電エネルギー': 250,

    // Current / Resistance / DC circuits
    'I|電流': 300,
    r'\frac{Q}{t}|電流': 310,
    r'\frac{V}{R}|電流': 320,
    'V|電流': 330,
    'R|抵抗': 340,
    'ρ|抵抗率': 350,
    r'\frac{\rho L}{S}|抵抗': 360,
    'RI|電圧': 370,
    'VI|電力': 380,
    r'\frac{V^2}{R}|電力': 390,
    'RI^2|消費電力': 400,
    r'RI^2t|ジュール熱': 410,
    'RC|時定数': 420,

    // Magnetic field (Ampere's law, current produces magnetic field)
    'μ0|真空の透磁率': 500,
    'H|磁場の強さ': 510,
    r'\frac{I}{2\pi r}|磁場の強さ': 520,
    r'\frac{I}{2r}|回転電流による磁場の強さ': 530,
    'nI|磁場の強さ': 540,
    'B|磁束密度': 550,
    r'\frac{\mu_0 I}{2\pi r}|直線電流による磁束密度': 560,
    r'\frac{\mu_0 I}{2r}|回転電流による磁束密度': 570,
    r'\mu_0 n I|ソレノイドによる磁束密度': 580,
    'm|磁荷': 590,
    'mH|磁気力': 600,

    // Lorentz / force in magnetic field
    'IBℓ|導体に働く力': 650,
    r'qvB \sin \theta|ローレンツ力': 660,

    // Induction / coils (self & mutual; incl. magnetic energy)
    'Φ|磁束': 700,
    'BS|磁束': 710,
    'LI|コイルを貫く全磁束': 720,
    'MI|2次コイルを貫く全磁束': 730,
    r'\frac{d\Phi}{dt}|誘導起電力': 740,
    'vBℓ|誘導起電力': 750,
    r'M\frac{dI}{dt}|相互誘導起電力': 760,
    'L|インダクタンス': 770,
    r'\mu n^2 l S|ソレノイドのインダクタンス': 780,
    r'\frac{\mu_0 N^2 S}{L}|ソレノイドコイルの自己インダクタンス': 790,
    r'\frac{\mu_0 N_1 N_2 S}{L}|相互インダクタンス': 800,
    r'\frac{1}{2}LI^2|コイルの磁気エネルギー': 810,
    r'\frac{L}{R}|時定数': 820,

    // AC / reactance (placed after coils)
    'Z|インピーダンス': 850,
    r'\frac{1}{\omega C}|容量性リアクタンス': 860,
    'ωL|誘導性リアクタンス': 870,
    r'\frac{1}{\sqrt{LC}}|LC共振周波数': 880,

    // EM waves (placed at the end; displacement current belongs here)
    r'\epsilon_0 \frac{ d\Phi_E}{dt}|変位電流': 900,
    r'\frac{1}{2}\epsilon_0E^2|エネルギー密度': 910,
    r'\frac{B^2}{2\mu_0}|磁場のエネルギー密度': 920,
    r'\frac{1}{\sqrt{\epsilon_0\mu_0}}|光速': 930,
  };

  static const Map<String, int> _atomCurriculumRank = {
    'R|リュードベリ定数': 10,
    'h|プランク定数': 20,
    'W|仕事関数': 30,
    'e|電気素量': 35,
    '1eV|電子ボルト': 36,
    '1u|原子質量単位': 37,
    'mc^2|静止エネルギー': 40,
    r'\frac{h\nu}{c}|光の運動量': 50,
    r'\frac{h}{p}|ドブロイ波長': 60,
    r'2d \sin \theta|ブラッグの条件の光路差': 70,
  };

  String _filterKey() {
    final cats = widget.selectedCategories.map((c) => c.name).toList()..sort();
    return '${cats.join(",")}|${widget.gachaFilterMode.name}';
  }

  String? _lastFilterKey;
  Future<List<UnitExprProblem>>? _filteredProblemsFuture;

  String _aggKey() {
    final cats = widget.selectedCategories.map((c) => c.name).toList()..sort();
    return '${cats.join(",")}|${widget.gachaFilterMode.name}';
  }

  String? _lastAggKey;
  Future<({int green, int red})>? _aggFuture;

  String? _lastVisibleAggKey;
  Future<({int solved, int failed, int none})>?
  _visibleAggFuture;

  @override
  void initState() {
    super.initState();
    // 学習履歴が更新されたら、一覧のキャッシュと集計Futureを破棄して再計算させる
    _learningEpochListener = () {
      if (!mounted) return;
      _slotsCache.clear();
      _lastFilterKey = null;
      _filteredProblemsFuture = null;
      _lastAggKey = null;
      _aggFuture = null;
      _lastVisibleAggKey = null;
      _visibleAggFuture = null;
      setState(() {});
    };
    SimpleDataManager.learningDataEpochListenable.addListener(_learningEpochListener!);
  }

  @override
  void dispose() {
    final l = _learningEpochListener;
    if (l != null) {
      SimpleDataManager.learningDataEpochListenable.removeListener(l);
    }
    super.dispose();
  }

  ProblemStatus _parseStatusFromHistory(Map<String, dynamic> h) {
    return ProblemStatus.values.firstWhere(
      (s) => s.name == (h['status'] as String? ?? 'none'),
      orElse: () => ProblemStatus.none,
    );
  }

  DateTime? _parseDateTimeFromHistory(Map<String, dynamic> h) {
    final timeStr = h['time'] as String?;
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      return DateTime.parse(timeStr);
    } catch (_) {
      return null;
    }
  }

  String _formatDtShort(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> _getSlots(UnitProblem p) async {
    final cached = _slotsCache[p.id];
    if (cached != null) return cached;

    final history = await SimpleDataManager.getLearningHistory(p);
    final latestHistory = history.length > _slotCount
        ? sortHistoryByTimeNewestFirst(history).take(_slotCount).toList()
        : history;

    final slots = <Map<String, dynamic>>[];
    for (var i = 0; i < _slotCount; i++) {
      if (i < latestHistory.length) {
        final h = latestHistory[i];
        slots.add({
          'status': _parseStatusFromHistory(h),
          'time': _parseDateTimeFromHistory(h),
        });
      } else {
        slots.add({'status': ProblemStatus.none, 'time': null});
      }
    }

    _slotsCache[p.id] = slots;
    return slots;
  }

  List<UnitExprProblem> _categoryFilteredExprProblems() {
    if (widget.selectedCategories.isEmpty) return widget.problemPool;
    final filtered = widget.problemPool
        .where((ep) => widget.selectedCategories.contains(ep.category))
        .toList();
    return filtered.isEmpty ? widget.problemPool : filtered;
  }

  Future<List<UnitExprProblem>> _filteredExprProblemsForList() async {
    final exprProblems = _categoryFilteredExprProblems();
    if (widget.gachaFilterMode == GachaFilterMode.random) {
      return _sortForCurriculum(exprProblems);
    }

    final exclusionMode = widget.gachaFilterMode.toExclusionMode();
    final out = <UnitExprProblem>[];
    for (final ep in exprProblems) {
      final kept = <UnitProblem>[];
      for (final up in ep.unitProblems) {
        final excluded = await shouldExcludeByMode(up, exclusionMode);
        if (!excluded) kept.add(up);
      }
      if (kept.isEmpty) continue;
      out.add(
        UnitExprProblem(
          expr: ep.expr,
          category: ep.category,
          defs: ep.defs,
          unitProblems: kept,
          meaning: ep.meaning,
          meaningEn: ep.meaningEn,
        ),
      );
    }
    return _sortForCurriculum(out);
  }

  Future<({int green, int red})> _aggregateGreenRedCounts() async {
    int green = 0;
    int red = 0;

    final exprProblems = _categoryFilteredExprProblems();

    // 除外モードが有効なら、除外されない UnitProblem のみ集計対象にする
    final exclusionMode = widget.gachaFilterMode.toExclusionMode();

    for (final ep in exprProblems) {
      for (final up in ep.unitProblems) {
        if (widget.gachaFilterMode != GachaFilterMode.random) {
          final excluded = await shouldExcludeByMode(up, exclusionMode);
          if (excluded) continue;
        }

        final slots = await _getSlots(up);
        for (final slot in slots) {
          final st = slot['status'] as ProblemStatus? ?? ProblemStatus.none;
          if (st == ProblemStatus.solved) green++;
          if (st == ProblemStatus.failed) red++;
        }
      }
    }

    return (green: green, red: red);
  }

  Future<({int solved, int failed, int none})>
  _aggregateVisibleStatusCounts(List<UnitExprProblem> visible) async {
    int solved = 0;
    int failed = 0;
    int none = 0;

    for (final ep in visible) {
      for (final up in ep.unitProblems) {
        final slots = await _getSlots(up);
        for (final slot in slots) {
          final st = slot['status'] as ProblemStatus? ?? ProblemStatus.none;
          switch (st) {
            case ProblemStatus.solved:
              solved++;
              break;
            case ProblemStatus.failed:
              failed++;
              break;
            case ProblemStatus.none:
              none++;
              break;
          }
        }
      }
    }

    return (solved: solved, failed: failed, none: none);
  }

  Widget _aggregationDescriptionGreenRed() {
    final key = _aggKey();
    if (_aggFuture == null || _lastAggKey != key) {
      _lastAggKey = key;
      _aggFuture = _aggregateGreenRedCounts();
    }

    return FutureBuilder<({int green, int red})>(
      future: _aggFuture,
      builder: (context, snapshot) {
        final green = snapshot.data?.green ?? 0;
        final red = snapshot.data?.red ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _statusBadgeSmall(ProblemStatus.solved, diameter: 24.0),
              const SizedBox(width: 6),
              Text(
                '$green',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              _statusBadgeSmall(ProblemStatus.failed, diameter: 24.0),
              const SizedBox(width: 6),
              Text(
                '$red',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _aggregationDescriptionVisibleAllIcons(List<UnitExprProblem> visible) {
    // Key must reflect the actually visible list as well as filter settings,
    // otherwise aggregation can get stale when only the visible items change.
    final totalUnitProblems = visible.fold<int>(0, (a, ep) => a + ep.unitProblems.length);
    final key = '${_aggKey()}|ep=${visible.length}|up=$totalUnitProblems';
    if (_visibleAggFuture == null || _lastVisibleAggKey != key) {
      _lastVisibleAggKey = key;
      _visibleAggFuture = _aggregateVisibleStatusCounts(visible);
    }

    return FutureBuilder<({int solved, int failed, int none})>(
      future: _visibleAggFuture,
      builder: (context, snapshot) {
        final solved = snapshot.data?.solved ?? 0;
        final failed = snapshot.data?.failed ?? 0;
        final none = snapshot.data?.none ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // const Text(
              //   '表示中(直近3回合算): ',
              //   style: TextStyle(
              //     fontSize: 12,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.black87,
              //   ),
              // ),
              _statusBadgeSmall(ProblemStatus.solved, diameter: 22.0),
              const SizedBox(width: 6),
              Text(
                '$solved',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 14),
              _statusBadgeSmall(ProblemStatus.failed, diameter: 22.0),
              const SizedBox(width: 6),
              Text(
                '$failed',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 14),
              _statusBadgeSmall(ProblemStatus.none, diameter: 22.0),
              const SizedBox(width: 6),
              Text(
                '$none',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _buildCurrentSlotsFromHistory(
    List<Map<String, dynamic>> history,
  ) {
    final current = <Map<String, dynamic>>[];
    for (var i = 0; i < _slotCount; i++) {
      if (i < history.length) {
        final h = history[i];
        final byCalc = h['byCalculator'];
        current.add({
          'status': _parseStatusFromHistory(h),
          'time': h['time'] as String?,
          if (byCalc is bool) 'byCalculator': byCalc,
        });
      } else {
        current.add({
          'status': ProblemStatus.none,
          'time': null,
          'byCalculator': false,
        });
      }
    }
    return current;
  }

  ProblemStatus _nextStatus(ProblemStatus cur) {
    switch (cur) {
      case ProblemStatus.none:
        return ProblemStatus.solved;
      case ProblemStatus.solved:
        return ProblemStatus.failed;
      case ProblemStatus.failed:
        return ProblemStatus.none;
    }
  }

  Future<void> _setSlot(UnitProblem p, int idx, ProblemStatus newStatus) async {
    // 2025/12/17版と同じ：履歴が無効ならPro要求
    final isHistoryEnabled = await SimpleDataManager.isFreeGachaEnabled(
      widget.prefsPrefix,
    );
    if (!isHistoryEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).proVersionRequired),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // 次のスロットに入れるには前が埋まっている必要がある
    if (newStatus != ProblemStatus.none && idx > 0) {
      final currentSlots = await _getSlots(p);
      for (var j = 0; j < idx; j++) {
        final prev =
            currentSlots[j]['status'] as ProblemStatus? ?? ProblemStatus.none;
        if (prev == ProblemStatus.none) return;
      }
    }

    final history = await SimpleDataManager.getLearningHistory(p);
    final current = _buildCurrentSlotsFromHistory(history);

    // 電卓Enter由来（byCalculator=true）の履歴は、一覧からは変更しない（ランキング/実績の整合性のため）
    final isCalculatorSlot = current[idx]['byCalculator'] == true;
    if (isCalculatorSlot) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('電卓で解いた履歴は一覧から変更できません'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final t = newStatus == ProblemStatus.none
        ? null
        : DateTime.now().toIso8601String();
    current[idx] = {'status': newStatus, 'time': t, 'byCalculator': false};

    // none に戻したら右側を連鎖クリア
    if (newStatus == ProblemStatus.none) {
      for (var j = idx + 1; j < current.length; j++) {
        // 電卓履歴は消さない（手動スロットのみクリア）
        if (current[j]['byCalculator'] == true) continue;
        current[j] = {
          'status': ProblemStatus.none,
          'time': null,
          'byCalculator': false,
        };
      }
    }

    await SimpleDataManager.saveLearningHistory(p, current);

    _slotsCache.remove(p.id);
    _aggFuture = null; // 集計は履歴に依存するので作り直す
    _visibleAggFuture = null; // 表示中集計も履歴に依存するので作り直す
    _filteredProblemsFuture = null; // 除外/表示にも影響するので作り直す
    if (!mounted) return;
    setState(() {});
  }

  Widget _statusBadgeSmall(ProblemStatus status, {double diameter = 20.0}) {
    final double iconSize = diameter * 0.6;
    IconData icon;
    Color color;
    switch (status) {
      case ProblemStatus.solved:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ProblemStatus.failed:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case ProblemStatus.none:
        icon = Icons.circle_outlined;
        color = Colors.grey;
        break;
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(diameter / 2.5),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }

  String _formatExpressionToTex(String expression) {
    // 2025/12/17版は 0.5 -> 1/2 のみ（その他は既存のformatExpressionで対応）
    final formatted = expression.replaceAllMapped(
      RegExp(r'0\.5'),
      (match) => r'\frac{1}{2}',
    );
    return formatExpression(formatted);
  }

  /// カテゴリーに応じた背景色を取得（旧UI）
  Color? _getCategoryBackgroundColor(UnitCategory? category) {
    if (category == null) return null;

    switch (category) {
      case UnitCategory.mechanics:
        return Colors.purple.shade50;
      case UnitCategory.thermodynamics:
        return const Color(0xFFFF9800).withAlpha(26);
      case UnitCategory.waves:
        return Colors.cyan.shade50;
      case UnitCategory.electromagnetism:
        return Colors.amber.shade50;
      case UnitCategory.atom:
        return Colors.lightGreen.shade50;
    }
  }

  /// カテゴリーに応じた背景グラデーション（旧UI：熱力学）
  LinearGradient? _getCategoryBackgroundGradient(UnitCategory? category) {
    if (category == null || category != UnitCategory.thermodynamics)
      return null;

    return LinearGradient(
      colors: [
        const Color(0xFFFF5722).withAlpha(26),
        const Color(0xFFFF9800).withAlpha(26),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// 記号定義をTeX文字列に変換（旧UI）
  String _buildSymbolDefTex(SymbolDef def) {
    final lang = AppLocale.languageCode(context);
    final symbolTex = def.texSymbol ?? formatSymbolToTex(def.symbol);
    final rawName = def.localizedName(
      lang,
    );
    // TeXパーサが落ちる入力（改行/CRなど）を最低限サニタイズ
    final name = rawName.replaceAll('\r', ' ').replaceAll('\n', ' ');

    String unitPart = '';
    final localizedUnit = def.localizedUnitSymbol(
      lang,
    );
    if (localizedUnit != null && localizedUnit.isNotEmpty) {
      // 記号定義の unitSymbol は "m/s^2", "kg/m^3" のように / を含むことがある。
      // ここは Math.tex で描画するため、\text の入れ子を作らないフォーマッタを使う。
      final unitTex = formatUnitSymbolForTexMath(localizedUnit);
      unitPart = r'\text{（}' + unitTex + r'\text{）}';
    }

    // 旧UIは textStyle で緑指定だが、環境によって反映されないケースがあるため
    // TeX側でも色を明示して確実に緑表示にする。
    final body = '$symbolTex: \\text{$name}$unitPart';
    // Dart文字列では `\\` で TeX の `\` 1文字になる（\\\\ にすると TeX の `\\` になって壊れる）
    return '{\\color{green} $body}';
  }

  Widget _buildSingleSymbolDef(SymbolDef def) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Math.tex(
        _buildSymbolDefTex(def),
        textStyle: const TextStyle(
          fontSize: 16,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
        mathStyle: MathStyle.text,
      ),
    );
  }

  Widget _buildSymbolDefinitions(UnitExprProblem ep) {
    // 2025/12/17版に合わせる：定義が0〜1件ならブロック自体を出さない
    if (ep.defs.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < ep.defs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildSingleSymbolDef(ep.defs[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildPointBox(String point) {
    final trimmed = point.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade600),
      ),
      child: MixedTextMath(
        trimmed,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          height: 1.3,
        ),
        mathStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildUnitProblemEquationRow(UnitExprProblem ep, int displayNo) {
    final l10n = AppLocalizations.of(context);
    final isEnglish = AppLocale.isEnglish(context);

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$displayNo. ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (ep.expr.isNotEmpty)
                  MixedTextMath(
                    _formatExpressionToTex(ep.expr),
                    forceTex: true,
                    labelStyle: const TextStyle(fontSize: 24),
                    mathStyle: const TextStyle(fontSize: 24),
                  ),
                if ((ep.meaning ?? '').isNotEmpty)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(' : ', style: TextStyle(fontSize: 18)),
                      Text(
                        // 物理量の意味（日本語固定になっていたので英語対応）
                        (isEnglish && (ep.meaningEn ?? '').isNotEmpty)
                            ? ep.meaningEn!
                            : ep.meaning!,
                        style: const TextStyle(fontSize: 18),
                        softWrap: true,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitProblemUnitRow(
    UnitProblem unitProblem,
    Future<List<Map<String, dynamic>>> slotsFuture,
  ) {
    final l10n = AppLocalizations.of(context);
    final lang = AppLocale.languageCode(context);
    final point = (unitProblem.localizedPoint(lang) ?? '')
        .trim();
    final hasPoint = point.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: slotsFuture,
        builder: (context, snapshot) {
          final slots = snapshot.data;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.unitLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                MixedTextMath(
                  formatUnitString(unitProblem.localizedAnswer(lang)),
                  forceTex: true,
                  labelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  mathStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '|',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                if (slots == null)
                  const SizedBox(
                    width: 56,
                    height: 20,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else ...[
                  ...slots.take(3).toList().asMap().entries.map((slotEntry) {
                    final idx = slotEntry.key;
                    final slot = slotEntry.value;
                    final status =
                        slot['status'] as ProblemStatus? ?? ProblemStatus.none;

                    // 学習履歴編集はこの画面では廃止（見た目はそのまま、タップ無反応）
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _statusBadgeSmall(status),
                    );
                  }),
                  const SizedBox(width: 4),
                  if (hasPoint) ...[
                    OutlinedButton(
                      onPressed: () => _togglePoint(unitProblem),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minimumSize: const Size(32, 26),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: _isPointOpen(unitProblem)
                              ? Colors.orange.shade700
                              : Colors.grey.shade600,
                          width: 1.2,
                        ),
                        foregroundColor: _isPointOpen(unitProblem)
                            ? Colors.orange.shade800
                            : Colors.grey.shade800,
                      ),
                      child: const Text(
                        'P',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else
                    const SizedBox(width: 6),
                  Builder(
                    builder: (context) {
                      DateTime? latestTime;
                      for (int i = slots.length - 1; i >= 0; i--) {
                        final st = slots[i]['status'] as ProblemStatus?;
                        if (st != null && st != ProblemStatus.none) {
                          final time = slots[i]['time'] as DateTime?;
                          if (time != null) {
                            latestTime = time;
                            break;
                          }
                        }
                      }
                      if (latestTime != null) {
                        return Text(
                          '${l10n.updatedLabel}${_formatDtShort(latestTime)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnitProblemCard(UnitExprProblem ep, int displayNo) {
    final l10n = AppLocalizations.of(context);
    final lang = AppLocale.languageCode(context);
    final backgroundColor = _getCategoryBackgroundColor(ep.category);
    final backgroundGradient = _getCategoryBackgroundGradient(ep.category);

    final openPoints = <String>[];
    for (final up in ep.unitProblems) {
      if (!_isPointOpen(up)) continue;
      final p = (up.localizedPoint(lang) ?? '').trim();
      if (p.isEmpty) continue;
      openPoints.add(p);
    }

    final card = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUnitProblemEquationRow(ep, displayNo),
          const SizedBox(height: 8),
          _buildSymbolDefinitions(ep),
          const Divider(height: 20, thickness: 1),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ep.unitProblems
                .map((up) => _buildUnitProblemUnitRow(up, _getSlots(up)))
                .toList(),
          ),
          if (openPoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (int i = 0; i < openPoints.length; i++) ...[
              _buildPointBox(openPoints[i]),
              if (i != openPoints.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundGradient == null ? backgroundColor : null,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: card,
    );
  }

  Future<void> _showPurchaseDialog({required String productId}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        bool busy = false;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> run(Future<void> Function() fn) async {
              if (busy) return;
              setLocalState(() => busy = true);
              try {
                await fn();
              } finally {
                if (context.mounted) setLocalState(() => busy = false);
              }
            }

            return AlertDialog(
              content: Text(l10n.purchaseDialogBody, style: const TextStyle(height: 1.4)),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          run(() async {
                            final ok = await RevenueCatService.restorePurchases();
                            ProblemAccessService.clearCache();
                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? l10n.purchaseRestored : l10n.noPurchasesFound),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            setState(() {});
                          });
                        },
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.restore),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          run(() async {
                            final res = await RevenueCatService.purchaseProduct(
                              productId,
                            );
                            ProblemAccessService.clearCache();
                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            if (!res.success && res.cancelled) {
                              return;
                            }
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res.success
                                      ? l10n.purchaseCompleted
                                      : (res.cancelled
                                            ? l10n.purchaseCancelled
                                            : (res.error ?? l10n.purchaseFailed)),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            setState(() {});
                          });
                        },
                  child: Text(l10n.purchase),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timerManager = widget.timerManager ?? TimerManager();

    final filterKey = _filterKey();
    if (_filteredProblemsFuture == null || _lastFilterKey != filterKey) {
      _lastFilterKey = filterKey;
      _filteredProblemsFuture = _filteredExprProblemsForList();
    }

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundImageWidget(),
          SafeArea(
            child: Column(
              children: [
                UnitGachaCommonHeader(
                  timerManager: timerManager,
                  l10n: l10n,
                  isHelpPageVisible: widget.isHelpPageVisible,
                  isProblemListVisible: widget.isProblemListVisible,
                  isReferenceTableVisible: widget.isReferenceTableVisible,
                  isScratchPaperMode: widget.isScratchPaperMode,
                  showFilterSettings: widget.showFilterSettings,
                  onHelpToggle: widget.onHelpToggle ?? () {},
                  onProblemListToggle: widget.onProblemListToggle ?? () {},
                  onReferenceTableToggle:
                      widget.onReferenceTableToggle ?? () {},
                  onScratchPaperToggle: widget.onScratchPaperToggle ?? () {},
                  onFilterToggle: widget.onFilterToggle ?? () {},
                  onLoginTap: widget.onLoginTap,
                  onDataAnalysisNavigate: widget.onDataAnalysisNavigate,
                  isDataAnalysisActive: widget.isDataAnalysisActive,
                  isAuthPageVisible: false,
                  disableTimer: true,
                  disableFilter: false,
                  filterSettingsPanel: widget.filterSettingsPanel,
                  showFilterPanel: widget.showFilterPanel,
                ),
                FutureBuilder<List<UnitExprProblem>>(
                  future: _filteredProblemsFuture,
                  builder: (context, snapshot) {
                    final items = snapshot.data;
                    if (items == null) return const SizedBox.shrink();
                    if (items.isEmpty) return const SizedBox.shrink();
                    return _aggregationDescriptionVisibleAllIcons(items);
                  },
                ),
                Expanded(
                  child: FutureBuilder<List<UnitExprProblem>>(
                    future: _filteredProblemsFuture,
                    builder: (context, snapshot) {
                      final items = snapshot.data;
                      if (items == null) {
                        return const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final ep = items[index];
                          final displayNo = index + 1;
                          final pid = ProblemAccessService.requiredProductIdFor(
                            ep,
                          );
                          if (pid == null || pid.isEmpty) {
                            return _buildUnitProblemCard(ep, displayNo);
                          }

                          return FutureBuilder<bool>(
                            future: ProblemAccessService.isExprProblemUnlocked(
                              ep,
                            ),
                            builder: (context, snapshot) {
                              final unlocked = snapshot.data == true;
                              if (unlocked)
                                return _buildUnitProblemCard(ep, displayNo);

                              final baseCard = _buildUnitProblemCard(
                                ep,
                                displayNo,
                              );
                              // Keep the normal card layout as-is, and just overlay a subtle grey veil.
                              final lockedCard = AbsorbPointer(
                                child: Stack(
                                  children: [
                                    baseCard,
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.grey.withOpacity(0.28),
                                      ),
                                    ),
                                    // Center watermark
                                    Positioned.fill(
                                      child: Center(
                                        child: Icon(
                                          Icons.lock_outline,
                                          size: 64,
                                          color: Colors.black.withOpacity(0.22),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              return Stack(
                                children: [
                                  lockedCard,
                                  Positioned.fill(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () =>
                                            _showPurchaseDialog(productId: pid),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
