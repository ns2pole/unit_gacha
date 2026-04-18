// lib/pages/help/help_page.dart
// Unit Gacha機能説明ページ

import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../localization/app_locale.dart';
import '../../widgets/common/icon_buttons.dart';
import '../../managers/timer_manager.dart';
import '../gacha/ui/unit_gacha_common_header.dart' show UnitGachaCommonHeader;
import '../../widgets/home/background_image_widget.dart';
import '../common/common.dart' show MixedTextMath;

class HelpPage extends StatelessWidget {
  // Helpページ内の「UnitList」用ボタン高さ（他画面に波及させないためローカル定数で管理）
  static const double _helpUnitButtonHeight = 52;
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

  const HelpPage({
    Key? key,
    this.onClose,
    this.timerManager,
    this.isHelpPageVisible = true,
    this.isProblemListVisible = false,
    this.isReferenceTableVisible = false,
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timerMgr = timerManager ?? TimerManager();

    return Scaffold(
      body: Stack(
        children: [
          // 背景画像（薄く、画面サイズに合わせて4枚周期的に表示）
          const BackgroundImageWidget(),
          // コンテンツ
          Column(
            children: [
              // 共通ヘッダー
              SafeArea(
                bottom: false,
                child: UnitGachaCommonHeader(
                  timerManager: timerMgr,
                  l10n: l10n,
                  isHelpPageVisible: isHelpPageVisible,
                  isProblemListVisible: isProblemListVisible,
                  isReferenceTableVisible: isReferenceTableVisible,
                  isScratchPaperMode: isScratchPaperMode,
                  showFilterSettings: showFilterSettings,
                  disableTimer: true,
                  disableFilter: true,
                  onHelpToggle: onHelpToggle ??
                      (onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  onProblemListToggle: onProblemListToggle ??
                      (onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  onReferenceTableToggle: onReferenceTableToggle ??
                      (onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  onScratchPaperToggle: onScratchPaperToggle ??
                      (onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  onFilterToggle: onFilterToggle ?? () {},
                  onLoginTap: onLoginTap,
                  onDataAnalysisNavigate: onDataAnalysisNavigate ??
                      (onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  isDataAnalysisActive: isDataAnalysisActive,
                ),
              ),
              // コンテンツ
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 5: 計算（ヘッダー左端の計算/単位系と意味が近いので維持）
                      _buildSection(
                        title: l10n.helpSection5Title,
                        icon: Icons.calculate,
                        children: [
                          _buildFeatureCard(
                            description: l10n.helpSection5Description,
                          ),
                          const SizedBox(height: 16),
                          _buildUnitListCard(context),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 1: ガチャ（そのまま）
                      _buildSection(
                        title: l10n.helpSection1Title,
                        icon: Icons.casino,
                        children: [
                          _buildFeatureCard(
                            description: l10n.helpSection1Description,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 2: タイマー（そのまま）
                      _buildSection(
                        title: l10n.helpSection2Title,
                        icon: Icons.timer,
                        children: [
                          _buildFeatureCard(
                            description: l10n.helpSection2Description,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 3: フィルター（funnel系に寄せる）
                      _buildSection(
                        title: l10n.helpSection3Title,
                        icon: Icons.filter_alt,
                        children: [
                          _buildFeatureCard(
                            description: l10n.helpSection3Description,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 4: 参照表（フラスコ/実験アイコン）
                      _buildSection(
                        title: l10n.helpSection4Title,
                        icon: Icons.science,
                        children: [
                          _buildFeatureCard(
                            description: l10n.helpSection4Description,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 6: 計算用紙/メモ（ペン系）
                      _buildSection(
                        title: l10n.helpSection6Title,
                        icon: Icons.edit,
                        children: [
                          _buildFeatureCard(
                            description: l10n.helpSection6Description,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 7: 問題リスト（listの見た目を寄せる）
                      _buildSection(
                        title: l10n.helpSection7Title,
                        icon: Icons.list_alt,
                        children: [
                          _buildFeatureCard(
                            description: l10n.helpSection7Description,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 8: データ/解析（グラフ系）
                      _buildSection(
                        title: l10n.helpSection8Title,
                        icon: Icons.bar_chart,
                        children: [
                          _buildFeatureCard(
                            description: l10n.helpSection8Description,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // 9: クラウド（同期）
                      _buildSection(
                        title: l10n.helpSection9Title,
                        icon: Icons.cloud,
                        children: [
                          _buildFeatureCard(
                            description: l10n.helpSection9Description,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B7355), // 元の灰色
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              color: const Color(0xFF8B7355), // 元の灰色
              size: 28,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFeatureCard({
    required String description,
  }) {
    return Container(
      width: double.infinity, // 横幅を統一
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 16, // 大きくする
          color: Colors.black, // 黒文字
          height: 1.5,
        ),
      ),
    );
  }

  static const Map<String, String> _unitHelpJa = {
    'kg': 'キログラム。質量の基本単位。',
    'm': 'メートル。長さの基本単位。',
    's': '秒。時間の基本単位。',
    'A': 'アンペア。電流の基本単位。',
    'J': 'ジュール(Joule)。\nエネルギー/仕事の単位。\n\n仕事の定義 \\(W=F\\,d\\) より \\(J=N\\,m=\\frac{kg\\, m^2}{s^2}\\)',
    'N': 'ニュートン(Newton)。\n力の単位。\n\n運動の第2法則 \\(F=m\\,a\\) より \\(N=kg\\,\\frac{m}{s^2}=\\frac{kg\\, m}{s^2}\\)',
    'W': 'ワット(Watt)。\n仕事率（パワー）の単位。\n\n仕事率の定義 \\(P=\\frac{W}{t}\\) より \\(W=\\frac{J}{s}=\\frac{kg\\, m^2}{s^3}\\)',
    'Pa': 'パスカル(Pascal)。\n圧力の単位。\n\n圧力の定義 \\(P=\\frac{F}{S}\\) より \\(Pa=\\frac{N}{m^2}=\\frac{kg}{m\\, s^2}\\)',
    'Hz': 'ヘルツ(Hertz)。\n周波数の単位。\n\n周波数の定義 \\(f=\\frac{1}{T}\\) より \\(Hz=\\frac{1}{s}\\)',
    'C': 'クーロン(Coulomb)。\n電荷の単位。\n\n電流の定義 \\(I=\\frac{Q}{t}\\) より \\(C=Q=I\\,t=A\\,s\\)',
    'V': 'ボルト(Volt)。\n電圧（電位差）の単位。\n\n電位差の定義 \\(V=\\frac{W}{Q}\\) より \\(V=\\frac{J}{C}=\\frac{kg\\, m^2/s^2}{A\\, s}=\\frac{kg\\, m^2}{A\\, s^3}\\)',
    'Ω': 'オーム(Ohm)。\n電気抵抗の単位。\n\nオームの法則 \\(V=I\\,R\\) より \\(\\Omega=R=\\frac{V}{I}=\\frac{kg\\, m^2/(A\\, s^3)}{A}=\\frac{kg\\, m^2}{A^2\\, s^3}\\)',
    'F': 'ファラド(Farad)。\n静電容量の単位。\n\n静電容量の定義 \\(C=\\frac{Q}{V}\\) より \\(F=\\frac{C}{V}=\\frac{A\\, s}{kg\\, m^2/(A\\, s^3)}=\\frac{A^2\\, s^4}{kg\\, m^2}\\)',
    'H': 'ヘンリー(Henry)。\nインダクタンスの単位。\n\nファラデーの電磁誘導の法則（自己誘導）\\(V=L\\,\\frac{dI}{dt}\\) より \\(H=L=\\frac{V\\,s}{A}=\\frac{(kg\\, m^2/(A\\, s^3))\\,s}{A}=\\frac{kg\\, m^2}{A^2\\, s^2}\\)',
    'T': 'テスラ(Tesla)。\n磁束密度の単位。\n\nローレンツ力 \\(F=q\\,v\\,B\\) より \\(T=B=\\frac{N}{C\\,(m/s)}=\\frac{(kg\\, m/s^2)}{(A\\, s)\\,(m/s)}=\\frac{kg}{A\\, s^2}\\)',
    'Wb': 'ウェーバ(Weber)。\n磁束の単位。\n\n磁束の定義 \\(\\Phi=B\\,S\\) より \\(Wb=\\Phi=T\\,m^2=\\frac{kg\\, m^2}{A\\, s^2}\\)',
  };

  static const Map<String, String> _unitHelpEn = {
    'kg': 'Kilogram. SI base unit of mass.',
    'm': 'Meter. SI base unit of length.',
    's': 'Second. SI base unit of time.',
    'A': 'Ampere. SI base unit of electric current.',
    'J': 'Joule (J).\nUnit of energy/work.\n\nFrom the definition of work \\(W=F\\,d\\): \\(J=N\\,m=\\frac{kg\\, m^2}{s^2}\\)',
    'N': "Newton (N).\nUnit of force.\n\nFrom Newton's 2nd law \\(F=m\\,a\\): \\(N=kg\\,\\frac{m}{s^2}=\\frac{kg\\, m}{s^2}\\)",
    'W': 'Watt (W).\nUnit of power.\n\nFrom the definition of power \\(P=\\frac{W}{t}\\): \\(W=\\frac{J}{s}=\\frac{kg\\, m^2}{s^3}\\)',
    'Pa': 'Pascal (Pa).\nUnit of pressure.\n\nFrom the definition of pressure \\(P=\\frac{F}{S}\\): \\(Pa=\\frac{N}{m^2}=\\frac{kg}{m\\, s^2}\\)',
    'Hz': 'Hertz (Hz).\nUnit of frequency.\n\nFrom the definition of frequency \\(f=\\frac{1}{T}\\): \\(Hz=\\frac{1}{s}\\)',
    'C': 'Coulomb (C).\nUnit of electric charge.\n\nFrom the definition of current \\(I=\\frac{Q}{t}\\): \\(C=Q=I\\,t=A\\,s\\)',
    'V': 'Volt (V).\nUnit of electric potential difference.\n\nFrom the definition \\(V=\\frac{W}{Q}\\): \\(V=\\frac{J}{C}=\\frac{kg\\, m^2/s^2}{A\\, s}=\\frac{kg\\, m^2}{A\\, s^3}\\)',
    'Ω': "Ohm (\\Omega).\nUnit of electrical resistance.\n\nFrom Ohm's law \\(V=I\\,R\\): \\(\\Omega=R=\\frac{V}{I}=\\frac{kg\\, m^2/(A\\, s^3)}{A}=\\frac{kg\\, m^2}{A^2\\, s^3}\\)",
    'F': 'Farad (F).\nUnit of capacitance.\n\nFrom the definition of capacitance \\(C=\\frac{Q}{V}\\): \\(F=\\frac{C}{V}=\\frac{A\\, s}{kg\\, m^2/(A\\, s^3)}=\\frac{A^2\\, s^4}{kg\\, m^2}\\)',
    'H': "Henry (H).\nUnit of inductance.\n\nFrom Faraday's law (self-induction) \\(V=L\\,\\frac{dI}{dt}\\): \\(H=L=\\frac{V\\,s}{A}=\\frac{(kg\\, m^2/(A\\, s^3))\\,s}{A}=\\frac{kg\\, m^2}{A^2\\, s^2}\\)",
    'T': 'Tesla (T).\nUnit of magnetic flux density.\n\nFrom the Lorentz force \\(F=q\\,v\\,B\\): \\(T=B=\\frac{N}{C\\,(m/s)}=\\frac{(kg\\, m/s^2)}{(A\\, s)\\,(m/s)}=\\frac{kg}{A\\, s^2}\\)',
    'Wb': 'Weber (Wb).\nUnit of magnetic flux.\n\nFrom the definition of magnetic flux \\(\\Phi=B\\,S\\): \\(Wb=\\Phi=T\\,m^2=\\frac{kg\\, m^2}{A\\, s^2}\\)',
  };

  static final RegExp _inlineMathParen = RegExp(r'\\\((.+?)\\\)', dotAll: true);
  static final RegExp _blockMathBracket = RegExp(r'\\\[(.+?)\\\]', dotAll: true);

  /// ヘルプページの単位説明で出す数式は \displaystyle で統一する。
  /// - `\( ... \)` や `\[ ... \]` の中身の先頭に `\displaystyle` を挿入
  /// - すでに `\displaystyle` が入っている場合は二重挿入しない
  String _forceDisplayStyleForMathInText(String s) {
    String addDisplayStyle(String body) {
      final leftTrimmed = body.trimLeft();
      if (leftTrimmed.startsWith(r'\displaystyle')) return body;
      return r'\displaystyle ' + body;
    }

    var out = s;
    out = out.replaceAllMapped(_inlineMathParen, (m) {
      final body = m.group(1) ?? '';
      return r'\(' + addDisplayStyle(body) + r'\)';
    });
    out = out.replaceAllMapped(_blockMathBracket, (m) {
      final body = m.group(1) ?? '';
      return r'\[' + addDisplayStyle(body) + r'\]';
    });
    return out;
  }

  void _showUnitHelpDialog(BuildContext context, String unit) {
    final l10n = AppLocalizations.of(context);
    final lang = AppLocale.languageCode(context);
    final help = (lang == 'ja' ? _unitHelpJa[unit] : _unitHelpEn[unit]) ??
        l10n.helpUnitDescriptionMissing;

    // 「単位の読み方」行はダイアログ1行目（タイトル）に寄せる。
    // 例:
    //   1行目: "W  ワット(Watt)"
    //   本文 : "仕事率（パワー）の単位。 ..."
    String dialogTitle = unit;
    String helpBody = help;
    if (help.contains('\n')) {
      final firstLine = help.split('\n').first.trim();
      final titleCore = (firstLine.endsWith('。') || firstLine.endsWith('.'))
          ? firstLine.substring(0, firstLine.length - 1).trimRight()
          : firstLine;
      if (titleCore.isNotEmpty) {
        dialogTitle = '$unit  $titleCore';
        final firstBreak = help.indexOf('\n');
        helpBody = (firstBreak >= 0 && firstBreak + 1 < help.length)
            ? help.substring(firstBreak + 1)
            : '';
        helpBody = helpBody.trimLeft();
      }
    }

    final helpDisplayStyle = _forceDisplayStyleForMathInText(helpBody);
    final closeText = l10n.commonClose;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);

        return AlertDialog(
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Text(dialogTitle),
          ),

          // ★ここが修正点：content に幅/高さ制約を付ける
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: media.size.width * 0.85,
              maxHeight: media.size.height * 0.60,
            ),
            child: SingleChildScrollView(
              child: MixedTextMath(
                helpDisplayStyle,
                labelStyle: const TextStyle(fontSize: 16, height: 1.35, color: Colors.black),
                mathStyle: const TextStyle(fontSize: 22, color: Colors.black),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(closeText),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnitListCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity, // 他のカードと同じ幅にする
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // 中央寄せ
        children: [
          Text(
            l10n.helpCalculatorUnitButtonsTitle,
            style: const TextStyle(
              fontSize: 20, // 大きくする
              fontWeight: FontWeight.bold,
              color: Colors.black, // 黒文字
            ),
          ),
          const SizedBox(height: 12),
          // 基本単位系
          Text(
            l10n.helpCalculatorBaseUnitSystemLabel,
            style: const TextStyle(
              fontSize: 18, // 大きくする
              fontWeight: FontWeight.w600,
              color: Colors.black, // 黒文字
            ),
          ),
          const SizedBox(height: 8),
          // 4つずつ並べる
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUnitButton(context, 'kg'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'm'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 's'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'A'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 1文字単位
          Text(
            l10n.helpCalculatorSingleUnitLabel,
            style: const TextStyle(
              fontSize: 18, // 大きくする
              fontWeight: FontWeight.w600,
              color: Colors.black, // 黒文字
            ),
          ),
          const SizedBox(height: 8),
          // 4つずつ並べる
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUnitButton(context, 'J'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'N'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'W'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'Pa'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUnitButton(context, 'Hz'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'C'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'V'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'Ω'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUnitButton(context, 'F'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'H'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'T'),
                  const SizedBox(width: 8),
                  _buildUnitButton(context, 'Wb'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitButton(BuildContext context, String unit) {
    return SizedBox(
      height: _helpUnitButtonHeight,
      width: 78,
      child: OutlinedButton(
        onPressed: () => _showUnitHelpDialog(context, unit),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          side: BorderSide(color: Colors.grey.shade400, width: 1),
          backgroundColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          unit,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
