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
          _showTutorial = !tutorialCompleted;
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

