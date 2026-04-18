// lib/pages/gacha/ui/builders/layout_builder.dart
// レイアウト構築

import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../localization/app_locale.dart';
import '../../../../problems/unit/unit_gacha_item.dart' show UnitGachaItem;
import '../../../../widgets/timer/timer_display.dart';
import '../../../../managers/timer_manager.dart';
import '../../../../widgets/common/expandable_calculator_wrapper.dart';
import '../../../../widgets/drawing/drawing_canvas.dart';
import '../../../../widgets/drawing/draggable_tool_buttons.dart' show DraggablePenButton;
import '../../../../widgets/drawing/draggable_eraser_button.dart';
import '../../../../widgets/drawing/draggable_scroll_button.dart';
import '../../../../widgets/drawing/draggable_calculator_button.dart';
import '../../../common/tablet_utils.dart';
import '../../../other/scratch_paper_page.dart' show isIPad;
import '../../drawing/unit_gacha_drawing_tools.dart' show DrawingTool, DrawingToolState;
import '../palette/unit_gacha_ipad_palette.dart' show UnitGachaIPadPalette;
import '../widgets/tilt_rotate_button.dart' show TiltRotateButton;
import 'problem_card_builder.dart' show ProblemCardBuilder;
import 'answer_display_builder.dart' show AnswerDisplayBuilder;
import 'action_buttons_builder.dart' show ActionButtonsBuilder;

class LayoutBuilder {
  final AppLocalizations _l10n;
  final TimerManager _timerManager;
  final ProblemCardBuilder _problemCardBuilder;
  final AnswerDisplayBuilder _answerDisplayBuilder;
  final ActionButtonsBuilder _actionButtonsBuilder;
  
  LayoutBuilder(
    this._l10n,
    this._timerManager,
    this._problemCardBuilder,
    this._answerDisplayBuilder,
    this._actionButtonsBuilder,
  );
  
  Widget buildEmptyPoolContent({
    required bool isLocked,
    required AppLocalizations l10n,
    required BuildContext context,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked ? Icons.lock : Icons.check_circle_outline,
              size: 42,
              color: isLocked ? Colors.black54 : Colors.green.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              isLocked
                  ? (AppLocale.isEnglish(context)
                      ? 'This content is locked.'
                      : '選択中の単元は購入が必要です。')
                  : l10n.allProblemsSolved,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNormalModeBody({
    required UnitGachaItem item,
    required String correctAnswer,
    required bool isAnswered,
    required bool isCorrect,
    required int currentProblemIndex,
    required int selectedProblemsLength,
    required VoidCallback onRefreshProblems,
    required VoidCallback onNextProblem,
    required BuildContext context,
  }) {
    final problem = item.unitProblem;
    final lang = AppLocale.languageCodeFromL10n(_l10n);
    // カードの横幅は固定(320)だと余白が目立つので、画面幅に合わせて少し広げる
    final cardWidth =
        (MediaQuery.of(context).size.width - 48).clamp(280.0, 360.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          // 外側の左右余白を少し減らして、カード内により多くの文字が収まるようにする
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _problemCardBuilder.buildProblemCard(
                      context: context,
                      item: item,
                      isAnswered: isAnswered,
                      isCorrect: isCorrect,
                      cardWidth: cardWidth,
                      fontSize: 52,
                      isScratchPaperMode: false,
                      answerDisplay: isAnswered
                          ? _answerDisplayBuilder.buildAnswerDisplay(
                              problem: problem,
                              correctAnswer: correctAnswer,
                              isCorrect: isCorrect,
                              isAnswered: isAnswered,
                            )
                          : null,
                      actionButtons: isAnswered
                          ? _actionButtonsBuilder.buildActionButtons(
                              onNext: onNextProblem,
                              isLastProblem: currentProblemIndex >= selectedProblemsLength - 1,
                              point: problem.localizedPoint(lang),
                            )
                          : null,
                    ),
                    if (isAnswered)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _answerDisplayBuilder.buildAnswerMark(
                            isCorrect: isCorrect,
                            isAnswered: isAnswered,
                          ),
                        ),
                      ),
                    if (!isAnswered)
                      Positioned(
                        top: 75,
                        right: -8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TiltRotateButton(
                              onPressed: onRefreshProblems,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: TabletUtils.isTablet(context) ? 24 : 16,
                                  vertical: 10,
                                ),
                                backgroundColor: Colors.purple.shade300,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                textStyle: TextStyle(
                                  fontSize: TabletUtils.isTablet(context) ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Text(_l10n.buttonGacha),
                            ),
                          ],
                          ),
                        ),
                    ],
                  ),
              ),
              const SizedBox(height: 16),
              // 電卓は unit_gacha_page.dart で構築されるため、ここではスペースのみ
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget buildScratchPaperModeBody({
    required UnitGachaItem item,
    required String correctAnswer,
    required bool isAnswered,
    required bool isCorrect,
    required int currentProblemIndex,
    required int selectedProblemsLength,
    required bool isCalculatorExpanded,
    required DrawingToolState drawingToolState,
    required ValueNotifier<bool> isDrawingNotifier,
    required ValueNotifier<String> activeToolNotifier,
    required Offset penButtonPosition,
    required Widget header,
    required Widget calculator,
    required VoidCallback onRefreshProblems,
    required VoidCallback onNextProblem,
    required ValueChanged<Offset> onPenPositionChanged,
    required VoidCallback onPenModeChanged,
    required ValueChanged<Color> onColorChanged,
    required ValueChanged<double> onStrokeWidthChanged,
    required VoidCallback onEraserToggle,
    required VoidCallback onScrollToggle,
    required VoidCallback onCalculatorToggle,
    required VoidCallback onStateChanged,
    required BuildContext context,
  }) {
    final problem = item.unitProblem;
    final lang = AppLocale.languageCodeFromL10n(_l10n);
    final isIPadDevice = isIPad(context);
    final cardWidth =
        (MediaQuery.of(context).size.width - 48).clamp(300.0, 380.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: isDrawingNotifier,
          builder: (context, isDrawing, child) {
            return SingleChildScrollView(
              physics: isDrawing && !drawingToolState.isScrollMode
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              // 計算用紙モードでもヘッダーはフル幅で表示（ボタン間隔が狭くならないように）
              // それ以外のコンテンツは従来通り左右に余白を付ける
              // ヘルプページ等と同じく、ヘッダー上の余白を増やさない
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: Column(
                children: [
                  header,
                  // homeモードと同程度の余白に合わせる
                  const SizedBox(height: 16),
                  Padding(
                    // 外側の左右余白を少し減らして、カード内により多くの文字が収まるようにする
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        if (_timerManager.isTimerEnabled)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: SizedBox(
                                width: 320,
                                child: TimerDisplay(timerManager: _timerManager),
                              ),
                            ),
                          ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _problemCardBuilder.buildHorizontalCard(
                              item: item,
                              isAnswered: isAnswered,
                              isCorrect: isCorrect,
                              cardWidth: cardWidth,
                              cardHeight: 220,
                              fontSize: 40,
                              answerDisplay: isAnswered
                                  ? _answerDisplayBuilder.buildAnswerDisplay(
                                      problem: problem,
                                      correctAnswer: correctAnswer,
                                      isCorrect: isCorrect,
                                      isAnswered: isAnswered,
                                    )
                                  : null,
                              actionButtons: isAnswered
                                  ? _actionButtonsBuilder.buildActionButtons(
                                      onNext: onNextProblem,
                                      isLastProblem: currentProblemIndex >= selectedProblemsLength - 1,
                                      point: problem.localizedPoint(lang),
                                    )
                                  : null,
                              isScratchPaperMode: true,
                              context: context,
                            ),
                            if (isAnswered)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _answerDisplayBuilder.buildAnswerMark(
                                    isCorrect: isCorrect,
                                    isAnswered: isAnswered,
                                  ),
                                ),
                              ),
                            if (!isAnswered)
                              Positioned(
                                top: 47,
                                right: -8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    TiltRotateButton(
                                      onPressed: onRefreshProblems,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: TabletUtils.isTablet(context) ? 24 : 16,
                                          vertical: 10,
                                        ),
                                        backgroundColor: Colors.purple.shade300,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                        textStyle: TextStyle(
                                          fontSize: TabletUtils.isTablet(context) ? 18 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      child: Text(_l10n.buttonGacha),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        ExpandableCalculatorWrapper(
                          isExpanded: isCalculatorExpanded,
                          onToggle: () {},
                          calculator: calculator,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.65,
                          child: Container(
                            margin: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DrawingCanvas(
                              isEraser: drawingToolState.isEraser,
                              isScrollMode: drawingToolState.isScrollMode,
                              isLassoTool:
                                  drawingToolState.currentTool == DrawingTool.lasso,
                              isMarkerTool:
                                  drawingToolState.currentTool == DrawingTool.marker,
                              markerBaseColor: drawingToolState.markerBaseColor,
                              eraserRadius:
                                  drawingToolState.currentTool == DrawingTool.partialEraser
                                      ? 40.0
                                      : 20.0,
                              isIPadDevice: isIPadDevice,
                              allowFingerDrawing:
                                  isIPadDevice ? drawingToolState.allowFingerDrawing : true,
                              currentColor: drawingToolState.currentColor,
                              currentStrokeWidth: drawingToolState.currentStrokeWidth,
                              isDrawingNotifier: isDrawingNotifier,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (!isIPad(context)) ...[
          DraggablePenButton(
            position: penButtonPosition,
            isSelected: !drawingToolState.isEraser && !drawingToolState.isScrollMode,
            currentColor: drawingToolState.currentColor,
            currentStrokeWidth: drawingToolState.currentStrokeWidth,
            onPositionChanged: onPenPositionChanged,
            onPenModeChanged: onPenModeChanged,
            onColorChanged: onColorChanged,
            onStrokeWidthChanged: onStrokeWidthChanged,
            activeToolNotifier: activeToolNotifier,
            isDrawingNotifier: isDrawingNotifier,
          ),
          DraggableEraserButton(
            isSelected: drawingToolState.isEraser && !drawingToolState.isScrollMode,
            onTap: onEraserToggle,
          ),
          DraggableScrollButton(
            isSelected: drawingToolState.isScrollMode,
            onTap: onScrollToggle,
          ),
        ],
        DraggableCalculatorButton(
          isExpanded: isCalculatorExpanded,
          isDraggable: false,
          onTap: onCalculatorToggle,
        ),
        if (isIPadDevice)
          UnitGachaIPadPalette(
            toolState: drawingToolState,
            activeToolNotifier: activeToolNotifier,
            onStateChanged: onStateChanged,
          ),
      ],
    );
  }
}





