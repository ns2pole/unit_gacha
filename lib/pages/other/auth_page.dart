// lib/pages/auth_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../util/platform_info.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../services/problems/simple_data_manager.dart';
import '../../widgets/home/background_image_widget.dart';
import '../../localization/app_localizations.dart';
import '../../localization/app_locale.dart';
import '../../managers/timer_manager.dart';
import '../gacha/ui/unit_gacha_common_header.dart' show UnitGachaCommonHeader;

class AuthPage extends StatefulWidget {
  final bool isInitialSignUp;
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

  const AuthPage({
    super.key,
    this.isInitialSignUp = false,
    this.onClose,
    this.timerManager,
    this.isHelpPageVisible = false,
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
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

enum AuthMethod { none, phone, email, google, apple }

enum _AuthBusyAction {
  none,
  emailAuth,
  passwordReset,
  sendSms,
  verifySms,
  google,
  apple,
}

class _EmailLockoutState {
  final int failedCount;
  final int? lockedUntilEpochMs;
  final bool requireReset;

  const _EmailLockoutState({
    this.failedCount = 0,
    this.lockedUntilEpochMs,
    this.requireReset = false,
  });

  DateTime? get lockedUntil {
    final ms = lockedUntilEpochMs;
    if (ms == null) return null;
    if (ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}

class _AuthPageState extends State<AuthPage> {
  static const int _minPasswordLengthSignIn = 6;
  static const int _minPasswordLengthSignUp = 8;

  // Email/password sign-in lockout thresholds (device-local).
  static const int _lockoutThreshold10Min = 5;
  static const int _lockoutThreshold1Hour = 10;
  static const Duration _lockoutDuration10Min = Duration(minutes: 10);
  static const Duration _lockoutDuration1Hour = Duration(hours: 1);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  final _smsFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  _AuthBusyAction _busyAction = _AuthBusyAction.none;
  late bool _isSignUp;
  AuthMethod _selectedAuthMethod = AuthMethod.none;
  bool _isSmsCodeSent = false;
  bool _isPasswordResetMode = false;
  String? _errorMessage;
  String? _verificationId;
  StreamSubscription<User?>? _authStateSubscription;
  bool _awaitingPhoneAuthResult = false;
  bool _authSuccessHandled = false;

  bool get _isEnglishUi => AppLocale.isEnglish(context);

  String _t(String ja, String en) => _isEnglishUi ? en : ja;

  bool _isBusy(_AuthBusyAction action) => _isLoading && _busyAction == action;

  String _normalizedEmailForLockout() {
    return _emailController.text.trim().toLowerCase();
  }

  String _lockoutPrefsKey(String emailNormalized, String field) {
    final encoded = Uri.encodeComponent(emailNormalized);
    return 'auth_email_lockout_${field}_$encoded';
  }

  Future<_EmailLockoutState> _loadEmailLockoutState(
    String emailNormalized,
  ) async {
    if (emailNormalized.isEmpty) {
      return const _EmailLockoutState();
    }
    final prefs = await SharedPreferences.getInstance();
    final failedCount =
        prefs.getInt(_lockoutPrefsKey(emailNormalized, 'failedCount')) ?? 0;
    final lockedUntilEpochMs = prefs.getInt(
      _lockoutPrefsKey(emailNormalized, 'lockedUntilEpochMs'),
    );
    final requireReset =
        prefs.getBool(_lockoutPrefsKey(emailNormalized, 'requireReset')) ??
        false;
    return _EmailLockoutState(
      failedCount: failedCount,
      lockedUntilEpochMs: lockedUntilEpochMs,
      requireReset: requireReset,
    );
  }

  Future<void> _saveEmailLockoutState(
    String emailNormalized,
    _EmailLockoutState state,
  ) async {
    if (emailNormalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lockoutPrefsKey(emailNormalized, 'failedCount'),
      state.failedCount,
    );
    if (state.lockedUntilEpochMs != null) {
      await prefs.setInt(
        _lockoutPrefsKey(emailNormalized, 'lockedUntilEpochMs'),
        state.lockedUntilEpochMs!,
      );
    } else {
      await prefs.remove(
        _lockoutPrefsKey(emailNormalized, 'lockedUntilEpochMs'),
      );
    }
    await prefs.setBool(
      _lockoutPrefsKey(emailNormalized, 'requireReset'),
      state.requireReset,
    );
  }

  Future<void> _clearEmailLockoutState(String emailNormalized) async {
    if (emailNormalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockoutPrefsKey(emailNormalized, 'failedCount'));
    await prefs.remove(_lockoutPrefsKey(emailNormalized, 'lockedUntilEpochMs'));
    await prefs.remove(_lockoutPrefsKey(emailNormalized, 'requireReset'));
  }

  bool _shouldCountEmailSignInFailure(String code) {
    // Only count credential-related failures for email/password sign-in.
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return true;
      default:
        return false;
    }
  }

  String _formatRemaining(Duration d) {
    if (d.isNegative) return _t('0秒', '0s');
    final totalSeconds = d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String two(int n) => n.toString().padLeft(2, '0');
    if (hours > 0) {
      return _t('${hours}時間${two(minutes)}分', '${hours}h ${two(minutes)}m');
    }
    return _t('${minutes}分${two(seconds)}秒', '${minutes}m ${two(seconds)}s');
  }

  Future<_EmailLockoutState> _registerEmailSignInFailure(
    String emailNormalized,
  ) async {
    final now = DateTime.now();
    final current = await _loadEmailLockoutState(emailNormalized);
    final nextFailed = current.failedCount + 1;

    int? lockedUntilMs = current.lockedUntilEpochMs;
    bool requireReset = current.requireReset;

    if (nextFailed == _lockoutThreshold10Min) {
      lockedUntilMs = now.add(_lockoutDuration10Min).millisecondsSinceEpoch;
    } else if (nextFailed == _lockoutThreshold1Hour) {
      lockedUntilMs = now.add(_lockoutDuration1Hour).millisecondsSinceEpoch;
    } else if (nextFailed > _lockoutThreshold1Hour) {
      requireReset = true;
    }

    final next = _EmailLockoutState(
      failedCount: nextFailed,
      lockedUntilEpochMs: lockedUntilMs,
      requireReset: requireReset,
    );
    await _saveEmailLockoutState(emailNormalized, next);
    return next;
  }

  Widget _loadingSpinner({Color? color}) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: color == null ? null : AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _loadingButtonChild({
    required String label,
    required bool loading,
    Color spinnerColor = Colors.white,
  }) {
    if (!loading) return Text(label);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _loadingSpinner(color: spinnerColor),
        const SizedBox(width: 10),
        Flexible(child: Text(label)),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // 初回登録フローの場合は新規登録モードで開始
    _isSignUp = widget.isInitialSignUp;
    _authStateSubscription = FirebaseAuthService.authStateChanges.listen((
      user,
    ) {
      if (user == null || !_awaitingPhoneAuthResult || _authSuccessHandled) {
        return;
      }
      unawaited(_handlePhoneAuthSuccess());
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneAuthSuccess() async {
    if (!mounted || _authSuccessHandled) return;

    _authSuccessHandled = true;
    _awaitingPhoneAuthResult = false;

    // バックグラウンドで同期処理を実行（画面を閉じる前に開始）
    _syncDataInBackground();

    setState(() {
      _isLoading = false;
      _busyAction = _AuthBusyAction.none;
      _errorMessage = null;
    });

    final loginMethod = FirebaseAuthService.loginMethod ?? _t('電話番号', 'Phone');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t('$loginMethodでクラウドに保存しました', 'Saved to cloud with $loginMethod'),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_selectedAuthMethod != AuthMethod.email) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _busyAction = _AuthBusyAction.passwordReset;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      await FirebaseAuthService.sendPasswordResetEmail(email: email);

      // Password reset request is required after too many attempts.
      // Clear lockout state once the reset email is successfully sent.
      final normalized = email.toLowerCase();
      await _clearEmailLockoutState(normalized);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'パスワードリセットメールを送信しました。\nメールボックスを確認してください。',
                'Password reset email sent.\nPlease check your inbox.',
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        // パスワードリセットモードを解除
        setState(() {
          _isPasswordResetMode = false;
          _emailController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = _t(
        'パスワードリセットメールの送信に失敗しました',
        'Failed to send password reset email.',
      );
      switch (e.code) {
        case 'user-not-found':
          errorMsg = _t(
            'このメールアドレスのアカウントが見つかりません。',
            'No account found for this email address.',
          );
          break;
        case 'invalid-email':
          errorMsg = _t('無効なメールアドレスです。', 'Invalid email address.');
          break;
        case 'too-many-requests':
          errorMsg = _t(
            'リクエストが多すぎます。\nしばらく待ってから再度お試しください。',
            'Too many requests.\nPlease try again later.',
          );
          break;
        default:
          errorMsg = _t(
            'パスワードリセットメールの送信に失敗しました: ${e.message ?? e.code}',
            'Failed to send password reset email: ${e.message ?? e.code}',
          );
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _t('エラー: $e', 'Error: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
        _busyAction = _AuthBusyAction.none;
      });
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (_selectedAuthMethod != AuthMethod.email) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Extra guard: enforce stronger password minimum on sign-up.
    final password = _passwordController.text;
    if (_isSignUp && password.length < _minPasswordLengthSignUp) {
      setState(() {
        _errorMessage = _t(
          'パスワードは${_minPasswordLengthSignUp}文字以上で入力してください',
          'Password must be at least ${_minPasswordLengthSignUp} characters.',
        );
      });
      return;
    }

    // Enforce device-local lockout for email/password SIGN IN only.
    final normalizedEmail = _normalizedEmailForLockout();
    if (!_isSignUp) {
      final lock = await _loadEmailLockoutState(normalizedEmail);
      final now = DateTime.now();

      if (lock.requireReset) {
        setState(() {
          _errorMessage = _t(
            '間違いが多いため、パスワードリセットを実行してください。',
            'Too many failed attempts. Please reset your password.',
          );
          _isPasswordResetMode = true;
        });
        return;
      }

      final lockedUntil = lock.lockedUntil;
      if (lockedUntil != null && lockedUntil.isAfter(now)) {
        final remaining = lockedUntil.difference(now);
        setState(() {
          _errorMessage = _t(
            '間違いが多いためロック中です。あと${_formatRemaining(remaining)}で再試行できます。',
            'Temporarily locked. Try again in ${_formatRemaining(remaining)}.',
          );
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _busyAction = _AuthBusyAction.emailAuth;
      _errorMessage = null;
    });

    try {
      UserCredential? userCredential;

      if (_isSignUp) {
        userCredential = await FirebaseAuthService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        userCredential = await FirebaseAuthService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (userCredential != null) {
        // Clear lockout state on successful SIGN IN.
        if (!_isSignUp) {
          await _clearEmailLockoutState(normalizedEmail);
        }
        // バックグラウンドで同期処理を実行（画面を閉じる前に開始）
        _syncDataInBackground();

        if (mounted) {
          // 成功メッセージを表示
          final loginMethod =
              FirebaseAuthService.loginMethod ?? _t('メールアドレス', 'Email');
          final message = _isSignUp
              ? _t('$loginMethodで新規登録しました', 'Signed up with $loginMethod')
              : _t(
                  '$loginMethodでクラウドに保存しました',
                  'Saved to cloud with $loginMethod',
                );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // オーバーレイの場合はonCloseを使用、通常のナビゲーションの場合はpop
          if (widget.onClose != null) {
            widget.onClose!();
          } else {
            Navigator.of(context).pop(true);
          }
        }
      } else {
        setState(() {
          _errorMessage = _isSignUp
              ? _t('サインアップに失敗しました', 'Sign up failed.')
              : _t('クラウドに保存に失敗しました', 'Failed to save to cloud.');
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = _t(
        'エラー: ${e.message ?? e.code}',
        'Error: ${e.message ?? e.code}',
      );

      // Update lockout state on email/password SIGN IN failures only.
      if (!_isSignUp && _shouldCountEmailSignInFailure(e.code)) {
        final updated = await _registerEmailSignInFailure(normalizedEmail);
        final now = DateTime.now();
        if (updated.requireReset) {
          errorMsg = _t(
            '間違いが多いため、パスワードリセットを実行してください。',
            'Too many failed attempts. Please reset your password.',
          );
          if (mounted) {
            setState(() => _isPasswordResetMode = true);
          }
        } else if (updated.lockedUntil != null &&
            updated.lockedUntil!.isAfter(now)) {
          final remaining = updated.lockedUntil!.difference(now);
          errorMsg = _t(
            '間違いが多いためロック中です。あと${_formatRemaining(remaining)}で再試行できます。',
            'Temporarily locked. Try again in ${_formatRemaining(remaining)}.',
          );
        }
      }

      // Firebase認証エラーを適切に処理
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = _t(
            'このメールアドレスは既に使用されています。\nクラウドに保存してください。',
            'This email is already in use.\nPlease sign in instead.',
          );
          break;
        case 'weak-password':
          errorMsg = _t(
            'パスワードが弱すぎます。\nより強力なパスワードを設定してください。',
            'Password is too weak.\nPlease choose a stronger password.',
          );
          break;
        case 'invalid-email':
          errorMsg = _t('無効なメールアドレスです。', 'Invalid email address.');
          break;
        case 'user-not-found':
          errorMsg = _t(
            'このメールアドレスのアカウントが見つかりません。\n新規登録してください。',
            'No account found for this email.\nPlease sign up.',
          );
          break;
        case 'wrong-password':
        case 'invalid-credential':
          errorMsg = _t(
            'メールアドレスまたはパスワードが正しくありません。\nもう一度確認してください。',
            'Incorrect email or password.\nPlease try again.',
          );
          break;
        case 'credential-already-in-use':
          errorMsg = _t(
            'このアカウントは既に別の方法で登録されています。\n既存の認証方法を使用してください。',
            'This account already exists with a different sign-in method.\nPlease use the existing method.',
          );
          break;
        case 'too-many-requests':
          errorMsg = _t(
            'リクエストが多すぎます。\nしばらく待ってから再度お試しください。',
            'Too many requests.\nPlease try again later.',
          );
          break;
        case 'operation-not-allowed':
          errorMsg = _t(
            'この認証方法は有効になっていません。',
            'This sign-in method is not enabled.',
          );
          break;
        default:
          errorMsg = _t(
            'クラウドに保存に失敗しました: ${e.message ?? e.code}',
            'Failed to save to cloud: ${e.message ?? e.code}',
          );
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _busyAction = _AuthBusyAction.none;
      });
    }
  }

  Future<void> _sendSmsCode() async {
    if (!_phoneFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _busyAction = _AuthBusyAction.sendSms;
      _errorMessage = null;
      _verificationId = null;
      _awaitingPhoneAuthResult = true;
      _authSuccessHandled = false;
    });

    try {
      String phoneNumber = _phoneController.text.trim();
      // 電話番号が+で始まっていない場合は+を追加（日本の場合）
      if (!phoneNumber.startsWith('+')) {
        // 日本の電話番号として処理（090-1234-5678 や 09012345678 の形式）
        phoneNumber = phoneNumber.replaceAll(RegExp(r'[-\s]'), '');
        if (phoneNumber.startsWith('0')) {
          phoneNumber = '+81${phoneNumber.substring(1)}';
        } else {
          phoneNumber = '+81$phoneNumber';
        }
      }

      await FirebaseAuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        codeSent: (String verificationId) {
          if (!mounted || _authSuccessHandled) return;
          setState(() {
            _verificationId = verificationId;
            _isSmsCodeSent = true;
            _isLoading = false;
            _busyAction = _AuthBusyAction.none;
          });
        },
        verificationFailed: (String error) {
          print('Phone verification failed in UI: $error');
          _awaitingPhoneAuthResult = false;
          setState(() {
            _errorMessage = error;
            _isLoading = false;
            _busyAction = _AuthBusyAction.none;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Androidで自動取得がタイムアウトした場合
          if (!mounted || _authSuccessHandled) return;
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      _awaitingPhoneAuthResult = false;
      setState(() {
        _errorMessage = _t(
          'SMSコードの送信に失敗しました: $e',
          'Failed to send SMS code: $e',
        );
        _isLoading = false;
        _busyAction = _AuthBusyAction.none;
      });
    }
  }

  Future<void> _verifySmsCode() async {
    if (FirebaseAuthService.isAuthenticated) {
      await _handlePhoneAuthSuccess();
      return;
    }

    if (!_smsFormKey.currentState!.validate()) {
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage = _t(
          '検証IDが取得できませんでした。もう一度お試しください。',
          'Could not get verification ID. Please try again.',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _busyAction = _AuthBusyAction.verifySms;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuthService.signInWithPhoneNumber(
        verificationId: _verificationId!,
        smsCode: _smsCodeController.text.trim(),
      );

      if (userCredential != null) {
        await _handlePhoneAuthSuccess();
      } else {
        setState(() {
          _errorMessage = _t(
            'SMSコードの認証に失敗しました',
            'SMS code verification failed.',
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'session-expired' && FirebaseAuthService.isAuthenticated) {
        await _handlePhoneAuthSuccess();
        return;
      }

      // Firebase認証エラーの詳細な処理
      String errorMsg = _t('SMSコードの認証に失敗しました', 'SMS code verification failed.');

      print('FirebaseAuthException in _verifySmsCode:');
      print('  Code: ${e.code}');
      print('  Message: ${e.message}');
      print('  Email: ${e.email}');
      print('  Credential: ${e.credential}');

      switch (e.code) {
        case 'invalid-verification-code':
          errorMsg = _t(
            'SMSコードが正しくありません。\nもう一度確認してください。',
            'Incorrect SMS code.\nPlease try again.',
          );
          break;
        case 'invalid-verification-id':
          errorMsg = _t(
            '検証IDが無効です。\nもう一度電話番号を入力してください。',
            'Invalid verification ID.\nPlease enter your phone number again.',
          );
          break;
        case 'session-expired':
          errorMsg = _t(
            'セッションが期限切れです。\nもう一度電話番号を入力してください。',
            'Session expired.\nPlease enter your phone number again.',
          );
          break;
        case 'credential-already-in-use':
          errorMsg = _t(
            'この電話番号は既に使用されています。\n既存の認証方法を使用してください。',
            'This phone number is already in use.\nPlease use the existing sign-in method.',
          );
          break;
        case 'provider-already-linked':
          errorMsg = _t(
            'この電話番号は既にこのアカウントにリンクされています。',
            'This phone number is already linked to the account.',
          );
          break;
        case 'too-many-requests':
          errorMsg = _t(
            'このデバイスからのリクエストが多すぎるため、\n'
                'Firebaseが一時的にブロックしています。\n\n'
                '対処法:\n'
                '• 数時間から24時間待ってから再度お試しください\n'
                '• 別のデバイスで試す\n'
                '• テスト中はリクエスト回数を減らす\n\n'
                'エラー詳細: ${e.message ?? "詳細情報なし"}',
            'Too many requests from this device.\n'
                'Firebase temporarily blocked it.\n\n'
                'Try:\n'
                '- Wait a few hours (up to 24h) and try again\n'
                '- Try on another device\n'
                '- Reduce requests during testing\n\n'
                'Details: ${e.message ?? "No details"}',
          );
          break;
        case 'quota-exceeded':
          errorMsg = _t(
            'SMS送信の上限に達しました。\n\n'
                '対処法:\n'
                '• Firebase Console > 設定 > 請求 でBlazeプランにアップグレード\n'
                '• 請求先アカウントが正しくリンクされているか確認\n'
                '• テスト用電話番号を使用（Firebase Console > Authentication > Settings）\n'
                '• 翌日まで待つ（1日あたりの制限がリセットされる）\n\n'
                'エラー詳細: ${e.message ?? "詳細情報なし"}',
            'SMS quota exceeded.\n\n'
                'Try:\n'
                '- Upgrade to Blaze plan (Firebase Console > Settings > Billing)\n'
                '- Check billing account linkage\n'
                '- Use test phone numbers (Firebase Console > Authentication > Settings)\n'
                '- Wait until tomorrow (daily limit resets)\n\n'
                'Details: ${e.message ?? "No details"}',
          );
          break;
        case 'operation-not-allowed':
          errorMsg = _t(
            '電話番号認証が有効になっていません。\nFirebase Consoleで設定を確認してください。',
            'Phone authentication is not enabled.\nPlease check Firebase Console settings.',
          );
          break;
        default:
          errorMsg = _t(
            '認証エラーが発生しました: ${e.code}\n${e.message ?? "詳細なエラー情報を確認してください"}',
            'Authentication error: ${e.code}\n${e.message ?? "Please check the error details."}',
          );
          // デバッグ用に詳細情報をログに出力
          print('Unhandled FirebaseAuthException code: ${e.code}');
      }

      setState(() {
        _errorMessage = errorMsg;
      });
    } catch (e, stackTrace) {
      // その他のエラー
      print('Unexpected error in _verifySmsCode: $e');
      print('Stack trace: $stackTrace');

      String errorMsg = _t('SMSコードの認証に失敗しました', 'SMS code verification failed.');
      if (e.toString().contains('invalid-verification-code')) {
        errorMsg = _t(
          'SMSコードが正しくありません。\nもう一度確認してください。',
          'Incorrect SMS code.\nPlease try again.',
        );
      } else if (e.toString().contains('session-expired')) {
        errorMsg = _t(
          'セッションが期限切れです。\nもう一度電話番号を入力してください。',
          'Session expired.\nPlease enter your phone number again.',
        );
      } else if (e.toString().contains('credential-already-in-use')) {
        errorMsg = _t(
          'この電話番号は既に使用されています。\n既存の認証方法を使用してください。',
          'This phone number is already in use.\nPlease use the existing sign-in method.',
        );
      } else {
        errorMsg = _t(
          'エラーが発生しました: $e\n\n詳細なエラー情報はログを確認してください。',
          'An error occurred: $e\n\nPlease check the logs for details.',
        );
      }

      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _busyAction = _AuthBusyAction.none;
      });
    }
  }

  void _resetAuthMethod() {
    _awaitingPhoneAuthResult = false;
    _authSuccessHandled = false;
    setState(() {
      _isLoading = false;
      _busyAction = _AuthBusyAction.none;
      _selectedAuthMethod = AuthMethod.none;
      _isSmsCodeSent = false;
      _verificationId = null;
      _phoneController.clear();
      _smsCodeController.clear();
      _emailController.clear();
      _passwordController.clear();
      _errorMessage = null;
      _isPasswordResetMode = false;
    });
  }

  /// バックグラウンドでデータ同期を実行（認証成功後、画面を閉じた後に実行）
  Future<void> _syncDataInBackground() async {
    try {
      // UIが先に表示されるように、同期処理を遅延実行
      // これにより、ログイン後の画面遷移がスムーズに行われる
      await Future.delayed(const Duration(seconds: 2));

      // 認証状態が確実に反映されるまで待機
      // 最大1秒まで待機
      int waitCount = 0;
      const maxWaitCount = 10; // 100ms × 10 = 1秒
      while (!FirebaseAuthService.isAuthenticated && waitCount < maxWaitCount) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }

      if (!FirebaseAuthService.isAuthenticated) {
        print(
          'Warning: Authentication state not ready after waiting, skipping sync',
        );
        return;
      }

      // UIスレッドに制御を戻す
      await Future.delayed(Duration.zero);

      // アカウント切り替えを検知
      final isAccountSwitched = await SimpleDataManager.isAccountSwitched();

      // UIスレッドに制御を戻す
      await Future.delayed(const Duration(milliseconds: 50));

      if (isAccountSwitched) {
        print('Account switch detected, clearing pending local data...');
        await SimpleDataManager.syncOnAccountSwitch();
      } else {
        await SimpleDataManager.syncLocalDataToFirestore();
        await Future.delayed(const Duration(milliseconds: 50));

        await SimpleDataManager.syncLocalSettingsToFirestore();
        await Future.delayed(const Duration(milliseconds: 50));

        // 現在のユーザーIDを保存（次回のアカウント切り替え検知用）
        final currentUserId = FirebaseAuthService.userId;
        if (currentUserId != null) {
          await SimpleDataManager.setLastUserId(currentUserId);
        }
      }

      print('Background sync completed');
    } catch (e) {
      print('Error in background sync: $e');
      // エラーが発生してもユーザーには影響しない（バックグラウンド処理のため）
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _busyAction = _AuthBusyAction.google;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuthService.signInWithGoogle();
      if (userCredential != null) {
        // バックグラウンドで同期処理を実行（画面を閉じる前に開始）
        _syncDataInBackground();

        if (mounted) {
          // 成功メッセージを表示
          final loginMethod =
              FirebaseAuthService.loginMethod ??
              _t('Googleアカウント', 'Google account');
          final message = _isSignUp
              ? _t('$loginMethodで新規登録しました', 'Signed up with $loginMethod')
              : _t(
                  '$loginMethodでクラウドに保存しました',
                  'Saved to cloud with $loginMethod',
                );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // オーバーレイの場合はonCloseを使用、通常のナビゲーションの場合はpop
          if (widget.onClose != null) {
            widget.onClose!();
          } else {
            Navigator.of(context).pop(true);
          }
        }
      } else {
        setState(() {
          _errorMessage = kIsWeb
              ? _t(
                  'Google Sign-Inに失敗しました。\nポップアップがブロックされていないか確認して、もう一度お試しください。',
                  'Google Sign-In failed.\nPlease allow the popup in your browser and try again.',
                )
              : _t('Google Sign-Inに失敗しました', 'Google Sign-In failed.');
        });
      }
    } catch (e) {
      String errorMsg = _t('Google Sign-Inに失敗しました', 'Google Sign-In failed.');
      // リンク時のエラーを適切に処理
      if (e.toString().contains('credential-already-in-use')) {
        errorMsg = _t(
          'このGoogleアカウントは既に使用されています。\n既存の認証方法を使用してください。',
          'This Google account is already in use.\nPlease use an existing sign-in method.',
        );
      } else if (e.toString().contains(
        'account-exists-with-different-credential',
      )) {
        errorMsg = _t(
          'このGoogleアカウントは既に別の方法で登録されています。\n既存の認証方法を使用してください。',
          'This Google account is already registered with a different method.\nPlease use an existing sign-in method.',
        );
      } else if (e.toString().contains('network')) {
        errorMsg = _t(
          'ネットワークエラーが発生しました。\nインターネット接続を確認してください。',
          'Network error.\nPlease check your internet connection.',
        );
      } else if (kIsWeb &&
          (e.toString().contains('popup') ||
              e.toString().contains('cancelled-popup-request') ||
              e.toString().contains('popup-blocked'))) {
        errorMsg = _t(
          'ブラウザのポップアップが開けませんでした。\nポップアップを許可して、もう一度お試しください。',
          'The browser popup could not be opened.\nPlease allow popups and try again.',
        );
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _busyAction = _AuthBusyAction.none;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _busyAction = _AuthBusyAction.apple;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuthService.signInWithApple();
      if (userCredential != null) {
        // バックグラウンドで同期処理を実行（画面を閉じる前に開始）
        _syncDataInBackground();

        if (mounted) {
          // 成功メッセージを表示
          final loginMethod =
              FirebaseAuthService.loginMethod ??
              _t('Appleアカウント', 'Apple account');
          final message = _isSignUp
              ? _t('$loginMethodで新規登録しました', 'Signed up with $loginMethod')
              : _t(
                  '$loginMethodでクラウドに保存しました',
                  'Saved to cloud with $loginMethod',
                );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // オーバーレイの場合はonCloseを使用、通常のナビゲーションの場合はpop
          if (widget.onClose != null) {
            widget.onClose!();
          } else {
            Navigator.of(context).pop(true);
          }
        }
      } else {
        setState(() {
          _errorMessage = _t(
            'Apple Sign-Inに失敗しました。\nFirebase ConsoleでApple Sign-Inが有効になっているか確認してください。',
            'Apple Sign-In failed.\nPlease make sure Apple Sign-In is enabled in Firebase Console.',
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      // FirebaseAuthExceptionのエラーコードを適切に処理
      String errorMsg = _t('Apple Sign-Inに失敗しました', 'Apple Sign-In failed.');

      switch (e.code) {
        case 'invalid-credential':
          errorMsg = _t(
            '認証情報が無効です。\nもう一度お試しください。',
            'Invalid credential.\nPlease try again.',
          );
          break;
        case 'invalid-id-token':
          errorMsg = _t(
            '認証トークンが無効です。\nもう一度お試しください。',
            'Invalid ID token.\nPlease try again.',
          );
          break;
        case 'credential-already-in-use':
          errorMsg = _t(
            'このAppleアカウントは既に使用されています。\n既存の認証方法を使用してください。',
            'This Apple account is already in use.\nPlease use an existing sign-in method.',
          );
          break;
        case 'account-exists-with-different-credential':
          errorMsg = _t(
            'このAppleアカウントは既に別の方法で登録されています。\n既存の認証方法を使用してください。',
            'This Apple account is already registered with a different method.\nPlease use an existing sign-in method.',
          );
          break;
        case 'operation-not-allowed':
          errorMsg = _t(
            'Apple Sign-InがFirebase Consoleで有効になっていません。\nFirebase Console > Authentication > Sign-in method で\nAppleを有効にしてください。',
            'Apple Sign-In is not enabled in Firebase Console.\nEnable Apple under Firebase Console > Authentication > Sign-in method.',
          );
          break;
        default:
          // エラーコードとメッセージを含めた詳細なメッセージ
          errorMsg = _t(
            'Apple Sign-Inに失敗しました。\nエラーコード: ${e.code}\n${e.message ?? "詳細情報なし"}',
            'Apple Sign-In failed.\nError code: ${e.code}\n${e.message ?? "No details"}',
          );
          break;
      }

      setState(() {
        _errorMessage = errorMsg;
      });
    } catch (e) {
      String errorMsg = _t('Apple Sign-Inに失敗しました', 'Apple Sign-In failed.');
      // Firebase設定エラーの場合、より具体的なメッセージを表示
      if (e.toString().contains('CONFIGURATION_NOT_FOUND') ||
          e.toString().contains('17999')) {
        errorMsg = _t(
          'Apple Sign-InがFirebase Consoleで設定されていません。\nFirebase Console > Authentication > Sign-in method で\nAppleを有効にしてください。',
          'Apple Sign-In is not configured in Firebase Console.\nEnable Apple under Firebase Console > Authentication > Sign-in method.',
        );
      } else if (e.toString().contains('credential-already-in-use')) {
        errorMsg = _t(
          'このAppleアカウントは既に使用されています。\n既存の認証方法を使用してください。',
          'This Apple account is already in use.\nPlease use an existing sign-in method.',
        );
      } else if (e.toString().contains(
        'account-exists-with-different-credential',
      )) {
        errorMsg = _t(
          'このAppleアカウントは既に別の方法で登録されています。\n既存の認証方法を使用してください。',
          'This Apple account is already registered with a different method.\nPlease use an existing sign-in method.',
        );
      }
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _busyAction = _AuthBusyAction.none;
      });
    }
  }

  /// Firebaseが初期化されているか確認
  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirebaseAvailable = _isFirebaseAvailable;
    final l10n = AppLocalizations.of(context);
    final timerMgr = widget.timerManager ?? TimerManager();

    return Scaffold(
      body: Stack(
        children: [
          // ヘルプページ同様、ヘッダー2行目まで背景を表示
          const Positioned.fill(child: BackgroundImageWidget()),
          Column(
            children: [
              // 共通ヘッダー
              SafeArea(
                bottom: false,
                child: UnitGachaCommonHeader(
                  timerManager: timerMgr,
                  l10n: l10n,
                  isHelpPageVisible: widget.isHelpPageVisible,
                  isProblemListVisible: widget.isProblemListVisible,
                  isReferenceTableVisible: widget.isReferenceTableVisible,
                  isScratchPaperMode: widget.isScratchPaperMode,
                  showFilterSettings: widget.showFilterSettings,
                  disableTimer: true,
                  disableFilter: true,
                  onHelpToggle:
                      widget.onHelpToggle ??
                      (widget.onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  onProblemListToggle:
                      widget.onProblemListToggle ??
                      (widget.onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  onReferenceTableToggle:
                      widget.onReferenceTableToggle ??
                      (widget.onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  onScratchPaperToggle:
                      widget.onScratchPaperToggle ??
                      (widget.onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  onFilterToggle: widget.onFilterToggle ?? () {},
                  onLoginTap: widget.onLoginTap,
                  onDataAnalysisNavigate:
                      widget.onDataAnalysisNavigate ??
                      (widget.onClose ??
                          () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }),
                  isDataAnalysisActive: widget.isDataAnalysisActive,
                  isAuthPageVisible: true,
                ),
              ),
              // コンテンツ
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),

                      // Firebaseが利用できない場合の警告
                      if (!isFirebaseAvailable) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _t(
                                      'Firebaseが設定されていません',
                                      'Firebase is not configured',
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _t(
                                  'クラウドに保存するには、Firebase設定ファイルが必要です。\n'
                                      'Firebase Consoleから設定ファイルをダウンロードして配置してください。',
                                  'To use cloud sync, Firebase configuration files are required.\n'
                                      'Download them from Firebase Console and place them in the project.',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // エラーメッセージ
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // 認証方法選択画面
                      if (_selectedAuthMethod == AuthMethod.none) ...[
                        // 1. 電話番号でクラウドに保存
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isLoading || !isFirebaseAvailable)
                                ? null
                                : () {
                                    setState(() {
                                      _selectedAuthMethod = AuthMethod.phone;
                                      _errorMessage = null;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _t('電話番号でクラウドに保存', 'Save to cloud with Phone'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. メールアドレスでクラウドに保存
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isLoading || !isFirebaseAvailable)
                                ? null
                                : () {
                                    setState(() {
                                      _selectedAuthMethod = AuthMethod.email;
                                      _errorMessage = null;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _t('メールアドレスでクラウドに保存', 'Save to cloud with Email'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Googleでクラウドに保存
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_isLoading || !isFirebaseAvailable)
                                ? null
                                : _signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _isBusy(_AuthBusyAction.google)
                                    ? _loadingSpinner(color: Colors.black87)
                                    : const Icon(Icons.g_mobiledata, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  _t(
                                    'Googleでクラウドに保存',
                                    'Save to cloud with Google',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 4. iOSのみAppleアカウントでクラウドに保存
                        if (PlatformInfo.isIOS) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !isFirebaseAvailable)
                                  ? null
                                  : _signInWithApple,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isBusy(_AuthBusyAction.apple)
                                      ? _loadingSpinner(color: Colors.white)
                                      : const Icon(Icons.apple, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    _t(
                                      'Appleアカウントでクラウドに保存',
                                      'Save to cloud with Apple',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ]
                      // メールアドレス認証フォーム
                      else if (_selectedAuthMethod == AuthMethod.email) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: _t('メールアドレス', 'Email'),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_isLoading,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return _t(
                                      'メールアドレスを入力してください',
                                      'Please enter your email.',
                                    );
                                  }
                                  if (!value.contains('@')) {
                                    return _t(
                                      '有効なメールアドレスを入力してください',
                                      'Please enter a valid email address.',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // パスワードフィールド（パスワードリセットモードでない場合のみ表示）
                              if (!_isPasswordResetMode) ...[
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: _t('パスワード', 'Password'),
                                    border: const OutlineInputBorder(),
                                  ),
                                  obscureText: true,
                                  enabled: !_isLoading,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return _t(
                                        'パスワードを入力してください',
                                        'Please enter your password.',
                                      );
                                    }
                                    final minLen = _isSignUp
                                        ? _minPasswordLengthSignUp
                                        : _minPasswordLengthSignIn;
                                    if (value.length < minLen) {
                                      return _t(
                                        'パスワードは${minLen}文字以上で入力してください',
                                        'Password must be at least ${minLen} characters.',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                // 通常のログイン/新規登録モード
                                ElevatedButton(
                                  onPressed:
                                      (_isLoading || !isFirebaseAvailable)
                                      ? null
                                      : _signInWithEmailAndPassword,
                                  child: _loadingButtonChild(
                                    label: _isSignUp
                                        ? _t('新規登録', 'Sign up')
                                        : _t('ログイン', 'Sign in'),
                                    loading: _isBusy(_AuthBusyAction.emailAuth),
                                    spinnerColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // パスワードリセットボタン（ログインモードの場合のみ表示）
                                if (!_isSignUp)
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isPasswordResetMode = true;
                                              _passwordController.clear();
                                              _errorMessage = null;
                                            });
                                          },
                                    child: Text(
                                      _t('パスワードを忘れた場合', 'Forgot password?'),
                                    ),
                                  ),
                                // サインアップ/クラウドに保存切り替え（初回登録フローの場合は表示しない）
                                if (!widget.isInitialSignUp)
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isSignUp = !_isSignUp;
                                              _isPasswordResetMode = false;
                                              _errorMessage = null;
                                            });
                                          },
                                    child: Text(
                                      _isSignUp
                                          ? _t(
                                              '既にアカウントをお持ちの方はこちら',
                                              'Already have an account? Sign in',
                                            )
                                          : _t(
                                              '新規登録はこちら',
                                              'Create a new account',
                                            ),
                                    ),
                                  ),
                              ] else ...[
                                // パスワードリセットモードの場合
                                ElevatedButton(
                                  onPressed:
                                      (_isLoading || !isFirebaseAvailable)
                                      ? null
                                      : _sendPasswordResetEmail,
                                  child: _loadingButtonChild(
                                    label: _t(
                                      'パスワードリセットメールを送信',
                                      'Send password reset email',
                                    ),
                                    loading: _isBusy(
                                      _AuthBusyAction.passwordReset,
                                    ),
                                    spinnerColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isPasswordResetMode = false;
                                            _errorMessage = null;
                                          });
                                        },
                                  child: Text(_t('戻る', 'Back')),
                                ),
                              ],
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _isLoading ? null : _resetAuthMethod,
                                child: Text(_t('戻る', 'Back')),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // 電話番号認証フォーム
                      else if (_selectedAuthMethod == AuthMethod.phone) ...[
                        if (!_isSmsCodeSent) ...[
                          // 電話番号入力フォーム
                          Form(
                            key: _phoneFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: _t('電話番号', 'Phone number'),
                                    hintText: _t(
                                      '09012345678 または +819012345678',
                                      'e.g. +819012345678',
                                    ),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return _t(
                                        '電話番号を入力してください',
                                        'Please enter your phone number.',
                                      );
                                    }
                                    // 基本的な電話番号形式チェック
                                    final cleaned = value.replaceAll(
                                      RegExp(r'[-\s]'),
                                      '',
                                    );
                                    if (cleaned.length < 10) {
                                      return _t(
                                        '有効な電話番号を入力してください',
                                        'Please enter a valid phone number.',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed:
                                      (_isLoading || !isFirebaseAvailable)
                                      ? null
                                      : _sendSmsCode,
                                  child: _loadingButtonChild(
                                    label: _t('SMSコードを送信', 'Send SMS code'),
                                    loading: _isBusy(_AuthBusyAction.sendSms),
                                    spinnerColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // SMSコード入力フォーム
                          Form(
                            key: _smsFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _t('SMSコードを入力してください', 'Enter the SMS code'),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _t(
                                    '${_phoneController.text} に送信しました',
                                    'Sent to ${_phoneController.text}',
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _smsCodeController,
                                  decoration: InputDecoration(
                                    labelText: _t('SMSコード', 'SMS code'),
                                    hintText: _t('6桁のコード', '6-digit code'),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.sms),
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return _t(
                                        'SMSコードを入力してください',
                                        'Please enter the SMS code.',
                                      );
                                    }
                                    if (value.length != 6) {
                                      return _t(
                                        '6桁のコードを入力してください',
                                        'Please enter the 6-digit code.',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed:
                                      (_isLoading || !isFirebaseAvailable)
                                      ? null
                                      : _verifySmsCode,
                                  child: _loadingButtonChild(
                                    label: _t('認証', 'Verify'),
                                    loading: _isBusy(_AuthBusyAction.verifySms),
                                    spinnerColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _isLoading ? null : _sendSmsCode,
                                  child: Text(_t('コードを再送信', 'Resend code')),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          _awaitingPhoneAuthResult = false;
                                          _authSuccessHandled = false;
                                          setState(() {
                                            _isSmsCodeSent = false;
                                            _verificationId = null;
                                            _smsCodeController.clear();
                                            _errorMessage = null;
                                          });
                                        },
                                  child: Text(
                                    _t('電話番号を変更', 'Change phone number'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _isLoading ? null : _resetAuthMethod,
                          child: Text(_t('戻る', 'Back')),
                        ),
                      ],

                      const SizedBox(height: 32),
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
}
