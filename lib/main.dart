import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/gacha/pages/unit_gacha_page.dart';
import 'pages/tutorial/tutorial_page.dart';
import 'services/problems/simple_data_manager.dart';
import 'services/payment/revenuecat_service.dart';
import 'managers/app_logger.dart';
import 'localization/app_localizations.dart';
import 'localization/app_locale.dart';
import 'firebase_options.dart';

// 共有の navigatorKey を1つだけ作る
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// これ未満なら「スマホ実機 or 狭いウィンドウ」とみなしブラウザのビューポートをそのまま使う。
const double _kWebUseNativeViewportShortestSide = 560;

/// 大画面 Web でレイアウトを寄せるときの論理幅（iPhone 12/13/14 付近）。
const double _kWebPhoneLayoutWidth = 390;

/// Web だけ: 実機スマホは端末の縦横比のまま。幅が十分あるときは中央に典型スマホ幅で表示し、
/// [MediaQuery.size] をその幅に合わせてネイティブのスマホ版に近い折り返しにする。
Widget _webResponsiveBuilder(BuildContext context, Widget? child) {
  if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();

  final data = MediaQuery.of(context);
  final size = data.size;
  final shortest = math.min(size.width, size.height);

  if (shortest < _kWebUseNativeViewportShortestSide) {
    return child;
  }

  final targetW = math.min(_kWebPhoneLayoutWidth, size.width);
  return ColoredBox(
    color: Colors.grey.shade400,
    child: Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: targetW,
          height: size.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: MediaQuery(
            data: data.copyWith(size: Size(targetW, size.height)),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  AppLogger.resetSectionCounter(totalSections: 3);
  AppLogger.section('アプリケーション初期化', showNumber: true);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final apps = Firebase.apps;
    if (apps.isEmpty) {
      AppLogger.warning('Firebaseアプリリストが空です',
        details: '設定ファイルが不足している可能性があります:\n- Android: android/app/google-services.json\n- iOS: ios/Runner/GoogleService-Info.plist\nFirebase機能は利用できません。');
    } else {
      AppLogger.success('Firebaseの初期化が完了しました', details: 'アプリ数: ${apps.length}');
    }
  } catch (e) {
    AppLogger.error('Firebaseの初期化に失敗しました', error: e,
      details: '設定ファイルを確認してください:\n- Android: android/app/google-services.json\n- iOS: ios/Runner/GoogleService-Info.plist\nアプリは続行しますが、Firebase機能は利用できません。');
  }
  
  runApp(const UnitGachaApp());
  
  // runApp の後で非同期に初期化処理を開始
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // シンプルデータマネージャーを初期化
    await SimpleDataManager.initialize();
    
    // RevenueCat SDKを初期化
    AppLogger.subsection('RevenueCat初期化', showNumber: true);
    final revenueCatInitialized = await RevenueCatService.initialize();
    if (revenueCatInitialized) {
      AppLogger.success('RevenueCatの初期化が完了しました');
    } else {
      AppLogger.warning('RevenueCatの初期化に失敗しました', 
        details: 'AndroidではAPIキーが設定されていない可能性があります（正常動作に影響なし）');
    }
  });
}

class UnitGachaApp extends StatelessWidget {
  const UnitGachaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        // Policy: Japanese device => ja, otherwise => en.
        // This makes non-Japanese devices always show English UI.
        return AppLocale.resolve(locale);
      },
      navigatorKey: appNavigatorKey,
      builder: _webResponsiveBuilder,
      home: const _InitialPage(),
    );
  }
}

/// 初回起動を検出して適切なページに遷移
class _InitialPage extends StatefulWidget {
  const _InitialPage({Key? key}) : super(key: key);

  @override
  State<_InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<_InitialPage> {
  bool _isLoading = true;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tutorialCompleted = prefs.getBool('tutorial_completed') ?? false;
      
      if (mounted) {
        setState(() {
          _showTutorial = !kIsWeb && !tutorialCompleted;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking tutorial status: $e');
      if (mounted) {
        setState(() {
          _showTutorial = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _showTutorial ? const TutorialPage() : const UnitGachaPage();
  }
}

