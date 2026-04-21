// lib/pages/scratch_paper_page.dart
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'; // ValueNotifier, kIsWeb
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../models/math_problem.dart';
import '../../models/learning_status.dart';
import '../../services/problems/simple_data_manager.dart';
import '../../services/payment/revenuecat_service.dart';
import '../../widgets/drawing/drawing_toolbar.dart';
import '../../widgets/drawing/draggable_tool_buttons.dart';
import '../../widgets/timer/draggable_timer.dart';
import '../../widgets/drawing/draggable_eraser_button.dart';
import '../../widgets/drawing/draggable_scroll_button.dart';
import '../../managers/timer_manager.dart';
import '../common/common.dart';
import '../common/problem_status.dart';
import '../../localization/app_localizations.dart';
// Firebase auth
import '../../util/platform_info.dart';
import '../../util/app_file_export.dart';
import '../../services/auth/firebase_auth_service.dart';
import 'auth_page.dart';
// Gacha page
import '../gacha/pages/unit_gacha_page.dart';
import '../gacha/data/unit_gacha_history.dart' show UnitGachaHistoryManager;

enum AnswerDisplayMode { none, answer, explanation }

// iPad検出用のヘルパー関数（エクスポート）
bool isIPad(BuildContext context) {
  if (!PlatformInfo.isIOS) return false;
  final screenSize = MediaQuery.of(context).size;
  final shortestSide = screenSize.shortestSide;
  // iPadの最小サイズは768pt（物理ピクセル）
  return shortestSide >= 768;
}

// ツールタイプのenum（エクスポート）
enum DrawingTool {
  text, // テキストツール
  pen, // 太いペン
  marker, // ハイライター
  strokeEraser, // ストローク消しゴム（ストローク全体を削除）
  partialEraser, // 部分消しゴム（部分削除）
  lasso, // ラッソ選択ツール
}

class ScratchPaperPage extends StatefulWidget {
  final MathProblem? problem;
  final String? prefsPrefix;

  const ScratchPaperPage({super.key, this.problem, this.prefsPrefix});

  @override
  State<ScratchPaperPage> createState() => _ScratchPaperPageState();
}

class _ScratchPaperPageState extends State<ScratchPaperPage>
    with WidgetsBindingObserver {
  final GlobalKey _paintKey = GlobalKey();
  List<DrawingPoint> _points = [];
  List<List<DrawingPoint>> _strokes = [];
  List<List<DrawingPoint>> _undoStack = []; // 取り消し用スタック
  List<List<DrawingPoint>> _redoStack = []; // やり直し用スタック
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 2.0;
  bool _isEraser = false;
  bool _isScrollMode = false; // スクロールモードの状態
  DrawingTool _currentTool = DrawingTool.pen; // iPad用のツール
  bool _allowFingerDrawing = false; // 指で描画を許可するか
  PointerDeviceKind? _activePointerKind; // 現在アクティブなポインターの種類
  Offset? _lastEraserPosition; // 消しゴムの前回位置
  AnswerDisplayMode _answerDisplayMode = AnswerDisplayMode.none;
  bool _showHint = false;
  LearningStatus _learningStatus = LearningStatus.none;
  bool _isLearningStatusPressed = false;
  bool _isSavePressed = false;

  // 学習履歴オプションは常に有効
  bool _isHistoryEnabled = true;
  late AppLocalizations _l10n;

  // ボタンの位置（ドラッグ可能にするため）
  Offset _penButtonPosition = const Offset(0, 0); // 初期化時に設定

  // iPad用パレットの状態
  bool _isPaletteExpanded = false;
  bool _isPaletteVisible = true; // パレットを完全に非表示にするか
  Offset _palettePosition = const Offset(0, 0); // 初期化時に設定
  bool _isPaletteDragging = false;

  // オブジェクト選択関連
  Set<int> _selectedStrokeIndices = {}; // 選択されたストロークのインデックス（複数選択対応）
  Offset? _selectionStart; // 輪っか選択の開始位置
  Offset? _selectionEnd; // 輪っか選択の終了位置
  bool _isLassoSelecting = false; // 輪っか選択中か
  List<Offset> _lassoPath = []; // 輪っか選択のパス
  DrawingTool _previousTool = DrawingTool.pen; // ラッソ選択前のツールを保存
  Offset? _selectionOffset; // 選択オブジェクトの移動オフセット
  double _selectionScale = 1.0; // 選択オブジェクトのスケール
  Offset? _selectionCenter; // 選択オブジェクトの中心点
  double _initialScale = 1.0; // スケール開始時のスケール値
  Map<int, List<Offset>> _originalStrokePositions = {}; // 選択時の元の位置を保存
  int? _selectedHandleIndex; // 選択されたハンドルのインデックス（0-3: 左上、右上、左下、右下）
  Offset? _handleDragStart; // ハンドルドラッグ開始位置
  Rect? _selectionBounds; // 選択されたオブジェクト全体のバウンディングボックス
  Rect? _originalSelectionBounds; // ハンドルドラッグ開始時の元のバウンディングボックス
  Offset? _originalSelectionCenter; // ハンドルドラッグ開始時の元の中心点

  // ScrollViewのコントローラ
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  // ScrollViewのキー
  final GlobalKey _scrollViewKey = GlobalKey();

  // ------------ 追加：親側で持つ Notifier ------------
  late final ValueNotifier<String> _activeToolNotifier;
  late final ValueNotifier<bool> _isDrawingNotifier;

  // 画面サイズ変化検出用
  Size? _lastScreenSize;

  // ボタン位置保存用のデバウンスタイマー
  DateTime? _lastSaveTime;
  static const _saveDebounceMs = 500; // 500ms以内の連続保存を防ぐ

  // 筆圧から線幅を計算する関数（iPadのメモアプリと同様の仕様）
  double _calculateStrokeWidth(double pressure) {
    if (pressure <= 0.0) {
      return _currentStrokeWidth; // デフォルト値（筆圧なし）
    }

    // ツールに応じた最小/最大幅を設定
    double minWidth;
    double maxWidth;

    switch (_currentTool) {
      case DrawingTool.text:
        minWidth = 1.0;
        maxWidth = 3.0;
        break;
      case DrawingTool.pen:
        minWidth = 1.0;
        maxWidth = 4.0;
        break;
      case DrawingTool.marker:
        minWidth = 6.0;
        maxWidth = 15.0;
        break;
      case DrawingTool.strokeEraser:
      case DrawingTool.partialEraser:
        minWidth = 10.0;
        maxWidth = 30.0;
        break;
      case DrawingTool.lasso:
        // ラッソ選択ツールは描画しないので、デフォルト値を返す
        return _currentStrokeWidth;
    }

    // 筆圧値（0.0〜1.0）を線幅にマッピング
    return minWidth + (pressure * (maxWidth - minWidth));
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Notifier 初期化（初期ツールは pen または _isEraser/_isScrollMode に合わせる）
    final initialTool = _isEraser
        ? 'eraser'
        : (_isScrollMode ? 'scroll' : 'pen');
    _activeToolNotifier = ValueNotifier<String>(initialTool);
    _isDrawingNotifier = ValueNotifier<bool>(false);

    // 初期位置を設定（画面サイズは後で取得）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeButtonPositions(context);
        _loadButtonPositions();
        if (isIPad(context)) {
          _loadPalettePosition();
        }
        // タイマー設定を読み込み
        final prefsPrefix = widget.prefsPrefix ?? 'integral';
        TimerManager().loadTimerSettings(prefsPrefix);
        // 学習履歴オプションの購入状態を確認
        _checkLearningHistoryOptionStatus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    // 画面サイズ変化を監視（回転や分割画面など）
    final screenSize = MediaQuery.of(context).size;
    if (_lastScreenSize == null || _lastScreenSize != screenSize) {
      _lastScreenSize = screenSize;
    }
  }

  /// 学習履歴オプションの購入状態を確認
  Future<void> _checkLearningHistoryOptionStatus() async {
    await UnitGachaHistoryManager.checkLearningHistoryOptionStatus();
  }

  @override
  void didChangeMetrics() {
    // 画面メトリクス（キーボード/回転など）変化時の処理
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _activeToolNotifier.dispose();
    _isDrawingNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ボタンの初期位置を設定（画面中央に横並びで配置）
  void _initializeButtonPositions(BuildContext? context) {
    if (!mounted || context == null) return;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final buttonSize = isMobile ? 56.0 : 72.0;
    final spacing = isMobile ? 40.0 : 60.0; // ボタン間の間隔

    // 画面の中央に配置（ペン、消しゴム、スクロールを横並び）
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    // 消しゴムボタンを中央に配置
    final eraserX = centerX - buttonSize / 2;
    final eraserY = centerY - buttonSize / 2;

    if (_penButtonPosition == Offset.zero) {
      // ペンは消しゴムの左
      _penButtonPosition = Offset(eraserX - buttonSize - spacing, eraserY);
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ボタンの位置を読み込む
  Future<void> _loadPalettePosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('ipad_palette_x');
    final savedY = prefs.getDouble('ipad_palette_y');
    final savedExpanded = prefs.getBool('ipad_palette_expanded');
    final savedVisible = prefs.getBool('ipad_palette_visible');

    if (mounted) {
      final screenSize = MediaQuery.of(context).size;

      // まず展開状態を読み込む（位置計算に必要）
      if (savedExpanded != null) {
        setState(() {
          _isPaletteExpanded = savedExpanded;
        });
      }

      final paletteWidth = _isPaletteExpanded ? 600.0 : 56.0;

      if (savedX != null && savedY != null) {
        // 既存データを読み込み（左上位置ベースとして扱う）
        // 既存データが中心点ベースの場合、最初は位置がずれる可能性があるが、
        // ユーザーがドラッグして再保存すれば正しい位置になる
        setState(() {
          _palettePosition = Offset(savedX, savedY);
        });
      } else {
        // デフォルト位置（画面下部中央、左上位置ベース）
        setState(() {
          _palettePosition = Offset(
            screenSize.width / 2 - paletteWidth / 2,
            100,
          );
        });
      }

      if (savedVisible != null) {
        setState(() {
          _isPaletteVisible = savedVisible;
        });
      }
    }
  }

  Future<void> _savePalettePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ipad_palette_x', _palettePosition.dx);
    await prefs.setDouble('ipad_palette_y', _palettePosition.dy);
    await prefs.setBool('ipad_palette_expanded', _isPaletteExpanded);
    await prefs.setBool('ipad_palette_visible', _isPaletteVisible);
  }

  Future<void> _loadButtonPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final penX = prefs.getDouble('scratch_paper_pen_button_x');
      final penY = prefs.getDouble('scratch_paper_pen_button_y');

      if (!mounted || context == null) return;

      bool needsInitialize = false;

      // ペンボタンの位置を読み込む
      if (penX != null && penY != null && penX != 0 && penY != 0) {
        _penButtonPosition = Offset(penX, penY);
      } else {
        needsInitialize = true;
      }

      if (needsInitialize && mounted) {
        // 保存された位置を削除して初期位置にリセット
        await _resetButtonPositions();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading button positions: $e');
    }
  }

  // ボタンの位置を保存する（デバウンス付き）
  Future<void> _saveButtonPositions() async {
    final now = DateTime.now();
    if (_lastSaveTime != null &&
        now.difference(_lastSaveTime!).inMilliseconds < _saveDebounceMs) {
      // デバウンス期間内の場合は保存をスキップ
      return;
    }
    _lastSaveTime = now;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
        'scratch_paper_pen_button_x',
        _penButtonPosition.dx,
      );
      await prefs.setDouble(
        'scratch_paper_pen_button_y',
        _penButtonPosition.dy,
      );
    } catch (e) {
      print('Error saving button positions: $e');
    }
  }

  // ボタンの位置をリセット（初期位置に戻す）
  Future<void> _resetButtonPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 保存された位置を削除
      await prefs.remove('scratch_paper_pen_button_x');
      await prefs.remove('scratch_paper_pen_button_y');
      await prefs.remove('draggable_eraser_button_x');
      await prefs.remove('draggable_eraser_button_y');
      await prefs.remove('draggable_scroll_button_x');
      await prefs.remove('draggable_scroll_button_y');

      // 位置を初期化（強制的に初期位置に設定）
      if (mounted && context != null) {
        final screenSize = MediaQuery.of(context).size;
        final isMobile = screenSize.width < 600;
        final buttonSize = isMobile ? 56.0 : 72.0;
        final spacing = isMobile ? 40.0 : 60.0;

        // 画面の中央に配置（ペン、消しゴム、スクロールを横並び）
        final centerX = screenSize.width / 2;
        final centerY = screenSize.height / 2;

        // 消しゴムボタンを中央に配置
        final eraserX = centerX - buttonSize / 2;
        final eraserY = centerY - buttonSize / 2;

        // ペンボタンの位置（消しゴムの左）
        final penX = eraserX - buttonSize - spacing;
        final penY = eraserY;

        setState(() {
          _penButtonPosition = Offset(penX, penY);
        });

        // 保存しておく
        // await _saveButtonPositions(); // 一時的に無効化
      }
    } catch (e) {
      print('Error resetting button positions: $e');
    }
  }

  // すべてのボタンが画面内にあるかチェックして、外れていたらクランプして保存
  // 領域制限を撤廃したため、このメソッドは使用されません
  // void _ensureButtonsWithinBounds() {
  //   // 領域制限を撤廃
  // }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                tooltip: '戻る',
              ),
            ),
            title: StreamBuilder(
              stream: FirebaseAuthService.authStateChanges,
              builder: (context, snapshot) {
                final isAuthenticated = FirebaseAuthService.isAuthenticated;
                final userEmail = FirebaseAuthService.userEmail;
                final userPhoneNumber = FirebaseAuthService.userPhoneNumber;
                final displayName = FirebaseAuthService.displayName;
                final loginMethod = FirebaseAuthService.loginMethod;

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        _l10n.fingerDrawing,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    if (isAuthenticated) ...[
                      // アカウントアイコン（ログアウトボタン付き）
                      PopupMenuButton<String>(
                        iconSize: 24.0,
                        icon: Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 24.0,
                        ),
                        onSelected: (value) async {
                          if (value == 'logout') {
                            await FirebaseAuthService.signOut();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ログアウトしました'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              setState(() {});
                            }
                          }
                        },
                        itemBuilder: (context) {
                          String? accountInfo;
                          if (userPhoneNumber != null &&
                              userPhoneNumber.isNotEmpty) {
                            accountInfo = userPhoneNumber;
                          } else if (userEmail != null &&
                              userEmail.isNotEmpty) {
                            accountInfo = userEmail;
                          } else if (displayName != null &&
                              displayName.isNotEmpty) {
                            accountInfo = displayName;
                          }

                          return [
                            if (accountInfo != null)
                              PopupMenuItem(
                                enabled: false,
                                child: Text(
                                  accountInfo,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            if (loginMethod != null)
                              PopupMenuItem(
                                enabled: false,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.login,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '$loginMethodでクラウドを利用中',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, size: 20),
                                  SizedBox(width: 8),
                                  Text('ログアウト'),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ] else ...[
                      // クラウドボタン（ログインしていない場合）
                      Material(
                        color: Colors.transparent,
                        child: IconButton(
                          iconSize: 24.0,
                          icon: Icon(
                            Icons.cloud_outlined,
                            color: Colors.white,
                            size: 24.0,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthPage(),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(() {});
                            }
                          },
                          tooltip: 'ログイン',
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            actionsIconTheme: const IconThemeData(size: 24),
            actions: [
              // --- 統一された spacing / padding を使う AppBar actions ---アイコンが多いので間隔に注意
              Builder(
                builder: (context) {
                  // 変更：少し詰める（マイルド）
                  final screenSize = MediaQuery.of(context).size;
                  final isMobile = screenSize.width < 600;
                  // アイコン自体はそのまま、間隔だけ小さくする
                  final iconSize = isMobile ? 20.0 : 28.0;
                  // B より少し詰める -> mobile 8px / desktop 10px
                  final iconSpacing = isMobile ? 0.0 : 10.0;
                  // 右端パディングを少し小さく
                  final endRightPadding = isMobile ? 16.0 : 18.0;
                  // 内側余白を小さめに（タップ領域はまだ十分）
                  final commonIconPadding = EdgeInsets.all(isMobile ? 0 : 6.0);
                  // 見た目の最小領域（幅/高さ）も少し詰める
                  final commonIconConstraints = BoxConstraints(
                    minWidth: iconSize + (isMobile ? 8.0 : 12.0),
                    minHeight: iconSize + (isMobile ? 8.0 : 12.0),
                  );

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // グループ1: 全消し / 元に戻す / やり直し
                      IconButton(
                        icon: Icon(Icons.autorenew, size: iconSize),
                        onPressed: _clearCanvas,
                        tooltip: '全消し',
                        padding: commonIconPadding,
                        constraints: commonIconConstraints,
                      ),
                      SizedBox(width: iconSpacing),
                      IconButton(
                        icon: Icon(Icons.undo, size: iconSize),
                        onPressed: _undoLastStroke,
                        tooltip: '元に戻す',
                        padding: commonIconPadding,
                        constraints: commonIconConstraints,
                      ),
                      SizedBox(width: iconSpacing),
                      IconButton(
                        icon: Icon(Icons.redo, size: iconSize),
                        onPressed: _redoLastStroke,
                        tooltip: 'やり直し',
                        padding: commonIconPadding,
                        constraints: commonIconConstraints,
                      ),
                      SizedBox(width: iconSpacing),

                      // widget.problem の存在で以降のボタンを表示
                      if (widget.problem != null) ...[
                        // グループ2: ヒント / 解答 / 解説（3段階トグル）
                        if (widget.problem != null &&
                            widget.problem!.hint != null &&
                            widget.problem!.hint!.isNotEmpty) ...[
                          IconButton(
                            icon: Icon(
                              Icons.lightbulb_outline,
                              color: _showHint ? Colors.orange : Colors.white,
                              size: iconSize,
                            ),
                            onPressed: () =>
                                setState(() => _showHint = !_showHint),
                            tooltip: _showHint ? 'ヒントを隠す' : 'ヒントを表示',
                            padding: commonIconPadding,
                            constraints: commonIconConstraints,
                          ),
                          SizedBox(width: iconSpacing),
                        ],
                        IconButton(
                          icon: Icon(
                            _answerDisplayMode == AnswerDisplayMode.none
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: _answerDisplayMode == AnswerDisplayMode.none
                                ? Colors.white
                                : Colors.amber,
                            size: iconSize,
                          ),
                          onPressed: () {
                            setState(() {
                              switch (_answerDisplayMode) {
                                case AnswerDisplayMode.none:
                                  _answerDisplayMode = AnswerDisplayMode.answer;
                                  break;
                                case AnswerDisplayMode.answer:
                                  _answerDisplayMode =
                                      AnswerDisplayMode.explanation;
                                  break;
                                case AnswerDisplayMode.explanation:
                                  _answerDisplayMode = AnswerDisplayMode.none;
                                  break;
                              }
                            });
                          },
                          tooltip: _answerDisplayMode == AnswerDisplayMode.none
                              ? '解答を表示'
                              : _answerDisplayMode == AnswerDisplayMode.answer
                              ? '解説を表示'
                              : '閉じる',
                          padding: commonIconPadding,
                          constraints: commonIconConstraints,
                        ),
                        SizedBox(width: iconSpacing),

                        // グループ3: 学習ステータス / 保存
                        GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _isLearningStatusPressed = true),
                          onTapUp: (_) =>
                              setState(() => _isLearningStatusPressed = false),
                          onTapCancel: () =>
                              setState(() => _isLearningStatusPressed = false),
                          onTap: _isHistoryEnabled
                              ? _cycleLearningStatus
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            padding: EdgeInsets.all(isMobile ? 10.0 : 14.0),
                            decoration: BoxDecoration(
                              color: _isLearningStatusPressed
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              _learningStatus.icon,
                              color: _isHistoryEnabled
                                  ? (_learningStatus == LearningStatus.none
                                        ? Colors.white
                                        : _learningStatus.color)
                                  : Colors.grey[400]!,
                              size: iconSize,
                            ),
                          ),
                        ),
                        SizedBox(width: iconSpacing),
                        GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _isSavePressed = true),
                          onTapUp: (_) =>
                              setState(() => _isSavePressed = false),
                          onTapCancel: () =>
                              setState(() => _isSavePressed = false),
                          onTap:
                              (_isHistoryEnabled &&
                                  _learningStatus != LearningStatus.none)
                              ? _saveLearningRecord
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            padding: EdgeInsets.all(isMobile ? 10.0 : 14.0),
                            decoration: BoxDecoration(
                              color: _isSavePressed
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.save,
                              color:
                                  (_isHistoryEnabled &&
                                      _learningStatus != LearningStatus.none)
                                  ? Colors.white
                                  : Colors.grey[400]!,
                              size: iconSize,
                            ),
                          ),
                        ),
                        SizedBox(width: endRightPadding),
                      ],
                      // Gacha!ボタン（常に表示）
                      SizedBox(width: iconSpacing),
                      IconButton(
                        icon: Icon(Icons.casino, size: iconSize),
                        onPressed: () => _navigateToGacha(),
                        tooltip: 'Gacha!',
                        padding: commonIconPadding,
                        constraints: commonIconConstraints,
                      ),
                      SizedBox(width: endRightPadding),
                    ],
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  if (widget.problem != null) ...[
                    _answerDisplayMode != AnswerDisplayMode.none
                        ? Expanded(
                            child: SingleChildScrollView(
                              controller: _verticalScrollController,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 12,
                                  bottom: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 32),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: MixedTextMath(
                                          widget.problem!.question,
                                          labelStyle: const TextStyle(
                                            fontSize: 18,
                                          ),
                                          mathStyle: const TextStyle(
                                            fontSize: 24,
                                          ),
                                          forceTex: false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_answerDisplayMode ==
                                            AnswerDisplayMode.answer ||
                                        _answerDisplayMode ==
                                            AnswerDisplayMode.explanation) ...[
                                      const SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: MixedTextMath(
                                          "【答え】",
                                          labelStyle: const TextStyle(
                                            fontSize: 19,
                                          ),
                                          mathStyle: const TextStyle(
                                            fontSize: 22,
                                          ),
                                          forceTex: false,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: MixedTextMath(
                                          widget.problem!.answer,
                                          labelStyle: const TextStyle(
                                            fontSize: 19,
                                          ),
                                          mathStyle: const TextStyle(
                                            fontSize: 28,
                                            color: Colors.green,
                                          ),
                                          forceTex: false,
                                        ),
                                      ),
                                    ],
                                    if (_showHint &&
                                        widget.problem!.hint != null &&
                                        widget.problem!.hint!.isNotEmpty) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange[200]!,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: MixedTextMath(
                                                "【ヒント】",
                                                labelStyle: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                mathStyle: const TextStyle(
                                                  fontSize: 20,
                                                ),
                                                forceTex: false,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: MixedTextMath(
                                                widget.problem!.hint!,
                                                forceTex: true,
                                                labelStyle: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                                mathStyle: const TextStyle(
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_answerDisplayMode ==
                                        AnswerDisplayMode.explanation) ...[
                                      const SizedBox(height: 16),
                                      if (widget.problem!.imageAsset !=
                                          null) ...[
                                        FutureBuilder<bool>(
                                          future: _assetExists(
                                            widget.problem!.imageAsset!,
                                          ),
                                          builder: (ctx, snap) {
                                            if (snap.connectionState !=
                                                ConnectionState.done) {
                                              return const SizedBox.shrink();
                                            }
                                            if (snap.hasData &&
                                                snap.data == true) {
                                              return LayoutBuilder(
                                                builder: (context, constraints) {
                                                  final maxWidth =
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.7;
                                                  return ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth: maxWidth,
                                                    ),
                                                    child: Image.asset(
                                                      widget
                                                          .problem!
                                                          .imageAsset!,
                                                      fit: BoxFit.contain,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) =>
                                                              const SizedBox.shrink(),
                                                    ),
                                                  );
                                                },
                                              );
                                            } else {
                                              return const SizedBox.shrink();
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      ...widget.problem!.steps.map((s) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (s.tex != null &&
                                                  s.tex!.trim().isNotEmpty)
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: MixedTextMath(
                                                    s.tex!,
                                                    forceTex: true,
                                                    labelStyle: const TextStyle(
                                                      fontSize: 20,
                                                    ),
                                                    mathStyle: const TextStyle(
                                                      fontSize: 22,
                                                    ),
                                                  ),
                                                ),
                                              if (s.imageAsset != null)
                                                FutureBuilder<bool>(
                                                  future: _assetExists(
                                                    s.imageAsset!,
                                                  ),
                                                  builder: (ctx, snap) {
                                                    if (snap.connectionState !=
                                                        ConnectionState.done) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    if (snap.hasData &&
                                                        snap.data == true) {
                                                      return Column(
                                                        children: [
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          Center(
                                                            child: ConstrainedBox(
                                                              constraints:
                                                                  const BoxConstraints(
                                                                    maxHeight:
                                                                        400,
                                                                  ),
                                                              child: Image.asset(
                                                                s.imageAsset!,
                                                                fit: BoxFit
                                                                    .contain,
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                    ) =>
                                                                        const SizedBox.shrink(),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    } else {
                                                      return const SizedBox.shrink();
                                                    }
                                                  },
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 12,
                              bottom: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 32,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: MixedTextMath(
                                            widget.problem!.question,
                                            labelStyle: const TextStyle(
                                              fontSize: 18,
                                            ),
                                            mathStyle: const TextStyle(
                                              fontSize: 24,
                                            ),
                                            forceTex: false,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (_answerDisplayMode ==
                                        AnswerDisplayMode.answer ||
                                    _answerDisplayMode ==
                                        AnswerDisplayMode.explanation) ...[
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: MixedTextMath(
                                      "【答え】",
                                      labelStyle: const TextStyle(fontSize: 19),
                                      mathStyle: const TextStyle(fontSize: 22),
                                      forceTex: false,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: MixedTextMath(
                                      widget.problem!.answer,
                                      labelStyle: const TextStyle(fontSize: 19),
                                      mathStyle: const TextStyle(
                                        fontSize: 28,
                                        color: Colors.green,
                                      ),
                                      forceTex: false,
                                    ),
                                  ),
                                ],
                                if (_showHint &&
                                    widget.problem!.hint != null &&
                                    widget.problem!.hint!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: MixedTextMath(
                                            "【ヒント】",
                                            labelStyle: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            mathStyle: const TextStyle(
                                              fontSize: 20,
                                            ),
                                            forceTex: false,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: MixedTextMath(
                                            widget.problem!.hint!,
                                            forceTex: true,
                                            labelStyle: const TextStyle(
                                              fontSize: 18,
                                            ),
                                            mathStyle: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ],
                  if (_answerDisplayMode == AnswerDisplayMode.none) ...[
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RepaintBoundary(
                          key: _paintKey,
                          child: _buildScrollableCanvas(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // iPadの場合はツールパレット、それ以外は既存のボタン
        if (_answerDisplayMode == AnswerDisplayMode.none) ...[
          if (isIPad(context))
            _buildIPadToolPalette()
          else ...[
            RepaintBoundary(child: _buildDraggablePenButton()),
            DraggableEraserButton(
              isSelected: _isEraser && !_isScrollMode,
              onTap: () {
                setState(() {
                  _isEraser = !_isEraser;
                  _isScrollMode = false;
                });
                _activeToolNotifier.value = _isEraser ? 'eraser' : 'pen';
              },
            ),
            DraggableScrollButton(
              isSelected: _isScrollMode,
              onTap: () {
                setState(() {
                  _isScrollMode = !_isScrollMode;
                  _isEraser = false;
                });
                _activeToolNotifier.value = _isScrollMode ? 'scroll' : 'pen';
              },
            ),
          ],
        ],
        const DraggableTimer(),
      ],
    );
  }

  // iPad用のツールパレットUI（メモアプリ風）
  Widget _buildIPadToolPalette() {
    if (!_isPaletteVisible) {
      // 完全に非表示の場合は小さなボタンで表示
      final screenSize = MediaQuery.of(context).size;
      return Positioned(
        right: 20,
        bottom: 20,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isPaletteVisible = true;
            });
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[600],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.brush, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final paletteWidth = _isPaletteExpanded ? 600.0 : 56.0;
    final paletteHeight = _isPaletteExpanded ? 120.0 : 56.0; // 2段なので高さを増やす

    // 位置が初期化されていない場合はデフォルト位置を設定（左上位置ベース）
    if (_palettePosition == Offset.zero) {
      _palettePosition = Offset(screenSize.width / 2 - paletteWidth / 2, 100);
    }

    // Positionedウィジェット用の位置計算（左上位置ベース）
    // _palettePosition.dxはleft、_palettePosition.dyはbottomからの距離
    // 展開状態で画面外にはみ出さないように位置を調整
    // 展開時は右端まで移動できるように、クランプの最大値を調整
    // パディング（左右各12px）は内部に含まれるため、paletteWidthで計算可能
    final maxX = screenSize.width - paletteWidth;
    final clampedX = _palettePosition.dx.clamp(0.0, maxX);
    final clampedY = _palettePosition.dy.clamp(
      0.0,
      screenSize.height - paletteHeight,
    );

    // 位置が調整された場合は_palettePositionも更新
    if (_palettePosition.dx != clampedX || _palettePosition.dy != clampedY) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _palettePosition = Offset(clampedX, clampedY);
          });
        }
      });
    }

    return Positioned(
      left: clampedX,
      bottom: clampedY,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isPaletteDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final paletteWidth = _isPaletteExpanded ? 600.0 : 56.0;
            final paletteHeight = _isPaletteExpanded ? 120.0 : 56.0;

            // タイマーと同様に左上位置を直接更新
            final newX = _palettePosition.dx + details.delta.dx;
            // bottom座標なので、Y方向は逆（上に動かすとbottomが減る）
            final newY = _palettePosition.dy - details.delta.dy;

            // 展開時は右端まで移動できるように、クランプの最大値を調整
            // パレットの右端が画面の右端に到達できるようにする
            final maxX = screenSize.width - paletteWidth;

            _palettePosition = Offset(
              newX.clamp(0.0, maxX),
              newY.clamp(0.0, screenSize.height - paletteHeight),
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isPaletteDragging = false;
          });
          _savePalettePosition();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isPaletteExpanded ? 600.0 : 56.0,
          height: _isPaletteExpanded ? 120.0 : 56.0,
          padding: EdgeInsets.symmetric(
            horizontal: _isPaletteExpanded ? 12 : 0,
            vertical: _isPaletteExpanded ? 8 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(_isPaletteExpanded ? 30 : 28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isPaletteExpanded
              ? Stack(
                  children: [
                    // 2段レイアウト
                    SizedBox(
                      width: 600.0 - 24.0, // パディング（左右各12px）を考慮
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 上段: ツール類
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 左側: Undo/Redoボタン
                              _buildUndoRedoButtons(),
                              const SizedBox(width: 12),
                              // 中央: 描画ツール
                              _buildDrawingTools(),
                              const SizedBox(width: 12),
                              // 右端: 追加オプション
                              _buildAdditionalOptions(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 下段: カラーパレット
                          _buildColorPalette(),
                        ],
                      ),
                    ),
                    // 右上に最小化ボタン
                    Positioned(top: 4, right: 4, child: _buildMinimizeButton()),
                  ],
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      final screenSize = MediaQuery.of(context).size;
                      final oldWidth = 56.0;
                      final newWidth = 600.0;

                      // 展開時に右端にはみ出さないように位置を調整
                      final currentLeft = _palettePosition.dx;
                      final maxLeft = screenSize.width - newWidth;
                      _palettePosition = Offset(
                        currentLeft.clamp(0.0, maxLeft),
                        _palettePosition.dy,
                      );

                      _isPaletteExpanded = true;
                    });
                    _savePalettePosition();
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildToolIcon(_currentTool, size: 28),
                  ),
                ),
        ),
      ),
    );
  }

  // Undo/Redoボタン
  Widget _buildUndoRedoButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCircularButton(
          icon: Icons.undo,
          onTap: _undoLastStroke,
          enabled: _strokes.isNotEmpty,
        ),
        const SizedBox(width: 8),
        _buildCircularButton(
          icon: Icons.redo,
          onTap: _redoLastStroke,
          enabled: _redoStack.isNotEmpty,
        ),
      ],
    );
  }

  // 描画ツールセクション
  Widget _buildDrawingTools() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildToolIconButton(DrawingTool.text),
        const SizedBox(width: 4),
        _buildToolIconButton(DrawingTool.pen),
        const SizedBox(width: 4),
        _buildToolIconButton(DrawingTool.marker),
        const SizedBox(width: 4),
        _buildToolIconButton(DrawingTool.strokeEraser),
        const SizedBox(width: 4),
        _buildToolIconButton(DrawingTool.partialEraser),
        const SizedBox(width: 4),
        _buildToolIconButton(DrawingTool.lasso),
      ],
    );
  }

  // カラーパレット
  Widget _buildColorPalette() {
    final presetColors = [
      Colors.black,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.red,
      Colors.orange,
      Colors.grey,
      Colors.brown,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 選択中の色
        _buildColorSwatch(_currentColor, isSelected: true),
        const SizedBox(width: 8),
        // プリセットカラー
        ...presetColors.map(
          (color) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildColorSwatch(color),
          ),
        ),
      ],
    );
  }

  // 追加オプション
  Widget _buildAdditionalOptions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 選択されたオブジェクトがある場合は削除ボタンを表示
        if (_selectedStrokeIndices.isNotEmpty) ...[
          _buildCircularButton(
            icon: Icons.delete_outline,
            onTap: _deleteSelectedStrokes,
          ),
          const SizedBox(width: 8),
        ],
        _buildCircularButton(
          icon: Icons.more_vert,
          onTap: () {
            _showOptionsMenu();
          },
        ),
      ],
    );
  }

  // 選択されたストロークを削除
  void _deleteSelectedStrokes() {
    if (_selectedStrokeIndices.isEmpty) return;

    setState(() {
      // インデックスを降順にソートして削除（インデックスがずれないように）
      final sortedIndices = _selectedStrokeIndices.toList()
        ..sort((a, b) => b.compareTo(a));
      for (final index in sortedIndices) {
        if (index < _strokes.length) {
          _strokes.removeAt(index);
        }
      }
      _selectedStrokeIndices.clear();
      _selectionScale = 1.0;
    });
  }

  // 選択を解除
  void _clearSelection() {
    setState(() {
      _selectedStrokeIndices.clear();
      _selectionScale = 1.0;
      _selectionOffset = null;
      _selectionCenter = null;
    });
  }

  // 最小化ボタン
  Widget _buildMinimizeButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          // 折りたたみ時は位置調整不要（サイズが小さくなるだけ）
          _isPaletteExpanded = false;
        });
        _savePalettePosition();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey[800],
          size: 20,
        ),
      ),
    );
  }

  // 閉じるボタン
  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isPaletteVisible = false;
          _isPaletteExpanded = false;
        });
        _savePalettePosition();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: Icon(Icons.close, color: Colors.grey[800], size: 20),
      ),
    );
  }

  // 円形ボタン
  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.grey[800] : Colors.grey[400],
          size: 20,
        ),
      ),
    );
  }

  // ツールアイコンボタン
  Widget _buildToolIconButton(DrawingTool tool) {
    final isSelected = _currentTool == tool;
    return GestureDetector(
      onTap: () {
        setState(() {
          // ラッソ選択ツール以外に切り替える場合は選択を解除
          if (_currentTool == DrawingTool.lasso && tool != DrawingTool.lasso) {
            _clearSelection();
          }

          // ラッソ選択ツールに切り替える場合は前のツールを保存
          if (tool == DrawingTool.lasso && _currentTool != DrawingTool.lasso) {
            _previousTool = _currentTool;
          }

          _currentTool = tool;
          _isEraser =
              tool == DrawingTool.strokeEraser ||
              tool == DrawingTool.partialEraser;
          _isScrollMode = false;

          // ツールに応じた設定
          switch (tool) {
            case DrawingTool.text:
              _currentStrokeWidth = 2.0;
              _currentColor = Colors.black;
              break;
            case DrawingTool.pen:
              _currentStrokeWidth = 2.5;
              _currentColor = Colors.black;
              break;
            case DrawingTool.marker:
              _currentStrokeWidth = 8.0;
              _currentColor = Colors.yellow[300]!.withOpacity(0.5);
              break;
            case DrawingTool.strokeEraser:
            case DrawingTool.partialEraser:
              break;
            case DrawingTool.lasso:
              // ラッソ選択ツール選択時は描画を無効化
              _isLassoSelecting = false;
              _lassoPath.clear();
              break;
          }
        });
        _activeToolNotifier.value = _isEraser ? 'eraser' : 'pen';
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[300] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildToolIcon(tool, size: 24),
      ),
    );
  }

  // カラースウォッチ
  Widget _buildColorSwatch(Color color, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  // カラーピッカーボタン
  Widget _buildColorPickerButton() {
    return GestureDetector(
      onTap: () {
        _showColorPicker();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.indigo,
              Colors.purple,
            ],
          ),
        ),
      ),
    );
  }

  // オプションメニューを表示
  // Gacha!ページに遷移
  void _navigateToGacha() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UnitGachaPage()),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(_l10n.fingerDrawing),
              trailing: Switch(
                value: _allowFingerDrawing,
                onChanged: (value) {
                  setState(() {
                    _allowFingerDrawing = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // カラーピッカーを表示
  void _showColorPicker() {
    // 簡易的なカラーピッカー（後で改善可能）
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.selectColor),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                [
                      Colors.black,
                      Colors.white,
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.indigo,
                      Colors.purple,
                      Colors.pink,
                      Colors.brown,
                      Colors.grey,
                    ]
                    .map(
                      (color) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentColor = color;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  // ツールアイコンを描画
  Widget _buildToolIcon(DrawingTool tool, {double size = 24}) {
    return CustomPaint(
      size: Size(size, size),
      painter: ToolIconPainter(tool: tool),
    );
  }

  // ドラッグ可能なペンボタン（パレット付き）
  Widget _buildDraggablePenButton() {
    final penSelected = !_isEraser && !_isScrollMode;
    return DraggablePenButton(
      position: _penButtonPosition,
      isSelected: penSelected,
      currentColor: _currentColor,
      currentStrokeWidth: _currentStrokeWidth,
      onPositionChanged: (newPosition) {
        if (_penButtonPosition != newPosition) {
          setState(() {
            _penButtonPosition = newPosition;
          });
          // _saveButtonPositions(); // 一時的に無効化
        }
      },
      onPenModeChanged: () {
        setState(() {
          _isEraser = false;
          _isScrollMode = false;
        });
        _activeToolNotifier.value = 'pen';
      },
      onColorChanged: (color) {
        setState(() {
          _currentColor = color;
          _isEraser = false;
        });
        _activeToolNotifier.value = 'pen';
      },
      onStrokeWidthChanged: (width) {
        setState(() => _currentStrokeWidth = width);
        _activeToolNotifier.value = 'pen';
      },
      activeToolNotifier: _activeToolNotifier,
      isDrawingNotifier: _isDrawingNotifier,
    );
  }

  // スクロールの有効/無効を計算するメソッド
  bool _calculateShouldEnableScroll(bool isIPadDevice) {
    // スクロールモードが有効な場合は常にスクロールを有効化
    if (_isScrollMode) {
      return true;
    }

    // Apple Pencilが使用されている場合はスクロールを無効化
    if (_activePointerKind == PointerDeviceKind.stylus) {
      return false;
    }

    // 指のタッチが使用されている場合はスクロールを有効化
    if (_activePointerKind == PointerDeviceKind.touch) {
      return true;
    }

    // ポインターが離れている場合は、iPadの場合はスクロールを有効化（既存の動作を維持）
    if (_activePointerKind == null && isIPadDevice) {
      return true;
    }

    return false;
  }

  Widget _buildScrollableCanvas() {
    // スクロールの有効/無効を制御
    final isIPadDevice = isIPad(context);
    final shouldEnableScroll = _calculateShouldEnableScroll(isIPadDevice);

    return SingleChildScrollView(
      key: _scrollViewKey,
      controller: _verticalScrollController,
      scrollDirection: Axis.vertical,
      physics: shouldEnableScroll
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        physics: shouldEnableScroll
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: 2000,
          height: 2000,
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: Listener(
              behavior: HitTestBehavior.translucent, // スクロールをブロックしないようにする
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: CustomPaint(
                painter: DrawingPainter(
                  strokes: _strokes,
                  currentStroke: _points,
                  showRuler: false,
                  rulerStart: Offset.zero,
                  rulerEnd: Offset.zero,
                  lassoPath: _isLassoSelecting ? _lassoPath : null,
                  selectedStrokeIndices: _selectedStrokeIndices,
                  selectionBounds: _selectionBounds,
                ),
                size: const Size(2000, 2000),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    // ポインターの種類を記録
    setState(() {
      _activePointerKind = event.kind;
    });

    // iPadの場合はスクロールモードを無効化
    if (_isScrollMode && !isIPad(context)) {
      return;
    }

    // 指で描画が無効で、かつ指のタッチの場合は無視
    if (isIPad(context) &&
        !_allowFingerDrawing &&
        event.kind == PointerDeviceKind.touch) {
      return;
    }

    // 選択されたオブジェクトがある場合の操作（ラッソツールより優先）
    if (_selectedStrokeIndices.isNotEmpty) {
      // バウンディングボックスを更新
      _selectionBounds = _calculateSelectionBounds();
      _selectionCenter = _calculateSelectionCenter();

      // ハンドルがタップされたかを確認（移動処理より優先）
      if (_selectionBounds != null) {
        final handleIndex = _getHandleAtPosition(event.localPosition);
        if (handleIndex != null) {
          // ハンドルをドラッグして拡大縮小開始
          // 元の位置を必ず保存（拡大縮小の基準点として使用）
          _originalStrokePositions.clear();
          for (final index in _selectedStrokeIndices) {
            if (index < _strokes.length && _strokes[index].isNotEmpty) {
              // 各ポイントの位置をコピーして保存
              _originalStrokePositions[index] = _strokes[index]
                  .map((p) => Offset(p.point.dx, p.point.dy))
                  .toList();
            }
          }

          setState(() {
            _selectedHandleIndex = handleIndex;
            _handleDragStart = event.localPosition;
            _selectionOffset = null; // 移動を無効化
            // 元のバウンディングボックスと中心を保存
            _originalSelectionBounds = _selectionBounds;
            _originalSelectionCenter = _selectionCenter;
            // 初期スケールを1.0に設定
            _selectionScale = 1.0;
          });
          return;
        }
      }

      // 選択オブジェクトの移動開始（ハンドルがタップされていない場合のみ）
      _selectionOffset = event.localPosition;
      return;
    }

    // ラッソ選択ツールの場合
    if (_currentTool == DrawingTool.lasso) {
      setState(() {
        _isLassoSelecting = true;
        _lassoPath = [event.localPosition];
        _selectionStart = event.localPosition;
      });
      return;
    }

    // 部分消しゴム（またはストローク消しゴム）の場合、前回位置を記録
    if (_currentTool == DrawingTool.partialEraser ||
        _currentTool == DrawingTool.strokeEraser) {
      setState(() {
        _lastEraserPosition = event.localPosition;
      });
    }

    // スクロールモードでない場合のみ描画を開始
    final pressure = event.pressure;
    final strokeWidth = _calculateStrokeWidth(pressure);

    _isDrawingNotifier.value = true;

    setState(() {
      _points = [
        DrawingPoint(
          event.localPosition,
          _currentColor,
          strokeWidth,
          _currentTool == DrawingTool.strokeEraser ||
              _currentTool == DrawingTool.partialEraser,
        ),
      ];
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    // iPadの場合はスクロールモードを無効化
    if (_isScrollMode && !isIPad(context)) {
      return;
    }

    // 指で描画が無効で、かつ指のタッチの場合は無視
    if (isIPad(context) &&
        !_allowFingerDrawing &&
        event.kind == PointerDeviceKind.touch) {
      return;
    }

    // ラッソ選択中
    if (_currentTool == DrawingTool.lasso && _isLassoSelecting) {
      setState(() {
        _lassoPath.add(event.localPosition);
      });
      return;
    }

    // ハンドルをドラッグして拡大縮小
    if (_selectedStrokeIndices.isNotEmpty &&
        _selectedHandleIndex != null &&
        _handleDragStart != null &&
        _originalSelectionBounds != null &&
        _originalSelectionCenter != null) {
      // 元の位置が存在しない場合は再計算（確実に保存されていることを確認）
      bool needsUpdate = false;
      for (final index in _selectedStrokeIndices) {
        if (index < _strokes.length &&
            !_originalStrokePositions.containsKey(index)) {
          needsUpdate = true;
          break;
        }
      }

      if (needsUpdate || _originalStrokePositions.isEmpty) {
        for (final index in _selectedStrokeIndices) {
          if (index < _strokes.length) {
            _originalStrokePositions[index] = _strokes[index]
                .map((p) => p.point)
                .toList();
          }
        }
      }

      final originalBounds = _originalSelectionBounds!;
      final originalCenter = _originalSelectionCenter!;
      final startPos = _handleDragStart!;
      final currentPos = event.localPosition;

      // 元のバウンディングボックスのハンドル位置を取得
      final originalHandles = [
        Offset(originalBounds.left, originalBounds.top), // 左上
        Offset(originalBounds.right, originalBounds.top), // 右上
        Offset(originalBounds.left, originalBounds.bottom), // 左下
        Offset(originalBounds.right, originalBounds.bottom), // 右下
      ];

      // ドラッグ開始時のハンドル位置（元の位置）
      final handleStartPos = originalHandles[_selectedHandleIndex!];
      // 現在のハンドル位置（ドラッグの移動量を加算）
      final handleCurrentPos = handleStartPos + (currentPos - startPos);

      // 元の中心からの距離でスケールを計算
      final startDistance = (handleStartPos - originalCenter).distance;
      final currentDistance = (handleCurrentPos - originalCenter).distance;

      // 距離が0より大きい場合のみスケールを計算
      if (startDistance > 0.01) {
        // より小さな閾値でゼロ除算を防ぐ
        final scale = (currentDistance / startDistance).clamp(0.5, 3.0);

        // スケールが実際に変化している場合のみ更新
        if ((scale - _selectionScale).abs() > 0.001 || _selectionScale == 1.0) {
          setState(() {
            _selectionScale = scale;
            // 元の位置からスケールを適用
            _scaleSelectedStrokesFromOriginal(scale, originalCenter);
            // バウンディングボックスと中心を更新
            _selectionBounds = _calculateSelectionBounds();
            _selectionCenter = _calculateSelectionCenter();
          });
        }
      }
      return;
    }

    // 選択されたオブジェクトの移動
    if (_selectedStrokeIndices.isNotEmpty && _selectionOffset != null) {
      final delta = event.localPosition - _selectionOffset!;
      setState(() {
        // 選択されたストロークを移動
        for (final index in _selectedStrokeIndices) {
          if (index < _strokes.length) {
            for (final point in _strokes[index]) {
              point.point += delta;
            }
            // 移動後に元の位置を更新
            _originalStrokePositions[index] = _strokes[index]
                .map((p) => p.point)
                .toList();
          }
        }
        _selectionOffset = event.localPosition;
        // バウンディングボックスを更新
        _selectionBounds = _calculateSelectionBounds();
      });
      return;
    }

    final pressure = event.pressure;
    final strokeWidth = _calculateStrokeWidth(pressure);

    if (_currentTool == DrawingTool.strokeEraser ||
        _currentTool == DrawingTool.partialEraser) {
      // ストローク消しゴムも部分消しゴムと同じ挙動にする（ユーザー要望により）
      // 前回位置から現在位置までの軌跡で消去
      if (_lastEraserPosition != null) {
        _eraseBetweenPoints(_lastEraserPosition!, event.localPosition);
      } else {
        _eraseAtPoint(event.localPosition);
      }
      setState(() {
        _lastEraserPosition = event.localPosition;
      });
    } else {
      setState(() {
        _points.add(
          DrawingPoint(event.localPosition, _currentColor, strokeWidth, false),
        );
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _isDrawingNotifier.value = false;

    // ポインターの種類をクリア
    setState(() {
      _activePointerKind = null;
      // 部分消しゴムの位置もクリア
      if (_currentTool == DrawingTool.partialEraser ||
          _currentTool == DrawingTool.strokeEraser) {
        _lastEraserPosition = null;
      }
    });

    // iPadの場合はスクロールモードを無効化
    if (_isScrollMode && !isIPad(context)) {
      return;
    }

    // 指で描画が無効で、かつ指のタッチの場合は無視
    if (isIPad(context) &&
        !_allowFingerDrawing &&
        event.kind == PointerDeviceKind.touch) {
      return;
    }

    // ラッソ選択の終了
    if (_currentTool == DrawingTool.lasso && _isLassoSelecting) {
      setState(() {
        _isLassoSelecting = false;
        if (_lassoPath.length >= 3) {
          _selectStrokesInLasso();
          _selectionScale = 1.0; // 選択時にスケールをリセット
        }
        _lassoPath.clear();
      });
      return;
    }

    // ハンドルドラッグ終了
    if (_selectedStrokeIndices.isNotEmpty && _selectedHandleIndex != null) {
      setState(() {
        // 拡大縮小終了時に元の位置を更新
        for (final index in _selectedStrokeIndices) {
          if (index < _strokes.length) {
            _originalStrokePositions[index] = _strokes[index]
                .map((p) => p.point)
                .toList();
          }
        }
        _selectedHandleIndex = null;
        _handleDragStart = null;
        _selectionScale = 1.0;
        // 元のバウンディングボックスと中心をクリア
        _originalSelectionBounds = null;
        _originalSelectionCenter = null;
        // バウンディングボックスを更新
        _selectionBounds = _calculateSelectionBounds();
        _selectionCenter = _calculateSelectionCenter();
      });
      return;
    }

    // 選択オブジェクトの移動終了
    if (_selectedStrokeIndices.isNotEmpty && _selectionOffset != null) {
      setState(() {
        // 移動終了時に元の位置を更新
        for (final index in _selectedStrokeIndices) {
          if (index < _strokes.length) {
            _originalStrokePositions[index] = _strokes[index]
                .map((p) => p.point)
                .toList();
          }
        }
        _selectionOffset = null;
        // バウンディングボックスを更新
        _selectionBounds = _calculateSelectionBounds();
      });
      return;
    }

    if (_currentTool != DrawingTool.strokeEraser &&
        _currentTool != DrawingTool.partialEraser) {
      setState(() {
        _strokes.add(List.from(_points));
        _points = [];
        _redoStack.clear();
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _isDrawingNotifier.value = false;

    // ポインターの種類をクリア
    setState(() {
      _activePointerKind = null;
      // 部分消しゴムの位置もクリア
      if (_currentTool == DrawingTool.partialEraser ||
          _currentTool == DrawingTool.strokeEraser) {
        _lastEraserPosition = null;
      }
    });

    if (_isScrollMode) {
      return;
    }

    if (!_isEraser && _points.isNotEmpty) {
      setState(() {
        _strokes.add(List.from(_points));
        _points = [];
        _redoStack.clear();
      });
    }
  }

  // ピンチジェスチャー開始
  void _onScaleStart(ScaleStartDetails details) {
    if (_selectedStrokeIndices.isNotEmpty) {
      _initialScale = _selectionScale;
      _selectionCenter = _calculateSelectionCenter();
    }
  }

  // ピンチジェスチャー更新（拡大・縮小）
  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_selectedStrokeIndices.isNotEmpty && _selectionCenter != null) {
      // 元の位置が存在しない場合は再計算
      if (_originalStrokePositions.isEmpty) {
        for (final index in _selectedStrokeIndices) {
          if (index < _strokes.length) {
            _originalStrokePositions[index] = _strokes[index]
                .map((p) => p.point)
                .toList();
          }
        }
      }

      final newScale = (_initialScale * details.scale).clamp(0.5, 3.0);
      setState(() {
        _selectionScale = newScale;
        // 元の位置からスケールを適用
        _scaleSelectedStrokesFromOriginal(newScale, _selectionCenter!);
      });
    }
  }

  // ピンチジェスチャー終了
  void _onScaleEnd(ScaleEndDetails details) {
    if (_selectedStrokeIndices.isNotEmpty) {
      setState(() {
        // 拡大縮小終了時に元の位置を更新
        for (final index in _selectedStrokeIndices) {
          if (index < _strokes.length) {
            _originalStrokePositions[index] = _strokes[index]
                .map((p) => p.point)
                .toList();
          }
        }
        _selectionScale = 1.0; // スケールをリセット
      });
    }
  }

  // 選択されたストロークの中心点を計算
  Offset _calculateSelectionCenter() {
    if (_selectedStrokeIndices.isEmpty) return Offset.zero;

    double totalX = 0;
    double totalY = 0;
    int pointCount = 0;

    for (final index in _selectedStrokeIndices) {
      if (index < _strokes.length) {
        for (final point in _strokes[index]) {
          totalX += point.point.dx;
          totalY += point.point.dy;
          pointCount++;
        }
      }
    }

    if (pointCount == 0) return Offset.zero;
    return Offset(totalX / pointCount, totalY / pointCount);
  }

  // 選択されたオブジェクト全体のバウンディングボックスを計算
  Rect? _calculateSelectionBounds() {
    if (_selectedStrokeIndices.isEmpty) return null;

    double? minX, minY, maxX, maxY;

    for (final index in _selectedStrokeIndices) {
      if (index < _strokes.length) {
        for (final point in _strokes[index]) {
          final x = point.point.dx;
          final y = point.point.dy;
          minX = minX == null ? x : math.min(minX, x);
          minY = minY == null ? y : math.min(minY, y);
          maxX = maxX == null ? x : math.max(maxX, x);
          maxY = maxY == null ? y : math.max(maxY, y);
        }
      }
    }

    if (minX == null || minY == null || maxX == null || maxY == null)
      return null;

    const padding = 8.0;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  // ハンドルがタップされたかを検出（0: 左上、1: 右上、2: 左下、3: 右下）
  int? _getHandleAtPosition(Offset position) {
    if (_selectionBounds == null) return null;

    // ハンドルの検出範囲を広げる（タッチしやすくするため）
    const handleTouchRadius = 20.0; // タッチ検出範囲を20pxに拡大

    final bounds = _selectionBounds!;
    final handles = [
      Offset(bounds.left, bounds.top), // 左上
      Offset(bounds.right, bounds.top), // 右上
      Offset(bounds.left, bounds.bottom), // 左下
      Offset(bounds.right, bounds.bottom), // 右下
    ];

    for (int i = 0; i < handles.length; i++) {
      if ((position - handles[i]).distance <= handleTouchRadius) {
        return i;
      }
    }

    return null;
  }

  // 選択されたストロークをスケール
  void _scaleSelectedStrokes(double scale, Offset center) {
    for (final index in _selectedStrokeIndices) {
      if (index < _strokes.length) {
        for (final point in _strokes[index]) {
          final offset = point.point - center;
          point.point = center + offset * scale;
        }
      }
    }
  }

  // 元の位置からスケールを適用（拡大縮小用）
  void _scaleSelectedStrokesFromOriginal(double scale, Offset center) {
    for (final index in _selectedStrokeIndices) {
      if (index < _strokes.length &&
          _originalStrokePositions.containsKey(index)) {
        final originalPositions = _originalStrokePositions[index]!;
        final stroke = _strokes[index];

        // ストロークと元の位置の長さが一致しない場合の処理
        final minLength = stroke.length < originalPositions.length
            ? stroke.length
            : originalPositions.length;

        for (int i = 0; i < minLength; i++) {
          final originalPoint = originalPositions[i];
          final offset = originalPoint - center;
          stroke[i].point = center + offset * scale;
        }

        // ストロークが元の位置より長い場合、残りのポイントもスケール
        if (stroke.length > originalPositions.length) {
          // 最後の元の位置からのオフセットを使用
          if (originalPositions.isNotEmpty) {
            final lastOriginalPoint = originalPositions.last;
            final lastOffset = lastOriginalPoint - center;
            for (int i = minLength; i < stroke.length; i++) {
              stroke[i].point = center + lastOffset * scale;
            }
          }
        }
      }
    }
  }

  // 部分消しゴム（部分削除）
  void _eraseAtPoint(Offset point) {
    setState(() {
      const eraseRadius = 20.0;
      final List<List<DrawingPoint>> newStrokes = [];

      for (final stroke in _strokes) {
        final List<DrawingPoint> remainingPoints = [];
        bool wasErasing = false;

        for (int i = 0; i < stroke.length; i++) {
          final distance = (stroke[i].point - point).distance;

          if (distance < eraseRadius) {
            // 消しゴムの範囲内のポイントはスキップ
            wasErasing = true;
          } else {
            // 消しゴムの範囲外のポイント
            if (wasErasing && remainingPoints.isNotEmpty) {
              // 前回の消去範囲から離れたので、新しいストロークとして保存
              if (remainingPoints.length > 1) {
                newStrokes.add(List.from(remainingPoints));
              }
              remainingPoints.clear();
            }
            remainingPoints.add(stroke[i]);
            wasErasing = false;
          }
        }

        // 残りのポイントがある場合は追加
        if (remainingPoints.length > 1) {
          newStrokes.add(remainingPoints);
        }
      }

      _strokes = newStrokes;
    });
  }

  // 前回位置から現在位置までの軌跡で消去する
  void _eraseBetweenPoints(Offset startPoint, Offset endPoint) {
    setState(() {
      const eraseRadius = 20.0;
      final List<List<DrawingPoint>> newStrokes = [];

      for (final stroke in _strokes) {
        if (stroke.isEmpty) {
          continue;
        }

        if (stroke.length == 1) {
          // 1点のストロークの場合、消しゴムの軌跡から十分離れている場合のみ保持
          final point = stroke[0].point;
          final distToLine = _pointToLineDistance(point, startPoint, endPoint);
          if (distToLine > eraseRadius) {
            newStrokes.add(stroke);
          }
          continue;
        }

        final List<DrawingPoint> currentSegment = [];
        bool wasErasing = false;

        for (int i = 0; i < stroke.length; i++) {
          final point = stroke[i].point;

          // 消しゴムの軌跡（線分）からポイントへの距離を計算
          final distToLine = _pointToLineDistance(point, startPoint, endPoint);

          // 消しゴムの軌跡の開始点と終了点からの距離もチェック（軌跡の範囲外の場合は無視）
          final distToStart = (point - startPoint).distance;
          final distToEnd = (point - endPoint).distance;

          // 消しゴムの軌跡上の点かどうかを判定（軌跡の線分上にあるか、または軌跡の端点に近いか）
          final isOnTrajectory =
              distToLine < eraseRadius &&
              (distToStart <= (endPoint - startPoint).distance + eraseRadius) &&
              (distToEnd <= (endPoint - startPoint).distance + eraseRadius);

          if (isOnTrajectory) {
            // 消しゴムの範囲内
            if (wasErasing) {
              // 既に消去範囲内にいる場合は何もしない
              continue;
            } else {
              // 消去範囲に入った場合、現在のセグメントを保存
              if (currentSegment.length > 1) {
                newStrokes.add(List.from(currentSegment));
              }
              currentSegment.clear();
              wasErasing = true;
            }
          } else {
            // 消しゴムの範囲外
            if (wasErasing) {
              // 消去範囲から出た場合、新しいセグメントを開始
              currentSegment.add(stroke[i]);
              wasErasing = false;
            } else {
              // 継続中のセグメントに追加
              currentSegment.add(stroke[i]);
            }
          }
        }

        // 最後のセグメントを保存
        if (currentSegment.length > 1) {
          newStrokes.add(currentSegment);
        } else if (currentSegment.length == 1 && stroke.length == 1) {
          // 単一点のストロークの場合
          newStrokes.add(currentSegment);
        }
      }

      _strokes = newStrokes;
    });
  }

  // 2つの線分間の最短距離を計算する
  double _lineSegmentToLineSegmentDistance(
    Offset line1Start,
    Offset line1End,
    Offset line2Start,
    Offset line2End,
  ) {
    // 各線分の端点からもう一方の線分への距離を計算
    final dist1 = _pointToLineDistance(line1Start, line2Start, line2End);
    final dist2 = _pointToLineDistance(line1End, line2Start, line2End);
    final dist3 = _pointToLineDistance(line2Start, line1Start, line1End);
    final dist4 = _pointToLineDistance(line2End, line1Start, line1End);

    // 最小距離を返す
    return [dist1, dist2, dist3, dist4].reduce((a, b) => a < b ? a : b);
  }

  // 点から線分への最短距離を計算する
  double _pointToLineDistance(Offset point, Offset lineStart, Offset lineEnd) {
    final lineVec = lineEnd - lineStart;
    final pointVec = point - lineStart;
    final lineLengthSq = lineVec.distanceSquared;

    if (lineLengthSq < 0.0001) {
      // 線分が点の場合
      return pointVec.distance;
    }

    final t =
        (pointVec.dx * lineVec.dx + pointVec.dy * lineVec.dy) / lineLengthSq;
    final tClamped = t.clamp(0.0, 1.0);
    final closestPoint = lineStart + lineVec * tClamped;

    return (point - closestPoint).distance;
  }

  // 線分と円の交差判定を行う
  bool _lineSegmentIntersectsCircle(
    Offset lineStart,
    Offset lineEnd,
    Offset circleCenter,
    double radius,
  ) {
    // 線分の端点が円内にあるかチェック
    if ((lineStart - circleCenter).distance < radius ||
        (lineEnd - circleCenter).distance < radius) {
      return true;
    }

    // 点から線分への最短距離が半径以下かチェック
    final distance = _pointToLineDistance(circleCenter, lineStart, lineEnd);
    return distance < radius;
  }

  // ストローク消しゴム（ストローク全体を削除）
  void _eraseStrokeAtPoint(Offset point) {
    setState(() {
      const eraseRadius = 20.0;
      _strokes.removeWhere((stroke) {
        return stroke.any((p) => (p.point - point).distance < eraseRadius);
      });
    });
  }

  // ラッソパス内のストロークを選択
  void _selectStrokesInLasso() {
    if (_lassoPath.length < 3) return;

    // ラッソパスを閉じたパスとして扱う
    final lassoPolygon = _lassoPath;
    final selectedIndices = <int>{};

    for (int i = 0; i < _strokes.length; i++) {
      final stroke = _strokes[i];
      // ストロークの各ポイントがラッソパス内にあるかチェック
      bool isInside = false;
      for (final point in stroke) {
        if (_isPointInPolygon(point.point, lassoPolygon)) {
          isInside = true;
          break;
        }
      }
      if (isInside) {
        selectedIndices.add(i);
      }
    }

    setState(() {
      _selectedStrokeIndices = selectedIndices;
      _selectionScale = 1.0; // 選択時にスケールをリセット
      // 元の位置を保存
      _originalStrokePositions.clear();
      for (final index in selectedIndices) {
        if (index < _strokes.length) {
          _originalStrokePositions[index] = _strokes[index]
              .map((p) => p.point)
              .toList();
        }
      }
      // バウンディングボックスを更新
      _selectionBounds = _calculateSelectionBounds();
      _selectionCenter = _calculateSelectionCenter();
    });
  }

  // ポイントがポリゴン内にあるかチェック（Ray Casting Algorithm）
  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;

      final intersect =
          ((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
      j = i;
    }

    return inside;
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _points.clear();
      _undoStack.clear();
      _redoStack.clear();
      _selectedStrokeIndices.clear();
      _lassoPath.clear();
    });
  }

  void _undoLastStroke() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _redoStack.add(_strokes.removeLast());
      });
    }
  }

  void _redoLastStroke() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_redoStack.removeLast());
      });
    }
  }

  Future<void> _saveImage() async {
    if (kIsWeb) {
      _showSnackBar(_l10n.saveFailed('Webでは画像保存に未対応です。'));
      return;
    }
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackBar(_l10n.storagePermissionRequired);
        return;
      }

      final RenderRepaintBoundary boundary =
          _paintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = await savePngToDocuments(
        pngBytes,
        'scratch_paper_$timestamp.png',
      );

      _showSnackBar(_l10n.imageSaved(path));
    } catch (e) {
      _showSnackBar(_l10n.saveFailed(e.toString()));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _cycleLearningStatus() {
    setState(() {
      _learningStatus = _learningStatus.next;
    });
  }

  Future<void> _saveLearningRecord() async {
    if (widget.problem == null || _learningStatus == LearningStatus.none)
      return;

    try {
      ProblemStatus problemStatus;
      switch (_learningStatus) {
        case LearningStatus.solved:
          problemStatus = ProblemStatus.solved;
          break;
        case LearningStatus.failed:
          problemStatus = ProblemStatus.failed;
          break;
        case LearningStatus.none:
        default:
          problemStatus = ProblemStatus.none;
          break;
      }

      final success = await SimpleDataManager.saveLearningRecord(
        widget.problem!,
        problemStatus,
      );

      if (success) {
        _showSnackBar(_l10n.learningRecordSaved);
        Navigator.pop(context, true);
      } else {
        _showSnackBar(_l10n.learningRecordSaveFailed);
      }
    } catch (e) {
      print('Error saving learning record: $e');
      _showSnackBar(_l10n.learningRecordSaveFailed);
    }
  }
}

class DrawingPoint {
  Offset point;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DrawingPoint(this.point, this.color, this.strokeWidth, this.isEraser);
}

// ツールアイコンを描画するCustomPainter
class ToolIconPainter extends CustomPainter {
  final DrawingTool tool;

  ToolIconPainter({required this.tool});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    switch (tool) {
      case DrawingTool.text:
        // テキストツール: ペンのようなアイコンに'A'
        paint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        // 'A'を描画
        final textPainter = TextPainter(
          text: const TextSpan(
            text: 'A',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(size.width * 0.35, size.height * 0.25),
        );
        break;

      case DrawingTool.pen:
        // 太いペン: 太い先端
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // 太い線を描画
        paint.color = Colors.grey[800]!;
        canvas.drawLine(
          Offset(size.width * 0.25, size.height * 0.5),
          Offset(size.width * 0.75, size.height * 0.5),
          paint..strokeWidth = 3,
        );
        // 太い先端
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.85),
          3,
          paint,
        );
        break;

      case DrawingTool.marker:
        // ハイライター: チャイゼル型の先端、半透明の青い帯
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // 青い帯
        paint.color = Colors.blue.withOpacity(0.3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.25,
              size.height * 0.3,
              size.width * 0.5,
              size.height * 0.3,
            ),
            const Radius.circular(1),
          ),
          paint,
        );
        // チャイゼル型の先端
        final path = Path();
        path.moveTo(size.width * 0.3, size.height * 0.85);
        path.lineTo(size.width * 0.7, size.height * 0.85);
        path.lineTo(size.width * 0.65, size.height * 0.95);
        path.lineTo(size.width * 0.35, size.height * 0.95);
        path.close();
        paint.color = Colors.blue[300]!.withOpacity(0.5);
        canvas.drawPath(path, paint);
        break;

      case DrawingTool.strokeEraser:
        // ストローク消しゴム: ピンクの先端
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // ピンクの先端
        paint.color = Colors.pink[300]!;
        canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.85),
          4,
          paint,
        );
        break;

      case DrawingTool.partialEraser:
        // 部分消しゴム: 斜めのストライプパターン
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // 斜めのストライプ
        strokePaint.color = Colors.grey[400]!;
        strokePaint.strokeWidth = 1;
        for (int i = 0; i < 5; i++) {
          final y = size.height * 0.2 + (i * size.height * 0.15);
          canvas.drawLine(
            Offset(size.width * 0.25, y),
            Offset(size.width * 0.75, y + size.height * 0.2),
            strokePaint,
          );
        }
        break;

      case DrawingTool.lasso:
        // ラッソ選択ツール: 輪っかのアイコン
        paint.color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        strokePaint.color = Colors.grey[800]!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.2,
              size.height * 0.1,
              size.width * 0.6,
              size.height * 0.7,
            ),
            const Radius.circular(2),
          ),
          strokePaint,
        );
        // 輪っかのパス
        strokePaint.color = Colors.blue[600]!;
        strokePaint.strokeWidth = 2;
        final lassoPath = Path();
        lassoPath.moveTo(size.width * 0.3, size.height * 0.3);
        lassoPath.quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.2,
          size.width * 0.7,
          size.height * 0.3,
        );
        lassoPath.quadraticBezierTo(
          size.width * 0.8,
          size.height * 0.5,
          size.width * 0.7,
          size.height * 0.7,
        );
        lassoPath.quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.8,
          size.width * 0.3,
          size.height * 0.7,
        );
        lassoPath.quadraticBezierTo(
          size.width * 0.2,
          size.height * 0.5,
          size.width * 0.3,
          size.height * 0.3,
        );
        canvas.drawPath(lassoPath, strokePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DrawingPainter extends CustomPainter {
  final List<List<DrawingPoint>> strokes;
  final List<DrawingPoint> currentStroke;
  final bool showRuler;
  final Offset rulerStart;
  final Offset rulerEnd;
  final List<Offset>? lassoPath;
  final Set<int> selectedStrokeIndices;
  final Rect? selectionBounds;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    this.showRuler = false,
    this.rulerStart = Offset.zero,
    this.rulerEnd = Offset.zero,
    this.lassoPath,
    this.selectedStrokeIndices = const {},
    this.selectionBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 定規を描画
    if (showRuler && rulerStart != Offset.zero && rulerEnd != Offset.zero) {
      _drawRuler(canvas);
    }

    // ストロークを描画
    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final isSelected = selectedStrokeIndices.contains(i);
      _drawStroke(canvas, stroke, isSelected: isSelected);
    }
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke);
    }

    // ラッソパスを描画
    if (lassoPath != null && lassoPath!.length >= 2) {
      _drawLassoPath(canvas);
    }

    // 選択されたストロークのハイライト
    if (selectedStrokeIndices.isNotEmpty) {
      _drawSelectionHighlight(canvas);
    }
  }

  void _drawLassoPath(Canvas canvas) {
    if (lassoPath == null || lassoPath!.length < 2) return;

    final lassoPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 点線を描画
    const dashWidth = 8.0;
    const dashSpace = 4.0;

    for (int i = 0; i < lassoPath!.length - 1; i++) {
      final start = lassoPath![i];
      final end = lassoPath![i + 1];
      final distance = (end - start).distance;
      final direction = (end - start) / distance;

      double currentDistance = 0.0;
      while (currentDistance < distance) {
        final dashStart = start + direction * currentDistance;
        final dashEnd =
            start + direction * math.min(currentDistance + dashWidth, distance);
        canvas.drawLine(dashStart, dashEnd, lassoPaint);
        currentDistance += dashWidth + dashSpace;
      }
    }
  }

  void _drawSelectionHighlight(Canvas canvas) {
    if (selectedStrokeIndices.isEmpty) return;

    // 全体のバウンディングボックスを使用
    final bounds = selectionBounds;
    if (bounds == null) return;

    final highlightPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // ハイライトを描画
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(4)),
      highlightPaint,
    );

    // 選択ハンドルを描画（4つの角に小さな丸）
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    const handleSize = 12.0;
    const handleRadius = handleSize / 2;

    // 左上、右上、左下、右下の順
    canvas.drawCircle(
      Offset(bounds.left, bounds.top),
      handleRadius,
      handlePaint,
    );
    canvas.drawCircle(
      Offset(bounds.right, bounds.top),
      handleRadius,
      handlePaint,
    );
    canvas.drawCircle(
      Offset(bounds.left, bounds.bottom),
      handleRadius,
      handlePaint,
    );
    canvas.drawCircle(
      Offset(bounds.right, bounds.bottom),
      handleRadius,
      handlePaint,
    );
  }

  void _drawRuler(Canvas canvas) {
    final rulerPaint = Paint()
      ..color = Colors.grey[400]!.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rulerFillPaint = Paint()
      ..color = Colors.grey[200]!.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // 定規の線
    final rulerPath = Path()
      ..moveTo(rulerStart.dx, rulerStart.dy)
      ..lineTo(rulerEnd.dx, rulerEnd.dy);

    // 定規の幅
    final rulerWidth = 40.0;
    final angle = (rulerEnd - rulerStart).direction;
    final perpendicular = Offset(
      -rulerWidth * 0.5 * math.sin(angle),
      rulerWidth * 0.5 * math.cos(angle),
    );

    final rulerRect = Path()
      ..moveTo(
        rulerStart.dx + perpendicular.dx,
        rulerStart.dy + perpendicular.dy,
      )
      ..lineTo(rulerEnd.dx + perpendicular.dx, rulerEnd.dy + perpendicular.dy)
      ..lineTo(rulerEnd.dx - perpendicular.dx, rulerEnd.dy - perpendicular.dy)
      ..lineTo(
        rulerStart.dx - perpendicular.dx,
        rulerStart.dy - perpendicular.dy,
      )
      ..close();

    canvas.drawPath(rulerRect, rulerFillPaint);
    canvas.drawPath(rulerPath, rulerPaint);

    // 目盛りを描画
    final tickPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1;

    final rulerLength = (rulerEnd - rulerStart).distance;
    final tickCount = (rulerLength / 20).floor();

    for (int i = 0; i <= tickCount; i++) {
      final t = i / tickCount;
      final tickPos = Offset.lerp(rulerStart, rulerEnd, t)!;
      final tickLength = i % 5 == 0 ? 15.0 : 8.0;
      final tickStart = tickPos + perpendicular * (tickLength / rulerWidth);
      final tickEnd = tickPos - perpendicular * (tickLength / rulerWidth);
      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }
  }

  void _drawStroke(
    Canvas canvas,
    List<DrawingPoint> stroke, {
    bool isSelected = false,
  }) {
    if (stroke.length < 2) return;

    for (int i = 0; i < stroke.length - 1; i++) {
      final point1 = stroke[i];
      final point2 = stroke[i + 1];

      final paint = Paint()
        ..color = point1.isEraser ? Colors.white : point1.color
        ..strokeWidth = point1.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (point1.isEraser) {
        paint.blendMode = BlendMode.clear;
      }

      // 選択されている場合は少し濃く描画
      if (isSelected && !point1.isEraser) {
        paint.color = paint.color.withOpacity(
          math.min(1.0, paint.color.opacity + 0.2),
        );
      }

      canvas.drawLine(point1.point, point2.point, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Firebaseクラウドデータとの同期ボタン
class _SyncButton extends StatefulWidget {
  const _SyncButton();

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> {
  bool _isSyncing = false;

  Future<void> _performSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      // ローカルデータをFirestoreに同期（並列実行で高速化）
      final results = await Future.wait([
        SimpleDataManager.syncLocalDataToFirestore(),
        SimpleDataManager.syncLocalSettingsToFirestore(),
      ], eagerError: false);

      // Firestoreからデータを取得してマージ（エラーが発生しても続行）
      try {
        await SimpleDataManager.initialize();
      } catch (e) {
        print('Warning: Error initializing from Firestore: $e');
        // 初期化エラーは無視（ローカルデータは既に同期済み）
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('クラウドデータとの同期が完了しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error syncing: $e');
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        final message = errorStr.contains('permission')
            ? 'Firestoreへのアクセス権限がありません。設定を確認してください。'
            : '同期中にエラーが発生しました。一部のデータは同期されていない可能性があります。';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        iconSize: 24.0,
        icon: _isSyncing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.cloud_sync, color: Colors.white, size: 24.0),
        onPressed: _isSyncing ? null : _performSync,
        tooltip: 'クラウドデータと同期',
      ),
    );
  }
}
