// lib/pages/tutorial/tutorial_page.dart
// 初回ダウンロード時のチュートリアルページ

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localizations.dart';
import '../../localization/app_locale.dart';
import '../../problems/unit/symbol.dart';
import '../../problems/unit/mechanics_problems.dart'
    show tutorialGravityUnitProblem, gravityAccelerationExprProblem;
import '../../problems/unit/unit_gacha_item.dart' show UnitGachaItem;
import '../../widgets/unit/unit_calculator.dart';
import '../../services/calculator/unit_calculator_service.dart';
import '../../services/problems/simple_data_manager.dart';
import '../../models/math_problem.dart';
import '../common/common.dart' show MixedTextMath;
import '../common/problem_status.dart';
import '../common/tablet_utils.dart';
import '../../widgets/home/background_image_widget.dart';
import '../gacha/pages/unit_gacha_page.dart';
import '../gacha/formatting/unit_formatters.dart';
import '../gacha/ui/builders/answer_display_builder.dart'
    show AnswerDisplayBuilder;
import '../gacha/ui/builders/problem_card_builder.dart' show ProblemCardBuilder;

/// チュートリアルページ
class TutorialPage extends StatefulWidget {
  const TutorialPage({Key? key}) : super(key: key);

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  int _currentStep = 0; // 0: アプリ説明, 1: 電卓説明, 2: 指数法則, 3: 実際に解答
  static const int _totalSteps = 4;
  String _userInput = '';
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isCompletingTutorial = false;
  Future<void>? _pendingHistorySave;
  late AppLocalizations _l10n;
  late AnswerDisplayBuilder _answerDisplayBuilder;
  late ProblemCardBuilder _problemCardBuilder;
  Timer? _highlightTimer;
  String? _highlightedButtonText; // 点灯させるボタンのテキスト
  String? _displayText; // 入力欄に表示するテキスト
  bool _highlightConfirmButton = false; // 確定ボタンを点灯させるか
  bool _disableButtons = false; // ACボタンと確定ボタンを無効化するか

  bool get _isEnglishUi => AppLocale.isEnglish(context);

  // チュートリアル用の問題（重力加速度 g）
  // mechanics_problems.dart の定義を参照して、チュートリアルと本編の問題プールで共有する。
  static const UnitProblem _tutorialProblem = tutorialGravityUnitProblem;

  // チュートリアル用のMathProblem（学習履歴保存用）
  static MathProblem get _tutorialMathProblem {
    return MathProblem(
      id: _tutorialProblem.id,
      no: "tutorial-1",
      category: "mechanics",
      level: "basic",
      question: r"g\text{（重力加速度）の単位を答えよ。}",
      answer: r"m \cdot s^{-2}",
      steps: [],
    );
  }

  @override
  void initState() {
    super.initState();
    _startHighlightAnimation();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    _answerDisplayBuilder = AnswerDisplayBuilder(_l10n);
    _problemCardBuilder = ProblemCardBuilder(_l10n);
  }

  void _startHighlightAnimation() {
    _highlightTimer?.cancel();
    if (_currentStep == 2) {
      // 3/4ページの場合のみ
      int index = 0;
      // シーケンス: m点灯(0.6秒) → 通常(0.3秒) → s^-1点灯(0.6秒) → 通常(0.3秒) → s^-1点灯(0.6秒) → 通常(0.3秒) → 確定ボタン点灯(0.6秒) → ボタン無効化状態(1.2秒) → リセット(0.3秒) → ループ
      // 各要素は0.3秒間隔
      final buttonSequence = [
        'm',
        'm',
        null,
        's^-1',
        's^-1',
        null,
        's^-1',
        's^-1',
        null,
        'confirm',
        'confirm',
        'disabled',
        'disabled',
        'disabled',
        'disabled',
        null,
      ];
      final textSequence = [
        'm ',
        'm ',
        'm ',
        'm s^-1 ',
        'm s^-1 ',
        'm s^-1 ',
        'm s^-2 ',
        'm s^-2 ',
        'm s^-2 ',
        'm s^-2 ',
        'm s^-2 ',
        '',
        '',
        '',
        '',
        '',
      ];
      _highlightTimer = Timer.periodic(const Duration(milliseconds: 300), (
        timer,
      ) {
        if (mounted) {
          setState(() {
            final button = buttonSequence[index];
            _highlightedButtonText =
                (button == 'confirm' || button == 'disabled') ? null : button;
            _highlightConfirmButton = (button == 'confirm');
            _disableButtons = (button == 'disabled');
            _displayText = textSequence[index];
            index = (index + 1) % buttonSequence.length;
          });
        }
      });
    } else {
      _highlightedButtonText = null;
      _displayText = null;
      _highlightConfirmButton = false;
      _disableButtons = false;
    }
  }

  void _handleAnswer(String input) {
    if (_isAnswered) {
      debugPrint('チュートリアル解答: 既に解答済みのためスキップ');
      return;
    }

    debugPrint('チュートリアル解答処理開始: input="$input"');

    // 正解の単位を計算
    final correctUnit = NormalizedUnit.fromString(_tutorialProblem.answer);

    // 入力と正解を比較
    bool isCorrect;
    try {
      final userUnit = NormalizedUnit.fromString(input.trim());
      isCorrect = userUnit.equals(correctUnit);
      debugPrint('チュートリアル解答判定: isCorrect=$isCorrect');
    } catch (e) {
      isCorrect = false;
      debugPrint('チュートリアル解答判定エラー: $e');
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _userInput = input;
    });

    // チュートリアル用の学習履歴を保存（無課金でも保存）
    debugPrint('チュートリアル履歴保存を開始: isCorrect=$isCorrect');
    _pendingHistorySave = _saveTutorialHistory(isCorrect);
  }

  Future<void> _showTutorialCompleteDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            _isEnglishUi ? 'Tutorial Complete!' : 'チュートリアル完了！',
            style: TextStyle(
              fontSize: _isEnglishUi ? 22 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B7355),
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            _isEnglishUi
                ? 'Your answer has been automatically registered in your learning history. Please check it in the list.\n\nEnjoy Unit Gacha!'
                : '解答は自動的に学習履歴に登録されます。一覧で確認してみてくださいね。\n\nそれでは、Unit Gachaをお楽しみ下さい!',
            style: TextStyle(
              // 英語本文が小さめだったので、他の文脈（例: "Correct!"）と同程度に寄せる
              fontSize: _isEnglishUi ? 18 : 16,
              color: Colors.grey[800],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEnglishUi ? 'OK' : 'OK',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// チュートリアル用の学習履歴を保存（無課金でも保存される例外処理）
  Future<void> _saveTutorialHistory(bool isCorrect) async {
    try {
      final status = isCorrect ? ProblemStatus.solved : ProblemStatus.failed;
      debugPrint('チュートリアル履歴保存開始: isCorrect=$isCorrect, status=$status');

      final success = await SimpleDataManager.saveLearningRecord(
        _tutorialMathProblem,
        status,
      );
      if (success) {
        debugPrint(
          'チュートリアル履歴保存成功: problemId=${_tutorialMathProblem.id}, status=$status',
        );
      } else {
        debugPrint('警告: チュートリアル履歴保存が失敗しました');
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving tutorial learning history: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _startHighlightAnimation();
    } else {
      // チュートリアル完了
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _startHighlightAnimation();
    }
  }

  Future<void> _completeTutorial() async {
    // 二重タップ等で多重遷移しないようガード
    if (_isCompletingTutorial) return;
    _isCompletingTutorial = true;

    // 履歴保存が走っている場合は完了前に待つ（次画面で「記録されない」ように見えるのを防ぐ）
    try {
      await _pendingHistorySave;
    } catch (_) {
      // 保存失敗はチュートリアル完了自体は妨げない
    }

    // 「解いた直後」ではなく「完了ボタン押下時」にモーダルを出す
    if (mounted) {
      await _showTutorialCompleteDialog();
    }
    if (!mounted) return;

    // チュートリアル完了フラグを保存
    await _markTutorialCompleted();
    if (!mounted) return;

    // メインページに遷移
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const UnitGachaPage()),
    );
  }

  Future<void> _markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundImageWidget(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // ページ番号
                  Text(
                    _isEnglishUi
                        ? 'Tutorial ${_currentStep + 1}/$_totalSteps'
                        : 'チュートリアル ${_currentStep + 1}/$_totalSteps',
                    style: TextStyle(
                      fontSize: _isEnglishUi ? 18 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // タイトル
                  Text(
                    _currentStep == 0
                        ? (_isEnglishUi
                              ? 'Welcome to Unit Gacha!'
                              : 'Unit Gachaへようこそ！')
                        : _currentStep == 1
                        ? (_isEnglishUi
                              ? 'How to Answer Unit Problems'
                              : '単位問題の解答方法')
                        : _currentStep == 2
                        ? (_isEnglishUi
                              ? 'Calculator Input and Exponent Laws'
                              : '電卓入力と指数法則')
                        : (_isEnglishUi ? 'Try the Problem' : '問題に挑戦'),
                    style: TextStyle(
                      fontSize: _isEnglishUi ? 30 : 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B7355),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ステップごとの説明
                  _buildStepContent(),
                  const SizedBox(height: 24),
                  // 次へボタン（ステップ0-2）または解答ボタン（ステップ3）
                  if (_currentStep < _totalSteps - 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 戻るボタン
                        if (_currentStep > 0)
                          ElevatedButton(
                            onPressed: _previousStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isEnglishUi ? 'Back' : '戻る',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 16),
                        // 次へボタン
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isEnglishUi ? 'Next' : '次へ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    _buildProblemSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildAppIntroduction();
      case 1:
        return _buildCalculatorExplanation();
      case 2:
        return _buildUnitInputExplanation();
      case 3:
        return const SizedBox.shrink(); // 4/4は問題セクションを表示
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUnitInputExplanation() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isEnglishUi
                  ? Text(
                      'Units entered in the calculator are combined using exponent laws.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(text: '電卓における単位入力は、'),
                          TextSpan(
                            text: '指数法則を用いて',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: '結合されます。例えば加速度なら、\n\n'),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Math.tex(
                              'm',
                              textStyle: const TextStyle(fontSize: 20),
                              mathStyle: MathStyle.text,
                            ),
                          ),
                          const TextSpan(text: '(メートル)を1回と'),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Math.tex(
                              's^{-1}',
                              textStyle: const TextStyle(fontSize: 20),
                              mathStyle: MathStyle.text,
                            ),
                          ),
                          const TextSpan(text: '(毎秒)を'),
                          TextSpan(
                            text: '2回入力して',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: '解答します。'),
                        ],
                      ),
                    ),
              const SizedBox(height: 24),
              // 例: m/s^2 = m s^-2
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Math.tex(
                        r'\begin{aligned} \frac{m}{s^2} &=  m \cdot s^{-2} \end{aligned}',
                        textStyle: TextStyle(fontSize: _isEnglishUi ? 28 : 26),
                        mathStyle: MathStyle.display,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 電卓を表示（アニメーション付き）
        UnitCalculator(
          key: const ValueKey('tutorial_calculator_animation'),
          type: CalculatorType.baseUnits,
          selectedAnswer: _tutorialProblem,
          onEnter: (_) {}, // チュートリアル表示用なので空のハンドラー
          isAnswered: false,
          highlightedButtonText: _highlightedButtonText,
          displayText: _displayText,
          highlightConfirmButton: _highlightConfirmButton,
          disableButtons: _disableButtons,
        ),
      ],
    );
  }

  Widget _buildAppIntroduction() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEnglishUi ? 'About This App' : 'このアプリについて',
                style: TextStyle(
                  fontSize: _isEnglishUi ? 22 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 16),
              _isEnglishUi
                  ? Text(
                      'Unit Gacha is an app for learning physics units.\n\n'
                      'Derive units from formulas and answer by entering units using the calculator.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[800],
                        height: 1.6,
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Unit Gachaは物理の単位を学ぶためのアプリです。\n\n出題された数式の単位を',
                          ),
                          TextSpan(
                            text: '電卓入力',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.6,
                            ),
                          ),
                          const TextSpan(text: 'で解答します。'),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorExplanation() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEnglishUi
                    ? 'Units are answered using the calculator below.'
                    : '単位の解答は、下記のような電卓を用いて行います。',
                style: TextStyle(
                  fontSize: _isEnglishUi ? 18 : 16,
                  color: Colors.grey[800],
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 電卓を表示（homeと同様に）
        UnitCalculator(
          key: const ValueKey('tutorial_calculator_demo'),
          type: CalculatorType.baseUnits,
          selectedAnswer: _tutorialProblem,
          onEnter: (_) {}, // チュートリアル表示用なので空のハンドラー
          isAnswered: false,
        ),
      ],
    );
  }

  Widget _buildProblemSection() {
    // Home（unit gacha）と同じカード幅レンジに合わせる（layout_builder.dart の通常モードと同等）
    final baseCardWidth = (MediaQuery.of(context).size.width - 48).clamp(
      280.0,
      360.0,
    );
    final item = UnitGachaItem(
      exprProblem: gravityAccelerationExprProblem,
      unitProblem: _tutorialProblem,
    );

    return Column(
      children: [
        // 問題カード
        Center(
          child: _problemCardBuilder.buildProblemCard(
            context: context,
            item: item,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            // Homeと同じ「ベース幅」を渡す（内部でTabletUtils.cardScaleが適用される）
            cardWidth: baseCardWidth,
            // Homeの通常モードと同じ
            fontSize: 52,
            isScratchPaperMode: false,
            answerDisplay: _isAnswered
                ? _answerDisplayBuilder.buildAnswerDisplay(
                    problem: _tutorialProblem,
                    correctAnswer: _tutorialProblem.answer,
                    isCorrect: _isCorrect,
                    isAnswered: _isAnswered,
                  )
                : null,
          ),
        ),
        SizedBox(height: TabletUtils.cardSpacing(context)),
        // 電卓（電卓ウィジェット内でタブレット対応済みのため、Transform.scaleは不要）
        UnitCalculator(
          key: const ValueKey('tutorial_calculator'),
          type: CalculatorType.baseUnits,
          selectedAnswer: _tutorialProblem,
          onEnter: _handleAnswer,
          isAnswered: _isAnswered,
          onNext: _isAnswered ? _completeTutorial : null,
          nextButtonText: _isEnglishUi ? 'Complete Tutorial' : 'チュートリアルを完了',
        ),
        const SizedBox(height: 24),
        // 戻るボタン
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _previousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEnglishUi ? 'Back' : '戻る',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
