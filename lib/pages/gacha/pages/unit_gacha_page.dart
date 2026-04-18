// lib/pages/gacha/pages/unit_gacha_page.dart
// 単位ガチャ専用ページ（メインページ）

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/app_locale.dart';
import '../../../problems/unit/symbol.dart' show UnitCategory, UnitProblem;
import '../../../problems/unit/unit_gacha_item.dart' show UnitGachaItem;
import '../../../util/platform_info.dart';
import '../../../services/payment/problem_access_service.dart';
import '../../../services/payment/revenuecat_service.dart';
import '../../../services/problems/simple_data_manager.dart';
import '../../../widgets/unit/unit_calculator.dart'
    show CalculatorType, UnitCalculator;
import '../../../widgets/home/background_image_widget.dart';
import '../../../managers/timer_manager.dart';
import '../../../widgets/timer/timer_display.dart';
import '../../../widgets/timer/timer_toggle.dart';
import '../../other/scratch_paper_page.dart' show isIPad;
import '../../../widgets/drawing/draggable_tool_buttons.dart'
    show DraggablePenButton;
import '../../../widgets/drawing/draggable_eraser_button.dart';
import '../../../widgets/drawing/draggable_scroll_button.dart';
import '../../../widgets/drawing/draggable_calculator_button.dart';
import '../../../widgets/drawing/drawing_canvas.dart';
import '../../../widgets/home/home_icon_guide_overlay.dart';
// 分割したファイル
import '../logic/unit_gacha_problem_manager.dart' show UnitGachaProblemManager;
import '../logic/unit_gacha_filter.dart' show UnitGachaFilterHelper;
import '../data/unit_gacha_history.dart' show UnitGachaHistoryManager;
import '../data/settings_manager.dart' show UnitGachaSettingsManager;
import '../ui/builders/problem_card_builder.dart' show ProblemCardBuilder;
import '../ui/builders/answer_display_builder.dart' show AnswerDisplayBuilder;
import '../ui/builders/action_buttons_builder.dart' show ActionButtonsBuilder;
import '../ui/unit_gacha_common_header.dart' show UnitGachaCommonHeader;
import '../ui/builders/layout_builder.dart'
    as layout_builder
    show LayoutBuilder;
import '../logic/unit_gacha_answer_handler.dart'
    show UnitGachaAnswerHandler, AnswerResult;
import 'gacha_settings_page.dart' show GachaFilterMode;
import '../../../problems/unit/unit_gacha.dart' show getUnitGachaProblems;
import '../ui/unit_reference_table_page.dart' show UnitReferenceTablePage;
import '../ui/data_analysis_page.dart' show DataAnalysisPage;
import '../../help/help_page.dart' show HelpPage;
import '../../problem/problem_list_page.dart' show ProblemListPage;
// Firebase auth
import '../auth/auth_sync.dart'
    show UnitGachaSyncButton, buildCloudMenuButton, buildLoginButton;
import '../../../services/auth/firebase_auth_service.dart';
import '../../other/auth_page.dart';
// Drawing tools
import '../drawing/unit_gacha_drawing_tools.dart'
    show DrawingTool, DrawingToolState;
import '../ui/palette/unit_gacha_ipad_palette.dart' show UnitGachaIPadPalette;
import '../../../problems/unit/problems.dart' show unitExprProblems;

enum _PurchaseRecommendCheckResult { shownOrResolved, blocked, nothing }

/// 単位ガチャページ
class UnitGachaPage extends StatefulWidget {
  const UnitGachaPage({Key? key}) : super(key: key);

  @override
  State<UnitGachaPage> createState() => _UnitGachaPageState();
}

class _UnitGachaPageState extends State<UnitGachaPage> {
  // 問題表示状態
  int _currentProblemIndex = 0;
  List<UnitGachaItem> _selectedProblems = [];
  List<CalculatorType> _selectedCalculatorTypes = [];
  List<UnitGachaItem> _displayProblems = [];

  // 電卓状態
  String _userInput = '';
  bool _isAnswered = false;
  bool _isCorrect = false;

  // 計算用紙モード状態
  bool _isScratchPaperMode = false;
  bool _isCalculatorExpanded = false;

  // ページ切り替え状態
  bool _isHelpPageVisible = false;
  bool _isProblemListVisible = false;
  bool _isReferenceTableVisible = false;
  bool _isDataAnalysisVisible = false;
  bool _isAuthPageVisible = false;

  // 描画関連の状態
  late final ValueNotifier<String> _activeToolNotifier;
  late final ValueNotifier<bool> _isDrawingNotifier;
  Offset _penButtonPosition = const Offset(0, 0);
  Offset _calculatorButtonPosition = const Offset(0, 0);

  // iPad用パレットの状態
  late final DrawingToolState _drawingToolState;

  // フィルタリング（複数選択可能）
  Set<UnitCategory> _selectedCategories = {};
  bool _showFilterSettings = false;

  // 除外設定と集計設定
  GachaFilterMode _gachaFilterMode = GachaFilterMode.random;

  // タイマー関連
  final TimerManager _timerManager = TimerManager();

  bool _isInitialized = false;

  // 学習履歴オプションは常に有効
  bool _isHistoryEnabled = true;
  late AppLocalizations _l10n;

  // 解答回数カウント（アプリ起動後）
  int _solvedCount = 0;

  bool _hasAnyUnlockedInSelection = true; // デフォルトはtrueとしておく

  // ===========================================================================
  // Purchase recommend (mechanics / electromagnetism) - once per category
  // ===========================================================================
  static const int _purchaseRecommendThreshold = 20;
  bool _purchaseRecommendNextBusy = false;
  bool _purchaseRecommendBootCheckScheduled = false;
  bool _purchaseRecommendBootCheckNeedsRetry = true;

  // Home icon guide (first time only)
  static const String _prefsKeyHomeIconGuideCompleted =
      'home_icon_guide_completed';
  bool _checkedHomeIconGuide = false;
  bool _showHomeIconGuide = false;
  int _homeIconGuideStep = 0;
  final GlobalKey _guideHelpKey = GlobalKey(debugLabel: 'guide_help');
  final GlobalKey _guideCloudKey = GlobalKey(debugLabel: 'guide_cloud');
  final GlobalKey _guideTimerKey = GlobalKey(debugLabel: 'guide_timer');
  final GlobalKey _guideFilterKey = GlobalKey(debugLabel: 'guide_filter');
  final GlobalKey _guideReferenceKey = GlobalKey(debugLabel: 'guide_reference');
  final GlobalKey _guideScratchKey = GlobalKey(debugLabel: 'guide_scratch');
  final GlobalKey _guideProblemListKey = GlobalKey(
    debugLabel: 'guide_problem_list',
  );
  final GlobalKey _guideDataAnalysisKey = GlobalKey(
    debugLabel: 'guide_data_analysis',
  );
  final GlobalKey _guideCalculatorKey = GlobalKey(
    debugLabel: 'guide_calculator',
  );
  bool _showCalculatorHelpSpotlight = false;

  // Home scroll controller (used to bring the calculator into view for spotlight)
  final ScrollController _homeScrollController = ScrollController();

  // 分割したクラスのインスタンス
  late UnitGachaProblemManager _problemManager;
  late UnitGachaFilterHelper _filterHelper;
  late ProblemCardBuilder _problemCardBuilder;
  late AnswerDisplayBuilder _answerDisplayBuilder;
  late ActionButtonsBuilder _actionButtonsBuilder;
  late layout_builder.LayoutBuilder _layoutBuilder;

  // 残りの問題数を取得
  int _calculateRemainingCount() {
    return _selectedProblems.length - _currentProblemIndex - 1;
  }

  // 残りの問題リスト（最大2枚まで表示）
  List<UnitGachaItem> _getRemainingProblems() {
    final remainingCount = _calculateRemainingCount();
    if (remainingCount > 0) {
      return _selectedProblems.sublist(
        _currentProblemIndex + 1,
        _currentProblemIndex + 1 + (remainingCount > 2 ? 2 : remainingCount),
      );
    }
    return <UnitGachaItem>[];
  }

  bool _isOverlayBlockingPurchaseRecommend() {
    return _isScratchPaperMode ||
        _isHelpPageVisible ||
        _isProblemListVisible ||
        _isReferenceTableVisible ||
        _isDataAnalysisVisible ||
        _isAuthPageVisible ||
        _showHomeIconGuide ||
        _showCalculatorHelpSpotlight;
  }

  String? _productIdForCategory(UnitCategory c) {
    switch (c) {
      case UnitCategory.mechanics:
        return 'mechanics_all_unlock';
      case UnitCategory.electromagnetism:
        return 'electromagnetism_all_unlock';
      case UnitCategory.thermodynamics:
      case UnitCategory.waves:
      case UnitCategory.atom:
        return null;
    }
  }

  Future<void> _onPurchaseRecommendAttemptConfirmed(UnitCategory category) async {
    // 20回おすすめ購入ダイアログは iOS のみで表示する。
    if (!PlatformInfo.isIOS) return;
    if (category != UnitCategory.mechanics &&
        category != UnitCategory.electromagnetism) {
      return;
    }

    final shown = await SimpleDataManager.getPurchaseRecommendShown(category);
    final next = await SimpleDataManager.incrementPurchaseRecommendAttemptCount(
      category,
    );
    if (!shown && next >= _purchaseRecommendThreshold) {
      await SimpleDataManager.setPurchaseRecommendPending(category, true);
    }
  }

  Future<_PurchaseRecommendCheckResult> _maybeShowPurchaseRecommendIfPending({
    required String trigger,
  }) async {
    // 念のため二重ガード（Android等では絶対におすすめダイアログを出さない）
    if (!PlatformInfo.isIOS) return _PurchaseRecommendCheckResult.nothing;
    if (!mounted) return _PurchaseRecommendCheckResult.nothing;
    if (_isOverlayBlockingPurchaseRecommend()) {
      return _PurchaseRecommendCheckResult.blocked;
    }

    UnitCategory? target;
    for (final c in const [
      UnitCategory.mechanics,
      UnitCategory.electromagnetism,
    ]) {
      final pending = await SimpleDataManager.getPurchaseRecommendPending(c);
      if (!pending) continue;

      final shown = await SimpleDataManager.getPurchaseRecommendShown(c);
      if (shown) {
        await SimpleDataManager.setPurchaseRecommendPending(c, false);
        continue;
      }
      target = c;
      break;
    }

    if (target == null) return _PurchaseRecommendCheckResult.nothing;

    final pid = _productIdForCategory(target);
    if (pid == null || pid.isEmpty) {
      await SimpleDataManager.setPurchaseRecommendPending(target, false);
      await SimpleDataManager.setPurchaseRecommendShown(target, true);
      return _PurchaseRecommendCheckResult.shownOrResolved;
    }

    final alreadyPurchased = await RevenueCatService.isProductPurchased(pid);
    if (alreadyPurchased) {
      await SimpleDataManager.setPurchaseRecommendPending(target, false);
      await SimpleDataManager.setPurchaseRecommendShown(target, true);
      return _PurchaseRecommendCheckResult.shownOrResolved;
    }

    if (!mounted) return _PurchaseRecommendCheckResult.nothing;

    final l10n = AppLocalizations.of(context);
    final categoryName = l10n.unitCategory(target);
    bool busy = false;
    PurchaseResult? purchaseResult;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
              title: Text(l10n.purchaseRecommendTitle),
              content: Text(
                l10n.purchaseRecommendBody(categoryName),
                style: const TextStyle(height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(dialogContext).pop('later'),
                  child: Text(l10n.cloudSavePromptLater),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => run(() async {
                            purchaseResult =
                                await RevenueCatService.purchaseProduct(pid);
                            ProblemAccessService.clearCache();
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop('purchase');
                          }),
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.purchase),
                ),
              ],
            );
          },
        );
      },
    );

    // Mark as shown regardless of outcome (the recommend dialog itself is one-time).
    await SimpleDataManager.setPurchaseRecommendPending(target, false);
    await SimpleDataManager.setPurchaseRecommendShown(target, true);

    if (!mounted) return _PurchaseRecommendCheckResult.shownOrResolved;

    if (action == 'later') {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            content: Text(
              l10n.purchaseRecommendLaterMessage,
              style: const TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonClose),
              ),
            ],
          );
        },
      );
      return _PurchaseRecommendCheckResult.shownOrResolved;
    }

    final res = purchaseResult;
    if (res != null) {
      final msg = res.success
          ? l10n.purchaseCompleted
          : (res.cancelled
              ? l10n.purchaseCancelled
              : (res.error ?? l10n.purchaseFailed));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
      setState(() {});
    }

    return _PurchaseRecommendCheckResult.shownOrResolved;
  }

  @override
  void initState() {
    super.initState();

    // 描画ツール状態を初期化
    _drawingToolState = DrawingToolState();

    // 描画関連のNotifierを初期化
    final initialTool = _drawingToolState.isEraser
        ? 'eraser'
        : (_drawingToolState.isScrollMode ? 'scroll' : 'pen');
    _activeToolNotifier = ValueNotifier<String>(initialTool);
    _isDrawingNotifier = ValueNotifier<bool>(false);

    // タイマーマネージャーのリスナーを設定
    _timerManager.isTimerEnabledNotifier.addListener(_onTimerStateChanged);
    _timerManager.isTimerRunningNotifier.addListener(_onTimerStateChanged);
    _timerManager.remainingSecondsNotifier.addListener(_onTimerStateChanged);

    // タイマー終了時のコールバックを設定
    _timerManager.onTimerFinished = () {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.timerFinished),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };

    // Pro版購入状態を確認
    _checkProVersionStatus();

    // iPadの場合はパレット位置を読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && isIPad(context)) {
        _drawingToolState.loadPalettePosition(context);
      }
      // 計算用紙モードの場合は電卓ボタン位置を読み込む
      if (mounted && _isScratchPaperMode) {
        _loadCalculatorButtonPosition();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    // 分割したクラスを初期化
    _problemManager = UnitGachaProblemManager(_l10n);
    _filterHelper = UnitGachaFilterHelper(_l10n, _problemManager);
    _problemCardBuilder = ProblemCardBuilder(_l10n);
    _answerDisplayBuilder = AnswerDisplayBuilder(_l10n);
    _actionButtonsBuilder = ActionButtonsBuilder(_l10n);
    _layoutBuilder = layout_builder.LayoutBuilder(
      _l10n,
      _timerManager,
      _problemCardBuilder,
      _answerDisplayBuilder,
      _actionButtonsBuilder,
    );
    // 初回の初期化時のみ設定を読み込む
    if (!_isInitialized) {
      _loadSettings();
    } else {
      // 初回の初期化後、ページが再表示される時に設定を再読み込み
      _reloadSettings();
    }
  }

  @override
  void dispose() {
    _activeToolNotifier.dispose();
    _isDrawingNotifier.dispose();
    _homeScrollController.dispose();
    // タイマーマネージャーのリスナーは削除しない（他のページでも使用するため）
    super.dispose();
  }

  void _onTimerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Pro版購入状態を確認
  Future<void> _checkProVersionStatus() async {
    await UnitGachaHistoryManager.checkProVersionStatus();
  }

  Future<void> _reloadSettings() async {
    // 設定を再読み込み
    await _loadSettings();
  }

  /// 保存された設定を読み込む
  Future<void> _loadSettings() async {
    try {
      final settings = await UnitGachaSettingsManager.loadSettings(
        timerManager: _timerManager,
      );

      // 学習履歴オプションは常に有効
      if (mounted) {
        setState(() {
          _selectedCategories = Set<UnitCategory>.from(
            settings.selectedCategories,
          );
          _gachaFilterMode = settings.gachaFilterMode;
          _isHistoryEnabled = true;
        });

        // ロックされていない問題が1つでもあるか確認
        _hasAnyUnlockedInSelection = await _problemManager.hasAnyUnlockedProblems(_selectedCategories);

        // 5枚のカードをランダムに選択（フィルタリング設定を適用）
        final newProblems = await _problemManager.shuffleProblems(
          _selectedCategories,
          _gachaFilterMode,
        );

        if (mounted) {
          setState(() {
            _displayProblems = newProblems;
            _prepareProblemsForPlay();
          });
          _isInitialized = true;
        }
      }
    } catch (e) {
      // エラーが発生した場合でも初期化を完了させる
      print('Error loading settings: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  /// 設定を保存する
  Future<void> _saveSettings() async {
    await UnitGachaSettingsManager.saveSettings(
      selectedCategories: _selectedCategories,
    );
  }

  void _prepareProblemsForPlay() {
    // フィルタリング後の問題が空の場合はフォールバックしない
    // これにより、残り問題数が0の場合に完了メッセージが表示される
    // 最初4枚を選択
    final allProblems = _displayProblems.length > 4
        ? _displayProblems.sublist(0, 4)
        : _displayProblems;
    _selectedProblems = List<UnitGachaItem>.from(allProblems);
    _selectedCalculatorTypes = _selectedProblems
        .map(
          (item) =>
              _problemManager.determineCalculatorType(item.unitProblem.answer),
        )
        .toList();
    _currentProblemIndex = 0;
    _isAnswered = false;
    _isCorrect = false;
    _userInput = '';
    // 計算用紙モードは維持する（ガチャを引いても計算用紙モードのまま）
    // _isScratchPaperMode = false;
    // _isCalculatorExpanded = false;
  }

  Future<void> _refreshProblems() async {
    // ロックされていない問題が1つでもあるか確認
    final hasUnlocked = await _problemManager.hasAnyUnlockedProblems(_selectedCategories);

    final newProblems = await _problemManager.shuffleProblems(
      _selectedCategories,
      _gachaFilterMode,
    );
    if (mounted) {
      setState(() {
        _hasAnyUnlockedInSelection = hasUnlocked;
        _displayProblems = newProblems;
        _prepareProblemsForPlay();
      });
    }
  }

  void _handleAnswer(String input) {
    final currentItem = _selectedProblems[_currentProblemIndex];
    final currentProblem = currentItem.unitProblem;
    final currentCalculatorType =
        _selectedCalculatorTypes[_currentProblemIndex];

    final result = UnitGachaAnswerHandler.handleAnswer(
      input: input,
      currentProblem: currentProblem,
      currentCalculatorType: currentCalculatorType,
      isAnswered: _isAnswered,
      currentSolvedCount: _solvedCount,
    );

    setState(() {
      _isAnswered = result.isAnswered;
      _isCorrect = result.isCorrect;
      _userInput = result.userInput;
      _solvedCount = result.solvedCount;
    });

    // 指定回数解いた時にメッセージを表示
    final message = AppLocalizations.of(
      context,
    ).unitGachaMilestoneMessage(_solvedCount);
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blue.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // 学習記録を保存
    UnitGachaAnswerHandler.saveLearningRecord(
      unitProblem: currentProblem,
      isCorrect: result.isCorrect,
      isHistoryEnabled: _isHistoryEnabled,
    );

    // Purchase recommend counter (per category; correct/incorrect both count).
    // Triggered on "confirm" only (handleAnswer blocks if isAnswered==true).
    unawaited(_onPurchaseRecommendAttemptConfirmed(currentItem.exprProblem.category));
  }

  void _nextProblem() {
    if (_purchaseRecommendNextBusy) return;
    _purchaseRecommendNextBusy = true;

    unawaited(() async {
      try {
        await _maybeShowPurchaseRecommendIfPending(trigger: 'next');
        if (!mounted) return;

        if (_currentProblemIndex < _selectedProblems.length - 1) {
          setState(() {
            _currentProblemIndex++;
            _isAnswered = false;
            _isCorrect = false;
            _userInput = '';
          });
        } else {
          // すべての問題が終了したら、自動的に新しい問題を読み込む（アラートは表示しない）
          await _refreshProblems();
        }
      } finally {
        _purchaseRecommendNextBusy = false;
      }
    }());
  }

  /// 問題画面の戻る挙動を統一的に処理
  /// - 計算用紙モード中はモード解除のみ
  Future<bool> _handleProblemViewBack() async {
    if (_isScratchPaperMode) {
      setState(() {
        _isScratchPaperMode = false;
        _isCalculatorExpanded = false;
      });
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeView();
  }

  Widget _buildHomeView() {
    // 初期化が完了していない場合はローディングを表示
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // First-time home icon guide: check once after we can build the header.
    if (!_checkedHomeIconGuide) {
      _checkedHomeIconGuide = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final prefs = await SharedPreferences.getInstance();
        final tutorialCompleted = prefs.getBool('tutorial_completed') ?? false;
        final guideCompleted =
            prefs.getBool(_prefsKeyHomeIconGuideCompleted) ?? false;
        if (!mounted) return;
        if (tutorialCompleted && !guideCompleted) {
          setState(() {
            _showHomeIconGuide = true;
            _homeIconGuideStep = 0;
          });
        }
      });
    }

    // Boot fallback: if a recommend dialog is pending (reached 20 attempts, but not shown),
    // show it once when the UI is in a safe state. If blocked by other overlays, retry later.
    //
    // NOTE: Placed after the home icon guide check so that if the guide decides to open
    // an overlay in the same frame, our post-frame callback runs after it and safely skips.
    if (_purchaseRecommendBootCheckNeedsRetry &&
        !_purchaseRecommendBootCheckScheduled) {
      _purchaseRecommendBootCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final r = await _maybeShowPurchaseRecommendIfPending(trigger: 'boot');
        if (!mounted) return;
        if (r == _PurchaseRecommendCheckResult.blocked) {
          setState(() {
            _purchaseRecommendBootCheckScheduled = false;
          });
        } else {
          _purchaseRecommendBootCheckNeedsRetry = false;
        }
      });
    }

    if (_selectedProblems.isEmpty && _displayProblems.isNotEmpty) {
      _prepareProblemsForPlay();
    }

    if (_selectedProblems.isEmpty && _isInitialized) {
      // 初期化済みでかつ問題が空（全解決 or ロック中）の場合
      final isLocked = !_hasAnyUnlockedInSelection;
      return WillPopScope(
        onWillPop: _handleProblemViewBack,
        child: Scaffold(
          body: Stack(
            children: [
              const BackgroundImageWidget(),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _layoutBuilder.buildEmptyPoolContent(
                          isLocked: isLocked,
                          l10n: _l10n,
                          context: context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 一覧ページ（条件付き表示）
              if (_isProblemListVisible) _buildProblemListOverlay(),
              if (_isHelpPageVisible) _buildHelpPageOverlay(),
              if (_isReferenceTableVisible) _buildReferenceTableOverlay(),
              if (_isDataAnalysisVisible) _buildDataAnalysisOverlay(),
              if (_isAuthPageVisible) _buildAuthPageOverlay(),
            ],
          ),
        ),
      );
    }

    if (_selectedProblems.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // _selectedProblemsが空の場合はclampを呼び出さない（エラー回避）
    final item =
        _selectedProblems[_currentProblemIndex.clamp(
          0,
          _selectedProblems.length - 1,
        )];
    final problem = item.unitProblem;
    final correctAnswer = problem.answer;
    return WillPopScope(
      onWillPop: _handleProblemViewBack,
      child: Scaffold(
        body: Stack(
          children: [
            const BackgroundImageWidget(),
            SafeArea(
              bottom: !_isScratchPaperMode,
              // NOTE:
              // 計算用紙の描画内容を「モード切替」「他モード（ヘルプ/一覧/参照/分析/ログイン）」や
              // 「次の問題」でも保持するため、DrawingCanvas をツリーから外さない。
              // 表示は Offstage で切り替え、State（ストローク）をメモリ内で維持する。
              child: Stack(
                children: [
                  Offstage(
                    offstage: _isScratchPaperMode,
                    child: SingleChildScrollView(
                      controller: _homeScrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 8),
                          // タイマー表示（タイマーONの場合のみ、カード外部の上に中央寄せで表示）
                          if (_timerManager.isTimerEnabled)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: SizedBox(
                                  width: 320, // カードと同じ横幅
                                  child: TimerDisplay(
                                    timerManager: _timerManager,
                                  ),
                                ),
                              ),
                            ),
                          _layoutBuilder.buildNormalModeBody(
                            item: item,
                            correctAnswer: correctAnswer,
                            isAnswered: _isAnswered,
                            isCorrect: _isCorrect,
                            currentProblemIndex: _currentProblemIndex,
                            selectedProblemsLength: _selectedProblems.length,
                            onRefreshProblems: _refreshProblems,
                            onNextProblem: _nextProblem,
                            context: context,
                          ),
                          Container(
                            key: _guideCalculatorKey,
                            child: _buildCalculator(problem),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Offstage(
                    offstage: !_isScratchPaperMode,
                    child: _buildScratchPaperModeLayout(item, correctAnswer),
                  ),
                ],
              ),
            ),
            // ヘルプページ（条件付き表示）
            if (_isHelpPageVisible) _buildHelpPageOverlay(),
            // 一覧ページ（条件付き表示）
            if (_isProblemListVisible) _buildProblemListOverlay(),
            // 物理量度定数一覧ページ（条件付き表示）
            if (_isReferenceTableVisible) _buildReferenceTableOverlay(),
            // データ分析ページ（条件付き表示）
            if (_isDataAnalysisVisible) _buildDataAnalysisOverlay(),
            // ログインページ（条件付き表示）
            if (_isAuthPageVisible) _buildAuthPageOverlay(),
            // Home icon guide overlay (first time only)
            if (_showHomeIconGuide)
              HomeIconGuideOverlay(
                targetKey: _currentGuideTargetKey(),
                title: _currentGuideTitle(),
                body: _currentGuideBody(),
                footer: _l10n.homeIconGuideFooter(_homeIconGuideStep + 1, 8),
                isEnglish: AppLocale.isEnglish(context),
                onNext: _advanceHomeIconGuide,
              ),
            if (_showCalculatorHelpSpotlight)
              HomeIconGuideOverlay(
                targetKey: _guideCalculatorKey,
                title: _l10n.homeCalculatorGuideTitle,
                body: _l10n.homeCalculatorGuideBody,
                footer: _l10n.homeCalculatorGuideFooter,
                isEnglish: AppLocale.isEnglish(context),
                panelPlacement: GuidePanelPlacement.above,
                // The calculator guidance text is a bit longer (esp. JP).
                // Make the panel about ~2 lines taller to avoid clipping.
                panelHeightOverride: AppLocale.isEnglish(context)
                    ? 168.0
                    : 176.0,
                onNext: _dismissCalculatorHelpSpotlight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({bool enableGuideKeys = true}) {
    return UnitGachaCommonHeader(
      timerManager: _timerManager,
      l10n: _l10n,
      isHelpPageVisible: _isHelpPageVisible,
      isProblemListVisible: _isProblemListVisible,
      isReferenceTableVisible: _isReferenceTableVisible,
      isScratchPaperMode: _isScratchPaperMode,
      showFilterSettings: _showFilterSettings,
      helpButtonKey: enableGuideKeys ? _guideHelpKey : null,
      cloudButtonKey: enableGuideKeys ? _guideCloudKey : null,
      timerButtonKey: enableGuideKeys ? _guideTimerKey : null,
      filterButtonKey: enableGuideKeys ? _guideFilterKey : null,
      referenceButtonKey: enableGuideKeys ? _guideReferenceKey : null,
      scratchPaperButtonKey: enableGuideKeys ? _guideScratchKey : null,
      problemListButtonKey: enableGuideKeys ? _guideProblemListKey : null,
      dataAnalysisButtonKey: enableGuideKeys ? _guideDataAnalysisKey : null,
      onHelpToggle: () {
        setState(() {
          final willShow = !_isHelpPageVisible;
          _isHelpPageVisible = willShow;
          if (willShow) {
            _isScratchPaperMode = false;
            _isCalculatorExpanded = false;
          }
        });
      },
      onProblemListToggle: () {
        setState(() {
          final willShow = !_isProblemListVisible;
          _isProblemListVisible = willShow;
          if (willShow) {
            _isScratchPaperMode = false;
            _isCalculatorExpanded = false;
            // 問題一覧モードに入ったらフィルタパネルを自動表示
            _showFilterSettings = true;
          }
        });
      },
      onReferenceTableToggle: () {
        setState(() {
          final willShow = !_isReferenceTableVisible;
          _isReferenceTableVisible = willShow;
          if (willShow) {
            _isScratchPaperMode = false;
            _isCalculatorExpanded = false;
          }
        });
      },
      onScratchPaperToggle: () {
        setState(() {
          _isScratchPaperMode = !_isScratchPaperMode;
          if (_isScratchPaperMode) {
            _loadCalculatorButtonPosition();
          } else {
            _isCalculatorExpanded = false;
          }
        });
      },
      onFilterToggle: () =>
          setState(() => _showFilterSettings = !_showFilterSettings),
      onLoginTap: () {
        setState(() {
          final willShow = !_isAuthPageVisible;
          _isAuthPageVisible = willShow;
          if (willShow) {
            _isScratchPaperMode = false;
            _isCalculatorExpanded = false;
          }
        });
      },
      onDataAnalysisNavigate: () {
        setState(() {
          final willShow = !_isDataAnalysisVisible;
          _isDataAnalysisVisible = willShow;
          if (willShow) {
            _isScratchPaperMode = false;
            _isCalculatorExpanded = false;
          }
        });
      },
      isDataAnalysisActive: _isDataAnalysisVisible,
      isAuthPageVisible: _isAuthPageVisible,
      filterSettingsPanel: _buildFilterSettingsPanel(),
      showFilterPanel: _showFilterSettings,
    );
  }

  GlobalKey _currentGuideTargetKey() {
    switch (_homeIconGuideStep) {
      case 0:
        return _guideHelpKey;
      case 1:
        return _guideCloudKey;
      case 2:
        return _guideTimerKey;
      case 3:
        return _guideFilterKey;
      case 4:
        return _guideReferenceKey;
      case 5:
        return _guideScratchKey;
      case 6:
        return _guideProblemListKey;
      case 7:
      default:
        return _guideDataAnalysisKey;
    }
  }

  String _currentGuideTitle() {
    switch (_homeIconGuideStep) {
      case 0:
        return _l10n.homeIconGuideHelpTitle;
      case 1:
        return _l10n.homeIconGuideCloudTitle;
      case 2:
        return _l10n.homeIconGuideTimerTitle;
      case 3:
        return _l10n.homeIconGuideFilterTitle;
      case 4:
        return _l10n.homeIconGuideReferenceTitle;
      case 5:
        return _l10n.homeIconGuideScratchTitle;
      case 6:
        return _l10n.homeIconGuideProblemListTitle;
      case 7:
      default:
        return _l10n.homeIconGuideDataAnalysisTitle;
    }
  }

  String _currentGuideBody() {
    switch (_homeIconGuideStep) {
      case 0:
        return _l10n.homeIconGuideHelpBody;
      case 1:
        return _l10n.homeIconGuideCloudBody;
      case 2:
        return _l10n.homeIconGuideTimerBody;
      case 3:
        return _l10n.homeIconGuideFilterBody;
      case 4:
        return _l10n.homeIconGuideReferenceBody;
      case 5:
        return _l10n.homeIconGuideScratchBody;
      case 6:
        return _l10n.homeIconGuideProblemListBody;
      case 7:
      default:
        return _l10n.homeIconGuideDataAnalysisBody;
    }
  }

  Future<void> _advanceHomeIconGuide() async {
    if (!_showHomeIconGuide) return;
    if (_homeIconGuideStep < 7) {
      setState(() => _homeIconGuideStep++);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyHomeIconGuideCompleted, true);
    if (!mounted) return;
    setState(() {
      _showHomeIconGuide = false;
    });

    // After finishing the 8-icon guide, spotlight the calculator once,
    // then (optionally) show the cloud save prompt.
    _showCalculatorHelpSpotlightOnce();
  }

  void _showCalculatorHelpSpotlightOnce() {
    if (!mounted) return;
    if (_isScratchPaperMode) return;
    if (_isHelpPageVisible ||
        _isProblemListVisible ||
        _isReferenceTableVisible ||
        _isDataAnalysisVisible ||
        _isAuthPageVisible) {
      return;
    }
    setState(() => _showCalculatorHelpSpotlight = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _guideCalculatorKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        // Place the calculator a bit lower in the viewport so the guide panel
        // can appear above it without overlapping.
        alignment: 0.88,
      );
    });
  }

  void _dismissCalculatorHelpSpotlight() {
    if (!mounted) return;
    setState(() => _showCalculatorHelpSpotlight = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (FirebaseAuthService.isAuthenticated) return;
      _showCloudSavePromptDialog();
    });
  }

  Future<void> _showCloudSavePromptDialog() async {
    // Avoid showing if another overlay is already open (rare, but safe).
    if (_isHelpPageVisible ||
        _isProblemListVisible ||
        _isReferenceTableVisible ||
        _isDataAnalysisVisible ||
        _isAuthPageVisible) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_l10n.cloudSavePromptTitle),
          content: Text(_l10n.cloudSavePromptBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_l10n.cloudSavePromptLater),
            ),
            // Keep the actions visually equal (no emphasized primary action).
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                setState(() {
                  _isAuthPageVisible = true;
                  // Keep the UI consistent with tapping the cloud icon.
                  _isHelpPageVisible = false;
                  _isProblemListVisible = false;
                  _isReferenceTableVisible = false;
                  _isDataAnalysisVisible = false;
                  _isScratchPaperMode = false;
                  _isCalculatorExpanded = false;
                });
              },
              child: Text(_l10n.cloudSavePromptSaveNow),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterSettingsPanel() {
    return _filterHelper.buildFilterSettingsPanel(
      selectedCategories: _selectedCategories,
      gachaFilterMode: _gachaFilterMode,
      onCategoryToggled: (category) async {
        setState(() {
          if (_selectedCategories.contains(category)) {
            _selectedCategories.remove(category);
          } else {
            _selectedCategories.add(category);
          }
        });
        final hasUnlocked = await _problemManager.hasAnyUnlockedProblems(_selectedCategories);
        final newProblems = await _problemManager.shuffleProblems(
          _selectedCategories,
          _gachaFilterMode,
        );
        if (mounted) {
          setState(() {
            _hasAnyUnlockedInSelection = hasUnlocked;
            _displayProblems = newProblems;
            _prepareProblemsForPlay();
          });
        }
        _saveSettings();
      },
      onGachaFilterModeChanged: (newMode) async {
        setState(() => _gachaFilterMode = newMode);
        final hasUnlocked = await _problemManager.hasAnyUnlockedProblems(_selectedCategories);
        final newProblems = await _problemManager.shuffleProblems(
          _selectedCategories,
          _gachaFilterMode,
        );
        if (mounted) {
          setState(() {
            _hasAnyUnlockedInSelection = hasUnlocked;
            _displayProblems = newProblems;
            _prepareProblemsForPlay();
          });
        }
        _saveSettings();
      },
      onStateChanged: () => setState(() {}),
    );
  }

  Widget _buildProblemListFilterSettingsPanel() {
    return _filterHelper.buildFilterSettingsPanel(
      selectedCategories: _selectedCategories,
      gachaFilterMode: _gachaFilterMode,
      onCategoryToggled: (category) async {
        setState(() {
          if (_selectedCategories.contains(category)) {
            _selectedCategories.remove(category);
          } else {
            _selectedCategories.add(category);
          }
        });
        final hasUnlocked = await _problemManager.hasAnyUnlockedProblems(_selectedCategories);
        final newProblems = await _problemManager.shuffleProblems(
          _selectedCategories,
          _gachaFilterMode,
        );
        if (mounted) {
          setState(() {
            _hasAnyUnlockedInSelection = hasUnlocked;
            _displayProblems = newProblems;
            _prepareProblemsForPlay();
          });
        }
        _saveSettings();
      },
      onGachaFilterModeChanged: (newMode) async {
        setState(() => _gachaFilterMode = newMode);
        final hasUnlocked = await _problemManager.hasAnyUnlockedProblems(_selectedCategories);
        final newProblems = await _problemManager.shuffleProblems(
          _selectedCategories,
          _gachaFilterMode,
        );
        if (mounted) {
          setState(() {
            _hasAnyUnlockedInSelection = hasUnlocked;
            _displayProblems = newProblems;
            _prepareProblemsForPlay();
          });
        }
        _saveSettings();
      },
      onStateChanged: () => setState(() {}),
      isProblemListMode: true,
    );
  }

  Widget _buildScratchPaperModeLayout(
    UnitGachaItem item,
    String correctAnswer,
  ) {
    if (_selectedProblems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildScratchPaperModeBody(item, correctAnswer);
  }

  Widget _buildScratchPaperModeBody(UnitGachaItem item, String correctAnswer) {
    final problem = item.unitProblem;
    return _layoutBuilder.buildScratchPaperModeBody(
      item: item,
      correctAnswer: correctAnswer,
      isAnswered: _isAnswered,
      isCorrect: _isCorrect,
      currentProblemIndex: _currentProblemIndex,
      selectedProblemsLength: _selectedProblems.length,
      isCalculatorExpanded: _isCalculatorExpanded,
      drawingToolState: _drawingToolState,
      isDrawingNotifier: _isDrawingNotifier,
      activeToolNotifier: _activeToolNotifier,
      penButtonPosition: _penButtonPosition,
      // NOTE: Scratch-paper mode is kept in the tree via Offstage to preserve
      // DrawingCanvas state. Avoid reusing the same GlobalKeys as the main header
      // (even when Offstage) to prevent "Multiple widgets used the same GlobalKey".
      header: _buildHeader(enableGuideKeys: false),
      calculator: _buildCalculator(problem),
      onRefreshProblems: _refreshProblems,
      onNextProblem: _nextProblem,
      onPenPositionChanged: (newPosition) {
        if (_penButtonPosition != newPosition) {
          setState(() => _penButtonPosition = newPosition);
        }
      },
      onPenModeChanged: () {
        setState(() {
          _drawingToolState.isEraser = false;
          _drawingToolState.isScrollMode = false;
        });
        _activeToolNotifier.value = 'pen';
      },
      onColorChanged: (color) =>
          setState(() => _drawingToolState.currentColor = color),
      onStrokeWidthChanged: (width) =>
          setState(() => _drawingToolState.currentStrokeWidth = width),
      onEraserToggle: () {
        setState(() {
          _drawingToolState.isEraser = !_drawingToolState.isEraser;
          _drawingToolState.isScrollMode = false;
        });
        _activeToolNotifier.value = _drawingToolState.isEraser
            ? 'eraser'
            : 'pen';
      },
      onScrollToggle: () {
        setState(() {
          _drawingToolState.isScrollMode = !_drawingToolState.isScrollMode;
          _drawingToolState.isEraser = false;
        });
        _activeToolNotifier.value = _drawingToolState.isScrollMode
            ? 'scroll'
            : 'pen';
      },
      onCalculatorToggle: () =>
          setState(() => _isCalculatorExpanded = !_isCalculatorExpanded),
      onStateChanged: () => setState(() {}),
      context: context,
    );
  }

  /// 電卓を構築（homeモードと計算用紙モードで共通）
  Widget _buildCalculator(UnitProblem problem) {
    return UnitCalculator(
      key: ValueKey(
        'calc_${_currentProblemIndex}_${_selectedProblems[_currentProblemIndex].unitProblem.units.join('_')}',
      ),
      type: _selectedCalculatorTypes[_currentProblemIndex],
      selectedAnswer: _selectedProblems[_currentProblemIndex].unitProblem,
      onEnter: _handleAnswer,
      isAnswered: _isAnswered,
      onNext: null,
      nextButtonText: _currentProblemIndex < _selectedProblems.length - 1
          ? _l10n.next
          : _l10n.complete,
      // home と 計算用紙モードで、1行目と2行目の間隔だけをほんの少し広げる
      firstSecondRowGapMultiplier: 1.2,
    );
  }

  // 電卓ボタン位置を読み込む
  Future<void> _loadCalculatorButtonPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('draggable_calculator_button_x');
    final savedY = prefs.getDouble('draggable_calculator_button_y');

    if (mounted) {
      if (savedX != null && savedY != null) {
        setState(() {
          _calculatorButtonPosition = Offset(savedX, savedY);
        });
      } else {
        // デフォルト位置（画面右下）
        final screenSize = MediaQuery.of(context).size;
        final isMobile = screenSize.width < 600;
        final buttonSize = isMobile ? 56.0 : 72.0;
        final margin = isMobile ? 16.0 : 24.0; // 右端と下端からのマージン
        final rightX = screenSize.width - buttonSize - margin;
        final bottomY = screenSize.height - buttonSize - margin;
        setState(() {
          _calculatorButtonPosition = Offset(rightX, bottomY);
        });
      }
    }
  }

  // 電卓ボタン位置を保存
  Future<void> _saveCalculatorButtonPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      'draggable_calculator_button_x',
      _calculatorButtonPosition.dx,
    );
    await prefs.setDouble(
      'draggable_calculator_button_y',
      _calculatorButtonPosition.dy,
    );
  }

  /// 共通のモード切り替えコールバックを生成
  Map<String, VoidCallback> _buildModeToggleCallbacks({
    required String currentMode,
  }) {
    return {
      'onHelpToggle': () {
        setState(() {
          _isScratchPaperMode = false;
          _isCalculatorExpanded = false;
          _isHelpPageVisible = currentMode != 'help' ? true : false;
          _isProblemListVisible = false;
          _isReferenceTableVisible = false;
          _isDataAnalysisVisible = false;
          _isAuthPageVisible = false;
        });
      },
      'onProblemListToggle': () {
        setState(() {
          _isScratchPaperMode = false;
          _isCalculatorExpanded = false;
          _isHelpPageVisible = false;
          final willShow = currentMode != 'problemList' ? true : false;
          _isProblemListVisible = willShow;
          _isReferenceTableVisible = false;
          _isDataAnalysisVisible = false;
          _isAuthPageVisible = false;
          // 問題一覧モードに入ったらフィルタパネルを自動表示
          if (willShow) {
            _showFilterSettings = true;
          }
        });
      },
      'onReferenceTableToggle': () {
        setState(() {
          _isScratchPaperMode = false;
          _isCalculatorExpanded = false;
          _isHelpPageVisible = false;
          _isProblemListVisible = false;
          _isReferenceTableVisible = currentMode != 'referenceTable'
              ? true
              : false;
          _isDataAnalysisVisible = false;
          _isAuthPageVisible = false;
        });
      },
      'onDataAnalysisNavigate': () {
        setState(() {
          _isScratchPaperMode = false;
          _isCalculatorExpanded = false;
          _isHelpPageVisible = false;
          _isProblemListVisible = false;
          _isReferenceTableVisible = false;
          _isDataAnalysisVisible = currentMode != 'dataAnalysis' ? true : false;
          _isAuthPageVisible = false;
        });
      },
      'onScratchPaperToggle': () {
        setState(() {
          final nextScratch = currentMode != 'scratchPaper' ? true : false;
          _isHelpPageVisible = false;
          _isProblemListVisible = false;
          _isReferenceTableVisible = false;
          _isDataAnalysisVisible = false;
          _isAuthPageVisible = false;
          _isScratchPaperMode = nextScratch;
          if (nextScratch) {
            _loadCalculatorButtonPosition();
          } else {
            _isCalculatorExpanded = false;
          }
        });
      },
      'onFilterToggle': () {
        setState(() {
          _showFilterSettings = !_showFilterSettings;
        });
      },
      'onLoginTap': () {
        setState(() {
          _isScratchPaperMode = false;
          _isCalculatorExpanded = false;
          _isHelpPageVisible = false;
          _isProblemListVisible = false;
          _isReferenceTableVisible = false;
          _isDataAnalysisVisible = false;
          _isAuthPageVisible = currentMode != 'auth' ? true : false;
        });
      },
    };
  }

  /// ヘルプページをオーバーレイとして表示
  Widget _buildHelpPageOverlay() {
    final callbacks = _buildModeToggleCallbacks(currentMode: 'help');
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: const Color(0xFFF5F5DC),
          child: HelpPage(
            onClose: callbacks['onHelpToggle']!,
            timerManager: _timerManager,
            isHelpPageVisible: _isHelpPageVisible,
            isProblemListVisible: _isProblemListVisible,
            isReferenceTableVisible: _isReferenceTableVisible,
            isScratchPaperMode: _isScratchPaperMode,
            showFilterSettings: _showFilterSettings,
            onHelpToggle: callbacks['onHelpToggle']!,
            onProblemListToggle: callbacks['onProblemListToggle']!,
            onReferenceTableToggle: callbacks['onReferenceTableToggle']!,
            onScratchPaperToggle: callbacks['onScratchPaperToggle']!,
            onFilterToggle: callbacks['onFilterToggle']!,
            onLoginTap: callbacks['onLoginTap']!,
            onDataAnalysisNavigate: callbacks['onDataAnalysisNavigate']!,
            isDataAnalysisActive: false,
          ),
        ),
      ),
    );
  }

  /// 一覧ページをオーバーレイとして表示
  Widget _buildProblemListOverlay() {
    final callbacks = _buildModeToggleCallbacks(currentMode: 'problemList');
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: ProblemListPage(
          problemPool: unitExprProblems,
          prefsPrefix: 'unit',
          onClose: callbacks['onProblemListToggle']!,
          timerManager: _timerManager,
          isHelpPageVisible: _isHelpPageVisible,
          isProblemListVisible: _isProblemListVisible,
          isReferenceTableVisible: _isReferenceTableVisible,
          isScratchPaperMode: _isScratchPaperMode,
          showFilterSettings: _showFilterSettings,
          onHelpToggle: callbacks['onHelpToggle']!,
          onProblemListToggle: callbacks['onProblemListToggle']!,
          onReferenceTableToggle: callbacks['onReferenceTableToggle']!,
          onScratchPaperToggle: callbacks['onScratchPaperToggle']!,
          onFilterToggle: callbacks['onFilterToggle']!,
          onLoginTap: callbacks['onLoginTap']!,
          onDataAnalysisNavigate: callbacks['onDataAnalysisNavigate']!,
          isDataAnalysisActive: false,
          filterSettingsPanel: _buildProblemListFilterSettingsPanel(),
          showFilterPanel: _showFilterSettings,
          selectedCategories: _selectedCategories,
          gachaFilterMode: _gachaFilterMode,
        ),
      ),
    );
  }

  /// 物理量度定数一覧ページをオーバーレイとして表示
  Widget _buildReferenceTableOverlay() {
    final callbacks = _buildModeToggleCallbacks(currentMode: 'referenceTable');
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.white,
          child: UnitReferenceTablePage(
            onClose: callbacks['onReferenceTableToggle']!,
            timerManager: _timerManager,
            isHelpPageVisible: _isHelpPageVisible,
            isProblemListVisible: _isProblemListVisible,
            isReferenceTableVisible: _isReferenceTableVisible,
            isScratchPaperMode: _isScratchPaperMode,
            showFilterSettings: _showFilterSettings,
            onHelpToggle: callbacks['onHelpToggle']!,
            onProblemListToggle: callbacks['onProblemListToggle']!,
            onReferenceTableToggle: callbacks['onReferenceTableToggle']!,
            onScratchPaperToggle: callbacks['onScratchPaperToggle']!,
            onFilterToggle: callbacks['onFilterToggle']!,
            onLoginTap: callbacks['onLoginTap']!,
            onDataAnalysisNavigate: callbacks['onDataAnalysisNavigate']!,
            isDataAnalysisActive: false,
          ),
        ),
      ),
    );
  }

  /// データ分析ページをオーバーレイとして表示
  Widget _buildDataAnalysisOverlay() {
    final callbacks = _buildModeToggleCallbacks(currentMode: 'dataAnalysis');
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: DataAnalysisPage(
          selectedCategories: _selectedCategories,
          gachaFilterMode: _gachaFilterMode,
          onClose: callbacks['onDataAnalysisNavigate']!,
          timerManager: _timerManager,
          isHelpPageVisible: _isHelpPageVisible,
          isProblemListVisible: _isProblemListVisible,
          isReferenceTableVisible: _isReferenceTableVisible,
          isScratchPaperMode: _isScratchPaperMode,
          showFilterSettings: _showFilterSettings,
          onHelpToggle: callbacks['onHelpToggle']!,
          onProblemListToggle: callbacks['onProblemListToggle']!,
          onReferenceTableToggle: callbacks['onReferenceTableToggle']!,
          onScratchPaperToggle: callbacks['onScratchPaperToggle']!,
          onFilterToggle: callbacks['onFilterToggle']!,
          onLoginTap: callbacks['onLoginTap']!,
          onDataAnalysisNavigate: callbacks['onDataAnalysisNavigate']!,
          isDataAnalysisActive: _isDataAnalysisVisible,
        ),
      ),
    );
  }

  /// ログインページをオーバーレイとして表示
  Widget _buildAuthPageOverlay() {
    final callbacks = _buildModeToggleCallbacks(currentMode: 'auth');
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.white,
          child: AuthPage(
            onClose: callbacks['onLoginTap']!,
            timerManager: _timerManager,
            isHelpPageVisible: _isHelpPageVisible,
            isProblemListVisible: _isProblemListVisible,
            isReferenceTableVisible: _isReferenceTableVisible,
            isScratchPaperMode: _isScratchPaperMode,
            showFilterSettings: _showFilterSettings,
            onHelpToggle: callbacks['onHelpToggle']!,
            onProblemListToggle: callbacks['onProblemListToggle']!,
            onReferenceTableToggle: callbacks['onReferenceTableToggle']!,
            onScratchPaperToggle: callbacks['onScratchPaperToggle']!,
            onFilterToggle: callbacks['onFilterToggle']!,
            onLoginTap: callbacks['onLoginTap']!,
            onDataAnalysisNavigate: callbacks['onDataAnalysisNavigate']!,
            isDataAnalysisActive: _isDataAnalysisVisible,
          ),
        ),
      ),
    );
  }
}
