import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../problems/unit/symbol.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('ja'),
    Locale('en'),
  ];

  static const _localizedValues = {
    'ja': {
      'appTitle': '物理単位ガチャ',
      'unitQuestionPrompt': '次の物理量の単位を求めよ。',
      'unitDefinitionHeader': '【記号の定義】',
      'unitFormulaLabel': '計算式',
      'unitShortExplanation': '{symbol}は{meaning}。単位は{unit}。',
      'unitGachaName': '単位ガチャ',
      'unitGachaDescription': '物理量の単位計算に挑戦！',
      'categoryMechanics': '力学',
      'categoryElectromagnetism': '電磁気学',
      'categoryThermodynamics': '熱力学',
      'categoryWaves': '波動',
      'categoryAtom': '原子物理',
      'problemDetailTitle': '問題詳細',
      'historyTitle': '学習履歴',
      'historyClear': '履歴クリア',
      'problemNumberLabel': 'No.{number}',
      'problemEquationLabel': '式: {equation}',
      'problemPointLabel': 'ポイント: {point}',
      'problemAnswerLabel': '答え: {answer}',
      'timerFinished': 'タイマーが終了しました',
      'gachaNext': '次へ',
      'gachaHint': 'ヒント',
      'gachaShowAnswer': '答えを表示',
      'gachaCheck': '答え合わせ',
      'gachaCorrect': '正解です！',
      'gachaIncorrect': 'もう一度考えましょう',
      'gachaHistorySaved': '履歴を保存しました',
      'filterNoExclusion': '除外なし 全{count}問',
      'totalCountOnly': '全{count}問',
      'filterRemaining': '(残 {filtered}問/{total}問)',
      'filterAdditional': 'ならガチャから外す',
      'menuLatest1': '最新1回のみ集計',
      'menuLatest3': '最新3回分集計',
      'aggregationLatest1Description': '最新1回の記録のみを集計',
      'aggregationLatest3Description': '最新3回分の記録を集計',
      'dialogCompleteTitle': '完了',
      'dialogCompleteBody': 'すべての問題を解きました！',
      'dialogNewProblems': '新しい問題を引く',
      'buttonDrawGacha': 'ガチャを引く',
      'buttonGacha': 'ガチャ！',
      'tooltipHideFilter': 'フィルターを隠す',
      'tooltipShowFilter': 'フィルターを表示',
      'tooltipProblemList': '問題一覧',
      'tooltipCloseProblemList': '問題一覧を閉じる',
      'tooltipHelp': 'ガチャ説明',
      'tooltipCloseHelp': 'ガチャ説明を閉じる',
      'tooltipReferenceTable': '定数・物理量一覧',
      'tooltipCloseReferenceTable': '定数・物理量一覧を閉じる',
      'tooltipScratchPaperOpen': '計算用紙を開く',
      'tooltipScratchPaperClose': '計算用紙を閉じる',
      'tooltipDataAnalysis': 'データ分析',
      'tooltipCloseDataAnalysis': 'データ分析を閉じる',
      'tooltipLogin': 'ログイン',
      'tooltipCloseLogin': 'ログインを閉じる',
      // Cloud sync / auth (shared)
      'cloudSyncTooltipSync': 'クラウドデータと同期',
      'cloudSyncTooltipLoginRequired': 'ログインが必要です',
      'cloudSyncCompleted': 'クラウドデータとの同期が完了しました',
      'cloudSyncPermissionDenied': 'Firestoreへのアクセス権限がありません。設定を確認してください。',
      'cloudSyncPartialError': '同期中にエラーが発生しました。一部のデータは同期されていない可能性があります。',
      'cloudUsingWithMethod': '{method}でクラウドを利用中',
      'popupSyncWithCloud': 'クラウドデータと同期',
      'popupLogout': 'ログアウト',
      'loggedOut': 'ログアウトしました',
      'tooltipToggleScratch': '計算用紙を開く',
      'tooltipCloseScratch': '計算用紙を閉じる',
      'categoryLabelMechanics': '力学',
      'categoryLabelThermodynamics': '熱力学',
      'categoryLabelWaves': '波動',
      'categoryLabelElectromagnetism': '電磁気学',
      'categoryLabelAtom': '原子物理',
      'pointHeader': '【ポイント】',
      'next': '次へ',
      'complete': '完了',
      'answerCorrect': r'\text{正解！}',
      'answerCorrectWithUnit': r'\text{単位は}',
      'answerIncorrect': r'\text{不正解。答えは} ',
      'confirm': '確定',
      'detail': '詳細',
      'proVersionRequired': '学習履歴機能を利用するにはPro版の購入が必要です',
      'purchaseRestored': '購入を復元しました',
      'noPurchasesFound': '復元できる購入が見つかりませんでした',
      'restoreFailed': '復元に失敗しました: {error}',
      'purchaseDialogBody': 'この問題は購入者向けです。',
      'restore': '復元',
      'purchase': '購入する',
      'purchaseCompleted': '購入が完了しました',
      'purchaseCancelled': '購入をキャンセルしました',
      'purchaseFailed': '購入に失敗しました',
      'purchaseRecommendTitle': '購入のおすすめ',
      'purchaseRecommendBody':
          '{category}の問題を合計20回解きました。\n{category}の問題を購入して、続きも学習しますか？',
      'purchaseRecommendLaterMessage':
          '問題一覧に出ている鍵のマークを押すことでいつでも購入可能なので、必要があればご購入下さい。',
      'androidBillingPreparing': 'Android版の課金は現在準備中です。しばらくお待ちください。',
      'storagePermissionRequired': 'ストレージ権限が必要です',
      'imageSaved': '画像を保存しました: {path}',
      'saveFailed': '保存に失敗しました: {error}',
      'learningRecordSaved': '学習記録を保存しました',
      'learningRecordSaveFailed': '学習記録の保存に失敗しました',
      'confirmDialog': '確認',
      'clearHistoryConfirm': 'このレベルの学習履歴をすべてクリアしますか？',
      'cancel': 'キャンセル',
      'back': '戻る',
      'clear': 'クリア',
      'clearHistory': '履歴クリア',
      'learningRecordRegistered': '学習記録を登録しました',
      'scratchPaper': '計算用紙',
      'scratchPaperPage': '計算用紙ページ',
      'fingerDrawing': '指で描画',
      'selectColor': '色を選択',
      'gachaSettings': 'ガチャ設定',
      'filterSettings': 'フィルタリング設定',
      'filterModeRandom': '完全ランダム（除外なし）',
      'filterModeExcludeSolved': '解決済みの問題を除く',
      'filterModeLatest1': '最新1回が',
      'filterModeLatest2': '最新2回が',
      'filterModeLatest3': '最新3回が',
      'filterModeUnsolvedOnly': '未解決の問題のみ',
      'filterThenExclude': 'ならガチャから外す',
      'filterThenHide': 'なら非表示',
      'settingsSaved': '設定を保存しました',
      'problemDifficulty': '問題{number}の難易度',
      'selectDifficultyForSlot': '各スロットの難易度を選択',
      'exclusionRuleNote': '※除外ルールは問題一覧で表示される最新3回の学習記録を使用します。',
      'differentialEquationNote1': '※微分方程式ガチャはキーワードで問題を分類します。',
      'differentialEquationNote2': '※キーワードの選択はガチャ画面で行えます。',
      'showAll': '全て表示',
      'excludeFromGacha': 'ガチャから外す',
      'hideFromList': '非表示',
      'latestN': '最新{number}回が',
      'noExclusion': '除外なし',
      'then': 'なら',
      'problemListTitle': '{gachaTypeName}問題一覧',
      'unitGachaProblemListTitle': 'Unit Gacha List',
      'unitLabel': '単位: ',
      'unitGachaTypeName': '物理単位ガチャ！',
      'updatedLabel': '更新: ',
      'allProblemsSolved': '全ての問題を解き切りました！',
      'helpPageTitle': 'Unit Gacha 使い方',
      'helpSection1Title': '2. ガチャを引く',
      'helpSection1Description': 'Gacha!ボタンを押すと、フィルター設定に基づいてランダムに問題が選ばれます。',
      'helpSection2Title': '3. タイマー機能',
      'helpSection2Description': '時計アイコンでタイマーの表示・非表示を切り替え、再生/停止ボタンで開始・停止できます。',
      'helpSection3Title': '4. フィルタリング機能',
      'helpSection3Description': 'フィルターアイコンでカテゴリーを選択して絞り込みできます。また、最新1〜3回の学習記録をもとに、正解済みの問題をガチャから外すなどのフィルタリングが可能です。',
      'helpSection4Title': '5. 単位参照',
      'helpSection4Description': '物理量や定数を分野ごとに一覧で確認できます。力学・熱力学・波動・電磁気のカテゴリを切り替えて、定義や単位系を参照できます。',
      'helpSection5Title': '1. 単位電卓',
      'helpSection5Description': '指数法則を用いて単位を含む計算を行います。',
      'helpSection6Title': '6. 計算用紙モード',
      'helpSection6Description': '計算用紙アイコンで描画モードに切り替え、ペンでメモや図を書けます。',
      'helpSection7Title': '7. 問題一覧',
      'helpSection7Description': '一覧アイコンで全問題のリストと学習状況を確認できます。',
      'helpSection8Title': '8. データ分析',
      'helpSection8Description': '学習状況をグラフや統計で分析できます。全体の達成率、週間の学習量、分野別内訳、正答率、ランキングなどを確認できます。クラウド（ログイン）を利用すると、分析データやランキング情報を複数デバイスで同期できます。',
      'helpSection9Title': '9. クラウド同期',
      'helpSection9Description': 'ログインすると、学習履歴・データ分析・ランキングなどの情報をクラウドに保存できます。複数の端末間で最新の学習状況を同期でき、端末を変えても続きから学習できます。',
      // Data Analysis Page
      'loginButton': 'ログインする',
      'rankingLoginButton': 'ログインしてランキングを見る',
      'rankingParticipation': 'ランキング参加',
      'nicknameOptional': 'ニックネーム（任意）',
      'save': '保存',
      'rankingParticipationNote': '参加すると順位が表示されます（週間は同じ週の解答も反映）',
      'rankingLogoutConfirmTitle': 'ログアウト',
      'rankingLogoutConfirmBody': 'クラウドをログアウトするとランキング参加は解除されます。\nログアウトしますか？',
      'rankingLogoutDoneMessage': 'ログアウトしました（ランキング参加は解除されました）',
      'rankingLoadFailed': 'ランキングの取得に失敗しました',
      'rankingLoadFailedHint': '通信状況・ログイン状態・Firebase設定（Firestoreルール/Functions）を確認して再試行してください',
      'rankingSettings': 'ランキング設定',
      'yourRanking': 'あなた: {name}  {score}点  （{rank}位 / {total}人）',
      'yourRankingNoRank': 'あなた: {name}  （参加すると順位が表示されます）',
      'top10': '上位10',
      'solvedFailedCount': '（正解{solved} / 不正解{failed}）',
      'overallData': '総合データ',
      'overallRanking': '総合ランキング',
      'weeklyRanking': '週間ランキング',
      'weeklyRankingNoData': 'データがありません（参加すると表示されます）',
      'weeklyData': '週間データ',
      'completionRate': '達成率',
      'problemsExcludedTotal': '除外された問題数 / 全問題数',
      'weeklyProblemsSolved': '1週間で解いた問題数',
      'weeklyCategoryBreakdown': '1週間で解いた分野内訳',
      'weeklyCategoryAccuracy': '1週間 分野ごとの正答率',
      'weeklyExerciseData': '1週間 正解/不正解データ',
      'correct': '正解',
      'incorrect': '不正解',
      'correctProblems': '正解の問題',
      'incorrectProblems': '不正解の問題',
      'randomModeNote': '※ランダムの場合は直近1回で集計しています',
      'noCorrectThisWeek': 'この週は正解がありません',
      'noFailedThisWeek': 'この週は不正解がありません',
      'noProblemsSolvedThisWeek': 'この週は問題を解いていません',
      'problemCountUnit': '問',
      // Completion rate label (uses filter gadget settings)
      'excludedMarkedProblemsPrefix': '最新{count}回が',
      'excludedMarkedProblemsSuffix': 'の問題数',
      'excludedMarkedProblemsNoCount': '緑アイコンの問題数',
      // Title levels
      'titleMechanicsMaster': '力学マスター',
      'titleMechanicsExpert': '力学達人',
      'titleHamiltonianBeliever': 'ハミルトニアン信者',
      'titleNewtonBeliever': 'ニュートン信者',
      'titleCelestialObserver': '天体を見る人',
      'titleEquationUser': '運動方程式使い',
      'titleMechanicsApprentice': '力学見習い',
      'titleThermodynamicsMaster': '熱力学マスター',
      'titleThermodynamicsExpert': '熱力学達人',
      'titleEntropyBeliever': 'エントロピー信者',
      'titleTemperatureFriend': '温度と仲良くなった人',
      'titleThermodynamicsApprentice': '熱力学見習い',
      'titleWavesMaster': '波動マスター',
      'titleWavesExpert': '波動達人',
      'titleFourierBeliever': 'フーリエ信者',
      'titleSuperpositionMan': '重ね合わせマン',
      'titleWavesApprentice': '波動見習い',
      'titleElectromagnetismMaster': '電磁気マスター',
      'titleElectromagnetismExpert': '電磁気達人',
      'titleMaxwellBeliever': 'マクスウェル信者',
      'titleElectromagneticFieldUser': '電磁場使い',
      'titleMagneticFieldUser': '磁場使い',
      'titleElectricFieldUser': '電場使い',
      'titleElectromagnetismApprentice': '電磁気見習い',
      'titleAtomMaster': '原子マスター',
      'titleAtomExpert': '原子達人',
      'titleBohrBeliever': 'ボーア信者',
      'titleQuantumFriend': '量子と仲良くなった人',
      'titleAtomApprentice': '原子見習い',

      // Home icon guide (first time only)
      'homeIconGuideFooter': 'タップで次へ  ({current}/{total})',
      'homeIconGuideHelpTitle': 'ガチャ説明',
      'homeIconGuideHelpBody': 'この「?」から、このアプリの使い方をいつでも確認できます。',
      'homeIconGuideCloudTitle': 'クラウド / ログイン',
      'homeIconGuideCloudBody': 'ログインすると、学習履歴や設定をクラウドに保存して複数端末で同期できます。',
      'homeIconGuideTimerTitle': 'タイマー',
      'homeIconGuideTimerBody': '時計アイコンでタイマー表示のON/OFFを切り替えます。',
      'homeIconGuideFilterTitle': 'フィルター',
      'homeIconGuideFilterBody': '出題する分野や条件を絞り込めます。',
      'homeIconGuideReferenceTitle': '定数・物理量一覧',
      'homeIconGuideReferenceBody': 'よく使う定数や物理量を一覧で確認できます。',
      'homeIconGuideScratchTitle': '計算用紙',
      'homeIconGuideScratchBody': '計算用紙モードに切り替えて、手書きでメモできます。',
      'homeIconGuideProblemListTitle': '問題一覧',
      'homeIconGuideProblemListBody': '全問題と学習状況を一覧で確認できます。',
      'homeIconGuideDataAnalysisTitle': 'データ分析',
      'homeIconGuideDataAnalysisBody': '学習データを集計して、正答率や傾向を確認できます。',

      // Calculator spotlight (after the 8-icon guide, before cloud prompt)
      'homeCalculatorGuideTitle': '電卓',
      'homeCalculatorGuideBody': '電卓のボタンの記号の意味が不明の場合は、？(ヘルプページ)を参考にしてくださいね。',
      'homeCalculatorGuideFooter': 'タップで次へ',

      // Cloud save prompt (after home icon guide)
      'cloudSavePromptTitle': 'クラウド保存',
      'cloudSavePromptBody': 'クラウドにデータを保存しますか？',
      'cloudSavePromptSaveNow': '保存する',
      'cloudSavePromptLater': 'あとで',

      // Help Page (unit calculator)
      'helpCalculatorUnitButtonsTitle': '電卓の単位ボタン（タップで説明）',
      'helpCalculatorBaseUnitSystemLabel': '基本単位系:',
      'helpCalculatorSingleUnitLabel': '1文字単位:',
      'helpUnitDescriptionMissing': '説明が未登録です。',

      // Unit derivation / explanation page
      'unitDerivationPageTitle': '単位導出',
      'unitDerivationSectionTitle': '単位導出',
      'symbolDefinitionsSectionTitle': '記号定義',
      'unitDerivationExpressionHeading': '文字式',
      'unitDerivationSubstitutionHeading': '単位を代入して整理',
      'unitDerivationResultLabel': '結果: ',
      'springConstantKUnitTitle': 'kの単位',
      'springConstantKUnitBody':
          'k の単位はフックの法則 F = kx (Fは弾性力, xはバネの自然長からの伸び)から求められる。\n'
          'ここで、弾性力Fの単位はN(ニュートン), xの単位はmであるので、kの単位は',
      'newtonBaseUnitTitle': 'N(ニュートン)の基本単位系での表示',
      'newtonBaseUnitBody':
          '運動方程式F=maより、力の単位N(ニュートン)は質量掛ける加速度の単位と等しくkg m /s^2である。',

      // Common
      'commonClose': '閉じる',

      // Widgets (misc)
      'answerPrefix': '答え: ',
      'timerDecrease30s': '30秒削減',
      'timerIncrease30s': '30秒追加',
      'timerResetTo1m': '1分にリセット',
      'drawingPen': 'ペン',
      'drawingColor': '色',
      'drawingThickness': '太さ',

      // Exclusion labels
      'exclusionLatestNWithGreenIcon': '(最新{count}回が[緑アイコン]の問題を除く)',
      'excludeMarkedProblemsPrefix': '最新{count}回が ',
      'excludeMarkedProblemsSuffix': 'の問題を除く',

      // Unit gacha milestones (snackbar)
      'unitGachaMilestone5': '5問解きました　いいね👍',
      'unitGachaMilestone10': '10問解きました　ナイス👍👍',
      'unitGachaMilestone15': '15問解きました　いい調子！👍',
      'unitGachaMilestone20': '20問解きました　素晴らしい！😁',
      'unitGachaMilestone30': '30問解きました　すごい！🤩',
      'unitGachaMilestone50': '50問解きました　天才的だ！😎',
      'unitGachaMilestone100': '100問解きました　お主に教えることはもう何もない。',
    },
    'en': {
      'appTitle': 'Unit Gacha',
      'unitQuestionPrompt': 'Find the unit of the following physical quantity.',
      'unitDefinitionHeader': '[Symbol definitions]',
      'unitFormulaLabel': 'Expression',
      'unitShortExplanation': r'{symbol} is {meaning}. Unit: {unit}.',
      'unitGachaName': 'Unit Gacha',
      'unitGachaDescription': 'Try calculating units of physical quantities!',
      'categoryMechanics': 'Mechanics',
      'categoryElectromagnetism': 'Electromagnetism',
      'categoryThermodynamics': 'Thermodynamics',
      'categoryWaves': 'Waves',
      'categoryAtom': 'Atom',
      'problemDetailTitle': 'Problem Detail',
      'historyTitle': 'Study History',
      'historyClear': 'Clear history',
      'problemNumberLabel': 'No.{number}',
      'problemEquationLabel': 'Equation: {equation}',
      'problemPointLabel': 'Point: {point}',
      'problemAnswerLabel': 'Answer: {answer}',
      'timerFinished': 'Timer finished',
      'gachaNext': 'Next',
      'gachaHint': 'Hint',
      'gachaShowAnswer': 'Show Answer',
      'gachaCheck': 'Check Answer',
      'gachaCorrect': 'Correct!',
      'gachaIncorrect': 'Try again',
      'gachaHistorySaved': 'History saved',
      'filterNoExclusion': 'No exclusion: total {count}',
      'totalCountOnly': 'Total {count}',
      'filterRemaining': '(Remaining {filtered}/{total})',
      'filterAdditional': 'Exclude in gacha',
      'menuLatest1': 'Aggregate latest 1 only',
      'menuLatest3': 'Aggregate latest 3',
      'aggregationLatest1Description': 'Aggregate only the latest attempt',
      'aggregationLatest3Description': 'Aggregate the latest 3 attempts',
      'dialogCompleteTitle': 'Done',
      'dialogCompleteBody': 'All problems are completed!',
      'dialogNewProblems': 'Draw new problems',
      'buttonDrawGacha': 'Draw',
      'buttonGacha': 'Gacha!',
      'tooltipHideFilter': 'Hide filters',
      'tooltipShowFilter': 'Show filters',
      'tooltipProblemList': 'Problem list',
      'tooltipCloseProblemList': 'Close problem list',
      'tooltipHelp': 'Help',
      'tooltipCloseHelp': 'Close help',
      'tooltipReferenceTable': 'Reference list',
      'tooltipCloseReferenceTable': 'Close reference list',
      'tooltipScratchPaperOpen': 'Open scratch paper',
      'tooltipScratchPaperClose': 'Close scratch paper',
      'tooltipDataAnalysis': 'Data analysis',
      'tooltipCloseDataAnalysis': 'Close data analysis',
      'tooltipLogin': 'Login',
      'tooltipCloseLogin': 'Close login',
      // Cloud sync / auth (shared)
      'cloudSyncTooltipSync': 'Sync with cloud',
      'cloudSyncTooltipLoginRequired': 'Login required',
      'cloudSyncCompleted': 'Cloud sync completed',
      'cloudSyncPermissionDenied': 'No permission to access Firestore. Please check your settings.',
      'cloudSyncPartialError': 'An error occurred during sync. Some data may not have been synced.',
      'cloudUsingWithMethod': 'Using cloud with {method}',
      'popupSyncWithCloud': 'Sync with cloud',
      'popupLogout': 'Logout',
      'loggedOut': 'Logged out',
      'tooltipToggleScratch': 'Open scratch pad',
      'tooltipCloseScratch': 'Close scratch pad',
      'categoryLabelMechanics': 'Mechanics',
      'categoryLabelThermodynamics': 'Thermodynamics',
      'categoryLabelWaves': 'Waves',
      'categoryLabelElectromagnetism': 'Electromagnetism',
      'categoryLabelAtom': 'Atom',
      'pointHeader': '[Point]',
      'next': 'Next',
      'complete': 'Complete',
      'answerCorrect': r'\text{Correct!}',
      'answerCorrectWithUnit': r'\text{Correct! Unit: }',
      'answerIncorrect': r'\text{Incorrect. Answer is }',
      'confirm': 'Confirm',
      'detail': 'Detail',
      'proVersionRequired': 'Pro version purchase is required to use the learning history feature',
      'purchaseRestored': 'Purchase restored',
      'noPurchasesFound': 'No purchases found to restore',
      'restoreFailed': 'Restore failed: {error}',
      'purchaseDialogBody': 'This problem requires purchase.',
      'restore': 'Restore',
      'purchase': 'Purchase',
      'purchaseCompleted': 'Purchase completed',
      'purchaseCancelled': 'Purchase cancelled',
      'purchaseFailed': 'Purchase failed',
      'purchaseRecommendTitle': 'Purchase recommendation',
      'purchaseRecommendBody':
          'You have solved {category} problems 20 times.\nWould you like to purchase {category} problems?',
      'purchaseRecommendLaterMessage':
          'You can purchase anytime by tapping the lock icon in the problem list, if needed.',
      'androidBillingPreparing':
          'In-app purchases on Android are coming soon. Please wait.',
      'storagePermissionRequired': 'Storage permission is required',
      'imageSaved': 'Image saved: {path}',
      'saveFailed': 'Save failed: {error}',
      'learningRecordSaved': 'Learning record saved',
      'learningRecordSaveFailed': 'Failed to save learning record',
      'confirmDialog': 'Confirm',
      'clearHistoryConfirm': 'Clear all learning history for this level?',
      'cancel': 'Cancel',
      'back': 'Back',
      'clear': 'Clear',
      'clearHistory': 'Clear History',
      'learningRecordRegistered': 'Learning record registered',
      'scratchPaper': 'Scratch Paper',
      'scratchPaperPage': 'Scratch Paper Page',
      'fingerDrawing': 'Finger Drawing',
      'selectColor': 'Select Color',
      'gachaSettings': 'Gacha Settings',
      'filterSettings': 'Filter Settings',
      'filterModeRandom': 'Random (No Exclusion)',
      'filterModeExcludeSolved': 'Exclude Solved',
      'filterModeLatest1': 'Latest 1',
      'filterModeLatest2': 'Latest 2',
      'filterModeLatest3': 'Latest 3',
      'filterModeUnsolvedOnly': 'Unsolved Only',
      'filterThenExclude': 'then Exclude',
      'filterThenHide': 'then Hide',
      'settingsSaved': 'Settings saved',
      'problemDifficulty': 'Problem {number} Difficulty',
      'selectDifficultyForSlot': 'Select difficulty for each slot',
      'exclusionRuleNote': '※Exclusion rules use the latest 3 learning records visible in the problem list.',
      'differentialEquationNote1': '※Differential equation gacha categorizes problems by keywords.',
      'differentialEquationNote2': '※Keyword selection can be done on the gacha screen.',
      'showAll': 'Show All',
      'excludeFromGacha': 'Exclude from Gacha',
      'hideFromList': 'Hide',
      'latestN': 'Latest {number}',
      'noExclusion': 'No Exclusion',
      'then': 'then',
      'problemListTitle': '{gachaTypeName} Problem List',
      'unitGachaProblemListTitle': 'Unit Gacha List',
      'unitLabel': 'Unit: ',
      'unitGachaTypeName': 'Unit Gacha!',
      'updatedLabel': 'Updated: ',
      'allProblemsSolved': 'All problems have been solved!',
      'helpPageTitle': 'Unit Gacha How to Use',
      'helpSection1Title': '2. Draw Gacha',
      'helpSection1Description': 'Press the Gacha! button to randomly select a problem based on your filter settings.',
      'helpSection2Title': '3. Timer Feature',
      'helpSection2Description': 'Toggle the timer display on/off with the clock icon, and start/stop it with the play/pause button.',
      'helpSection3Title': '4. Filtering Feature',
      'helpSection3Description': 'Use the filter icon to narrow problems by category. You can also filter based on your latest study records (last 1–3 attempts), such as excluding already-solved problems from the gacha.',
      'helpSection4Title': '5. Unit Reference',
      'helpSection4Description': 'You can browse physical quantities and constants by category. Switch between Mechanics, Thermodynamics, Waves, and Electromagnetism to review definitions and unit systems.',
      'helpSection5Title': '1. Unit List',
      'helpSection5Description': 'Perform calculations with units using exponent laws.',
      'helpSection6Title': '6. Scratch Paper Mode',
      'helpSection6Description': 'Switch to scratch paper mode and use the pen to write notes or draw diagrams.',
      'helpSection7Title': '7. Problem List',
      'helpSection7Description': 'View the list of all problems and check your learning status with the list icon.',
      'helpSection8Title': '8. Data Analysis',
      'helpSection8Description': 'You can analyze your learning progress with charts and statistics. This page shows overall completion rates, weekly activity, category breakdowns, accuracy, and rankings. When cloud sync (login) is enabled, your analysis data and rankings are synchronized across multiple devices.',
      'helpSection9Title': '9. Cloud Sync',
      'helpSection9Description': 'By logging in, your learning history, data analysis, and rankings are saved to the cloud. This allows you to sync your latest study progress across multiple devices and continue learning seamlessly.',
      // Data Analysis Page
      'loginButton': 'Log In',
      'rankingLoginButton': 'Log in to view ranking',
      'rankingParticipation': 'Ranking Participation',
      'nicknameOptional': 'Nickname (Optional)',
      'save': 'Save',
      'rankingParticipationNote': 'Your rank will be displayed when you participate (weekly ranking also reflects earlier attempts in the same week).',
      'rankingLogoutConfirmTitle': 'Log Out',
      'rankingLogoutConfirmBody': 'Logging out will disable ranking participation.\nDo you want to log out?',
      'rankingLogoutDoneMessage': 'Logged out (ranking participation disabled)',
      'rankingLoadFailed': 'Failed to load ranking',
      'rankingLoadFailedHint': 'Please check your connection, login state, and Firebase setup (Firestore rules / Functions) and try again.',
      'rankingSettings': 'Ranking Settings',
      'yourRanking': 'You: {name}  {score} points  (Rank {rank} / {total} users)',
      'yourRankingNoRank': 'You: {name}  (Your rank will be displayed when you participate)',
      'top10': 'Top 10',
      'solvedFailedCount': '(Correct {solved} / Incorrect {failed})',
      'overallData': 'Overall Data',
      'overallRanking': 'Overall Ranking',
      'weeklyRanking': 'Weekly Ranking',
      'weeklyRankingNoData': 'No data yet (it will appear after you participate).',
      'weeklyData': 'Weekly Data',
      'completionRate': 'Completion Rate',
      'problemsExcludedTotal': 'Excluded Problems / Total Problems',
      'weeklyProblemsSolved': 'Problems Solved This Week',
      'weeklyCategoryBreakdown': 'Category Breakdown This Week',
      'weeklyCategoryAccuracy': 'Category Accuracy This Week',
      'weeklyExerciseData': 'Correct/Incorrect Data This Week',
      'correct': 'Correct',
      'incorrect': 'Incorrect',
      'correctProblems': 'Correct Problems',
      'incorrectProblems': 'Incorrect Problems',
      'randomModeNote': '※In random mode, only the latest attempt is counted',
      'noCorrectThisWeek': 'No correct answers this week',
      'noFailedThisWeek': 'No incorrect answers this week',
      'noProblemsSolvedThisWeek': 'No problems solved this week',
      'problemCountUnit': 'problems',
      // Completion rate label (uses filter gadget settings)
      'excludedMarkedProblemsPrefix': 'Problems marked',
      'excludedMarkedProblemsSuffix': 'in the last {count} attempts',
      'excludedMarkedProblemsNoCount': 'Count of problems marked',
      // Title levels
      'titleMechanicsMaster': 'Mechanics Master',
      'titleMechanicsExpert': 'Mechanics Expert',
      'titleHamiltonianBeliever': 'Hamiltonian Believer',
      'titleNewtonBeliever': 'Newton Believer',
      'titleCelestialObserver': 'Celestial Observer',
      'titleEquationUser': 'Equation User',
      'titleMechanicsApprentice': 'Mechanics Apprentice',
      'titleThermodynamicsMaster': 'Thermodynamics Master',
      'titleThermodynamicsExpert': 'Thermodynamics Expert',
      'titleEntropyBeliever': 'Entropy Believer',
      'titleTemperatureFriend': 'Temperature Friend',
      'titleThermodynamicsApprentice': 'Thermodynamics Apprentice',
      'titleWavesMaster': 'Waves Master',
      'titleWavesExpert': 'Waves Expert',
      'titleFourierBeliever': 'Fourier Believer',
      'titleSuperpositionMan': 'Superposition Man',
      'titleWavesApprentice': 'Waves Apprentice',
      'titleElectromagnetismMaster': 'Electromagnetism Master',
      'titleElectromagnetismExpert': 'Electromagnetism Expert',
      'titleMaxwellBeliever': 'Maxwell Believer',
      'titleElectromagneticFieldUser': 'EM Field User',
      'titleMagneticFieldUser': 'Magnetic Field User',
      'titleElectricFieldUser': 'Electric Field User',
      'titleElectromagnetismApprentice': 'Electromagnetism Apprentice',
      'titleAtomMaster': 'Atom Master',
      'titleAtomExpert': 'Atom Expert',
      'titleBohrBeliever': 'Bohr Believer',
      'titleQuantumFriend': 'Quantum Friend',
      'titleAtomApprentice': 'Atom Apprentice',

      // Home icon guide (first time only)
      'homeIconGuideFooter': 'Tap to continue  ({current}/{total})',
      'homeIconGuideHelpTitle': 'Help',
      'homeIconGuideHelpBody': 'Open this anytime to see how to use the app.',
      'homeIconGuideCloudTitle': 'Cloud / Login',
      'homeIconGuideCloudBody': 'Log in to save your history and settings to the cloud and sync across devices.',
      'homeIconGuideTimerTitle': 'Timer',
      'homeIconGuideTimerBody': 'Toggle the timer display on/off.',
      'homeIconGuideFilterTitle': 'Filters',
      'homeIconGuideFilterBody': 'Narrow down categories and conditions for problems.',
      'homeIconGuideReferenceTitle': 'Reference List',
      'homeIconGuideReferenceBody': 'Check a list of frequently used constants and quantities.',
      'homeIconGuideScratchTitle': 'Scratch Pad',
      'homeIconGuideScratchBody': 'Switch to scratch pad mode to write notes by hand.',
      'homeIconGuideProblemListTitle': 'Problem List',
      'homeIconGuideProblemListBody': 'Browse all problems and your progress.',
      'homeIconGuideDataAnalysisTitle': 'Analytics',
      'homeIconGuideDataAnalysisBody': 'See summaries like accuracy and trends from your learning data.',

      // Calculator spotlight (after the 8-icon guide, before cloud prompt)
      'homeCalculatorGuideTitle': 'Calculator',
      'homeCalculatorGuideBody': 'If you’re not sure what a symbol on the calculator means, check the “?” (Help page).',
      'homeCalculatorGuideFooter': 'Tap to continue',

      // Cloud save prompt (after home icon guide)
      'cloudSavePromptTitle': 'Cloud save',
      'cloudSavePromptBody': 'Would you like to save your data to the cloud?',
      'cloudSavePromptSaveNow': 'Save',
      'cloudSavePromptLater': 'Later',

      // Help Page (unit calculator)
      'helpCalculatorUnitButtonsTitle': 'Calculator unit buttons (tap for details)',
      'helpCalculatorBaseUnitSystemLabel': 'Base units:',
      'helpCalculatorSingleUnitLabel': 'Symbol units:',
      'helpUnitDescriptionMissing': 'No description available.',

      // Unit derivation / explanation page
      'unitDerivationPageTitle': 'Unit derivation',
      'unitDerivationSectionTitle': 'Unit derivation',
      'symbolDefinitionsSectionTitle': 'Symbol definitions',
      'unitDerivationExpressionHeading': 'Expression',
      'unitDerivationSubstitutionHeading': 'Substitute units and simplify',
      'unitDerivationResultLabel': 'Result: ',
      'springConstantKUnitTitle': 'Unit of k',
      'springConstantKUnitBody':
          'The unit of k can be derived from Hooke’s law (F = kx) '
          '(F: elastic force, x: extension from the natural length of the spring).\n'
          'Since F is measured in newtons (N) and x in meters (m), the unit of k is',
      'newtonBaseUnitTitle': 'Newton (N) in base units',
      'newtonBaseUnitBody':
          'From Newton’s second law (F = ma), the unit of force (newton, N) equals '
          'mass times acceleration, so N = kg·m·s^-2.',

      // Common
      'commonClose': 'Close',

      // Widgets (misc)
      'answerPrefix': 'Answer: ',
      'timerDecrease30s': 'Decrease 30s',
      'timerIncrease30s': 'Increase 30s',
      'timerResetTo1m': 'Reset to 1 min',
      'drawingPen': 'Pen',
      'drawingColor': 'Color',
      'drawingThickness': 'Thickness',

      // Exclusion labels
      'exclusionLatestNWithGreenIcon': '(Exclude problems with [green icon] in the latest {count} attempts)',
      'excludeMarkedProblemsPrefix': 'Exclude problems marked ',
      'excludeMarkedProblemsSuffix': ' in the latest {count} attempts',

      // Unit gacha milestones (snackbar)
      'unitGachaMilestone5': 'Solved 5 problems. Nice 👍',
      'unitGachaMilestone10': 'Solved 10 problems. Nice! 👍👍',
      'unitGachaMilestone15': 'Solved 15 problems. Keep it up! 👍',
      'unitGachaMilestone20': 'Solved 20 problems. Great job! 😁',
      'unitGachaMilestone30': 'Solved 30 problems. Awesome! 🤩',
      'unitGachaMilestone50': 'Solved 50 problems. Genius! 😎',
      'unitGachaMilestone100': 'Solved 100 problems. I have nothing left to teach you.',
    },
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String _value(String key) {
    final lang = _localizedValues[locale.languageCode] ?? _localizedValues['en']!;
    return lang[key] ?? _localizedValues['en']![key] ?? key;
  }

  String get appTitle => _value('appTitle');

  String unitQuestion({
    required String defsText,
    required String expr,
  }) {
    final prompt = _value('unitQuestionPrompt');
    final defs = _value('unitDefinitionHeader');
    final formula = _value('unitFormulaLabel');
    return '$prompt\n\n$defs\n$defsText\n\n$formula: $expr';
  }

  String unitShortExplanationText({
    required SymbolDef def,
    required String unitAnswer,
  }) {
    final template = _value('unitShortExplanation');
    final symbolName = def.localizedName(locale.languageCode);
    final meaning = def.localizedMeaning(locale.languageCode);
    final unit = def.localizedUnitSymbol(locale.languageCode) ?? unitAnswer;
    return template
        .replaceAll('{symbol}', symbolName)
        .replaceAll('{meaning}', meaning)
        .replaceAll('{unit}', unit);
  }

  String unitCategory(UnitCategory category) {
    switch (category) {
      case UnitCategory.mechanics:
        return _value('categoryMechanics');
      case UnitCategory.electromagnetism:
        return _value('categoryElectromagnetism');
      case UnitCategory.thermodynamics:
        return _value('categoryThermodynamics');
      case UnitCategory.waves:
        return _value('categoryWaves');
      case UnitCategory.atom:
        return _value('categoryAtom');
    }
  }

  String problemNumberLabel(dynamic number) =>
      _value('problemNumberLabel').replaceAll('{number}', number.toString());

  String problemEquationLabel(String equation) =>
      _value('problemEquationLabel').replaceAll('{equation}', equation);

  String problemPointLabel(String point) =>
      _value('problemPointLabel').replaceAll('{point}', point);

  String problemAnswerLabel(String answer) =>
      _value('problemAnswerLabel').replaceAll('{answer}', answer);

  String get problemDetailTitle => _value('problemDetailTitle');
  String get historyTitle => _value('historyTitle');
  String get historyClear => _value('historyClear');
  String get timerFinished => _value('timerFinished');

  // Gacha specific
  String get gachaNext => _value('gachaNext');
  String get gachaHint => _value('gachaHint');
  String get gachaShowAnswer => _value('gachaShowAnswer');
  String get gachaCheck => _value('gachaCheck');
  String get gachaCorrect => _value('gachaCorrect');
  String get gachaIncorrect => _value('gachaIncorrect');
  String get gachaHistorySaved => _value('gachaHistorySaved');
  String get unitGachaName => _value('unitGachaName');
  String get unitGachaDescription => _value('unitGachaDescription');
  String filterNoExclusion(int total) =>
      _value('filterNoExclusion').replaceAll('{count}', total.toString());
  String totalCountOnly(int total) =>
      _value('totalCountOnly').replaceAll('{count}', total.toString());
  String filterRemaining(int filtered, int total) => _value('filterRemaining')
      .replaceAll('{filtered}', filtered.toString())
      .replaceAll('{total}', total.toString());
  String get filterAdditional => _value('filterAdditional');
  String get menuLatest1 => _value('menuLatest1');
  String get menuLatest3 => _value('menuLatest3');
  String get aggregationLatest1Description => _value('aggregationLatest1Description');
  String get aggregationLatest3Description => _value('aggregationLatest3Description');
  String get dialogCompleteTitle => _value('dialogCompleteTitle');
  String get dialogCompleteBody => _value('dialogCompleteBody');
  String get dialogNewProblems => _value('dialogNewProblems');
  String get buttonDrawGacha => _value('buttonDrawGacha');
  String get buttonGacha => _value('buttonGacha');
  String get tooltipHideFilter => _value('tooltipHideFilter');
  String get tooltipShowFilter => _value('tooltipShowFilter');
  String get tooltipProblemList => _value('tooltipProblemList');
  String get tooltipCloseProblemList => _value('tooltipCloseProblemList');
  String get tooltipHelp => _value('tooltipHelp');
  String get tooltipCloseHelp => _value('tooltipCloseHelp');
  String get tooltipReferenceTable => _value('tooltipReferenceTable');
  String get tooltipCloseReferenceTable => _value('tooltipCloseReferenceTable');
  String get tooltipScratchPaperOpen => _value('tooltipScratchPaperOpen');
  String get tooltipScratchPaperClose => _value('tooltipScratchPaperClose');
  String get tooltipDataAnalysis => _value('tooltipDataAnalysis');
  String get tooltipCloseDataAnalysis => _value('tooltipCloseDataAnalysis');
  String get tooltipLogin => _value('tooltipLogin');
  String get tooltipCloseLogin => _value('tooltipCloseLogin');
  // Cloud sync / auth (shared)
  String get cloudSyncTooltipSync => _value('cloudSyncTooltipSync');
  String get cloudSyncTooltipLoginRequired => _value('cloudSyncTooltipLoginRequired');
  String get cloudSyncCompleted => _value('cloudSyncCompleted');
  String get cloudSyncPermissionDenied => _value('cloudSyncPermissionDenied');
  String get cloudSyncPartialError => _value('cloudSyncPartialError');
  String cloudUsingWithMethod(String method) =>
      _value('cloudUsingWithMethod').replaceAll('{method}', method);
  String get popupSyncWithCloud => _value('popupSyncWithCloud');
  String get popupLogout => _value('popupLogout');
  String get loggedOut => _value('loggedOut');
  String get tooltipToggleScratch => _value('tooltipToggleScratch');
  String get tooltipCloseScratch => _value('tooltipCloseScratch');
  String get categoryLabelMechanics => _value('categoryLabelMechanics');
  String get categoryLabelThermodynamics => _value('categoryLabelThermodynamics');
  String problemListTitle(String gachaTypeName) =>
      _value('problemListTitle').replaceAll('{gachaTypeName}', gachaTypeName);
  String get unitGachaProblemListTitle => _value('unitGachaProblemListTitle');
  String get categoryLabelWaves => _value('categoryLabelWaves');
  String get categoryLabelElectromagnetism => _value('categoryLabelElectromagnetism');
  String get categoryLabelAtom => _value('categoryLabelAtom');
  String get pointHeader => _value('pointHeader');
  String get unitLabel => _value('unitLabel');
  String get unitGachaTypeName => _value('unitGachaTypeName');
  String get updatedLabel => _value('updatedLabel');
  String get allProblemsSolved => _value('allProblemsSolved');
  String get next => _value('next');
  String get complete => _value('complete');
  String get answerCorrect => _value('answerCorrect');
  String get answerCorrectWithUnit => _value('answerCorrectWithUnit');
  String get answerIncorrect => _value('answerIncorrect');
  String get confirm => _value('confirm');
  String get detail => _value('detail');
  String get proVersionRequired => _value('proVersionRequired');
  String get purchaseRestored => _value('purchaseRestored');
  String get noPurchasesFound => _value('noPurchasesFound');
  String restoreFailed(String error) => _value('restoreFailed').replaceAll('{error}', error);
  String get purchaseDialogBody => _value('purchaseDialogBody');
  String get restore => _value('restore');
  String get purchase => _value('purchase');
  String get purchaseCompleted => _value('purchaseCompleted');
  String get purchaseCancelled => _value('purchaseCancelled');
  String get purchaseFailed => _value('purchaseFailed');
  String get purchaseRecommendTitle => _value('purchaseRecommendTitle');
  String purchaseRecommendBody(String category) =>
      _value('purchaseRecommendBody').replaceAll('{category}', category);
  String get purchaseRecommendLaterMessage => _value('purchaseRecommendLaterMessage');
  String get androidBillingPreparing => _value('androidBillingPreparing');
  String get storagePermissionRequired => _value('storagePermissionRequired');
  String imageSaved(String path) => _value('imageSaved').replaceAll('{path}', path);
  String saveFailed(String error) => _value('saveFailed').replaceAll('{error}', error);
  String get learningRecordSaved => _value('learningRecordSaved');
  String get learningRecordSaveFailed => _value('learningRecordSaveFailed');
  String get confirmDialog => _value('confirmDialog');
  String get clearHistoryConfirm => _value('clearHistoryConfirm');
  String get cancel => _value('cancel');
  String get back => _value('back');
  String get clear => _value('clear');
  String get clearHistory => _value('clearHistory');
  String get learningRecordRegistered => _value('learningRecordRegistered');
  String get scratchPaper => _value('scratchPaper');
  String get scratchPaperPage => _value('scratchPaperPage');
  String get fingerDrawing => _value('fingerDrawing');
  String get selectColor => _value('selectColor');
  String get gachaSettings => _value('gachaSettings');
  String get filterSettings => _value('filterSettings');
  String get filterModeRandom => _value('filterModeRandom');
  String get filterModeExcludeSolved => _value('filterModeExcludeSolved');
  String get filterModeLatest1 => _value('filterModeLatest1');
  String get filterModeLatest2 => _value('filterModeLatest2');
  String get filterModeLatest3 => _value('filterModeLatest3');
  String get filterModeUnsolvedOnly => _value('filterModeUnsolvedOnly');
  String get filterThenExclude => _value('filterThenExclude');
  String get filterThenHide => _value('filterThenHide');
  String get settingsSaved => _value('settingsSaved');
  String problemDifficulty(int number) => _value('problemDifficulty').replaceAll('{number}', (number + 1).toString());
  String get selectDifficultyForSlot => _value('selectDifficultyForSlot');
  String get exclusionRuleNote => _value('exclusionRuleNote');
  String get differentialEquationNote1 => _value('differentialEquationNote1');
  String get differentialEquationNote2 => _value('differentialEquationNote2');
  String get showAll => _value('showAll');
  String get excludeFromGacha => _value('excludeFromGacha');
  String get hideFromList => _value('hideFromList');
  String latestN(int number) => _value('latestN').replaceAll('{number}', number.toString());
  String get noExclusion => _value('noExclusion');
  String get then => _value('then');
  String get helpPageTitle => _value('helpPageTitle');
  String get helpSection1Title => _value('helpSection1Title');
  String get helpSection1Description => _value('helpSection1Description');
  String get helpSection2Title => _value('helpSection2Title');
  String get helpSection2Description => _value('helpSection2Description');
  String get helpSection3Title => _value('helpSection3Title');
  String get helpSection3Description => _value('helpSection3Description');
  String get helpSection4Title => _value('helpSection4Title');
  String get helpSection4Description => _value('helpSection4Description');
  String get helpSection5Title => _value('helpSection5Title');
  String get helpSection5Description => _value('helpSection5Description');
  String get helpSection6Title => _value('helpSection6Title');
  String get helpSection6Description => _value('helpSection6Description');
  String get helpSection7Title => _value('helpSection7Title');
  String get helpSection7Description => _value('helpSection7Description');
  String get helpSection8Title => _value('helpSection8Title');
  String get helpSection8Description => _value('helpSection8Description');
  String get helpSection9Title => _value('helpSection9Title');
  String get helpSection9Description => _value('helpSection9Description');

  // Data Analysis Page
  String get loginButton => _value('loginButton');
  String get rankingLoginButton => _value('rankingLoginButton');
  String get rankingParticipation => _value('rankingParticipation');
  String get nicknameOptional => _value('nicknameOptional');
  String get save => _value('save');
  String get rankingParticipationNote => _value('rankingParticipationNote');
  String get rankingLogoutConfirmTitle => _value('rankingLogoutConfirmTitle');
  String get rankingLogoutConfirmBody => _value('rankingLogoutConfirmBody');
  String get rankingLogoutDoneMessage => _value('rankingLogoutDoneMessage');
  String get rankingLoadFailed => _value('rankingLoadFailed');
  String get rankingLoadFailedHint => _value('rankingLoadFailedHint');
  String get rankingSettings => _value('rankingSettings');
  String yourRanking(String name, int score, int rank, int total) =>
      _value('yourRanking')
          .replaceAll('{name}', name)
          .replaceAll('{score}', score.toString())
          .replaceAll('{rank}', rank.toString())
          .replaceAll('{total}', total.toString());
  String yourRankingNoRank(String name) =>
      _value('yourRankingNoRank').replaceAll('{name}', name);
  String get top10 => _value('top10');
  String solvedFailedCount(int solved, int failed) =>
      _value('solvedFailedCount')
          .replaceAll('{solved}', solved.toString())
          .replaceAll('{failed}', failed.toString());
  String get overallData => _value('overallData');
  String get overallRanking => _value('overallRanking');
  String get weeklyRanking => _value('weeklyRanking');
  String get weeklyRankingNoData => _value('weeklyRankingNoData');
  String get weeklyData => _value('weeklyData');
  String get completionRate => _value('completionRate');
  String get problemsExcludedTotal => _value('problemsExcludedTotal');
  String get weeklyProblemsSolved => _value('weeklyProblemsSolved');
  String get weeklyCategoryBreakdown => _value('weeklyCategoryBreakdown');
  String get weeklyCategoryAccuracy => _value('weeklyCategoryAccuracy');
  String get weeklyExerciseData => _value('weeklyExerciseData');
  String get correct => _value('correct');
  String get incorrect => _value('incorrect');
  String get correctProblems => _value('correctProblems');
  String get incorrectProblems => _value('incorrectProblems');
  String get randomModeNote => _value('randomModeNote');
  String get noCorrectThisWeek => _value('noCorrectThisWeek');
  String get noFailedThisWeek => _value('noFailedThisWeek');
  String get noProblemsSolvedThisWeek => _value('noProblemsSolvedThisWeek');
  String problemCountUnit(int count) {
    final unit = _value('problemCountUnit');
    // 英語の場合、単数形の場合は "problem" に変更
    if (locale.languageCode == 'en' && count == 1) {
      return 'problem';
    }
    return unit;
  }
  String excludedMarkedProblemsPrefix(int count) =>
      _value('excludedMarkedProblemsPrefix').replaceAll('{count}', count.toString());
  String excludedMarkedProblemsSuffix(int count) =>
      _value('excludedMarkedProblemsSuffix').replaceAll('{count}', count.toString());
  String get excludedMarkedProblemsNoCount => _value('excludedMarkedProblemsNoCount');
  // Title levels
  String get titleMechanicsMaster => _value('titleMechanicsMaster');
  String get titleMechanicsExpert => _value('titleMechanicsExpert');
  String get titleHamiltonianBeliever => _value('titleHamiltonianBeliever');
  String get titleNewtonBeliever => _value('titleNewtonBeliever');
  String get titleCelestialObserver => _value('titleCelestialObserver');
  String get titleEquationUser => _value('titleEquationUser');
  String get titleMechanicsApprentice => _value('titleMechanicsApprentice');
  String get titleThermodynamicsMaster => _value('titleThermodynamicsMaster');
  String get titleThermodynamicsExpert => _value('titleThermodynamicsExpert');
  String get titleEntropyBeliever => _value('titleEntropyBeliever');
  String get titleTemperatureFriend => _value('titleTemperatureFriend');
  String get titleThermodynamicsApprentice => _value('titleThermodynamicsApprentice');
  String get titleWavesMaster => _value('titleWavesMaster');
  String get titleWavesExpert => _value('titleWavesExpert');
  String get titleFourierBeliever => _value('titleFourierBeliever');
  String get titleSuperpositionMan => _value('titleSuperpositionMan');
  String get titleWavesApprentice => _value('titleWavesApprentice');
  String get titleElectromagnetismMaster => _value('titleElectromagnetismMaster');
  String get titleElectromagnetismExpert => _value('titleElectromagnetismExpert');
  String get titleMaxwellBeliever => _value('titleMaxwellBeliever');
  String get titleElectromagneticFieldUser => _value('titleElectromagneticFieldUser');
  String get titleMagneticFieldUser => _value('titleMagneticFieldUser');
  String get titleElectricFieldUser => _value('titleElectricFieldUser');
  String get titleElectromagnetismApprentice => _value('titleElectromagnetismApprentice');
  String get titleAtomMaster => _value('titleAtomMaster');
  String get titleAtomExpert => _value('titleAtomExpert');
  String get titleBohrBeliever => _value('titleBohrBeliever');
  String get titleQuantumFriend => _value('titleQuantumFriend');
  String get titleAtomApprentice => _value('titleAtomApprentice');

  // Home icon guide (first time only)
  String homeIconGuideFooter(int current, int total) => _value('homeIconGuideFooter')
      .replaceAll('{current}', current.toString())
      .replaceAll('{total}', total.toString());
  String get homeIconGuideHelpTitle => _value('homeIconGuideHelpTitle');
  String get homeIconGuideHelpBody => _value('homeIconGuideHelpBody');
  String get homeIconGuideCloudTitle => _value('homeIconGuideCloudTitle');
  String get homeIconGuideCloudBody => _value('homeIconGuideCloudBody');
  String get homeIconGuideTimerTitle => _value('homeIconGuideTimerTitle');
  String get homeIconGuideTimerBody => _value('homeIconGuideTimerBody');
  String get homeIconGuideFilterTitle => _value('homeIconGuideFilterTitle');
  String get homeIconGuideFilterBody => _value('homeIconGuideFilterBody');
  String get homeIconGuideReferenceTitle => _value('homeIconGuideReferenceTitle');
  String get homeIconGuideReferenceBody => _value('homeIconGuideReferenceBody');
  String get homeIconGuideScratchTitle => _value('homeIconGuideScratchTitle');
  String get homeIconGuideScratchBody => _value('homeIconGuideScratchBody');
  String get homeIconGuideProblemListTitle => _value('homeIconGuideProblemListTitle');
  String get homeIconGuideProblemListBody => _value('homeIconGuideProblemListBody');
  String get homeIconGuideDataAnalysisTitle => _value('homeIconGuideDataAnalysisTitle');
  String get homeIconGuideDataAnalysisBody => _value('homeIconGuideDataAnalysisBody');

  // Calculator spotlight (after the 8-icon guide, before cloud prompt)
  String get homeCalculatorGuideTitle => _value('homeCalculatorGuideTitle');
  String get homeCalculatorGuideBody => _value('homeCalculatorGuideBody');
  String get homeCalculatorGuideFooter => _value('homeCalculatorGuideFooter');

  // Cloud save prompt (after home icon guide)
  String get cloudSavePromptTitle => _value('cloudSavePromptTitle');
  String get cloudSavePromptBody => _value('cloudSavePromptBody');
  String get cloudSavePromptSaveNow => _value('cloudSavePromptSaveNow');
  String get cloudSavePromptLater => _value('cloudSavePromptLater');

  // Help Page (unit calculator)
  String get helpCalculatorUnitButtonsTitle => _value('helpCalculatorUnitButtonsTitle');
  String get helpCalculatorBaseUnitSystemLabel => _value('helpCalculatorBaseUnitSystemLabel');
  String get helpCalculatorSingleUnitLabel => _value('helpCalculatorSingleUnitLabel');
  String get helpUnitDescriptionMissing => _value('helpUnitDescriptionMissing');

  // Unit derivation / explanation page
  String get unitDerivationPageTitle => _value('unitDerivationPageTitle');
  String get unitDerivationSectionTitle => _value('unitDerivationSectionTitle');
  String get symbolDefinitionsSectionTitle => _value('symbolDefinitionsSectionTitle');
  String get unitDerivationExpressionHeading => _value('unitDerivationExpressionHeading');
  String get unitDerivationSubstitutionHeading => _value('unitDerivationSubstitutionHeading');
  String get unitDerivationResultLabel => _value('unitDerivationResultLabel');
  String get springConstantKUnitTitle => _value('springConstantKUnitTitle');
  String get springConstantKUnitBody => _value('springConstantKUnitBody');
  String get newtonBaseUnitTitle => _value('newtonBaseUnitTitle');
  String get newtonBaseUnitBody => _value('newtonBaseUnitBody');

  // Common
  String get commonClose => _value('commonClose');

  // Widgets (misc)
  String get answerPrefix => _value('answerPrefix');
  String get timerDecrease30s => _value('timerDecrease30s');
  String get timerIncrease30s => _value('timerIncrease30s');
  String get timerResetTo1m => _value('timerResetTo1m');
  String get drawingPen => _value('drawingPen');
  String get drawingColor => _value('drawingColor');
  String get drawingThickness => _value('drawingThickness');

  // Exclusion labels
  String exclusionLatestNWithGreenIcon(int count) =>
      _value('exclusionLatestNWithGreenIcon').replaceAll('{count}', count.toString());
  String excludeMarkedProblemsPrefix(int count) =>
      _value('excludeMarkedProblemsPrefix').replaceAll('{count}', count.toString());
  String excludeMarkedProblemsSuffix(int count) =>
      _value('excludeMarkedProblemsSuffix').replaceAll('{count}', count.toString());

  // Unit gacha milestones (snackbar)
  String? unitGachaMilestoneMessage(int count) {
    switch (count) {
      case 5:
        return _value('unitGachaMilestone5');
      case 10:
        return _value('unitGachaMilestone10');
      case 15:
        return _value('unitGachaMilestone15');
      case 20:
        return _value('unitGachaMilestone20');
      case 30:
        return _value('unitGachaMilestone30');
      case 50:
        return _value('unitGachaMilestone50');
      case 100:
        return _value('unitGachaMilestone100');
      default:
        return null;
    }
  }

  /// answer文字列内の「(無次元)」を「(dimensionless)」に翻訳
  String localizeAnswer(String answer, String languageCode) {
    if (languageCode == 'en') {
      return answer.replaceAll('(無次元)', '(dimensionless)');
    }
    return answer;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
