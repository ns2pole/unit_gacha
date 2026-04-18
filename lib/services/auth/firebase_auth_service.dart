// lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../util/platform_info.dart';

/// Firebase認証サービス
/// メール/パスワード、電話番号認証、Google認証、Apple Sign-Inをサポート
class FirebaseAuthService {
  static const String _iosGoogleClientId = String.fromEnvironment(
    'FIREBASE_IOS_CLIENT_ID',
    defaultValue: '',
  );
  static const String _appleWebClientId = String.fromEnvironment(
    'FIREBASE_APPLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
  static const String _authHandlerUrl = String.fromEnvironment(
    'FIREBASE_AUTH_HANDLER_URL',
    defaultValue: '',
  );

  /// Firebaseが初期化されているか確認
  static bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// FirebaseAuthインスタンスを取得（初期化チェック付き）
  static FirebaseAuth get _auth {
    if (!_isFirebaseInitialized) {
      throw StateError(
        'Firebase has not been initialized. '
        'Make sure Firebase.initializeApp() is called before using Firebase services.'
      );
    }
    return FirebaseAuth.instance;
  }

  /// 現在のユーザーを取得
  static User? get currentUser {
    try {
      if (!_isFirebaseInitialized) return null;
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// 認証状態のストリーム
  static Stream<User?> get authStateChanges {
    try {
      if (!_isFirebaseInitialized) {
        return Stream.value(null);
      }
      return _auth.authStateChanges();
    } catch (e) {
      print('Error getting auth state changes: $e');
      return Stream.value(null);
    }
  }

  /// メール/パスワードでサインアップ
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (!_isFirebaseInitialized) {
        print('Error: Firebase not initialized');
        return null;
      }

      // 通常のサインアップ
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException signing up with email:');
      print('  Code: ${e.code}');
      print('  Message: ${e.message}');
      rethrow; // 呼び出し側でエラーを処理できるように再スロー
    } catch (e, stackTrace) {
      print('Error signing up with email: $e');
      print('Stack trace: $stackTrace');
      rethrow; // 呼び出し側でエラーを処理できるように再スロー
    }
  }

  /// メール/パスワードでログイン
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (!_isFirebaseInitialized) {
        print('Error: Firebase not initialized');
        return null;
      }

      // 通常のログイン
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException signing in with email:');
      print('  Code: ${e.code}');
      print('  Message: ${e.message}');
      rethrow; // 呼び出し側でエラーを処理できるように再スロー
    } catch (e, stackTrace) {
      print('Error signing in with email: $e');
      print('Stack trace: $stackTrace');
      rethrow; // 呼び出し側でエラーを処理できるように再スロー
    }
  }

  /// Google認証でログイン
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!_isFirebaseInitialized) {
        print('Error: Firebase not initialized');
        return null;
      }

      // Google Sign-Inのインスタンスを作成
      // iOSではclientIdを明示的に指定する必要がある
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: PlatformInfo.isIOS && _iosGoogleClientId.isNotEmpty
            ? _iosGoogleClientId
            : null,
      );

      // 既にサインインしている場合はサインアウト（再認証のため）
      await googleSignIn.signOut();

      // Googleアカウントでサインイン
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // ユーザーがサインインをキャンセルした
        print('Google Sign-In cancelled by user');
        return null;
      }

      // 認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase認証用のクレデンシャルを作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 通常のサインイン
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  /// 電話番号認証でSMSコードを送信
  /// [phoneNumber] 電話番号（例: +81901234567）
  /// [codeSent] SMSコードが送信されたときに呼ばれるコールバック
  /// [verificationFailed] 検証に失敗したときに呼ばれるコールバック
  /// [codeAutoRetrievalTimeout] 自動取得がタイムアウトしたときに呼ばれるコールバック
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) verificationFailed,
    Function(String verificationId)? codeAutoRetrievalTimeout,
  }) async {
    try {
      if (!_isFirebaseInitialized) {
        print('Error: Firebase not initialized');
        verificationFailed('Firebaseが初期化されていません');
        return;
      }

      print('Starting phone number verification...');
      print('Phone number: $phoneNumber');
      print(
        'Platform: ${PlatformInfo.isIOS ? "iOS" : PlatformInfo.isAndroid ? "Android" : "Unknown"}',
      );
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // 自動検証が成功した場合（Androidのみ）
          print('Phone number auto-verification completed');
          try {
            // 通常のサインイン
            await _auth.signInWithCredential(credential);
            print('Successfully signed in with phone number');
          } catch (e) {
            print('Error during auto-verification: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone number verification failed:');
          print('  Code: ${e.code}');
          print('  Message: ${e.message}');
          print('  Email: ${e.email}');
          print('  Credential: ${e.credential}');
          print('  Stack trace: ${e.stackTrace}');
          
          // internal-errorの場合、より詳細な情報を提供
          String errorMessage = e.message ?? '電話番号認証に失敗しました';
          if (e.code == 'internal-error') {
            errorMessage = '内部エラーが発生しました。\n'
                          'Firebase Consoleで電話番号認証が有効になっているか確認してください。\n'
                          'エラーコード: ${e.code}\n'
                          '詳細: ${e.message ?? "詳細情報なし"}';
            print('⚠️ Internal error detected. Possible causes:');
            print('  1. Phone authentication not enabled in Firebase Console');
            print('  2. reCAPTCHA configuration issue (Android)');
            print('  3. SMS service configuration issue');
            print('  4. Network connectivity issue');
            print('  5. Invalid phone number format');
          } else if (e.code == 'invalid-phone-number') {
            errorMessage = '無効な電話番号です。\n'
                          '国際形式（+81から始まる形式）で入力してください。';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'このデバイスからのリクエストが多すぎるため、\n'
                          'Firebaseが一時的にブロックしています。\n\n'
                          '対処法:\n'
                          '• 数時間から24時間待ってから再度お試しください\n'
                          '• 別のデバイスで試す\n'
                          '• テスト中はリクエスト回数を減らす\n\n'
                          'エラー詳細: ${e.message ?? "詳細情報なし"}';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'SMS送信の上限に達しました。\n\n'
                          '対処法:\n'
                          '• Firebase Console > 設定 > 請求 でBlazeプランにアップグレード\n'
                          '• 請求先アカウントが正しくリンクされているか確認\n'
                          '• テスト用電話番号を使用（Firebase Console > Authentication > Settings）\n'
                          '• 翌日まで待つ（1日あたりの制限がリセットされる）\n\n'
                          'エラー詳細: ${e.message ?? "詳細情報なし"}';
          } else if (e.code == 'operation-not-allowed') {
            errorMessage = '電話番号認証が有効になっていません。\n'
                          'Firebase Console > Authentication > Sign-in method で\n'
                          '電話番号認証を有効にしてください。';
          } else if (e.code == 'missing-phone-number') {
            errorMessage = '電話番号が入力されていません。';
          } else if (e.code == 'captcha-check-failed') {
            errorMessage = 'reCAPTCHA認証に失敗しました。\n'
                          'もう一度お試しください。';
          } else if (e.code == 'missing-app-credential' || e.code == 'invalid-app-credential') {
            errorMessage = 'アプリの認証情報が無効です。\n'
                          'Firebase設定ファイルを確認してください。';
          }
          
          verificationFailed(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('SMS code sent. Verification ID: $verificationId');
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('SMS code auto-retrieval timeout. Verification ID: $verificationId');
          if (codeAutoRetrievalTimeout != null) {
            codeAutoRetrievalTimeout(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Error verifying phone number: $e');
      verificationFailed('電話番号認証の開始に失敗しました: $e');
    }
  }

  /// SMSコードで電話番号認証を完了
  /// [verificationId] verifyPhoneNumberで取得した検証ID
  /// [smsCode] ユーザーが入力したSMSコード
  /// エラーが発生した場合は例外をスロー（呼び出し側で処理）
  static Future<UserCredential?> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (!_isFirebaseInitialized) {
        print('Error: Firebase not initialized');
        throw StateError('Firebaseが初期化されていません');
      }

      print('Attempting to sign in with phone number');
      print('Verification ID: ${verificationId.substring(0, 20)}...');
      print('SMS Code length: ${smsCode.length}');

      // PhoneAuthCredentialを作成
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // 通常のサインイン
      print('Signing in with phone credential (non-anonymous)');
      try {
        final userCredential = await _auth.signInWithCredential(credential);
        print('Successfully signed in with phone number');
        print('User UID: ${userCredential.user?.uid}');
        return userCredential;
      } on FirebaseAuthException catch (e) {
        print('FirebaseAuthException during sign-in:');
        print('  Code: ${e.code}');
        print('  Message: ${e.message}');
        print('  Email: ${e.email}');
        print('  Credential: ${e.credential}');
        rethrow; // 呼び出し側でエラーを処理できるように再スロー
      }
    } catch (e, stackTrace) {
      print('Error signing in with phone number: $e');
      print('Stack trace: $stackTrace');
      rethrow; // 呼び出し側でエラーを処理できるように再スロー
    }
  }

  /// Apple Sign-Inでログイン
  static Future<UserCredential?> signInWithApple() async {
    try {
      if (!_isFirebaseInitialized) {
        print('Error: Firebase not initialized');
        return null;
      }

      // AndroidでのApple Sign-Inは複雑で、Web認証の設定が必要
      // 通常はiOSでのみ使用することを推奨
      if (PlatformInfo.isAndroid) {
        print('⚠️ Apple Sign-In on Android requires complex web authentication setup.');
        print('⚠️ It is recommended to use Apple Sign-In on iOS only.');
      }

      // Apple Sign-Inの認証フロー
      // AndroidではwebAuthenticationOptionsが必要
      // Firebase Console > Authentication > Sign-in method > Apple で設定された
      // WebクライアントIDとリダイレクトURIを使用する必要があります
      //
      // ⚠️ 重要: Firebase Consoleで以下の手順でWebクライアントIDを確認してください:
      // 1. Firebase Console > Authentication > Sign-in method > Apple を開く
      // 2. 「Web SDK設定」セクションで「WebクライアントID」を確認
      // 3. その値を以下の clientId に設定してください
      // 4. リダイレクトURIもFirebase Consoleで設定されている値と一致させる必要があります
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: PlatformInfo.isAndroid &&
                _appleWebClientId.isNotEmpty &&
                _authHandlerUrl.isNotEmpty
            ? WebAuthenticationOptions(
                clientId: _appleWebClientId,
                redirectUri: Uri.parse(_authHandlerUrl),
              )
            : null,
      );

      // IDトークンが取得できなかった場合
      if (appleCredential.identityToken == null) {
        print('Error: Apple Sign-In identity token is null');
        return null;
      }

      // トークンの検証
      final identityToken = appleCredential.identityToken!;
      if (identityToken.isEmpty) {
        print('Error: Apple Sign-In identity token is empty');
        return null;
      }

      // authorizationCodeの検証を緩和（iOSではnullでも動作する可能性がある）
      // iOSではauthorizationCodeがnullの場合があるため、必須チェックを削除
      if (appleCredential.authorizationCode != null && 
          appleCredential.authorizationCode!.isEmpty) {
        print('Warning: Apple Sign-In authorization code is empty (but continuing with idToken only)');
      }

      // デバッグ用: トークンの最初の部分を表示（完全なトークンは表示しない）
      print('Apple Sign-In: Received identity token (length: ${identityToken.length})');
      print('Apple Sign-In: Received authorization code (length: ${appleCredential.authorizationCode!.length})');
      print('Apple Sign-In: User ID: ${appleCredential.userIdentifier}');
      print('Apple Sign-In: Email: ${appleCredential.email ?? "not provided"}');

      // Firebaseに認証情報を送信
      // iOSではauthorizationCodeがnullの場合、idTokenだけでクレデンシャルを作成
      // authorizationCodeがnullの場合は、accessTokenパラメータを省略するか、nullを渡す
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: identityToken,
        // iOSではauthorizationCodeがnullの場合、accessTokenを省略
        accessToken: appleCredential.authorizationCode,
      );

      print('Apple Sign-In: Attempting to sign in with Firebase...');
      print('Apple Sign-In: Using idToken (length: ${identityToken.length})');
      print('Apple Sign-In: authorizationCode is ${appleCredential.authorizationCode != null ? "provided" : "null"}');
      
      try {
        final userCredential = await _auth.signInWithCredential(oauthCredential);
        print('Apple Sign-In: Successfully signed in with Firebase');
        return userCredential;
      } on FirebaseAuthException catch (e) {
        // FirebaseAuthExceptionを適切にキャッチ
        print('FirebaseAuthException during Apple Sign-In:');
        print('  Code: ${e.code}');
        print('  Message: ${e.message}');
        print('  Email: ${e.email}');
        print('  Credential: ${e.credential}');
        
        // エラーコードに応じた適切な処理
        if (e.code == 'invalid-credential') {
          print('⚠️ Invalid credential error. This may indicate:');
          print('   - The identity token is invalid or expired');
          print('   - The bundle ID does not match Firebase Console');
          print('   - Apple Sign-In service configuration is incomplete');
        } else if (e.code == 'invalid-id-token') {
          print('⚠️ Invalid ID token error. This may indicate:');
          print('   - The identity token format is incorrect');
          print('   - The token has expired');
        } else if (e.code == 'account-exists-with-different-credential') {
          print('⚠️ Account exists with different credential');
        } else if (e.code == 'credential-already-in-use') {
          print('⚠️ Credential already in use');
        }
        
        // エラーを再スローせず、nullを返して呼び出し側で処理できるようにする
        return null;
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      // Apple Sign-Inの認証エラー
      if (e.code == AuthorizationErrorCode.canceled) {
        print('Apple Sign-In cancelled by user');
      } else {
        print('Apple Sign-In authorization error: ${e.code} - ${e.message}');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // FirebaseAuthExceptionの特定のエラーコードに対する適切な処理
      print('FirebaseAuthException during Apple Sign-In (outer catch):');
      print('  Code: ${e.code}');
      print('  Message: ${e.message}');
      print('  Email: ${e.email}');
      print('  Credential: ${e.credential}');
      
      // エラーコードに応じた詳細なログ出力
      if (e.code == 'invalid-credential') {
        print('⚠️ Invalid credential error detected.');
        print('⚠️ This may indicate:');
        print('   1. The identity token is invalid or expired');
        print('   2. The bundle ID does not match Firebase Console');
        print('   3. Apple Sign-In service configuration is incomplete');
      } else if (e.code == 'invalid-id-token') {
        print('⚠️ Invalid ID token error detected.');
        print('⚠️ This may indicate:');
        print('   1. The identity token format is incorrect');
        print('   2. The token has expired');
      } else if (e.code == 'account-exists-with-different-credential') {
        print('⚠️ Account exists with different credential');
      } else if (e.code == 'credential-already-in-use') {
        print('⚠️ Credential already in use');
      }
      
      return null;
    } catch (e, stackTrace) {
      print('Error signing in with Apple: $e');
      print('Stack trace: $stackTrace');
      
      // Androidでのエラーの場合、特別なメッセージを表示
      if (PlatformInfo.isAndroid) {
        print('');
        print('⚠️ Apple Sign-In failed on Android.');
        print('⚠️ Apple Sign-In on Android requires:');
        print('   1. Correct Web client ID in Firebase Console');
        print('   2. Correct redirect URI configuration');
        print('   3. Proper OAuth setup in Google Cloud Console');
        print('⚠️ It is recommended to use Apple Sign-In on iOS only.');
        print('⚠️ For Android, consider using Google Sign-In instead.');
        print('');
      }
      
      // Firebase設定エラーの場合、より詳細な情報を提供
      final errorString = e.toString();
      
      if (errorString.contains('CONFIGURATION_NOT_FOUND') || 
          errorString.contains('17999')) {
        print('');
        print('⚠️ Apple Sign-In configuration error detected.');
        print('⚠️ This error usually means Apple Sign-In is not configured in Firebase Console.');
        print('⚠️ To fix this:');
        print('   1. Go to Firebase Console > Authentication > Sign-in method');
        print('   2. Enable "Apple" as a sign-in provider');
        print('   3. Make sure your bundle ID ( com.joyphysics.unitgacha) matches your Firebase project');
        print('   4. Configure the OAuth client ID if required');
        print('');
      } else if (errorString.contains('invalid') && errorString.contains('client')) {
        print('');
        print('⚠️ Invalid client ID error detected.');
        print('⚠️ This error means the Web client ID in the code does not match Firebase Console.');
        print('⚠️ To fix this:');
        print('   1. Go to Firebase Console > Authentication > Sign-in method > Apple');
        print('   2. Check the "Web SDK configuration" section');
        print('   3. Copy the "Web client ID" (format: PROJECT_NUMBER-XXXXX.apps.googleusercontent.com)');
        print('   4. Update the clientId in firebase_auth_service.dart with the actual value');
        print('   5. Also verify the redirect URI matches Firebase Console settings');
        print('');
      } else if (errorString.contains('invalid-credential') || 
                 errorString.contains('Invalid OAuth response')) {
        print('');
        print('⚠️ Apple Sign-In credential validation error detected.');
        print('⚠️ This error usually means:');
        print('   1. The identity token from Apple is invalid or expired');
        print('   2. The bundle ID in Firebase Console does not match your app');
        print('   3. Apple Sign-In service configuration in Firebase is incomplete');
        print('');
        print('⚠️ To fix this:');
        print('   1. Verify your bundle ID ( com.joyphysics.unitgacha) matches in:');
        print('      - Xcode project settings');
        print('      - Firebase Console > Project Settings > Your apps');
        print('      - Apple Developer Console');
        print('   2. In Firebase Console > Authentication > Sign-in method > Apple:');
        print('      - Verify the service is enabled');
        print('      - Check if OAuth client ID is required and configured');
        print('   3. Make sure you are testing on a real device (not simulator)');
        print('      or that the simulator is properly configured');
        print('');
      }
      
      return null;
    }
  }

  /// パスワードリセットメールを送信
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      if (!_isFirebaseInitialized) {
        print('Error: Firebase not initialized');
        throw StateError('Firebaseが初期化されていません');
      }
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException sending password reset email:');
      print('  Code: ${e.code}');
      print('  Message: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  /// ログアウト
  static Future<void> signOut() async {
    try {
      if (!_isFirebaseInitialized) {
        print('Error: Firebase not initialized');
        return;
      }
      await _auth.signOut();
      // ログアウト時もlastUserIdを保持し、次回ログイン時のアカウント切り替え判定に使用
      // これにより、ログアウト後に別アカウントでログインした場合、正しくマージ処理が実行される
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// 認証済みかどうか
  static bool get isAuthenticated {
    try {
      if (!_isFirebaseInitialized) return false;
      return currentUser != null;
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  /// ユーザーIDを取得
  static String? get userId => currentUser?.uid;

  /// ユーザーのメールアドレスを取得
  static String? get userEmail => currentUser?.email;

  /// ユーザーの電話番号を取得
  static String? get userPhoneNumber => currentUser?.phoneNumber;

  /// ユーザーの表示名を取得
  static String? get displayName => currentUser?.displayName;

  /// ログイン方法を取得（日本語表示用）
  /// 例: "メールアドレス", "Googleアカウント", "Appleアカウント", "電話番号", "匿名"
  static String? get loginMethod {
    try {
      if (!_isFirebaseInitialized) return null;
      final user = currentUser;
      if (user == null) return null;

      // providerDataからログイン方法を取得
      // 複数のプロバイダーがリンクされている場合、最初の非匿名プロバイダーを使用
      for (final provider in user.providerData) {
        switch (provider.providerId) {
          case 'password':
            return 'メールアドレス';
          case 'google.com':
            return 'Googleアカウント';
          case 'apple.com':
            return 'Appleアカウント';
          case 'phone':
            return '電話番号';
          default:
            continue;
        }
      }

      // デフォルト（不明な場合）
      return null;
    } catch (e) {
      print('Error getting login method: $e');
      return null;
    }
  }

}

